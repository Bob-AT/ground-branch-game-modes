if not _ENV.gbmc_path_fixed then
	package.path = package.path .. ';../../../GroundBranch/Content/GroundBranch/Lua/?.lua;../../../GroundBranch/Content/GroundBranch/GameMode/?.lua;'
	_ENV.gbmc_path_fixed = true
end

package.loaded['AssetExtraction'] = nil
return require("AssetExtraction")
