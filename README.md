# rack.nvim

Neovim plugin for [Rack](../Rack/README.md) — a git-like version control system built around content-addressable storage. Zero dependencies beyond Neovim 0.10+.

## Features

- Telescope-style 3-pane picker (prompt / results / preview) built from scratch with `nvim_open_win`
- Plate history browser with timestamps, restore, and diff
- Interactive diff picker — choose any two plates, browse changed files, view per-file diffs with `DiffAdd`/`DiffDelete` highlighting
- File browser with live preview
- Project switcher
- Floating commit, push, pull, status, domain, reconstruct
- Auto-push timer via `vim.uv`

## Requirements

- Neovim 0.10+
- `rack` binary on `$PATH` (or configured via `rack_cmd`)

## Installation

**lazy.nvim**
```lua
{
  dir = '~/project/rack.nvim',
  config = function()
    require('rack').setup()
  end,
}
```

With keymaps:
```lua
{
  dir = '~/project/rack.nvim',
  config = function()
    require('rack').setup({
      keymaps = {
        ['<leader>rc'] = function() require('rack').commit_quick() end,
        ['<leader>rC'] = function() require('rack').commit_named() end,
        ['<leader>rl'] = function() require('rack').log() end,
        ['<leader>rf'] = function() require('rack').files() end,
        ['<leader>rs'] = function() require('rack').status() end,
        ['<leader>rp'] = function() require('rack').push() end,
        ['<leader>rP'] = function() require('rack').pull() end,
        ['<leader>rd'] = function() require('rack').domain() end,
        ['<leader>rD'] = function() require('rack').diff() end,
        ['<leader>rx'] = function() require('rack').diff_pick() end,
        ['<leader>rr'] = function() require('rack').reconstruct() end,
        ['<leader>ri'] = function() require('rack').init_project() end,
        ['<leader>r?'] = function() require('rack').server_check() end,
      },
    })
  end,
}
```

## Configuration

All fields are optional. These are the defaults:

```lua
require('rack').setup({
  -- Path to the rack binary
  rack_cmd = 'rack',

  -- Available flags shown in the flag picker when doing a named commit
  flags = { 'Normal', 'Hotfix', 'Knot' },

  -- Auto-push: commit + push on a timer in the background
  auto_push = {
    enabled          = false,
    interval         = 600,    -- seconds (default: 10 min)
    only_if_changed  = true,   -- skip if HEAD hasn't moved since last push
    silent           = true,   -- suppress notifications on each auto-push
  },

  -- Optional keymap table: { ['<key>'] = function() ... end }
  keymaps = nil,

  -- Floating window appearance
  ui = {
    width         = 0.8,       -- fraction of editor width
    height        = 0.8,       -- fraction of editor height
    border        = 'rounded', -- 'rounded' | 'single' | 'double' | 'none'
    preview_ratio = 0.6,       -- preview panel takes 60% of total width
  },

  -- Show vim.notify messages for actions
  notify = true,
})
```

## Commands

| Command | Description |
|---|---|
| `:RackCommit` | Commit current files (quick, no name) |
| `:RackCommitNamed` | Prompt for name → flag picker → commit |
| `:RackPush [project]` | Push to server |
| `:RackPull [project]` | Pull from server |
| `:RackLog [project]` | Open plate history picker |
| `:RackFiles [project]` | Open files picker for latest plate |
| `:RackProjects` | Open project list picker |
| `:RackStatus` | Show local vs server diff in a float |
| `:RackDiff` | Diff local HEAD vs server HEAD (file picker) |
| `:RackDiff <plate>` | Diff plate vs server HEAD (short hash ok) |
| `:RackDiff <plateA> <plateB>` | Diff two server plates |
| `:RackDiffPicker` | Interactive two-step plate selector → diff |
| `:RackDomain` | Prompt for server URL and save it |
| `:RackInitProject` | Prompt for project name, init/activate it |
| `:RackDeleteProject [name]` | Delete project from server (confirm dialog) |
| `:RackReconstruct` | Rebuild files from local HEAD (confirm dialog) |
| `:RackServerCheck` | Ping server and notify online/offline |
| `:RackAutoPushToggle` | Toggle the auto-push timer on/off |

## Pickers

All pickers share the same controls:

| Key | Action |
|---|---|
| Type anything | Fuzzy-filter results |
| `<C-n>` / `<C-p>` | Move selection down / up |
| `<CR>` | Confirm selection |
| `<Esc>` | Close picker |

### Plate Log (`:RackLog`)

