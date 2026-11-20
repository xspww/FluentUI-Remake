-- A floating Dynamic Island pill at the top centre. Tapping it toggles the
-- interface. The pill carries an avatar, a name, a breathing status dot and a
-- live FPS readout. Motion: instant press feedback, no overshoot, and a slow
-- ambient breath on the dot only.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")

local Root = script.Parent.Parent
local Creator = require(Root.Creator)
local Flipper = require(Root.Packages.Flipper)

local New = Creator.New
local Spring = Flipper.Spring.new
local Instant = Flipper.Instant.new
local LAYOUT_FREQUENCY = 6 -- ~0.16s settle, critically damped
local function lerp(A, B, T)
	return A + (B - A) * T
end

local PILL_WIDTH = 190 -- pre-layout initial value; layout() sizes from content
local PILL_HEIGHT = 34
local PADDING, GAP = 10, 8
local PRESS_FREQUENCY = 14
local RELEASE_FREQUENCY = 8
local BREATH_HZ = 0.6
local FPS_INTERVAL = 5
local FPS_TEXT_PULSE = 0.16 -- 160ms, opacity only (reduced-motion safe)

local function setGoal(Motor, Value, Frequency)
	Motor:setGoal(Spring(Value, { frequency = Frequency, dampingRatio = 1 }))
end

local function avatarFor(UserId)
	local Success, Image = pcall(function()
		return Players:GetUserThumbnailAsync(
			UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size48x48
		)
	end)
	return Success and Image or "rbxassetid://10709791437"
end

local function hashString(Value)
	local Hash = 2166136261
	for Index = 1, #Value do
		Hash = (Hash * 16777619) % 4294967296
		Hash = (Hash + string.byte(Value, Index)) % 4294967296
	end
	return string.format("%x", math.floor(Hash))
end

local function extensionFor(Url)
	local Ext = Url:match("%.([%w]+)$")
	if Ext and #Ext <= 5 then
		return "." .. Ext:lower()
	end
	return ".png"
end

-- Roblox ImageLabel cannot load an arbitrary http url. Real executors can
-- fetch the bytes, write a workspace file and turn it into an rbxasset id.
local function resolveAvatar(Source)
	if type(Source) ~= "string" then
		return nil
	end
	if Source:match("^rbxasset") or Source:match("^%d+$") or not Source:match("^https?://") then
		return Source
	end
	if type(request) ~= "function" or type(writefile) ~= "function" or type(getcustomasset) ~= "function" then
		return Source
	end

	local Ok, Asset = pcall(function()
		local Response = request({ Url = Source, Method = "GET" })
		local Body = type(Response) == "table" and Response.Success and Response.Body or nil
		if not Body or #Body == 0 then
			return nil
		end
		local Path = "FluentIsland/avatar_" .. hashString(Source) .. extensionFor(Source)
		writefile(Path, Body)
		return getcustomasset(Path)
	end)

	if Ok and type(Asset) == "string" then
		return Asset
	end
	return Source
end

