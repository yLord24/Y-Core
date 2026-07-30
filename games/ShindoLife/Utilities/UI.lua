--//Variables
local UI = {}

--//Source
function UI.SetLabel(label, text)
	if label and typeof(label.SetText) == "function" then
		pcall(function()
			label:SetText(tostring(text))
		end)
	end
end

function UI.GetOptions()
	local environment = (getgenv and getgenv()) or _G
	return environment.Options or {}
end

function UI.Notify(library, message, duration)
	if library and typeof(library.Notify) == "function" then
		pcall(function()
			library:Notify(tostring(message), duration or 3)
		end)
	end
end

function UI.CallFeature(feature, methodName)
	if not feature or typeof(feature[methodName]) ~= "function" then
		return false, "Feature not ready"
	end

	return feature[methodName](feature)
end

function UI.CallFeatureWithValue(feature, methodName, value)
	if not feature or typeof(feature[methodName]) ~= "function" then
		return false, "Feature not ready"
	end

	return feature[methodName](feature, value)
end

return UI
