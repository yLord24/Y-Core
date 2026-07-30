--//Imports
local Text = yrequire("games/ShindoLife/Utilities/Text.lua")
local UI = yrequire("games/ShindoLife/Utilities/UI.lua")

--//Variables
local SessionUI = {}

--//Source
function SessionUI.CreateServerInfo(app, library, tab)
	local serverInfoGroup = tab:AddLeftGroupbox("Server Info")
	local placeLabel = serverInfoGroup:AddLabel("Place: " .. tostring(game.PlaceId), true)
	local jobLabel = serverInfoGroup:AddLabel("Job: " .. Text.ShortJobId(game.JobId), true)
	local populationLabel = serverInfoGroup:AddLabel("Players: " .. tostring(#app.Services.Players:GetPlayers()) .. "/" .. tostring(app.Services.Players.MaxPlayers), true)
	local uptimeLabel = serverInfoGroup:AddLabel("Uptime: 0s", true)
	local panel = {
		Group = serverInfoGroup,
		PlaceLabel = placeLabel,
		JobLabel = jobLabel,
		PopulationLabel = populationLabel,
		UptimeLabel = uptimeLabel,
		StartedAt = os.clock(),
		Running = true,
	}

	task.spawn(function()
		while panel.Running and library and not library.Unloaded do
			UI.SetLabel(placeLabel, "Place: " .. tostring(game.PlaceId))
			UI.SetLabel(jobLabel, "Job: " .. Text.ShortJobId(game.JobId))
			UI.SetLabel(populationLabel, "Players: " .. tostring(#app.Services.Players:GetPlayers()) .. "/" .. tostring(app.Services.Players.MaxPlayers))
			UI.SetLabel(uptimeLabel, "Uptime: " .. tostring(math.floor(os.clock() - panel.StartedAt)) .. "s")
			task.wait(2)
		end
	end)

	return panel
end

function SessionUI.CreateSessionControls(app, library, tab)
	local session = app.Modules.Session
	local sessionGroup = tab:AddRightGroupbox("Session")
	local sessionStatus = sessionGroup:AddLabel("Ready", true)

	sessionGroup:AddButton("Rejoin", function()
		UI.SetLabel(sessionStatus, "Starting")

		local success, message = UI.CallFeature(session, "Rejoin")

		UI.SetLabel(sessionStatus, message or (success and "Teleporting" or "Failed"))
		UI.Notify(library, message or "Rejoin", 2.5)
	end)

	return {
		Group = sessionGroup,
		Status = sessionStatus,
	}
end

function SessionUI.Create(app, library, tab)
	return {
		ServerInfo = SessionUI.CreateServerInfo(app, library, tab),
		Session = SessionUI.CreateSessionControls(app, library, tab),
	}
end

function SessionUI.Destroy(panel)
	if panel and panel.ServerInfo then
		panel.ServerInfo.Running = false
	end
end

return SessionUI
