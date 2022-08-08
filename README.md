# telescope-git-browse.nvim
Git browsing extension for [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim).

   - impove **git_commits**
      - don't reorder commits when filtering them
      - add commit SHA/date/author/message in preview
      - actions open the commit preview
   - add git **live_grep** and **grep_string**
   - add tag **live_grep**

# Installation

## packer

```lua
use { "antoinemadec/telescope-git-browse.nvim" }
```

## Vim-Plug

```viml
Plug 'antoinemadec/telescope-git-browse.nvim'
```

# Setup and Configuration

```lua
require('telescope').setup {
...
}

require('telescope').load_extension('git_browse')
````

# Documentation

| **Command**                           | **Description**                                                               | **Comment**                                           |
|---------------------------------------|-------------------------------------------------------------------------------|-------------------------------------------------------|
| `Telescope git_browse commit_msgs`    |   Replaces `git_commits` : no reordering, more info, actions open the commit  |                                                       |
| `Telescope git_browse bcommit_msgs`   |   Replaces `git_bcommits` : no reordering, more info, actions open the commit |                                                       |
| `Telescope git_browse ccommit_msgs`   |   `commit_msgs` for current working directory                                 |                                                       |
| `Telescope git_browse live_grep`      |   Equivalent of `live_grep` using `git grep`                                  | Not fuzzy                                             |
| `Telescope git_browse grep_string`    |   Equivalent of `grep_string` using `git grep`. Default: search for \<cword\> | Fuzzy. Call with `search=` to search in the whole repo|
| `Telescope git_browse live_tags`      |   Equivalent of `live_grep` in ctags files                                    | Not fuzzy                                             |
