if vim.g.loaded_rack then return end
vim.g.loaded_rack = true

local function rack() return require('rack') end

local cmd = vim.api.nvim_create_user_command

cmd('RackCommit',      function()     rack().commit_quick()  end, { desc = 'Rack: quick commit' })
cmd('RackCommitNamed', function()     rack().commit_named()  end, { desc = 'Rack: named commit + flag picker' })

cmd('RackPush', function(a)
  rack().push(a.args ~= '' and a.args or nil)
end, { nargs = '?', desc = 'Rack: push [project]' })

cmd('RackPull', function(a)
  rack().pull(a.args ~= '' and a.args or nil)
end, { nargs = '?', desc = 'Rack: pull [project]' })

cmd('RackLog', function(a)
  rack().log(a.args ~= '' and a.args or nil)
end, { nargs = '?', desc = 'Rack: plate history picker [project]' })

cmd('RackFiles', function(a)
  rack().files(a.args ~= '' and a.args or nil)
end, { nargs = '?', desc = 'Rack: files in latest plate [project]' })

cmd('RackProjects',     function()    rack().projects()       end, { desc = 'Rack: project list picker' })
cmd('RackStatus',       function()    rack().status()         end, { desc = 'Rack: status float' })
cmd('RackDomain',       function()    rack().domain()         end, { desc = 'Rack: set server URL' })
cmd('RackReconstruct',  function()    rack().reconstruct()    end, { desc = 'Rack: rebuild files from local HEAD' })
cmd('RackServerCheck',  function()    rack().server_check()   end, { desc = 'Rack: ping server' })
cmd('RackInitProject',  function()    rack().init_project()   end, { desc = 'Rack: init/activate project' })
cmd('RackAutoPushToggle', function()  rack().auto_push_toggle() end, { desc = 'Rack: toggle auto-push' })

cmd('RackDiff', function(a)
  local parts = vim.split(a.args, '%s+')
  rack().diff(parts[1] ~= '' and parts[1] or nil, parts[2] or nil)
end, { nargs = '*', desc = 'Rack: diff [plateA [plateB]]' })

cmd('RackDiffPicker', function(a)
  rack().diff_pick(a.args ~= '' and a.args or nil)
end, { nargs = '?', desc = 'Rack: interactive plate diff picker' })

cmd('RackDeleteProject', function(a)
  rack().delete_project(a.args ~= '' and a.args or nil)
end, { nargs = '?', desc = 'Rack: delete project [name]' })
