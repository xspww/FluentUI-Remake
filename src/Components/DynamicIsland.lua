-- A floating Dynamic Island pill at the top centre. Tapping it toggles the
-- interface. The pill carries an avatar, a name, a breathing status dot and a
-- live FPS readout. Motion: instant press feedback, no overshoot, a slow
-- ambient breath on the dot, and a blurred scroll on the FPS text.

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
local SCROLL_DISTANCE = 20
local SCROLL_FREQUENCY = 5
local GHOST_OFFSETS = { -2.5, -1, 1, 2.5 }
local TEXT_FONT = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular, Enum.FontStyle.Normal)

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

	local Viewport = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	})

	Island.FpsLabel = New("TextLabel", {
		Text = "-- fps",
		FontFace = TEXT_FONT,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromOffset(46, 20),
		Position = UDim2.new(0, 136, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		TextTransparency = 1,
		ThemeTag = { TextColor3 = "SubText" },
	}, { Viewport })

	-- Roblox has no text blur; offset translucent copies approximate the smear
	-- while the two entries trade places.
	local function makeEntry(Text)
		local Entry = { Ghosts = {} }

		for _, Offset in ipairs(GHOST_OFFSETS) do
			local Ghost = New("TextLabel", {
				Parent = Viewport,
				Text = Text,
				FontFace = TEXT_FONT,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				ThemeTag = { TextColor3 = "SubText" },
				Size = UDim2.fromScale(1, 1),
				Visible = false,
				TextTransparency = 1,
			})
			table.insert(Entry.Ghosts, { Label = Ghost, Offset = Offset })
		end

		Entry.Sharp = New("TextLabel", {
			Parent = Viewport,
			Text = Text,
			FontFace = TEXT_FONT,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			ThemeTag = { TextColor3 = "SubText" },
			Size = UDim2.fromScale(1, 1),
		})

		function Entry.SetText(NewText)
			Entry.Sharp.Text = NewText
			for _, Ghost in ipairs(Entry.Ghosts) do
				Ghost.Label.Text = NewText
			end
		end

		function Entry.Apply(Y, Blur)
			Entry.Sharp.Position = UDim2.new(0, 0, 0, Y)
			Entry.Sharp.TextTransparency = Blur * 0.18
			for _, Ghost in ipairs(Entry.Ghosts) do
				Ghost.Label.Position = UDim2.new(0, 0, 0, Y + Ghost.Offset * Blur)
				Ghost.Label.TextTransparency = 1 - Blur * 0.42
				Ghost.Label.Visible = Blur > 0.01
			end
		end

		return Entry
	end

	local function destroyEntry(Entry)
		if not Entry then
			return
		end
		Entry.Sharp:Destroy()
		for _, Ghost in ipairs(Entry.Ghosts) do
			Ghost.Label:Destroy()
		end
	end

	local CurrentEntry = makeEntry("-- fps")
	CurrentEntry.Apply(0, 0)

	Island.ScrollMotor = Flipper.SingleMotor.new(0)
	local ScrollToken
	local ScrollOut, ScrollIn

	Island.ScrollMotor:onStep(function(Value)
		if not ScrollToken then
			return
		end
		local Blur = math.sin(Value * math.pi)
		ScrollOut.Apply(-SCROLL_DISTANCE * Value, Blur)
		ScrollIn.Apply(SCROLL_DISTANCE * (1 - Value), Blur)
	end)

	Island.ScrollMotor:onComplete(function()
		if not ScrollToken then
			return
		end
		ScrollToken = nil
		local Outgoing, Incoming = ScrollOut, ScrollIn
		ScrollOut, ScrollIn = nil, nil
		destroyEntry(Outgoing)
		CurrentEntry = Incoming
		CurrentEntry.Apply(0, 0)
	end)

	local function startScroll(Text)
		if ScrollOut then
			destroyEntry(ScrollOut)
			CurrentEntry = ScrollIn
			CurrentEntry.Apply(0, 0)
			ScrollOut, ScrollIn, ScrollToken = nil, nil, nil
		end

		-- Reset fires onStep and onComplete; the cleared token keeps them from
		-- committing a scroll that has not started yet.
		Island.ScrollMotor:setGoal(Instant(0))
		Island.ScrollMotor:step(0)

		local Incoming = makeEntry(Text)
		Incoming.Apply(SCROLL_DISTANCE, 0)
		ScrollOut, ScrollIn = CurrentEntry, Incoming
		ScrollToken = {}
		setGoal(Island.ScrollMotor, 1, SCROLL_FREQUENCY)
	end

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

		-- Real frame rate: count actual Heartbeats over a 5s window instead
		-- of reading GetRealPhysicsFPS(), which reports the target rate.
		-- Display the real measured value; uncapped clients report high numbers.
		SampleTime = SampleTime + Delta
		FrameCount = FrameCount + 1
		if SampleTime >= FPS_INTERVAL then
			Island.RawFps = FrameCount / SampleTime
			local Fps = math.max(1, math.floor(Island.RawFps + 0.5))
			local Text = tostring(Fps) .. " fps"
			Island.FpsLabel.Text = Text
			if Library.ReducedMotion then
				CurrentEntry.SetText(Text)
			else
				startScroll(Text)
			end
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
		Island.ScrollMotor:stop()
		Island.Root:Destroy()
	end

	task.defer(layout)

	return Island
end
