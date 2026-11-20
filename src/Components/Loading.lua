-- A centred loading panel: one horizontal progress line inside a quiet
-- themed wrapper. No full-screen dim — the real window stays hidden until
-- this panel has finished and faded out.
--
-- Motion rules (same bar as the rest of the library):
--   * critically damped springs, so nothing overshoots
--   * entrance starts at scale 0.97, never scale(0)
--   * the exit retraces the entrance and retargets from the live value
--   * the unknown-progress sweep is linear because it never accelerates
--   * ReducedMotion drops movement and keeps the opacity cross-fade

local RunService = game:GetService("RunService")

local Root = script.Parent.Parent
local Creator = require(Root.Creator)
local Flipper = require(Root.Packages.Flipper)

local New = Creator.New
local Spring = Flipper.Spring.new

local ENTER_FREQUENCY = 6 -- ~0.25s to settle at damping 1
local EXIT_FREQUENCY = 7 -- a touch quicker on the way out
local BAR_FREQUENCY = 7 -- bar tracks updates without visible lag
local SWEEP_SECONDS = 1.2 -- one left-to-right pass
local SWEEP_WIDTH = 0.28 -- fraction of the track
local CLOSED_SCALE = 0.97 -- never scale(0)
local Z = 100 -- above the window and the island

local FONT = "rbxassetid://12187365364"

local function clamp01(Value)
	if Value ~= Value then
		return 0
	end
	return math.clamp(Value, 0, 1)
end

