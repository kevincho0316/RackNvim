local M = {}
local float = require('rack.ui.float')

-- Minimal vertical menu: no text input, arrow/j/k navigation, Enter to confirm.
-- opts: title, items, format, on_select
function M.open(opts)
  local cfg   = require('rack.config').get()
  local items = opts.items or {}
  if #items == 0 then return end

  local sel    = 1
  local closed = false
  local ns     = vim.api.nvim_create_namespace('rack_select')

  local cols = vim.o.columns
  local rows = vim.o.lines
  local max_w = #(opts.title or '') + 4
  for _, it in ipairs(items) do
    local s = opts.format and opts.format(it) or tostring(it)
    max_w = math.max(max_w, #s + 6)
  end
  local w   = math.min(max_w, math.floor(cols * 0.4))
  local h   = #items
  local row = math.floor((rows - h - 2) / 2)
  local col = math.floor((cols - w) / 2)

  local f = float.open({
    title    = opts.title or 'Select',
    width    = w, height = h,
    row      = row, col = col,
    border   = cfg.ui.border or 'rounded',
    enter    = true,
    win_opts = { winhighlight = 'Normal:RackNormal,FloatBorder:RackBorder' },
  })

  local function render()
    if not vim.api.nvim_buf_is_valid(f.buf) then return end
    vim.api.nvim_set_option_value('modifiable', true, { buf = f.buf })
    local lines = {}
    for i, it in ipairs(items) do
      local s = opts.format and opts.format(it) or tostring(it)
      lines[i] = (i == sel and '  > ' or '    ') .. s
    end
    vim.api.nvim_buf_set_lines(f.buf, 0, -1, false, lines)
    vim.api.nvim_buf_clear_namespace(f.buf, ns, 0, -1)
    vim.api.nvim_buf_set_extmark(f.buf, ns, sel - 1, 0, {
      line_hl_group = 'RackSelection', priority = 100,
    })
    vim.api.nvim_set_option_value('modifiable', false, { buf = f.buf })
    pcall(vim.api.nvim_win_set_cursor, f.win, { sel, 0 })
  end

  local function close()
    if closed then return end
    closed = true
    if vim.api.nvim_win_is_valid(f.win) then pcall(vim.api.nvim_win_close, f.win, true) end
  end

  local function map(key, fn)
    vim.keymap.set('n', key, fn, { buffer = f.buf, nowait = true, silent = true })
  end

  map('<Down>', function() sel = math.min(#items, sel + 1); render() end)
  map('<Up>',   function() sel = math.max(1, sel - 1);      render() end)
  map('j',      function() sel = math.min(#items, sel + 1); render() end)
  map('k',      function() sel = math.max(1, sel - 1);      render() end)
  map('<CR>', function()
    local item = items[sel]
    close()
    vim.schedule(function() if opts.on_select then opts.on_select(item) end end)
  end)
  map('<Esc>', close)
  map('q',     close)

  vim.api.nvim_create_autocmd('BufLeave', {
    buffer = f.buf, once = true,
    callback = function() vim.schedule(close) end,
  })

  render()
end

return M
