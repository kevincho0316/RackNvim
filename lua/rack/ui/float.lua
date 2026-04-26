local M = {}

-- opts: title, width, height, row, col, border, focusable, enter, buf_opts, win_opts
-- Returns { buf, win }
function M.open(opts)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })

  for k, v in pairs(opts.buf_opts or {}) do
    vim.api.nvim_set_option_value(k, v, { buf = buf })
  end

  local win_cfg = {
    relative  = 'editor',
    width     = opts.width,
    height    = opts.height,
    row       = opts.row,
    col       = opts.col,
    style     = 'minimal',
    border    = opts.border or 'rounded',
    focusable = opts.focusable ~= false,
  }
  if opts.title and opts.title ~= '' then
    win_cfg.title     = ' ' .. opts.title .. ' '
    win_cfg.title_pos = 'center'
  end

  local enter = opts.enter ~= false
  local win = vim.api.nvim_open_win(buf, enter, win_cfg)

  for k, v in pairs(opts.win_opts or {}) do
    vim.api.nvim_set_option_value(k, v, { win = win })
  end

  return { buf = buf, win = win }
end

-- Write lines to a buffer (handles modifiable flag)
function M.set_lines(buf, lines)
  vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
end

function M.close(win)
  if win and vim.api.nvim_win_is_valid(win) then
    pcall(vim.api.nvim_win_close, win, true)
  end
end

return M
