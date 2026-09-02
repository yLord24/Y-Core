--//Variables
local GameRegistry = {
	Default = "shinsei",
	PublicBaseUrl = "https://raw.githubusercontent.com/yLord24/Y-Core/main/",

	Games = {
		bridge = {
			Name = "Y Hub - Bridger",
			Version = "0.1.0",
			Entry = "games/Bridge/init.lua",
			BundleName = "Bridger.luau",
			BundleUrl = "https://raw.githubusercontent.com/yLord24/Y-Core-Builds/main/Bridger.luau",
			Manifest = "games/Bridge/Metadatas/Manifest.lua",
			PlaceIds = { 133950099874787 },
		},
		shinsei = {
			Name = "Y Auto Signal",
			Version = "0.1.0",
			Entry = "games/Shinsei/init.lua",
			BundleUrl = "https://raw.githubusercontent.com/yLord24/Y-Core-Builds/main/Shinsei.luau",
			Manifest = "games/Shinsei/Metadatas/Manifest.lua",
			PlaceIds = { 136532079004320 },
		},
		shindolife = {
			Name = "Y Hub - Shindo Life",
			Version = "0.1.0",
			Entry = "games/ShindoLife/init.lua",
			BundleUrl = "https://raw.githubusercontent.com/yLord24/Y-Core-Builds/main/ShindoLife.luau",
			Manifest = "games/ShindoLife/Metadatas/Manifest.lua",
			PlaceIds = { 4616652839 },
		},
		gakuran = {
			Name = "Y Hub - Gakuran",
			Version = "0.3.2",
			Entry = "games/Gakuran/init.lua",
			BundleUrl = "https://raw.githubusercontent.com/yLord24/Y-Core-Builds/main/Gakuran.luau",
			Manifest = "games/Gakuran/Metadatas/Manifest.lua",
			PlaceIds = { 128736949265057 },
		},
	},
}

--//Source
function GameRegistry.NormalizeGameId(gameId)
	return tostring(gameId or ""):lower()
end

function GameRegistry.GetGame(gameId)
	return GameRegistry.Games[GameRegistry.NormalizeGameId(gameId)]
end

function GameRegistry.FindByPlaceId(placeId)
	local numericPlaceId = tonumber(placeId)

	if not numericPlaceId then
		return nil
	end

	for gameId, gameInfo in pairs(GameRegistry.Games) do
		for _, registeredPlaceId in ipairs(gameInfo.PlaceIds or {}) do
			if tonumber(registeredPlaceId) == numericPlaceId then
				return gameId
			end
		end
	end

	return nil
end

return GameRegistry