Shows the full plate chain, HEAD first. Each row shows the short hash, flag, name, timestamp, and HEAD marker. Rows are colour-coded by flag and name (see [Highlight groups](#highlight-groups)).

```
┌─ Plate Log ──────────────────────────────────────┐  ┌─ Preview ──────────────────────────┐
│ > query_                                         │  │ ID:     a3f8c1d92b04               │
├──────────────────────────────────────────────────┤  │ Flag:   Hotfix                     │
│ > a3f8c1d92b04  Hotfix   fix auth  2025-04-27 …  │  │ Name:   fix auth token check       │
│   91b2d477cc1e  Normal   add tests 2025-04-26 …  │  │ Files:  12                         │
│   ...                                            │  │ Time:   2025-04-27 14:32:01        │
└──────────────────────────────────────────────────┘  │         <- HEAD                    │
                                                       │                                    │
                                                       │   src/auth.cpp                     │
                                                       │   src/token.h                      │
                                                       │   ...                              │
                                                       └───────────────────────────────────┘
```

Extra keys in this picker:

| Key | Action |
|---|---|
| `<CR>` | Restore selected plate (confirm dialog) |
| `<C-r>` | Restore selected plate immediately (no confirm) |
| `<C-d>` | Diff selected plate vs local HEAD |

The preview shows plate metadata (ID, flag, name, file count, timestamp). For the HEAD plate it also lists all files.

### Diff picker (`:RackDiff`, `:RackDiffPicker`, `<C-d>` in log)

All diff paths lead to the same 3-pane file picker. Changed files are listed and colour-coded; preview shows the unified diff for the selected file; `<CR>` opens a focused full-screen diff float for that file.

```
┌─ diff  a3f8c1  →  91b2d4  (1 added, 0 removed, 2 modified) ─┐  ┌─ Preview ──────────────────────┐
│ > filter_                                                    │  │ --- a/src/auth.cpp             │
├──────────────────────────────────────────────────────────────┤  │ +++ b/src/auth.cpp             │
│ > [~]  src/auth.cpp                                          │  │ @@ ... @@                      │
│   [~]  src/token.h                                           │  │ -if (expiry < now)             │
│   [+]  src/logger.cpp                                        │  │ +if (expiry <= now)            │
└──────────────────────────────────────────────────────────────┘  └────────────────────────────────┘
```

Row colours: `[+]` added → `DiffAdd`, `[-]` removed → `DiffDelete`, `[~]` modified → `DiffChange`. Preview and focused float use the same `DiffAdd`/`DiffDelete`/`Comment` extmarks for line highlighting.

**`:RackDiff [plateA [plateB]]`** — quick diff, no plate selection step:
```vim
:RackDiff                    " local  vs  server HEAD
:RackDiff a3f8c1             " plate a3f8c1  vs  server HEAD
:RackDiff a3f8c1 91b2d4      " plate a3f8c1  vs  plate 91b2d4
```

**`:RackDiffPicker`** — interactive two-step plate selector:

1. Picker shows full plate log + `local HEAD` special entry → pick **plate A**
2. Picker shows plate log (excluding A) + `server HEAD` special entry → pick **plate B**
3. Diff file picker opens with results

`<C-d>` inside `:RackLog` runs `rack diff <plate>` directly (selected plate vs local HEAD).

### Files (`:RackFiles`)

Lists every file in the latest server plate. Preview shows file contents from disk with syntax highlighting. `<CR>` opens the file in whichever window was active before the picker.

### Projects (`:RackProjects`)

Lists all projects on the server. Active project is marked `<- active`.

| Key | Action |
|---|---|
| `<CR>` | Switch to selected project (`rack init <name>`) |
| `<C-d>` | Delete selected project (confirm dialog) |

## Statusline integration

`require('rack').server_status()` returns `true` if the server is reachable. Synchronous — use only in statuslines that already poll:

```lua
-- lualine example
{
  function()
    return require('rack').server_status() and '● rack' or '○ rack'
  end,
  color = function()
    return { fg = require('rack').server_status() and '#a6e3a1' or '#f38ba8' }
  end,
}
```

## Auto-push

When enabled, a `vim.uv` timer fires every `interval` seconds and:

1. Reads current local HEAD hash.
2. If `only_if_changed = true` and HEAD hasn't moved since last push, skips.
3. Runs `rack commit` then `rack push`.

Toggle at runtime with `:RackAutoPushToggle` or `require('rack').auto_push_toggle()`.

## Highlight groups

Override in your colorscheme or `init.lua`:

| Group | Default | Used for |
|---|---|---|
| `RackNormal` | `NormalFloat` | Window background |
| `RackBorder` | `FloatBorder` | Window borders |
| `RackSelection` | `Visual` | Selected row in results |
| `RackFlagHotfix` | `#f38ba8` (red) | Log row with `Hotfix` flag |
| `RackFlagKnot` | `#cba6f7` (purple) | Log row with `Knot` flag |
| `RackNamed` | `#f9e2af` (yellow) | Log row with a name but `Normal` flag |
| `RackDiffAdded` | `DiffAdd` | Diff picker row — added file |
| `RackDiffRemoved` | `DiffDelete` | Diff picker row — removed file |
| `RackDiffModified` | `DiffChange` | Diff picker row — modified file |

```lua
vim.api.nvim_set_hl(0, 'RackBorder',    { fg = '#89b4fa' })
vim.api.nvim_set_hl(0, 'RackSelection', { bg = '#313244', bold = true })
```

## Notes

- **File preview for old plates** is not available because `rack files` only shows the latest plate. A `rack files <plate-id>` CLI command would unlock this.
- **`rack log` / `rack files` / `rack projects`** output is plain text. Adding `--json` to the CLI would make parsing more robust.
- All async CLI calls use `vim.system` and schedule results onto the main loop — no blocking.
