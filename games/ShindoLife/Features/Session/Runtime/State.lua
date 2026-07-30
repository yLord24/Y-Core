--//Variables
local State = {}

--//Source
function State.new(app, sessionConfig)
	return {
		App = app,
		Config = sessionConfig or {},
		LastHop = 0,
		LastServerId = nil,
	}
end

return State
