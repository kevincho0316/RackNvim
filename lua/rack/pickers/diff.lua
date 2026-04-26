local M = {}

local diff_ns = vim.api.nvim_create_namespace('rack_diff_hl')

-- Apply DiffAdd/DiffDelete/Comment extmarks to buffer lines
local function hl_diff(buf, lines)
  vim.api.nvim_buf_clear_namespace(buf, diff_ns, 0, -1)
  for i, line in ipairs(lines) do
    local hl
    if     line:match('^%+%+%+') or line:match('^%-%-%- ') then hl = 'DiffChange'
    elseif line:match('^%+')                                then hl = 'DiffAdd'
    elseif line:match('^%-')                                then hl = 'DiffDelete'
    elseif line:match('^@@')                                then hl = 'Comment'
    end
    if hl then
      vim.api.nvim_buf_set_extmark(buf, diff_ns, i - 1, 0, {
        line_hl_group = hl, priority = 10,
      })
    end
  end
end

-- Focused single-file diff float
local function open_file_float(file)
  local float = require('rack.ui.float')
  local cfg   = require('rack.config').get()
  local cols  = vim.o.columns
  local rows  = vim.o.lines
  local w     = math.floor(cols * 0.92)
  local h     = math.min(math.floor(rows * 0.88), math.max(4, #file.lines))
  local row   = math.floor((rows - h - 2) / 2)
  local col   = math.floor((cols - w) / 2)

  local f = float.open({
    title    = file.path,
    width = w, height = h, row = row, col = col,
    border   = cfg.ui.border,
    win_opts = { winhighlight = 'Normal:RackNormal,FloatBorder:RackBorder', wrap = false },
  })
  vim.api.nvim_set_option_value('modifiable', true, { buf = f.buf })
  vim.api.nvim_buf_set_lines(f.buf, 0, -1, false, file.lines)
  hl_diff(f.buf, file.lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = f.buf })

  local function close()
    if vim.api.nvim_win_is_valid(f.win) then pcall(vim.api.nvim_win_close, f.win, true) end
  end
  vim.keymap.set('n', 'q',     close, { buffer = f.buf, nowait = true, silent = true })
  vim.keymap.set('n', '<Esc>', close, { buffer = f.buf, nowait = true, silent = true })
end

-- Show parsed diff as a file-list picker (used by all diff entry points)
function M.show(diff_data, label_a, label_b)
  local files = diff_data.files
  if #files == 0 then
    vim.notify('No differences', vim.log.levels.INFO, { title = 'Rack' }); return
  end

  local icon = { added = '[+]', removed = '[-]', modified = '[~]' }
  local hl   = { added = 'RackDiffAdded', removed = 'RackDiffRemoved', modified = 'RackDiffModified' }

  require('rack.ui.picker').open({
    title   = ('diff  %s  →  %s  (%s)'):format(label_a, label_b, diff_data.summary),
    items   = files,
    format  = function(f) return (icon[f.kind] or '[?]') .. '  ' .. f.path end,
    item_hl = function(f) return hl[f.kind] end,
    preview = function(file, bufnr)
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, file.lines)
      hl_diff(bufnr, file.lines)
    end,
    on_select = open_file_float,
  })
end

-- ── helpers ──────────────────────────────────────────────────────────────

local function plate_format(p)
  if p._label then return p._label end
  local ts   = p.timestamp and ('  ' .. p.timestamp) or ''
  local head = p.is_head and '  HEAD' or ''
  return ('%-14s  %-8s  %s%s%s'):format(p.id, p.flag, p.name, ts, head)
end

local function plate_hl(p)
  if p._label then return nil end
  if p.flag == 'Hotfix' then return 'RackFlagHotfix' end
  if p.flag == 'Knot'   then return 'RackFlagKnot'   end
  if p.name ~= ''       then return 'RackNamed'       end
end

-- Find HEAD plate in a plates list
local function server_head(plates)
  for _, p in ipairs(plates) do
    if p.is_head then return p end
  end
  return plates[1]  -- fallback: first plate
end

-- Run diff and show results.
-- CLI contract (after main.cpp fix):
--   rack diff              → local vs server:HEAD   (plateA="",  plateB="")
--   rack diff <B>          → local vs plate B       (plateA="",  plateB=B.id)
--   rack diff <A> <B>      → plate A vs plate B     (plateA=A.id, plateB=B.id)
local function run_diff(plateA_id, plateB_id, label_a, label_b)
  local cli   = require('rack.cli')
  local parse = require('rack.parse')
  local args  = { 'diff' }
  if plateA_id and plateA_id ~= '' then table.insert(args, plateA_id) end
  if plateB_id and plateB_id ~= '' then table.insert(args, plateB_id) end

  cli.run(args, function(out, e, code)
    if code ~= 0 and (out .. e):find('Server offline') then
      vim.notify('Server offline', vim.log.levels.ERROR, { title = 'Rack' }); return
    end
    M.show(parse.diff(out ~= '' and out or e), label_a, label_b)
  end)
end

-- ── step 2: pick plate B ─────────────────────────────────────────────────

local function pick_b(plates, plate_a, label_a)
  local head = server_head(plates)

  -- Build B items.
  -- When A is local: B can be any plate OR server HEAD (= rack diff with no plateB)
  -- When A is a plate: B can be any OTHER plate OR server HEAD plate
  --   (rack diff <A> <head.id> since rack diff <A> now means local vs A)
  local b_items
  if plate_a._local then
    b_items = vim.list_extend(
      { { _label = 'server HEAD  (' .. head.id:sub(1,12) .. ')', _server_head_id = '' } },
      plates
    )
  else
    b_items = vim.list_extend(
      { { _label = 'server HEAD  (' .. head.id:sub(1,12) .. ')', _server_head_id = head.id } },
      vim.tbl_filter(function(p) return p.id ~= plate_a.id end, plates)
    )
  end

  require('rack.ui.picker').open({
    title   = 'Compare with  (B)',
    items   = b_items,
    format  = plate_format,
    item_hl = plate_hl,
    on_select = function(plate_b)
      local a_id    = plate_a._local and '' or plate_a.id
      local b_id    = plate_b._server_head_id ~= nil and plate_b._server_head_id or plate_b.id
      local label_b = plate_b._server_head_id ~= nil
                        and ('server:HEAD (' .. (b_id ~= '' and b_id:sub(1,12) or '…') .. ')')
                        or  plate_b.id:sub(1, 12)
      run_diff(a_id, b_id, label_a, label_b)
    end,
  })
end

-- ── entry point ──────────────────────────────────────────────────────────

function M.open(proj)
  local cli   = require('rack.cli')
  local parse = require('rack.parse')

  local args = { 'log' }
  if proj then table.insert(args, proj) end

  cli.run(args, function(out, e, code)
    if code ~= 0 then
      vim.notify('rack log: ' .. (e ~= '' and e or out), vim.log.levels.ERROR, { title = 'Rack' })
      return
    end
    local plates = parse.log(out)
    if #plates == 0 then
      vim.notify('No plates yet', vim.log.levels.INFO, { title = 'Rack' }); return
    end

    local items = vim.list_extend(
      { { _label = 'local HEAD', _local = true } },
      plates
    )

    require('rack.ui.picker').open({
      title   = 'Select base plate  (A)',
      items   = items,
      format  = plate_format,
      item_hl = plate_hl,
      on_select = function(plate_a)
        local label_a = plate_a._local and 'local' or plate_a.id:sub(1, 12)
        pick_b(plates, plate_a, label_a)
      end,
    })
  end)
end

return M
