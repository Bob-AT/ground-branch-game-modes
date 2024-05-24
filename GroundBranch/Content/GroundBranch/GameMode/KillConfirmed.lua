local NAME = 'KillConfirmed'
package.loaded[NAME] = nil

print("*** Loading " .. NAME .. " ***")
local MOD_ID = 3249217564
local old_path = (function(mod_id, cpath)
    local idx = cpath:find("\\common\\Ground Branch\\GroundBranch\\Binaries\\Win64\\%?%.dll;")
    local prefix = cpath:sub(1, idx - 1)

    local additional_paths =
    prefix .. '/workshop/content/16900/' .. mod_id .. '/GroundBranch/Lua/?.lua;' ..
            prefix .. '/workshop/content/16900/' .. mod_id .. '/GroundBranch/GameMode/?.lua'

    local old_path = package.path
    local new_path = old_path .. ";" .. additional_paths
    print("Current package.path is: " .. old_path)
    print("New package.path is: " .. new_path)
    package.path = new_path
    return old_path
end)(MOD_ID, package.cpath)

local mode = require(NAME)
package.path = old_path
print("*** Loading " .. NAME .. " done ***")
return mode
