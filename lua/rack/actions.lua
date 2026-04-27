local M = {}

local function cfg()    return require('rack.config').get() end
local function cli()    return require('rack.cli') end
local function notify(msg, lvl)
  if cfg().notify then
    vim.notify(msg, lvl or vim.log.levels.INFO, { title = 'Rack' })
  end
end
local function err(msg) notify(msg, vim.log.levels.ERROR) end
local function warn(msg) notify(msg, vim.log.levels.WARN) end

local function result_text(out, e)
  local s = (out ~= '' and out or e):gsub('\n', ' '):match('^%s*(.-)%s*$')
  return s
end

-- ── commit ───────────────────────────────────────────────────────────────

function M.commit_quick()
  notify('Committing...')
  cli().run({ 'commit' }, function(out, e, code)
    if code ~= 0 then err('Commit failed: ' .. result_text(out, e)); return end
    local hash   = out:match('Local commit:%s*(%S+)') or ''
    local pushed = out:match('Pushed plate:%s*(%S+)')
    if pushed then
      notify('Committed + pushed: ' .. pushed:sub(1, 12))
    else
      notify('Committed: ' .. (hash ~= '' and hash:sub(1, 12) or result_text(out, e)))
    end
  end)
end

function M.commit_named()
  require('rack.ui.prompt').input({
    title = 'Commit name',
    on_confirm = function(name)
      require('rack.ui.select').open({
        title     = 'Select flag',
        items     = cfg().flags,
        format    = function(f) return f end,
        on_select = function(flag)
          local args = { 'commit', '-f', flag }
          if name ~= '' then vim.list_extend(args, { '-n', name }) end
          notify('Committing...')
          cli().run(args, function(out, e, code)
            if code ~= 0 then err('Commit failed: ' .. result_text(out, e)); return end
            local hash   = out:match('Local commit:%s*(%S+)') or ''
            local pushed = out:match('Pushed plate:%s*(%S+)')
            if pushed then
              notify(('[%s] %s → pushed %s'):format(flag, name ~= '' and name or '–', pushed:sub(1, 12)))
            else
              notify(('Committed [%s] %s: %s'):format(flag, name, hash:sub(1, 12)))
            end
          end)
        end,
      })
    end,
  })
end

-- ── push / pull ──────────────────────────────────────────────────────────

function M.push(proj)
  local args = proj and { 'push', proj } or { 'push' }
  cli().run(args, function(out, e, code)
    if code ~= 0 then err('Push failed: ' .. result_text(out, e)); return end
    notify('Pushed: ' .. result_text(out, e))
  end)
end

function M.pull(proj)
  local args = proj and { 'pull', proj } or { 'pull' }
  cli().run(args, function(out, e, code)
    if code ~= 0 then err('Pull failed: ' .. result_text(out, e)); return end
    notify('Pulled')
    vim.cmd('checktime')
  end)
end

-- ── domain ───────────────────────────────────────────────────────────────

function M.domain()
  require('rack.ui.prompt').input({
    title = 'Server URL',
    on_confirm = function(url)
      if url == '' then return end
      cli().run({ 'domain', url }, function(out, e, code)
        if code ~= 0 then err('Failed: ' .. result_text(out, e)); return end
        notify('Domain set: ' .. url)
      end)
    end,
  })
end

-- ── reconstruct ──────────────────────────────────────────────────────────

function M.reconstruct()
  require('rack.ui.confirm').ask({
    message = 'Reconstruct files from local HEAD?',
    on_confirm = function()
      cli().run({ 'reconstruct' }, function(out, e, code)
        if code ~= 0 then err('Reconstruct failed: ' .. result_text(out, e)); return end
        notify('Reconstructed')
        vim.cmd('checktime')
      end)
    end,
  })
end

-- ── server check ─────────────────────────────────────────────────────────

function M.server_check()
  cli().run({ 'serverCheck' }, function(_, _, code)
    if code == 0 then notify('Server online')
    else warn('Server offline') end
  end)
end

-- ── delete project ───────────────────────────────────────────────────────

function M.delete_project(proj)
  local display = proj or '(active project)'
  require('rack.ui.confirm').ask({
    message = ("Delete '%s' from server?"):format(display),
    on_confirm = function()
      local args = { 'delete-project', '-y' }
      if proj then table.insert(args, proj) end
      cli().run(args, function(out, e, code)
        if code ~= 0 then err('Delete failed: ' .. result_text(out, e)); return end
        notify('Deleted: ' .. display)
      end)
    end,
  })
end

-- ── restore ──────────────────────────────────────────────────────────────

function M.restore(plate_id)
  require('rack.ui.confirm').ask({
    message = 'Restore plate ' .. plate_id:sub(1, 12) .. '?',
    on_confirm = function()
      cli().run({ 'restore', plate_id }, function(out, e, code)
        if code ~= 0 then err('Restore failed: ' .. result_text(out, e)); return end
        notify('Restored: ' .. plate_id:sub(1, 12))
        vim.cmd('checktime')
      end)
    end,
  })
