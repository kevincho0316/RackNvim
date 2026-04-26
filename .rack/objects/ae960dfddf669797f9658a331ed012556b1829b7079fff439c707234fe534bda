local M = {}
local float = require('rack.ui.float')

-- opts: message, on_confirm, on_cancel
function M.ask(opts)
  local cfg  = require('rack.config').get()
  local msg  = opts.message or 'Are you sure?'
  local w    = math.max(#msg + 8, 36)
  local cols = vim.o.columns
  local rows = vim.o.lines
  local row  = math.floor(rows / 2) - 3
  local col  = math.floor((cols - w) / 2)

  local f = float.open({
    title    = 'Confirm',
    width    = w, height = 4,
    row      = row, col = col,
    border   = cfg.ui.border or 'rounded',
    enter    = true,
    win_opts = { winhighlight = 'Normal:RackNormal,FloatBorder:RackBorder' },
  })

  vim.api.nvim_set_option_value('modifiable', true, { buf = f.buf })
  vim.api.nvim_buf_set_lines(f.buf, 0, -1, false, {
    '',
    '  ' .. msg,
    '',
    '  [y] Confirm   [n / Esc] Cancel',
  })
  vim.api.nvim_set_option_value('modifiable', false, { buf = f.buf })

  local done = false
  local function close()
    if done then return end
    done = true
    float.close(f.win)
  end

  vim.keymap.set('n', 'y', function()
    close()
    vim.schedule(function() if opts.on_confirm then opts.on_confirm() end end)
  end, { buffer = f.buf, nowait = true, silent = true })

  local function cancel()
    close()
    if opts.on_cancel then opts.on_cancel() end
  end

  vim.keymap.set('n', 'n',    cancel, { buffer = f.buf, nowait = true, silent = true })
  vim.keymap.set('n', '<Esc>', cancel, { buffer = f.buf, nowait = true, silent = true })
end

return M
