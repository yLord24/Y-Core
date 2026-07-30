--//Imports
local Guard = yrequire("games/ShindoLife/Utilities/Guard.lua")
local UI = yrequire("games/ShindoLife/Utilities/UI.lua")

--//Variables
local RollbackUI = {}

--//Source
function RollbackUI.Create(app, library, tab)
	local rollback = app.Modules.Rollback
	local rollbackGroup = tab:AddLeftGroupbox("Rollback")
	local rollbackStatus = rollbackGroup:AddLabel("Ready", true)
	local defaultState = false

	if rollback and typeof(rollback.IsEnabled) == "function" then
		defaultState = rollback:IsEnabled()
	end

	rollbackGroup:AddToggle("YCoreShindoLifeRollbackEnabled", {
		Text = "Rollback",
		Default = defaultState,
		Callback = function(value)
			local success, message = UI.CallFeatureWithValue(rollback, "SetEnabled", value == true)

			if not success and not message and Guard.ShouldSilence(app) then
				return
			end

			UI.SetLabel(rollbackStatus, message or (success and "Updated" or "Failed"))
			UI.Notify(library, message or "Rollback", 2.5)
		end,
	})

	return {
		Group = rollbackGroup,
		Status = rollbackStatus,
	}
end

return RollbackUI
