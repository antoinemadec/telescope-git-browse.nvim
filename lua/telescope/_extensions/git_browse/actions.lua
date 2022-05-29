local M = {}
local action_state = require "telescope.actions.state"

local edit_buffer
do
  local map = {
    edit = "buffer",
    new = "sbuffer",
    vnew = "vert sbuffer",
    tabedit = "tab sb",
  }

  edit_buffer = function(command, bufnr)
    command = map[command]
    if command == nil then
      error "There was no associated buffer command"
    end
    vim.cmd(string.format("%s %d", command, bufnr))
  end
end

local select_preview = function(prompt_bufnr, command)
  local picker = action_state.get_current_picker(prompt_bufnr) -- picker state

  -- copy previewer content in new buffer
  local buf_preview = picker.previewer.state.bufnr
  local lines = vim.api.nvim_buf_get_lines(buf_preview, 0, -1, false)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'git')
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)

  -- set context mark for jumplist
  pcall(vim.api.nvim_set_current_win, picker.original_win_id)
  vim.cmd "normal! m'"

  -- open new buffer
  edit_buffer(command, buf)
end

M.select_preview_default = function(prompt_bufnr)
  return select_preview(prompt_bufnr, "edit")
end

M.select_preview_horizontal = function(prompt_bufnr)
  return select_preview(prompt_bufnr, "new")
end

M.select_preview_vertical = function(prompt_bufnr)
  return select_preview(prompt_bufnr, "vnew")
end

M.select_preview_tab = function(prompt_bufnr)
  return select_preview(prompt_bufnr, "tabedit")
end

return M
