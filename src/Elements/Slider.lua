local UserInputService = game:GetService("UserInputService")
local Root = script.Parent.Parent
local Creator = require(Root.Creator)

local New = Creator.New
local Components = Root.Components

local Element = {}
Element.__index = Element
Element.__type = "Slider"

function Element:New(Idx, Config)
	local Library = self.Library
	assert(Config.Title, "Slider - Missing Title.")
	assert(Config.Default, "Slider - Missing default value.")
	assert(Config.Min, "Slider - Missing minimum value.")
	assert(Config.Max, "Slider - Missing maximum value.")
	assert(Config.Rounding, "Slider - Missing rounding value.")

	local Slider = {
		Value = nil,
		Min = Config.Min,
		Max = Config.Max,
		Rounding = Config.Rounding,
		Callback = Config.Callback or function(Value) end,
		Type = "Slider",
	}

	local Dragging = false
	local DragTouch = nil
	local InputLock = "Slider_" .. tostring(Idx)

	local SliderFrame = require(Components.Element)(Config.Title, Config.Description, self.Container, false)
	SliderFrame.DescLabel.Size = UDim2.new(1, -170, 0, 14)

	Slider.SetTitle = SliderFrame.SetTitle
	Slider.SetDesc = SliderFrame.SetDesc

	local SliderDot = New("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -7, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		Image = "rbxassetid://12266946128",
		ThemeTag = {
			ImageColor3 = "Accent",
		},
	})

	local SliderRail = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(7, 0),
		Size = UDim2.new(1, -14, 1, 0),
	}, {
		SliderDot,
	})

	local SliderFill = New("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		ThemeTag = {
			BackgroundColor3 = "Accent",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),
	})

	local SliderDisplay = New("TextLabel", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		Text = "Value",
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 100, 0, 14),
		Position = UDim2.new(0, -4, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		ThemeTag = {
			TextColor3 = "SubText",
		},
	})

	local SliderInner = New("Frame", {
		Size = UDim2.new(1, 0, 0, 4),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		BackgroundTransparency = 0.4,
		Parent = SliderFrame.Frame,
		ThemeTag = {
			BackgroundColor3 = "SliderRail",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),
		New("UISizeConstraint", {
			MaxSize = Vector2.new(150, math.huge),
		}),
		SliderDisplay,
		SliderFill,
		SliderRail,
	})

	local function StopDragging()
		Dragging = false
		DragTouch = nil
		Library:UnlockInput(InputLock)
	end

	Creator.AddSignal(SliderDot.InputBegan, function(Input)
		if
			Input.UserInputType ~= Enum.UserInputType.MouseButton1
			and Input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		Dragging = true
		DragTouch = Input.UserInputType == Enum.UserInputType.Touch and Input or nil
		Library:LockInput(InputLock)
	end)

	local InputChangedConnection = Creator.AddSignal(UserInputService.InputChanged, function(Input)
		if
			Dragging
			and (
				Input.UserInputType == Enum.UserInputType.MouseMovement
				or (Input.UserInputType == Enum.UserInputType.Touch and Input == DragTouch)
			)
		then
			local Width = SliderRail.AbsoluteSize.X
			if Width <= 0 then
				return
			end

			local SizeScale =
				math.clamp((Input.Position.X - SliderRail.AbsolutePosition.X) / Width, 0, 1)
			Slider:SetValue(Slider.Min + ((Slider.Max - Slider.Min) * SizeScale))
		end
	end)

	-- Releasing the pointer outside of the dot must still end the drag,
	-- otherwise the slider (and the input lock) stays active.
	local InputEndedConnection = Creator.AddSignal(UserInputService.InputEnded, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or (Input.UserInputType == Enum.UserInputType.Touch and Input == DragTouch)
		then
			StopDragging()
		end
	end)

	function Slider:OnChanged(Func)
		Slider.Changed = Func
		Func(Slider.Value)
	end

	function Slider:SetValue(Value)
		self.Value = Library:Round(math.clamp(Value, Slider.Min, Slider.Max), Slider.Rounding)

		local Range = Slider.Max - Slider.Min
		local Alpha = Range > 0 and (self.Value - Slider.Min) / Range or 0

		SliderDot.Position = UDim2.new(Alpha, -7, 0.5, 0)
		SliderFill.Size = UDim2.fromScale(Alpha, 1)
		SliderDisplay.Text = tostring(self.Value)

		Library:SafeCallback(Slider.Callback, self.Value)
		Library:SafeCallback(Slider.Changed, self.Value)
	end

	function Slider:Destroy()
		StopDragging()

		Creator.RemoveSignal(InputChangedConnection)
		Creator.RemoveSignal(InputEndedConnection)

		SliderFrame:Destroy()
		Library.Options[Idx] = nil
	end

	Slider:SetValue(Config.Default)

	Library.Options[Idx] = Slider
	return Slider
end

return Element
