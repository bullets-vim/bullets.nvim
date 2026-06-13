# bullets.nvim

Neovim Lua plugin for continuing, renumbering, promoting, demoting, and toggling bullet lists.

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "bullets-vim/bullets.nvim",
  opts = {},
}
```

Configure options through `opts`:

```lua
{
  "bullets-vim/bullets.nvim",
  opts = {
    enabled_file_types = { "markdown", "text", "gitcommit" },
    mapping_leader = "",
  },
}
```

Without a plugin manager, call setup from Lua:

```lua
require("bullets").setup({})
```

Vim is unsupported. Vimscript configuration, including `vim.g.bullets_*` variables, is unsupported.
Configure this plugin only with `require("bullets").setup({})` or lazy.nvim `opts`.

## Options

Defaults from `lua/bullets/config.lua`:

```lua
{
  enabled_file_types = { "markdown", "text", "gitcommit" },
  enable_in_empty_buffers = false,
  set_mappings = true,
  mapping_leader = "",
  custom_mappings = {},
  delete_last_bullet_if_empty = 1,
  line_spacing = 1,
  pad_right = true,
  max_alpha_characters = 2,
  enable_roman_list = true,
  list_item_styles = { "-", "*+", ".+", "#.", "+", "\\item" },
  outline_levels = { "ROM", "ABC", "num", "abc", "rom", "std-", "std*", "std+" },
  renumber_on_change = true,
  nested_checkboxes = true,
  enable_wrapped_lines = true,
  checkbox_markers = " .oOX",
  checkbox_partials_toggle = 1,
  auto_indent_after_colon = true,
}
```

`custom_mappings` entries are passed to `vim.keymap.set` as `{ mode, lhs, rhs }` for each configured buffer.

## Commands

The plugin defines these commands:

| Command                | Action                                   |
| ---------------------- | ---------------------------------------- |
| `:InsertNewBullet`     | Insert a continued list item.            |
| `:RenumberList`        | Renumber the current list.               |
| `:RenumberSelection`   | Renumber the selected range.             |
| `:ToggleCheckbox`      | Toggle the checkbox on the current item. |
| `:RecomputeCheckboxes` | Recompute nested checkbox states.        |
| `:BulletDemote`        | Demote the current item.                 |
| `:BulletPromote`       | Promote the current item.                |
| `:BulletDemoteVisual`  | Demote the selected range.               |
| `:BulletPromoteVisual` | Promote the selected range.              |

These selection commands are registered but not implemented yet: `:SelectCheckbox`,
`:SelectCheckboxInside`, `:SelectBullet`, and `:SelectBulletText`.

## Mappings

Default mappings are buffer-local for `enabled_file_types` when `set_mappings = true`.
Each left-hand side is prefixed with `mapping_leader`, which defaults to an empty string.

| Mode   | Mapping     | Action                                   |
| ------ | ----------- | ---------------------------------------- |
| Insert | `<CR>`      | Insert a continued list item.            |
| Insert | `<C-CR>`    | Insert a plain newline.                  |
| Normal | `o`         | Insert a continued list item.            |
| Normal | `gN`        | Renumber the current list.               |
| Visual | `gN`        | Renumber the selected range.             |
| Normal | `<leader>x` | Toggle the checkbox on the current item. |
| Insert | `<C-t>`     | Demote the current item.                 |
| Normal | `>>`        | Demote the current item.                 |
| Insert | `<C-d>`     | Promote the current item.                |
| Normal | `<<`        | Promote the current item.                |

The plugin also defines these `<Plug>` mappings for custom mappings:

| Mapping                                | Modes                  |
| -------------------------------------- | ---------------------- |
| `<Plug>(bullets-newline)`              | Insert, Normal         |
| `<Plug>(bullets-renumber)`             | Normal, Visual         |
| `<Plug>(bullets-toggle-checkbox)`      | Normal                 |
| `<Plug>(bullets-recompute-checkboxes)` | Normal                 |
| `<Plug>(bullets-demote)`               | Insert, Normal, Visual |
| `<Plug>(bullets-promote)`              | Insert, Normal, Visual |

## Development

Install tools with mise:

```sh
mise install
```

Format files:

```sh
mise run fmt
```

Check formatting:

```sh
mise run fmt:check
```

Run tests:

```sh
mise run test
```

The test task runs each `test/*_spec.lua` file in headless Neovim with plenary.

## Releases

See [docs/RELEASE.md](docs/RELEASE.md) for release-please setup and token permissions.
