--[[
	Security Detail (Semi-Permissive)

	See SecurityDetail.lua
]]--

local AdminConfiguration = {
	-- If you want to disable soft fail, change the next line to:
	--   SoftFailEnabled = false
	SoftFailEnabled = true,
	-- The max. amount of collateral damage before failing the mission
	CollateralDamageThreshold = 3
}


package.loaded['SecurityDetail'] = nil -- clear cache

local Tables = require('Common.Tables')

local super = Tables.DeepCopy(require('SecurityDetail'))
for k, v in ipairs(AdminConfiguration) do super.Config[k] = v end
super.Logger.name = 'SecDetSP'
super.IsSemiPermissive = true

return super
