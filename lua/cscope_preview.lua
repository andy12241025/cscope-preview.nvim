-- Floating-window peek for cscope results (goto-preview style, no LSP).
-- Queries through cscope_maps.nvim, so it uses the exact same cscope db.
local M = {}

local RC = require("cscope_maps.utils.ret_codes")

---@class CscopePreviewOpts
---@field width? number  fraction of editor width (default 0.6)
---@field height? number fraction of editor height (default 0.5)
---@field border? string border style (default "rounded")
local opts = { width = 0.6, height = 0.5, border = "rounded" }

-- stack of open previews, innermost last
local stack = {}

local ops = {
  definition = { n = "1", s = "g" },
  references = { n = "0", s = "s" },
  callers = { n = "3", s = "c" },
  callees = { n = "2", s = "d" },
}

local function close_top()
  local top = table.remove(stack)
  if top and vim.api.nvim_win_is_valid(top.win) then
    vim.api.nvim_win_close(top.win, true)
  end
end

function M.close_all()
  while #stack > 0 do
    close_top()
  end
end

local function load_buf(path)
  local buf = vim.fn.bufadd(path)
  if not vim.api.nvim_buf_is_loaded(buf) then
    vim.fn.bufload(buf)
    vim.bo[buf].buflisted = false
  end
  if vim.bo[buf].filetype == "" then
    local ft = vim.filetype.match({ buf = buf })
    if ft then
      vim.bo[buf].filetype = ft
    end
  end
  return buf
end

-- cscope line numbers go stale when a file is edited after the db was built
local function stale_note(path)
  local conn = require("cscope.db").primary_conn()
  local dbst = conn and vim.uv.fs_stat(conn.file)
  local fst = vim.uv.fs_stat(path)
  if dbst and fst and fst.mtime.sec > dbst.mtime.sec then
    return " (file newer than cscope db)"
  end
  return ""
end

local function show(entry, idx, total)
  local path = vim.fn.fnamemodify(entry.filename, ":p")
  local buf = load_buf(path)
  local lnum = math.min(tonumber(entry.lnum) or 1, vim.api.nvim_buf_line_count(buf))
  local title = string.format(" %s:%d [%d/%d]%s ", vim.fn.fnamemodify(path, ":~:."), lnum, idx, total, stale_note(path))

  local width = math.floor(vim.o.columns * opts.width)
  local height = math.floor(vim.o.lines * opts.height)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = opts.border,
    title = title,
    title_pos = "center",
  })
  vim.wo[win].number = true
  vim.wo[win].cursorline = true
  vim.api.nvim_win_set_cursor(win, { lnum, 0 })
  vim.cmd("normal! zz")
  return win, buf
end

local function open(results)
  local idx = 1
  local map_keys
  local win, buf = show(results[1], 1, #results)
  table.insert(stack, { win = win })

  local function goto_idx(i)
    idx = (i - 1) % #results + 1
    local old = win
    win, buf = show(results[idx], idx, #results)
    stack[#stack].win = win
    vim.api.nvim_win_close(old, true)
    map_keys()
  end

  map_keys = function()
    local o = { buffer = buf, nowait = true, silent = true }
    vim.keymap.set("n", "q", close_top, o)
    vim.keymap.set("n", "<Esc>", close_top, o)
    vim.keymap.set("n", "<C-n>", function() goto_idx(idx + 1) end, o)
    vim.keymap.set("n", "<C-p>", function() goto_idx(idx - 1) end, o)
    -- jump to the previewed location in the real window
    vim.keymap.set("n", "<CR>", function()
      local l = vim.api.nvim_win_get_cursor(win)[1]
      local name = vim.api.nvim_buf_get_name(buf)
      M.close_all()
      vim.cmd("normal! m'")
      vim.cmd.edit(vim.fn.fnameescape(name))
      vim.api.nvim_win_set_cursor(0, { l, 0 })
    end, o)
  end
  map_keys()

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = function()
      for i, s in ipairs(stack) do
        if s.win == win then
          table.remove(stack, i)
          break
        end
      end
    end,
  })
end

---@param kind "definition"|"references"|"callers"|"callees"
function M.peek(kind)
  local op = ops[kind]
  local symbol = vim.fn.expand("<cword>")
  if symbol == "" then
    return
  end
  local rc, res = require("cscope").get_result(op.n, op.s, symbol, true)
  if rc ~= RC.SUCCESS or not res or #res == 0 then
    vim.notify("cscope_preview: no " .. kind .. " for '" .. symbol .. "'", vim.log.levels.WARN)
    return
  end
  open(res)
end

---@param user? CscopePreviewOpts
function M.setup(user)
  opts = vim.tbl_extend("force", opts, user or {})
end

return M
