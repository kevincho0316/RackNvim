local M = {}

function M.open()
  local cli     = require('rack.cli')
  local parse   = require('rack.parse')
  local picker  = require('rack.ui.picker')
  local actions = require('rack.actions')

  cli.run({ 'projects' }, function(out, e, code)
    if code ~= 0 then
      vim.notify('rack projects: ' .. (e ~= '' and e or out), vim.log.levels.ERROR, { title = 'Rack' })
      return
    end

    local projects = parse.projects(out)
    if #projects == 0 then
      vim.notify('No projects on server', vim.log.levels.INFO, { title = 'Rack' })
      return
    end

    picker.open({
      title  = 'Projects',
      items  = projects,
      format = function(p)
        return p.name .. (p.active and '  <- active' or '')
      end,

      on_select = function(proj)
        cli.run({ 'init', proj.name }, function(iout, ie, icode)
          if icode ~= 0 then
            vim.notify('Switch failed: ' .. (ie ~= '' and ie or iout), vim.log.levels.ERROR, { title = 'Rack' })
            return
          end
          vim.notify("Switched to '" .. proj.name .. "'", vim.log.levels.INFO, { title = 'Rack' })
        end)
      end,

      mappings = {
        -- <C-d>: delete project
        ['<C-d>'] = function(proj, close_fn)
          close_fn()
          actions.delete_project(proj.name)
        end,
      },
    })
  end)
end

return M
