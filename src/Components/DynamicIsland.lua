-- A floating Dynamic Island pill at the top centre. Tapping it toggles the
-- interface. Just the pill and a status dot — no labels, no switch.
-- Motion: feedback starts on pointer-down, the scale spring retargets from
-- the live value, and nothing overshoots.

local Root = script.Parent.Parent
local Creator = require(Root.Creator)
local Flipper = require(Root.Packages.Flipper)

local New = Creator.New
local Spring = Flipper.Spring.new

local PILL_WIDTH = 52
local PILL_HEIGHT = 34
local PRESS_FREQUENCY = 14
local RELEASE_FREQUENCY = 8

local function setGoal(Motor, Value, Frequency)
	Motor:setGoal(Spring(Value, { frequency = Frequency, dampingRatio = 1 }))
end

return function(Library, Parent)
	local Island = {}
	local Window = Library.Window
	local Enabled = true

	local Scaler = New("UIScale", { Scale = 1 })
	Island.ScaleMotor = Flipper.SingleMotor.new(1)
	Island.ScaleMotor:onStep(function(Value)
		Scaler.Scale = Value
	end)

	Island.Dot = New("Frame", {
		Size = UDim2.fromOffset(10, 10),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 0,
		ThemeTag = { BackgroundColor3 = "Accent" },
	}, {
		New("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	Island.Root = New("TextButton", {
		Size = UDim2.fromOffset(PILL_WIDTH, PILL_HEIGHT),
		Position = UDim2.new(0.5, 0, 0, 10),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 0,
		AutoButtonColor = false,
		Text = "",
		Parent = Parent,
		ThemeTag = { BackgroundColor3 = "Background" },
	}, {
		Scaler,
		New("UICorner", { CornerRadius = UDim.new(0, PILL_HEIGHT / 2) }),
		New("UIStroke", {
			Thickness = 1,
			Transparency = 0.5,
			ThemeTag = { Color = "ElementBorder" },
		}),
		Island.Dot,
	})

	function Island:SetEnabled(Value, Silent)
		Enabled = Value and true or false
		Creator.OverrideTag(self.Dot, { BackgroundColor3 = Enabled and "Accent" or "SubText" })

		if not Silent and Window then
			Window:Minimize(true, true)
		end
	end

	if Window then
		Window.OnMinimizeChanged = function(Minimized)
			Island:SetEnabled(not Minimized, true)
		end
	end

	Creator.AddSignal(Island.Root.MouseButton1Down, function()
		setGoal(Island.ScaleMotor, 0.94, PRESS_FREQUENCY)
	end)

	local function release()
		setGoal(Island.ScaleMotor, 1, RELEASE_FREQUENCY)
	end

	Creator.AddSignal(Island.Root.MouseButton1Up, function()
		release()
		Island:SetEnabled(not Enabled)
	end)
	Creator.AddSignal(Island.Root.MouseLeave, release)

	function Island:Destroy()
		Island.ScaleMotor:stop()
		Island.Root:Destroy()
	end

	return Island
end
