package.path = package.path .. ';../GameMode/?.lua'

local test = UnitTest or error('Run with TestSuite.lua')
local modes = {
'AssetExtraction',
'AssetExtractionSemiPermissive',
'BreakOut',
'BreakThrough',
'Debug',
'Defend',
'KillConfirmed',
'KillConfirmedSemiPermissive',
'SecurityDetail',
'SecurityDetailSemiPermissive',
'TemplateAll',
'Test',
}

for _, mode in ipairs(modes)
do
	test('Can load ' .. mode .. '.lua', function()
		require(mode)
	end)
end
