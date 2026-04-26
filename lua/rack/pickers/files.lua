local M = {}

function M.open(proj)
  local cli    = require('rack.cli')
  local parse  = require('rack.parse')
  local picker = require('rack.ui.picker')

  local args = { 'files' }
  if proj then table.insert(args, proj) end

  cli.run(args, function(out, e, code)
    if code ~= 0 then
      vim.notify('rack files: ' .. (e ~= '' and e or out), vim.log.levels.ERROR, { title = 'Rack' })
      return
    end

    local files = parse.files(out)
    if #files == 0 then
      vim.notify('No files in latest plate', vim.log.levels.INFO, { title = 'Rack' })
      return
    end

    local prev_win = vim.api.nvim_get_current_win()

    picker.open({
      title  = 'Files',
      items  = files,
      format = function(f) return f end,

      preview = function(path, bufnr)
        local ok, content = pcall(vim.fn.readfile, path)
        local lines = (ok and content) and content or { '(not readable on disk)' }
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
        local ext = path:match('%.(%w+)$')
        if ext then
          pcall(vim.api.nvim_set_option_value, 'filetype', ext, { buf = bufnr })
        end
      end,

      on_select = function(path)
        if vim.api.nvim_win_is_valid(prev_win) then
          vim.api.nvim_set_current_win(prev_win)
        end
        vim.cmd('edit ' .. vim.fn.fnameescape(path))
      end,
    })
  end)
end

return M