return function(Library, Parent, Config)
	Config = Config or {}

	local ReducedMotion = Config.ReducedMotion == true or Library.ReducedMotion == true
	local Indeterminate = Config.Progress == nil
	local StartedAt = os.clock()

	local Handle = {
		Closed = false,
		Destroyed = false,
	}

	-- Full-screen container only. It is transparent on purpose: dimming the
	-- whole screen is exactly what the user does not want here.
	local Overlay = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = Z,
		Parent = Parent,
	})

	local Scaler = New("UIScale", {
		Scale = ReducedMotion and 1 or CLOSED_SCALE,
	})

	local Title = New("TextLabel", {
		Text = Config.Title or "Loading",
		FontFace = Font.new(FONT, Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(20, 14),
		Size = UDim2.fromOffset(240, 18),
		BackgroundTransparency = 1,
		ZIndex = Z,
		ThemeTag = { TextColor3 = "Text" },
	})

	local Percent = New("TextLabel", {
		Text = Indeterminate and "" or (math.floor(clamp01(Config.Progress) * 100 + 0.5) .. "%"),
		FontFace = Font.new(FONT, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromOffset(260, 14),
		Size = UDim2.fromOffset(120, 18),
		BackgroundTransparency = 1,
		Visible = not Indeterminate,
		ZIndex = Z,
		ThemeTag = { TextColor3 = "SubText" },
	})

	local Fill = New("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundTransparency = 0,
		Visible = not Indeterminate,
		ZIndex = Z,
		ThemeTag = { BackgroundColor3 = "Accent" },
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 2) }),
	})

	local Sweep = New("Frame", {
		Size = UDim2.new(SWEEP_WIDTH, 0, 1, 0),
		Position = UDim2.new(-SWEEP_WIDTH, 0, 0, 0),
		BackgroundTransparency = 0,
		Visible = Indeterminate,
		ZIndex = Z,
		ThemeTag = { BackgroundColor3 = "Accent" },
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 2) }),
	})

	local Track = New("Frame", {
		Size = UDim2.fromOffset(360, 4),
		Position = UDim2.fromOffset(20, 44),
		BackgroundTransparency = 0,
		-- The sweep segment starts outside the left edge and finishes outside
		-- the right one. Without clipping its blue pixels leak past the rail.
		ClipsDescendants = true,
		ZIndex = Z,
		ThemeTag = { BackgroundColor3 = "SliderRail" },
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 2) }),
		Fill,
		Sweep,
	})

	local SubText = New("TextLabel", {
		Text = Config.Text or "",
		FontFace = Font.new(FONT, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(20, 58),
		Size = UDim2.fromOffset(360, 16),
		TextWrapped = true,
		BackgroundTransparency = 1,
		ZIndex = Z,
		ThemeTag = { TextColor3 = "SubText" },
	})

	-- CanvasGroup keeps the wrapper and every child on one opacity motor, so
	-- the panel arrives as one piece instead of label by label.
	local Content = New("CanvasGroup", {
		Size = UDim2.fromOffset(400, 92),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 0,
		GroupTransparency = 1,
		ZIndex = Z,
		Parent = Overlay,
		ThemeTag = { BackgroundColor3 = "Background" },
	}, {
		Scaler,
		New("UICorner", { CornerRadius = UDim.new(0, 8) }),
		New("UIStroke", {
			Thickness = 1,
			Transparency = 0.55,
			ThemeTag = { Color = "ElementBorder" },
		}),
		Title,
		Percent,
		Track,
		SubText,
	})

	local Surface = Flipper.GroupMotor.new({
		Alpha = 1,
		Scale = Scaler.Scale,
	})

	Surface:onStep(function(Values)
		Content.GroupTransparency = Values.Alpha
		Scaler.Scale = Values.Scale
	end)

	local Progress = clamp01(Config.Progress or 0)
	local Bar = Flipper.SingleMotor.new(Progress)

	Bar:onStep(function(Value)
		Progress = Value
		Fill.Size = UDim2.new(Value, 0, 1, 0)
		if not Indeterminate then
			Percent.Text = math.floor(Value * 100 + 0.5) .. "%"
		end
	end)

	-- Unknown progress gets a short segment sliding across the track. It is
	-- constant motion, so the phase advances linearly rather than on a spring.
	-- Reduced motion parks the segment in the middle and lets the fade carry.
	local SweepConnection = nil

	local function stopSweep()
		if SweepConnection then
			Creator.RemoveSignal(SweepConnection)
			SweepConnection = nil
		end
	end

	local function startSweep()
		if ReducedMotion then
			Sweep.Position = UDim2.fromScale(0.36, 0)
			return
		end
		if SweepConnection then
			return
		end
		local Phase = 0
		SweepConnection = Creator.AddSignal(RunService.Heartbeat, function(Delta)
			if Handle.Closed or not Sweep.Parent then
				return
			end
			Phase = (Phase + Delta / SWEEP_SECONDS) % 1
			Sweep.Position = UDim2.new(-SWEEP_WIDTH + Phase * (1 + SWEEP_WIDTH), 0, 0, 0)
		end)
	end

	if Indeterminate then
		startSweep()
	end

	function Handle:SetProgress(Value)
		if self.Closed or self.Destroyed then
			return
		end
		self:SetIndeterminate(false)
		Bar:setGoal(Spring(clamp01(Value), { frequency = BAR_FREQUENCY, dampingRatio = 1 }))
	end

	function Handle:SetIndeterminate(Value)
		if self.Closed or self.Destroyed then
			return
		end
		Indeterminate = Value == true
		Fill.Visible = not Indeterminate
		Percent.Visible = not Indeterminate
		Sweep.Visible = Indeterminate

		if Indeterminate then
			startSweep()
		else
			stopSweep()
		end
	end

	function Handle:SetTitle(Value)
		Title.Text = tostring(Value or "")
	end

	function Handle:SetText(Value)
		SubText.Text = tostring(Value or "")
	end

	function Handle:GetProgress()
		return Progress
	end

	function Handle:GetMinDuration()
		return Config.MinDuration or 0.45
	end

	function Handle:GetElapsed()
		return os.clock() - StartedAt
	end

	function Handle:Close()
		if self.Closed or self.Destroyed then
			return
		end
		self.Closed = true

		stopSweep()
		Bar:stop()

		local Frequency = ReducedMotion and ENTER_FREQUENCY or EXIT_FREQUENCY
		Surface:setGoal({
			Alpha = Spring(1, { frequency = Frequency, dampingRatio = 1 }),
			Scale = Spring(ReducedMotion and 1 or CLOSED_SCALE, { frequency = Frequency, dampingRatio = 1 }),
		})

		-- Destroy only after the exit spring has settled. task.delay runs on a
		-- fresh thread, so it does not hold up whichever script called Close.
		task.delay(ReducedMotion and 0.2 or 0.3, function()
			if not self.Destroyed then
				self:Destroy()
			end
		end)
	end

	function Handle:Destroy()
		if self.Destroyed then
			return
		end
		self.Destroyed = true
		self.Closed = true

		stopSweep()
		Surface:stop()
		Bar:stop()
		Overlay:Destroy()

		if Library.Loading == self then
			Library.Loading = nil
			Library.LoadingToken = nil
			Library.LoadingIsAuto = false
		end
	end

	-- Enter. The spring starts from the values above, so a Close() during the
	-- entrance simply retargets from wherever the overlay is right now.
	Surface:setGoal({
		Alpha = Spring(0, { frequency = ENTER_FREQUENCY, dampingRatio = 1 }),
		Scale = Spring(1, { frequency = ENTER_FREQUENCY, dampingRatio = 1 }),
	})

	if not Indeterminate then
		Bar:setGoal(Spring(Progress, { frequency = BAR_FREQUENCY, dampingRatio = 1 }))
	end

	return Handle
end
