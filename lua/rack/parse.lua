local M = {}

-- rack log output:
--   Project: <name>  (<n> plates)
--   <hash12>  [<flag>]  "<name>"  <n> files  <YYYY-MM-DD HH:MM:SS|unknown> [<- HEAD]
function M.log(output)
  local plates = {}
  for line in output:gmatch('[^\n]+') do
    if not line:match('^Project:') and not line:match('^No plates') and not line:match('^Server') then
      local hash, flag, name, count = line:match('^(%S+)%s+%[(.-)%]%s+"(.-)".*%s+(%d+)%s+files')
      if hash then
        local is_head = line:find('<- HEAD') ~= nil
        -- timestamp sits between "N files  " and optional " <- HEAD"
        local after = line:match('%d+ files%s+(.*)$') or ''
        local ts = after:gsub('%s*<-%s*HEAD.*$', ''):match('^%s*(.-)%s*$')
        table.insert(plates, {
          id         = hash,
          flag       = flag,
          name       = name,
          file_count = tonumber(count) or 0,
          is_head    = is_head,
          timestamp  = (ts ~= '' and ts ~= 'unknown') and ts or nil,
        })
      end
    end
  end
  return plates
end

-- rack files output:
--   Files in latest plate (<n>):
--     <path>
function M.files(output)
  local files = {}
  local in_list = false
  for line in output:gmatch('[^\n]+') do
    if line:match('^Files in') then
      in_list = true
    elseif in_list then
      local path = line:match('^%s+(.+)$')
      if path then table.insert(files, path) end
    end
  end
  return files
end

-- rack projects output:
--   Projects (<n>):
--     <name>  [<- active]
function M.projects(output)
  local projects = {}
  local in_list = false
  for line in output:gmatch('[^\n]+') do
    if line:match('^Projects') then
      in_list = true
    elseif in_list then
      local raw = line:match('^%s+(.+)$')
      if raw then
        local active = raw:find('<- active') ~= nil
        local name = raw:gsub('%s*<- active%s*$', ''):match('^(.-)%s*$')
        table.insert(projects, { name = name, active = active })
      end
    end
  end
  return projects
end

-- rack status output:
--   new:      <path>
--   modified: <path>
--   deleted:  <path>
-- or: Up to date with server
function M.status(output)
  local result = { new = {}, modified = {}, deleted = {}, clean = false }
  if output:find('Up to date') then
    result.clean = true
    return result
  end
  for line in output:gmatch('[^\n]+') do
    local p = line:match('^%s+new:%s+(.+)$')
    if p then table.insert(result.new, p) end
    p = line:match('^%s+modified:%s+(.+)$')
    if p then table.insert(result.modified, p) end
    p = line:match('^%s+deleted:%s+(.+)$')
    if p then table.insert(result.deleted, p) end
  end
  return result
end

return M
