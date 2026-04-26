local M = {}
local float = require('rack.ui.float')

-- Single-line floating input.
-- opts: title, on_confirm(text), on_cancel
function M.input(opts)
  local cfg  = require('rack.config').get()
  local cols = vim.o.columns
  local lines_n = vim.o.lines
  local w   = math.floor(cols * 0.4)
  local row = math.floor(lines_n / 2) - 2
  local col = math.floor((cols - w) / 2)

  local f = float.open({
    title    = opts.title or 'Input',
    width    = w, height = 1,
    row      = row, col = col,
    border   = cfg.ui.border or 'rounded',
    enter    = true,
    buf_opts = { buftype = 'prompt', filetype = 'rack_input' },
    win_opts = { winhighlight = 'Normal:RackNormal,FloatBorder:RackBorder' },
  })

  local done = false
  local function close()
    if done then return end
    done = true
    float.close(f.win)
  end

  vim.fn.prompt_setprompt(f.buf, '> ')
  vim.fn.prompt_setcallback(f.buf, function(text)
    close()
    vim.schedule(function()
      if opts.on_confirm then opts.on_confirm(text) end
    end)
  end)

  vim.keymap.set({ 'i', 'n' }, '<Esc>', function()
    close()
    if opts.on_cancel then opts.on_cancel() end
  end, { buffer = f.buf, nowait = true, silent = true })

  vim.api.nvim_create_autocmd('BufLeave', {
    buffer   = f.buf,
    once     = true,
    callback = function()
      vim.schedule(function()
        if not done and opts.on_cancel then opts.on_cancel() end
      end)
    end,
  })

  vim.cmd('startinsert')
end

return M
