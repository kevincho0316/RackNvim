local M = {}

function M.setup(user_cfg)
  local config = require('rack.config')
  config.setup(user_cfg)

  -- Default highlight groups (users override via colorscheme or explicit hi)
  vim.api.nvim_set_hl(0, 'RackNormal',    { link = 'NormalFloat', default = true })
  vim.api.nvim_set_hl(0, 'RackBorder',    { link = 'FloatBorder', default = true })
  vim.api.nvim_set_hl(0, 'RackSelection', { link = 'Visual',      default = true })
  -- Plate log colours
  vim.api.nvim_set_hl(0, 'RackFlagHotfix', { fg = '#f38ba8', default = true })
  vim.api.nvim_set_hl(0, 'RackFlagKnot',   { fg = '#cba6f7', default = true })
  vim.api.nvim_set_hl(0, 'RackNamed',      { fg = '#f9e2af', default = true })
  -- Diff picker file-list colours (link to standard diff groups)
  vim.api.nvim_set_hl(0, 'RackDiffAdded',    { link = 'DiffAdd',    default = true })
  vim.api.nvim_set_hl(0, 'RackDiffRemoved',  { link = 'DiffDelete', default = true })
  vim.api.nvim_set_hl(0, 'RackDiffModified', { link = 'DiffChange', default = true })

  local cfg = config.get()

  if cfg.keymaps then
    for key, action in pairs(cfg.keymaps) do
      vim.keymap.set('n', key, action, { silent = true })
    end
  end

  require('rack.auto').start()

  vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function() require('rack.auto').stop() end,
  })
end

-- Public API ----------------------------------------------------------------

function M.commit_quick()       require('rack.actions').commit_quick() end
function M.commit_named()       require('rack.actions').commit_named() end
function M.push(proj)           require('rack.actions').push(proj) end
function M.pull(proj)           require('rack.actions').pull(proj) end
function M.domain()             require('rack.actions').domain() end
function M.reconstruct()        require('rack.actions').reconstruct() end
function M.server_check()       require('rack.actions').server_check() end
function M.delete_project(proj) require('rack.actions').delete_project(proj) end
function M.status()             require('rack.actions').status_float() end
function M.init_project()       require('rack.actions').init_project() end
function M.log(proj)            require('rack.pickers.log').open(proj) end
function M.files(proj)          require('rack.pickers.files').open(proj) end
function M.projects()           require('rack.pickers.projects').open() end
function M.auto_push_toggle()   require('rack.auto').toggle() end
function M.diff(plateA, plateB) require('rack.actions').diff_float(plateA, plateB) end
function M.diff_pick(proj)     require('rack.pickers.diff').open(proj) end

-- Returns true if server is reachable; safe to call from statusline
function M.server_status()
  local _, _, code = require('rack.cli').run_sync({ 'serverCheck' })
  return code == 0
end

return M
