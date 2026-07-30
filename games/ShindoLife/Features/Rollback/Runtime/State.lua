--//Variables
local State = {}

--//Source
function State.new(app, rollbackConfig)
	rollbackConfig = rollbackConfig or {}

	return {
		App = app,
		Config = rollbackConfig,
		Enabled = rollbackConfig.Enabled == true,
		LastTrigger = 0,
	}
end

return State