return function(Library, Parent)
	local Island = {}
	local Window = Library.Window
	local Breath, SampleTime, FrameCount = 0, 0, 0
	local FpsPulse = 0

	local Scaler = New("UIScale", { Scale = 1 })
	Island.ScaleMotor = Flipper.SingleMotor.new(1)
	Island.ScaleMotor:onStep(function(Value)
		Scaler.Scale = Value
	end)

	local AvatarImage = avatarFor(Players.LocalPlayer.UserId)

	Island.Avatar = New("ImageLabel", {
		Size = UDim2.fromOffset(22, 22),
		Position = UDim2.new(0, 8, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		Image = AvatarImage,
	}, {
		New("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	Island.NameLabel = New("TextLabel", {
		Text = "xspww",
		FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromOffset(76, 20),
		Position = UDim2.new(0, 38, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		ThemeTag = { TextColor3 = "Text" },
	})

	Island.DotGlow = New("Frame", {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.new(0, 124, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ThemeTag = { BackgroundColor3 = "Accent" },
	}, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	Island.Dot = New("Frame", {
		Size = UDim2.fromOffset(6, 6),
		Position = UDim2.new(0, 121, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 0,
		ThemeTag = { BackgroundColor3 = "Accent" },
	}, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	Island.FpsLabel = New("TextLabel", {
		Text = "-- fps",
		FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromOffset(46, 20),
		Position = UDim2.new(0, 136, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		ThemeTag = { TextColor3 = "SubText" },
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
		Island.Avatar,
		Island.NameLabel,
		Island.DotGlow,
		Island.Dot,
		Island.FpsLabel,
	})

	Island.LayoutMotor = Flipper.SingleMotor.new(1)
	local From, To = {}, {}
	local LayoutReady = false

	Island.LayoutMotor:onStep(function(Value)
		Island.Root.Size = UDim2.fromOffset(lerp(From.width, To.width, Value), PILL_HEIGHT)
		Island.NameLabel.Size = UDim2.fromOffset(lerp(From.nameWidth, To.nameWidth, Value), 20)
		Island.Dot.Position = UDim2.new(0, lerp(From.dotX, To.dotX, Value), 0.5, 0)
		Island.DotGlow.Position = UDim2.new(0, lerp(From.glowX, To.glowX, Value), 0.5, 0)
		Island.FpsLabel.Position = UDim2.new(0, lerp(From.fpsX, To.fpsX, Value), 0.5, 0)
		if Island.OnSizeChanged then
			Island.OnSizeChanged(lerp(From.width, To.width, Value))
		end
	end)

	-- Horizontal layout is driven by the labels' own TextBounds so the pill
	-- hugs its content. task.defer because TextBounds lags one frame after a
	-- text change.
	local function layout()
		local NameWidth = math.ceil(TextService:GetTextSize(
			Island.NameLabel.Text, 12, Enum.Font.Gotham, Vector2.new(9999, 20)).X) + 4
		local FpsWidth = math.ceil(TextService:GetTextSize(
			Island.FpsLabel.Text, 11, Enum.Font.Gotham, Vector2.new(9999, 20)).X) + 2

		Island.FpsLabel.Size = UDim2.fromOffset(FpsWidth, 20)

		local X = PADDING + 22 + GAP                 -- after avatar
		Island.NameLabel.Position = UDim2.new(0, X, 0.5, 0)
		Island.NameLabel.AnchorPoint = Vector2.new(0, 0.5)
		X = X + NameWidth + GAP

		To.dotX = X         -- dot is 6 wide, left anchored
		To.glowX = X + 3    -- glow is 12 wide, centre anchored
		X = X + 6 + GAP

		To.fpsX = X
		Island.FpsLabel.AnchorPoint = Vector2.new(0, 0.5)
		X = X + FpsWidth + PADDING

		To.nameWidth = NameWidth
		To.width = X

		if not LayoutReady then
			LayoutReady = true
			From = table.clone(To)
			Island.LayoutMotor:setGoal(Instant(1))
			-- apply To directly once:
			Island.Root.Size = UDim2.fromOffset(To.width, PILL_HEIGHT)
			Island.NameLabel.Size = UDim2.fromOffset(To.nameWidth, 20)
			Island.Dot.Position = UDim2.new(0, To.dotX, 0.5, 0)
			Island.DotGlow.Position = UDim2.new(0, To.glowX, 0.5, 0)
			Island.FpsLabel.Position = UDim2.new(0, To.fpsX, 0.5, 0)
			return
		end

		From = {
			width = Island.Root.AbsoluteSize.X,
			nameWidth = Island.NameLabel.AbsoluteSize.X,
			dotX = Island.Dot.Position.X.Offset,
			glowX = Island.DotGlow.Position.X.Offset,
			fpsX = Island.FpsLabel.Position.X.Offset,
		}
		Island.LayoutMotor:setGoal(Instant(0))
		Island.LayoutMotor:step(0) -- consume the Instant goal now
		Island.LayoutMotor:setGoal(Spring(1, { frequency = LAYOUT_FREQUENCY, dampingRatio = 1 }))
	end

	function Island:SetName(Name)
		self.NameLabel.Text = tostring(Name)
		task.defer(layout)
	end

	function Island:SetAvatar(Image)
		if type(Image) ~= "string" then
			return
		end
		self.AvatarSource = Image
		if not Image:match("^https?://") then
			self.Avatar.Image = Image
			return
		end
		-- Downloading yields, so resolve off the caller's thread.
		task.spawn(function()
			local Resolved = resolveAvatar(Image)
			if Resolved and self.Avatar.Parent then
				self.Avatar.Image = Resolved
			end
		end)
	end

	-- The rbxasset:// id from getcustomasset is session-scoped. Keep the
	-- original URL so a teleport/rejoin can re-resolve it instead of showing
	-- the fallback thumbnail.
	function Island:RefreshAvatar()
		local Source = self.AvatarSource
		if type(Source) ~= "string" or not Source:match("^https?://") then
			return
		end
		task.spawn(function()
			local Resolved = resolveAvatar(Source)
			if Resolved and self.Avatar.Parent then
				self.Avatar.Image = Resolved
			end
		end)
	end

	pcall(function()
		Creator.AddSignal(Players.LocalPlayer.OnTeleport, function()
			pcall(function()
				Island:RefreshAvatar()
			end)
		end)
	end)

	-- Ambient breath: a gentle sine, not a spring, because nothing interrupts
	-- it. Keep it subtle and slow so it reads as alive, not distracting.
	Creator.AddSignal(RunService.Heartbeat, function(Delta)
		Breath = (Breath + Delta * BREATH_HZ) % 1
		local Wave = (math.sin(Breath * math.pi * 2) + 1) / 2
		Island.Dot.BackgroundTransparency = Wave * 0.35
		Island.DotGlow.BackgroundTransparency = 0.75 + Wave * 0.2

		-- Text change feedback: a short alpha dip, not a scale or position
		-- change. sin() peaks in the middle and lands back at 0 on both ends,
		-- so the label never jumps when the number updates.
		if FpsPulse > 0 then
			FpsPulse = math.max(0, FpsPulse - Delta / FPS_TEXT_PULSE)
			Island.FpsLabel.TextTransparency = math.sin(FpsPulse * math.pi) * 0.45
		elseif Island.FpsLabel.TextTransparency ~= 0 then
			Island.FpsLabel.TextTransparency = 0
		end

		-- Real frame rate: count actual Heartbeats over a 5s window instead
		-- of reading GetRealPhysicsFPS(), which reports the target rate.
		-- Display the real measured value; uncapped clients report high numbers.
		SampleTime = SampleTime + Delta
		FrameCount = FrameCount + 1
		if SampleTime >= FPS_INTERVAL then
			Island.RawFps = FrameCount / SampleTime
			local Fps = math.max(1, math.floor(Island.RawFps + 0.5))
			Island.FpsLabel.Text = tostring(Fps) .. " fps"
			FpsPulse = 1
			task.defer(layout)
			SampleTime, FrameCount = 0, 0
		end
	end)

	Creator.AddSignal(Island.Root.MouseButton1Down, function()
		setGoal(Island.ScaleMotor, 0.94, PRESS_FREQUENCY)
	end)

	local function release()
		setGoal(Island.ScaleMotor, 1, RELEASE_FREQUENCY)
	end

	Creator.AddSignal(Island.Root.MouseButton1Up, function()
		release()
		Window:Minimize(true, true)
	end)
	Creator.AddSignal(Island.Root.MouseLeave, release)

	function Island:Destroy()
		Island.ScaleMotor:stop()
		Island.LayoutMotor:stop()
		Island.Root:Destroy()
	end

	task.defer(layout)

	return Island
end
