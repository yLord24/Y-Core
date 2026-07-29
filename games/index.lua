--//Variables
local GameRegistry = {
	Default = "shinsei",
	PublicBaseUrl = "https://raw.githubusercontent.com/yLord24/Y-Core/main/",

	Games = {
		shinsei = {
			Name = "Y Auto Signal",
			Version = "0.1.0",
			Entry = "games/shinsei/init.lua",
			Loader = "games/shinsei/loader.lua",
			Manifest = "games/shinsei/Metadatas/Manifest.lua",
			PlaceIds = {},
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
