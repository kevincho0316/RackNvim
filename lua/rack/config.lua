local M = {}

local defaults = {
  rack_cmd = 'rack',
  flags = { 'Normal', 'Hotfix', 'Knot' },
  auto_push = {
    enabled = false,
    interval = 10 * 60,
    only_if_changed = true,
    silent = true,
  },
  keymaps = nil,
  ui = {
    width = 0.8,
    height = 0.8,
    border = 'rounded',
    preview_ratio = 0.6,
  },
  notify = true,
}

local current = {}

function M.setup(user_cfg)
  current = vim.tbl_deep_extend('force', defaults, user_cfg or {})
end

function M.get()
  if vim.tbl_isempty(current) then
    current = vim.deepcopy(defaults)
  end
  return current
end

return M
