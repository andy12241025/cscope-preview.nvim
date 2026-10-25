# cscope-preview.nvim

Peek definitions, references and callers in a floating window, like
[goto-preview](https://github.com/rmagatti/goto-preview), but powered by
**cscope** instead of LSP. It queries through
[cscope_maps.nvim](https://github.com/dhananjaylatkar/cscope_maps.nvim), so it
uses the very same cscope database and needs no `compile_commands.json`.

## Requirements

- Neovim 0.10+
- `cscope` executable
- [dhananjaylatkar/cscope_maps.nvim](https://github.com/dhananjaylatkar/cscope_maps.nvim)
  configured with a cscope database

## Install (lazy.nvim)

```lua
{
  "andy12241025/cscope-preview.nvim",
  dependencies = { "dhananjaylatkar/cscope_maps.nvim" },
  opts = {}, -- { width = 0.6, height = 0.5, border = "rounded" }
  keys = {
    { "<leader>d", function() require("cscope_preview").peek("definition") end, desc = "Cscope preview definition" },
    { "<leader>s", function() require("cscope_preview").peek("references") end, desc = "Cscope preview references" },
    { "<leader>r", function() require("cscope_preview").peek("callers") end, desc = "Cscope preview callers" },
  },
},
```

## Usage

`:CscopePreview {definition|references|callers|callees}` previews the symbol
under the cursor. `:CscopePreviewClose` closes all previews. Previews can be
nested.

Inside a preview (an editable float):

| Key | Action |
| --- | --- |
| `<C-n>` / `<C-p>` | next / previous match |
| `<CR>` | close previews and jump to this location |
| `q` | close all previews |
| `<Esc>` | close this preview only |

## Notes

- cscope matches by name, not type or scope, so common names can have several
  hits; use `<C-n>` / `<C-p>`.
- cscope line numbers go stale when a file changes after the database was
  built. The float title shows `(file newer than cscope db)` in that case.
  Rebuild the database to fix it.

## License

MIT