end

-- ── status float ─────────────────────────────────────────────────────────

function M.status_float()
  local float_ui = require('rack.ui.float')
  local parse    = require('rack.parse')

  cli().run({ 'status' }, function(out, e, code)
    local lines = {}
    if code ~= 0 then
      lines = vim.split((e ~= '' and e or out), '\n', { plain = true })
    else
      local s = parse.status(out)
      if s.clean then
        lines = { '', '  Up to date with server', '' }
      else
        local function section(title, items, sigil)
          if #items == 0 then return end
          table.insert(lines, '  ' .. title)
          for _, f in ipairs(items) do
            table.insert(lines, ('  %s %s'):format(sigil, f))
          end
          table.insert(lines, '')
        end
        table.insert(lines, '')
        section('New:', s.new, '+')
        section('Modified:', s.modified, '~')
        section('Deleted:', s.deleted, '-')
      end
    end

    local cols = vim.o.columns
    local rows = vim.o.lines
    local w    = math.min(math.max(50, #(lines[1] or '') + 4), math.floor(cols * 0.6))
    for _, l in ipairs(lines) do w = math.max(w, #l + 4) end
    w = math.min(w, math.floor(cols * 0.6))
    local h   = math.max(3, #lines)
    local row = math.floor((rows - h - 2) / 2)
    local col = math.floor((cols - w) / 2)

    local f = float_ui.open({
      title    = 'Rack Status',
      width    = w, height = h,
      row      = row, col = col,
      border   = cfg().ui.border,
      win_opts = { winhighlight = 'Normal:RackNormal,FloatBorder:RackBorder' },
    })
    float_ui.set_lines(f.buf, lines)

    local function close()
      if vim.api.nvim_win_is_valid(f.win) then
        pcall(vim.api.nvim_win_close, f.win, true)
      end
    end
    vim.keymap.set('n', 'q',    close, { buffer = f.buf, nowait = true, silent = true })
    vim.keymap.set('n', '<Esc>', close, { buffer = f.buf, nowait = true, silent = true })
  end)
end

-- ── diff float ───────────────────────────────────────────────────────────
-- plateA / plateB optional strings matching CLI modes:
--   diff()            → local HEAD vs server HEAD
--   diff(id)          → local HEAD vs plate id
--   diff(idA, idB)    → plate A vs plate B

-- CLI arg convention (after main.cpp fix):
--   diff()         → rack diff           (local vs server:HEAD)
--   diff(X)        → rack diff <X>       (local vs plate X)
--   diff(A, B)     → rack diff <A> <B>   (plate A vs plate B)
function M.diff_float(plateA, plateB)
  local args = { 'diff' }
  if plateA and plateA ~= '' then table.insert(args, plateA) end
  if plateB and plateB ~= '' then table.insert(args, plateB) end

  cli().run(args, function(out, e, code)
    local text = out ~= '' and out or e
    if code ~= 0 and text:find('Server offline') then err('Server offline'); return end
    local parse = require('rack.parse')
    local diff  = require('rack.pickers.diff')
    -- label_a: local when no plateA given (single-arg = local vs plateA)
    local label_a = (plateA and plateA ~= '' and plateB and plateB ~= '') and plateA:sub(1,12) or 'local'
    local label_b = plateB and plateB ~= '' and plateB:sub(1,12)
                    or (plateA and plateA ~= '' and plateA:sub(1,12) or 'server:HEAD')
    diff.show(parse.diff(text), label_a, label_b)
  end)
end

-- ── auth key ─────────────────────────────────────────────────────────────

function M.set_api_key()
  require('rack.ui.prompt').input({
    title = 'API Key',
    on_confirm = function(key)
      if key == '' then return end
      cli().run({ 'auth', key }, function(out, e, code)
        if code ~= 0 then err('Failed: ' .. result_text(out, e)); return end
        notify('API key saved')
      end)
    end,
  })
end

-- ── checkout (fresh device setup) ────────────────────────────────────────

function M.checkout()
  require('rack.ui.prompt').input({
    title = 'Server URL',
    on_confirm = function(domain)
      if domain == '' then return end
      require('rack.ui.prompt').input({
        title = 'Project name',
        on_confirm = function(project)
          if project == '' then return end
          notify('Checking out ' .. project .. '...')
          cli().run({ 'checkout', domain, project }, function(out, e, code)
            if code ~= 0 then err('Checkout failed: ' .. result_text(out, e)); return end
            notify('Checked out: ' .. project)
            vim.cmd('checktime')
          end)
        end,
      })
    end,
  })
end

-- ── init project ─────────────────────────────────────────────────────────

function M.init_project()
  require('rack.ui.prompt').input({
    title = 'Project name',
    on_confirm = function(name)
      if name == '' then return end
      cli().run({ 'init', name }, function(out, e, code)
        if code ~= 0 then err('Init failed: ' .. result_text(out, e)); return end
        notify("Project '" .. name .. "' active")
      end)
    end,
  })
end

return M
