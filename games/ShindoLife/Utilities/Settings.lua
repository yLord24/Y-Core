--//Imports
local UI = yrequire("games/ShindoLife/Utilities/UI.lua")

--//Variables
local Settings = {}

--//Source
function Settings.ApplyManagers(app, themeManager, saveManager, tabs)
	if not tabs or not tabs["UI Settings"] then
		return
	end

	local library = app.UI and app.UI.Library
	local uiConfig = app.Config.UI or {}

	pcall(function()
		themeManager:SetLibrary(library)
		saveManager:SetLibrary(library)
		saveManager:IgnoreThemeSettings()
		saveManager:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName" })
		themeManager:SetFolder("YHubV3")
		saveManager:SetFolder(uiConfig.SaveFolder or "YHubV3/ShindoLife")
		saveManager:BuildConfigSection(tabs["UI Settings"])
		themeManager:ApplyToTab(tabs["UI Settings"])

		task.defer(function()
			local loadSuccess, loaded, detail = pcall(function()
				return saveManager:LoadAutoloadConfig()
			end)

			app.Debug:Log("config-autoload", {
				ok = loadSuccess,
				loaded = loaded,
				detail = detail,
			})
		end)
	end)
end

function Settings.Create(app, library, tab, unloadCallback)
	local menuGroup = tab:AddLeftGroupbox("Menu")

	menuGroup:AddButton("Unload", function()
		library:Unload()
	end)

	menuGroup:AddLabel("Menu bind"):AddKeyPicker("YCoreShindoLifeMenuKeybind", {
		Default = app.Config.UI.MenuKeybind or "End",
		NoUI = true,
		Text = "Menu keybind",
	})

	if UI.GetOptions().YCoreShindoLifeMenuKeybind then
		library.ToggleKeybind = UI.GetOptions().YCoreShindoLifeMenuKeybind
	end

	if unloadCallback then
		library:OnUnload(unloadCallback)
	end

	return {
		Group = menuGroup,
	}
end

return Settings
