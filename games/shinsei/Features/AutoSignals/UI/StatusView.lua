--//Variables
local StatusView = {}
StatusView.__index = StatusView

--//Source
function StatusView.new(context)
	return setmetatable({
		Context = context,
		State = context.State,
		LocalPlayer = context.LocalPlayer,
	}, StatusView)
end

function StatusView:Set(text)
	self.State.LastStatus = text

	if self.State.StatusLabel and self.State.StatusLabel.Parent then
		self.State.StatusLabel.Text = "AUTO SIGNS: " .. text
			.. "\nCASTS: " .. tostring(self.State.Casts)
			.. "\n<font color=\"rgb(210, 85, 255)\">CREDITS: @me_erste</font>"
	end
end

function StatusView:GetPlayerGui()
	return self.LocalPlayer:FindFirstChildOfClass("PlayerGui")
end

function StatusView:GetInterface()
	local playerGui = self:GetPlayerGui()
	return playerGui and playerGui:FindFirstChild("Interface")
end

function StatusView:VisibleGui(gui)
	return gui and gui:IsA("GuiObject") and gui.Visible and gui.AbsoluteSize.X > 1 and gui.AbsoluteSize.Y > 1
end

function StatusView:GetGoalInfo(castUI)
	return castUI and castUI:FindFirstChild("goalInfo")
end

function StatusView:GetLanguage()
	return self.LocalPlayer:GetAttribute("Language") or "ENG"
end

function StatusView:GetCastUI(coreState)
	local interface = self:GetInterface()

	if not interface then
		return nil
	end

	local preferred = coreState and coreState.castGameUI

	if preferred then
		local folder = interface:FindFirstChild(preferred)

		if folder then
			return folder
		end
	end

	--> Prefer the UI currently visible
	for _, name in ipairs({ "castGamePC", "castGameMobile" }) do
		local folder = interface:FindFirstChild(name)
		local goalInfo = folder and folder:FindFirstChild("goalInfo")

		if self:VisibleGui(goalInfo) then
			return folder
		end
	end

	return nil
end

function StatusView:Start()
	if not self.State.ShowStatus then
		return
	end

	local playerGui = self:GetPlayerGui() or self.LocalPlayer:WaitForChild("PlayerGui")
	local oldStatusGui = playerGui:FindFirstChild("YShinseiAutoSignsStatus")

	if oldStatusGui then
		oldStatusGui:Destroy()
	end

	local statusGui = Instance.new("ScreenGui")
	statusGui.Name = "YShinseiAutoSignsStatus"
	statusGui.ResetOnSpawn = false
	statusGui.IgnoreGuiInset = true
	statusGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	statusGui.Parent = playerGui

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "Status"
	statusLabel.AnchorPoint = Vector2.new(0, 1)
	statusLabel.Position = UDim2.new(0, 10, 1, -12)
	statusLabel.Size = UDim2.fromOffset(250, 62)
	statusLabel.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
	statusLabel.BackgroundTransparency = 0.25
	statusLabel.BorderSizePixel = 0
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.RichText = true
	statusLabel.TextColor3 = Color3.fromRGB(255, 224, 70)
	statusLabel.TextStrokeTransparency = 0.65
	statusLabel.TextSize = 13
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.TextYAlignment = Enum.TextYAlignment.Center
	statusLabel.Text = "AUTO SIGNS: waiting\nCASTS: 0\n<font color=\"rgb(210, 85, 255)\">CREDITS: @me_erste</font>"
	statusLabel.Parent = statusGui

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.Parent = statusLabel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = statusLabel

	self.State.StatusGui = statusGui
	self.State.StatusLabel = statusLabel
end

function StatusView:Destroy()
	if self.State.StatusGui and self.State.StatusGui.Parent then
		self.State.StatusGui:Destroy()
	end
end

return StatusView
