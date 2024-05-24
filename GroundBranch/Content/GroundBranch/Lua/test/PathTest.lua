--local test = UnitTest or error('Run with TestSuite.lua')
--
--test('Trivial test #2', function()
--
--    local path = [[Z:\media\ssdp2\Steam\steamapps\common\Ground Branch\GroundBranch\Binaries\Win64\?.dll;Z:\media\ssdp2\Steam\steamapps\common\Ground Branch\GroundBranch\Binaries\Win64\..\lib\lua\5.3\?.dll;Z:\media\ssdp2\Steam\steamapps\common\Ground Branch\GroundBranch\Binaries\Win64\loadall.dll;.\?.dll]]
--
--    local r = path:find("[\\/]Ground Branch[\\/]GroundBranch[\\/]Binaries[\\/]Win64[\\/]?.dll")
--    assert(2 < 3)
--    assert(3 > 2)
--end)

local tmp = [[Z:\media\ssdp2\Steam\steamapps\common\Ground Branch\GroundBranch\Binaries\Win64\?.dll;Z:\media\ssdp2\Steam\steamapps\common\Ground Branch\GroundBranch\Binaries\Win64\..\lib\lua\5.3\?.dll;Z:\media\ssdp2\Steam\steamapps\common\Ground Branch\GroundBranch\Binaries\Win64\loadall.dll;.\?.dll]]
local MOD_ID = 3249217564
local old_path = (function(mod_id, cpath)
    local idx = cpath:find("\\common\\Ground Branch\\GroundBranch\\Binaries\\Win64\\%?%.dll;")
    local prefix = cpath:sub(1, idx - 1)

    local additional_paths =
        prefix .. '/workshop/content/16900/' .. mod_id .. '/GroundBranch/GameMode/?.lua;' ..
        prefix .. '/workshop/content/16900/' .. mod_id .. '/GroundBranch/Lua/?.lua'

    local old_path = package.path
    local new_path = old_path .. ";" .. additional_paths
    package.path = new_path
    return old_path
end)(MOD_ID, tmp)

print(package.path, "\n")
print(old_path, "\n")
