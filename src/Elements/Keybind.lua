local UserInputService = game:GetService("UserInputService")

local Root = script.Parent.Parent
local Creator = require(Root.Creator)

local New = Creator.New
local Components = Root.Components

local Element = {}
Element.__index = Element
Element.__type = "Keybind"

local ValidModes = {
	Toggle = true,
	Hold = true,
	Always = true,
}

local function NormalizeKey(Key)
	if typeof(Key) == "EnumItem" then
		Key = Key.Name
	end

	if Key == "MouseLeft" or Key == "MouseRight" or Key == "None" then
		return Key
	end

	if type(Key) == "string" and Enum.KeyCode[Key] then
		return Key
	end

	return "None"
end

function Element:New(Idx, Config)
	local Library = self.Library
	assert(Config.Title, "KeyBind - Missing Title")
	assert(Config.Default, "KeyBind - Missing default value.")

	local Default = NormalizeKey(Config.Default)

	local Keybind = {
		Value = Default,
		Toggled = false,
		Mode = ValidModes[Config.Mode] and Config.Mode or "Toggle",
		Type = "Keybind",
		Callback = Config.Callback or function(Value) end,
		ChangedCallback = Config.ChangedCallback or function(New) end,
	}

	local Picking = false
	local PickBeganEvent
	local PickEndedEvent
	local ToggleConnection
	local PickLock = "Keybind_" .. tostring(Idx)

	local KeybindFrame = require(Components.Element)(Config.Title, Config.Description, self.Container, true)

	Keybind.SetTitle = KeybindFrame.SetTitle
	Keybind.SetDesc = KeybindFrame.SetDesc

	local KeybindDisplayLabel = New("TextLabel", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		Text = Default,
		TextColor3 = Color3.fromRGB(240, 240, 240),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(0, 0, 0, 14),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		ThemeTag = {
			TextColor3 = "Text",
		},
	})

	local KeybindDisplayFrame = New("TextButton", {
		Size = UDim2.fromOffset(0, 30),
		Position = UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 0.9,
		Parent = KeybindFrame.Frame,
		AutomaticSize = Enum.AutomaticSize.X,
		ThemeTag = {
			BackgroundColor3 = "Keybind",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),
		New("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}),
		New("UIStroke", {
			Transparency = 0.5,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag = {
				Color = "InElementBorder",
			},
		}),
		KeybindDisplayLabel,
	})

	local function ClearPick()
		if PickBeganEvent then
			Creator.RemoveSignal(PickBeganEvent)
			PickBeganEvent = nil
		end

		if PickEndedEvent then
			Creator.RemoveSignal(PickEndedEvent)
			PickEndedEvent = nil
		end

		if Picking then
			Library:UnlockInput(PickLock)
		end

		Picking = false
	end

	local function FinishPick(Key, InputObject)
		KeybindDisplayLabel.Text = Key
		Keybind.Value = Key

		Library:SafeCallback(Keybind.ChangedCallback, InputObject.KeyCode or InputObject.UserInputType)
		Library:SafeCallback(Keybind.Changed, InputObject.KeyCode or InputObject.UserInputType)
	end

	local function BeginPick()
		if Picking then
			return
		end

		Picking = true
		Library:LockInput(PickLock)
		KeybindDisplayLabel.Text = "..."

		task.wait(0.2)

		if not Picking then
			return
		end

		if not KeybindDisplayLabel.Parent then
			ClearPick()
			return
		end

		PickBeganEvent = Creator.AddSignal(UserInputService.InputBegan, function(Input, GameProcessed)
			if not Picking or Library:IsTyping() then
				return
			end

			if Input.KeyCode == Enum.KeyCode.Escape then
				KeybindDisplayLabel.Text = Keybind.Value
				ClearPick()
				return
			end

			if GameProcessed then
				return
			end

			local Key

			if Input.UserInputType == Enum.UserInputType.Keyboard then
				Key = Input.KeyCode.Name
			elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
				Key = "MouseLeft"
			elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
				Key = "MouseRight"
			end

			if not Key then
				return
			end

			if PickEndedEvent then
				Creator.RemoveSignal(PickEndedEvent)
				PickEndedEvent = nil
			end

			local Began = Input

			PickEndedEvent = Creator.AddSignal(UserInputService.InputEnded, function(Ended)
				local Matches

				if Began.UserInputType == Enum.UserInputType.Keyboard then
					Matches = Ended.UserInputType == Enum.UserInputType.Keyboard and Ended.KeyCode == Began.KeyCode
				else
					Matches = Ended.UserInputType == Began.UserInputType
				end

				if Matches then
					FinishPick(Key, Began)
					ClearPick()
				end
			end)
		end)
	end

	function Keybind:GetState()
		if Library:IsTyping() and Keybind.Mode ~= "Always" then
			return false
		end

		if Keybind.Mode == "Always" then
			return true
		elseif Keybind.Mode == "Hold" then
			if Keybind.Value == "None" then
				return false
			end

			if Keybind.Value == "MouseLeft" then
				return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
			elseif Keybind.Value == "MouseRight" then
				return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
			end

			local KeyCode = Enum.KeyCode[Keybind.Value]
			return KeyCode ~= nil and UserInputService:IsKeyDown(KeyCode)
		else
			return Keybind.Toggled
		end
	end

	function Keybind:SetValue(Key, Mode)
		Key = NormalizeKey(Key or Keybind.Value)
		Mode = ValidModes[Mode or Keybind.Mode] and (Mode or Keybind.Mode) or "Toggle"

		KeybindDisplayLabel.Text = Key
		Keybind.Value = Key
		Keybind.Mode = Mode
	end

	function Keybind:OnClick(Callback)
		Keybind.Clicked = Callback
	end

	function Keybind:OnChanged(Callback)
		Keybind.Changed = Callback
		Callback(Keybind.Value)
	end

	function Keybind:DoClick()
		Library:SafeCallback(Keybind.Callback, Keybind.Toggled)
		Library:SafeCallback(Keybind.Clicked, Keybind.Toggled)
	end

	function Keybind:Destroy()
		ClearPick()

		if ToggleConnection then
			Creator.RemoveSignal(ToggleConnection)
			ToggleConnection = nil
		end

		KeybindFrame:Destroy()
		Library.Options[Idx] = nil
	end

	Creator.AddSignal(KeybindDisplayFrame.InputBegan, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			BeginPick()
		end
	end)

	ToggleConnection = Creator.AddSignal(UserInputService.InputBegan, function(Input, GameProcessed)
		if GameProcessed or Picking or Library:IsTyping() or Library:IsInputLocked() then
			return
		end

		if Keybind.Mode ~= "Toggle" then
			return
		end

		local Key = Keybind.Value

		if Key == "MouseLeft" or Key == "MouseRight" then
			if
				Key == "MouseLeft" and Input.UserInputType == Enum.UserInputType.MouseButton1
				or Key == "MouseRight" and Input.UserInputType == Enum.UserInputType.MouseButton2
			then
				Keybind.Toggled = not Keybind.Toggled
				Keybind:DoClick()
			end
		elseif Input.UserInputType == Enum.UserInputType.Keyboard then
			if Input.KeyCode.Name == Key then
				Keybind.Toggled = not Keybind.Toggled
				Keybind:DoClick()
			end
		end
	end)

	Library.Options[Idx] = Keybind
	return Keybind
end

return Element
