if vim.g.loaded_cscope_preview then
  return
end
vim.g.loaded_cscope_preview = true

local kinds = { "definition", "references", "callers", "callees" }

vim.api.nvim_create_user_command("CscopePreview", function(args)
  require("cscope_preview").peek(args.args)
end, {
  nargs = 1,
  complete = function()
    return kinds
  end,
  desc = "Peek a cscope result in a floating window",
})

vim.api.nvim_create_user_command("CscopePreviewClose", function()
  require("cscope_preview").close_all()
end, { desc = "Close all cscope previews" })
