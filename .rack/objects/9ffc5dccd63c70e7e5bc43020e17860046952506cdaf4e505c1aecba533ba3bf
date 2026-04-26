local M = {}

local function get_cmd()
  return require('rack.config').get().rack_cmd
end

-- Async: runs rack with args, calls cb(stdout, stderr, exit_code) on main loop
function M.run(args, cb, opts)
  opts = opts or {}
  local cmd = vim.list_extend({ get_cmd() }, args)
  local sys_opts = {
    cwd = opts.cwd or vim.fn.getcwd(),
  }
  if opts.stdin then sys_opts.stdin = opts.stdin end

  vim.system(cmd, sys_opts, function(result)
    vim.schedule(function()
      cb(result.stdout or '', result.stderr or '', result.code)
    end)
  end)
end

-- Sync: blocks until done, returns (stdout, stderr, exit_code)
function M.run_sync(args, opts)
  opts = opts or {}
  local cmd = vim.list_extend({ get_cmd() }, args)
  local sys_opts = { cwd = opts.cwd or vim.fn.getcwd() }
  if opts.stdin then sys_opts.stdin = opts.stdin end
  local result = vim.system(cmd, sys_opts):wait()
  return result.stdout or '', result.stderr or '', result.code
end

return M
