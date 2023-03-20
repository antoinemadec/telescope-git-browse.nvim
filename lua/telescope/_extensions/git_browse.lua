local M_git = {}
local M_file = {}

local action_set = require "telescope.actions.set"
local action_state = require "telescope.actions.state"
local actions = require "telescope.actions"
local conf = require("telescope.config").values
local finders = require "telescope.finders"
local make_entry = require "telescope.make_entry"
local pickers = require "telescope.pickers"
local previewers = require "telescope.previewers"
local sorters = require "telescope.sorters"
local utils = require "telescope.utils"

local gb_actions = require('telescope._extensions.git_browse.actions')
local gb_previewers = require('telescope._extensions.git_browse.previewers')
local gb_sorters = require('telescope._extensions.git_browse.sorters')
local gb_utils = require('telescope._extensions.git_browse.utils')

local git_grep_command = { 'git', 'grep', '--line-number', '--column', '-I', '--ignore-case' }
local git_log_command = { "git", "log", "--pretty=oneline", "--abbrev-commit", "--", }

M_git.live_grep = function(opts)
  if opts.is_bare then
    utils.notify("git_browse.live_grep", {
      msg = "This operation must be run in a work tree",
      level = "ERROR",
    })
    return
  end

  local recurse_submodules = vim.F.if_nil(opts.recurse_submodules, false)
  local git_command = vim.F.if_nil(opts.git_command, git_grep_command)

  local live_grepper = finders.new_job(function(prompt)
    if not prompt or prompt == "" then
      return nil
    end
    return vim.tbl_flatten { git_command, recurse_submodules, "--", prompt }
  end, opts.entry_maker or make_entry.gen_from_vimgrep(opts), opts.max_results, opts.cwd)

  pickers.new(opts, {
    prompt_title = "GitBrowse Live Grep",
    finder = live_grepper,
    previewer = conf.grep_previewer(opts),
    sorter = sorters.highlighter_only(opts),
  }):find()
end

M_git.grep_string = function(opts)
  if opts.is_bare then
    utils.notify("git_browse.grep_string", {
      msg = "This operation must be run in a work tree",
      level = "ERROR",
    })
    return
  end

  local recurse_submodules = vim.F.if_nil(opts.recurse_submodules, false)
  local git_command = vim.F.if_nil(opts.git_command, git_grep_command)

  local word = opts.search or vim.fn.expand "<cword>"
  local search = opts.use_regex and word or gb_utils.escape_chars(word)
  local word_match = opts.word_match
  opts.entry_maker = opts.entry_maker or make_entry.gen_from_vimgrep(opts)

  local additional_args = {}
  if opts.additional_args ~= nil and type(opts.additional_args) == "function" then
    additional_args = opts.additional_args(opts)
  end

  -- TODO: when adding '--' inbetween word_match and search, vim.flatten sometimes skip search.
  -- this behavior is not consistant and seem to arise more on slower machines
  local args = vim.tbl_flatten {
    git_command,
    recurse_submodules,
    additional_args,
    word_match,
    search,
  }

  pickers.new(opts, {
    prompt_title = "GitBrowse Find Word (" .. word .. ")",
    finder = finders.new_oneshot_job(args, opts),
    previewer = conf.grep_previewer(opts),
    sorter = conf.generic_sorter(opts),
  }):find()
end

local commit_msgs_core = function(opts)
  opts.entry_maker = vim.F.if_nil(opts.entry_maker, make_entry.gen_from_git_commits(opts))
  local git_command = vim.F.if_nil(opts.git_command, git_log_command)
  if opts.git_files_or_dirs then
    git_command = vim.tbl_flatten { git_command, opts.git_files_or_dirs }
  end

  pickers
    .new(opts, {
      prompt_title = "GitBrowse Commits",
      finder = finders.new_oneshot_job(git_command, opts),
      previewer = gb_previewers.git_commit_diff_to_parent.new(opts),
      sorter = gb_sorters.preserve_order(opts),
      attach_mappings = function(_, _)
        actions.select_default:replace(gb_actions.select_preview_default)
        actions.select_horizontal:replace(gb_actions.select_preview_horizontal)
        actions.select_vertical:replace(gb_actions.select_preview_vertical)
        actions.select_tab:replace(gb_actions.select_preview_tab)
        return true
      end,
    })
    :find()
end

M_git.commit_msgs = function(opts)
  commit_msgs_core(opts)
end

M_git.bcommit_msgs = function(opts)
  opts.git_files_or_dirs = vim.api.nvim_buf_get_name(0)
  commit_msgs_core(opts)
end

M_git.ccommit_msgs = function(opts)
  opts.git_files_or_dirs = vim.fn.getcwd()
  commit_msgs_core(opts)
end

M_file.live_tags = function(opts)
  local tag_grep_command = { "rg", "--color=never", "--no-heading", "--smart-case" }
  opts.bufnr = 0 -- TODO: dirty hack to leverage make_entry.gen_from_ctags()

  local tagfiles = opts.ctags_file and { opts.ctags_file } or vim.fn.tagfiles()
  if vim.tbl_isempty(tagfiles) then
    utils.notify("builtin.tags", {
      msg = "No tags file found. Create one with ctags -R",
      level = "ERROR",
    })
    return
  end

  local live_grepper = finders.new_job(function(prompt)
    if not prompt or prompt == "" then
      return nil
    end
    return vim.tbl_flatten { tag_grep_command, "--", prompt, tagfiles }
  end, opts.entry_maker or make_entry.gen_from_ctags(opts), opts.max_results, opts.cwd)

  pickers.new(opts, {
    prompt_title = "Live Tags",
    finder = live_grepper,
    previewer = previewers.ctags.new(opts),
    sorter = sorters.highlighter_only(opts),
    attach_mappings = function()
      action_set.select:enhance {
        post = function()
          local selection = action_state.get_selected_entry()

          if selection.scode then
            -- un-escape / then escape required
            -- special chars for vim.fn.search()
            -- ] ~ *
            local scode = selection.scode:gsub([[\/]], "/"):gsub("[%]~*]", function(x)
              return "\\" .. x
            end)

            vim.cmd "norm! gg"
            vim.fn.search(scode)
            vim.cmd "norm! zz"
          else
            vim.api.nvim_win_set_cursor(0, { selection.lnum, 0 })
          end
        end,
      }
      return true
    end,
  }):find()
end

local gb_with_checks = gb_utils.apply_checks(M_git)

return require('telescope').register_extension({
  exports = {
    live_grep = gb_with_checks.live_grep,
    grep_string = gb_with_checks.grep_string,
    commit_msgs = gb_with_checks.commit_msgs,
    bcommit_msgs = gb_with_checks.bcommit_msgs,
    ccommit_msgs = gb_with_checks.ccommit_msgs,
    live_tags = M_file.live_tags,
  },
})
