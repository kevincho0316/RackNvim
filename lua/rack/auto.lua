local M = {}

local timer     = nil
local last_head = nil

local function do_auto_push()
  local cli = require('rack.cli')
  local cfg = require('rack.config').get()

  local function push_now()
    cli.run({ 'push' }, function(_, _, code)
      if not cfg.auto_push.silent and code == 0 then
        vim.notify('Auto-pushed', vim.log.levels.INFO, { title = 'Rack' })
      end
    end)
  end

  if cfg.auto_push.only_if_changed then
    local head, _, code = cli.run_sync({ 'cat', 'init' })
    if code ~= 0 then return end
    head = head:match('^%s*(.-)%s*$')  -- trim whitespace
    if head == '' or head == last_head then return end
    last_head = head
    -- commit to capture any new changes, then push
    cli.run({ 'commit' }, function(_, _, ccode)
      if ccode == 0 then push_now() end
    end)
  else
    cli.run({ 'commit' }, function(_, _, ccode)
      if ccode == 0 then push_now() end
    end)
  end
end

function M.start()
  local cfg = require('rack.config').get()
  if not cfg.auto_push.enabled or timer then return end

  timer = vim.uv.new_timer()
  local ms = cfg.auto_push.interval * 1000
  timer:start(ms, ms, function()
    vim.schedule(do_auto_push)
  end)
end

function M.stop()
  if not timer then return end
  timer:stop()
  timer:close()
  timer = nil
end

function M.toggle()
  if timer then
    M.stop()
    vim.notify('Auto-push disabled', vim.log.levels.INFO, { title = 'Rack' })
  else
    require('rack.config').get().auto_push.enabled = true
    M.start()
    vim.notify('Auto-push enabled', vim.log.levels.INFO, { title = 'Rack' })
  end
end

return M
