local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Root = script.Parent.Parent
local Flipper = require(Root.Packages.Flipper)
local Creator = require(Root.Creator)
local Components = script.Parent

local Spring = Flipper.Spring.new
local Instant = Flipper.Instant.new
local New = Creator.New

-- The window size is fixed. Resizing and maximizing were removed, so this is
-- the only size the window can ever have.
local WINDOW_SIZE = UDim2.fromOffset(635, 541)

local function GetViewportSize()
	local Camera = Workspace.CurrentCamera
	return Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
end

local function GetViewportBounds()
	local TopLeft, BottomRight
	local Success = pcall(function()
		TopLeft, BottomRight = GuiService:GetGuiInset()
	end)

	if not Success then
		TopLeft, BottomRight = Vector2.zero, Vector2.zero
	end

	return GetViewportSize() - (TopLeft or Vector2.zero) - (BottomRight or Vector2.zero)
end

return function(Config)
	local Library = require(Root)
	local Viewport = GetViewportSize()

	local Window = {
		Minimized = false,
		Hidden = false,
		Size = WINDOW_SIZE,
		CurrentPos = 0,
		TabWidth = 0,
		Position = UDim2.fromOffset(
			Viewport.X / 2 - WINDOW_SIZE.X.Offset / 2,
			Viewport.Y / 2 - WINDOW_SIZE.Y.Offset / 2
		),
	}

	local Dragging = false
	local DragTouch = nil
	local DragStartInput = nil
	local DragStartPos = nil
	local MinimizeNotif = false

	local function ClampToViewport(Position, Size)
		local Bounds = GetViewportBounds()
		Size = Size or (Window.Root and Window.Root.AbsoluteSize) or Vector2.zero

		if Size.X <= 0 or Size.Y <= 0 then
			Size = Vector2.new(Window.Size.X.Offset, Window.Size.Y.Offset)
		end

		local MaxX = math.max(0, Bounds.X - Size.X)
		local MaxY = math.max(0, Bounds.Y - Size.Y)

		return Vector2.new(math.clamp(Position.X, 0, MaxX), math.clamp(Position.Y, 0, MaxY))
	end

	Window.BackgroundCorner = New("UICorner", { CornerRadius = UDim.new(0, 8) })

	Window.Background = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0,
		ThemeTag = {
			BackgroundColor3 = "Background",
		},
	}, {
		Window.BackgroundCorner,
	})

	Window.TabWidth = Config.TabWidth

	local Selector = New("Frame", {
		Size = UDim2.fromOffset(4, 0),
		BackgroundColor3 = Color3.fromRGB(76, 194, 255),
		Position = UDim2.fromOffset(0, 17),
		AnchorPoint = Vector2.new(0, 0.5),
		ThemeTag = {
			BackgroundColor3 = "Accent",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 2),
		}),
	})
	Window.Selector = Selector

	Window.TabHolder = New("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScrollBarImageTransparency = 1,
		ScrollBarThickness = 0,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromScale(0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local TabFrame = New("Frame", {
		Size = UDim2.new(0, Window.TabWidth, 1, -66),
		Position = UDim2.new(0, 12, 0, 54),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, {
		Window.TabHolder,
		Selector,
	})

	Window.TabDisplay = New("TextLabel", {
		RichText = true,
		Text = "Tab",
		TextTransparency = 0,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
		TextSize = 28,
		TextXAlignment = "Left",
		TextYAlignment = "Center",
		Size = UDim2.new(1, -16, 0, 28),
		Position = UDim2.fromOffset(Window.TabWidth + 26, 56),
		BackgroundTransparency = 1,
		ThemeTag = {
			TextColor3 = "Text",
		},
	})

	Window.ContainerHolder = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})

	Window.ContainerAnim = New("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})

	Window.ContainerCanvas = New("Frame", {
		Size = UDim2.new(1, -Window.TabWidth - 32, 1, -102),
		Position = UDim2.fromOffset(Window.TabWidth + 26, 90),
		BackgroundTransparency = 1,
	}, {
		Window.ContainerAnim,
		Window.ContainerHolder
	})

	-- A CanvasGroup gives one cheap group-alpha for the whole window.
	Window.Root = New("CanvasGroup", {
		BackgroundTransparency = 1,
		GroupTransparency = 0,
		Size = Window.Size,
		Position = Window.Position,
		Parent = Config.Parent,
	}, {
		Window.Background,
		Window.TabDisplay,
		Window.ContainerCanvas,
		TabFrame,
	})

	-- The WINDOW ITSELF becomes the pill. Width and height get independent
	-- springs (Apple §3), the corner radius follows height so the rectangle
	-- turns into a capsule, and the centre travels to the island (§7).
	local ISLAND_CENTRE = Vector2.new(Viewport.X / 2, 10 + 34 / 2)
	local PILL_SIZE = Vector2.new(190, 34) -- Y is the pill height; X is only a width fallback
	local OPEN_SIZE = Vector2.new(Window.Size.X.Offset, Window.Size.Y.Offset)
	local WINDOW_CORNER, PILL_CORNER = 8, 17

	Window.WidthMotor = Flipper.SingleMotor.new(OPEN_SIZE.X)
	Window.HeightMotor = Flipper.SingleMotor.new(OPEN_SIZE.Y)

	-- Read the island's LIVE centre instead of trusting a hard-coded offset.
	-- The island can move with safe-area insets or a layout change, and its
	-- press feedback changes its AbsoluteSize — both are picked up here.
	local function islandCentre()
		local Island = Library.DynamicIsland
		if Island and Island.Root and Island.Root.Parent then
			return Island.Root.AbsolutePosition + Island.Root.AbsoluteSize / 2
		end
		return ISLAND_CENTRE
	end

	-- The island sizes itself to its text, so the folded width must be read
	-- live instead of copied from a constant.
	local function closedWidth()
		local Island = Library.DynamicIsland
		return Island and Island.Root.AbsoluteSize.X or 190
	end

	local contentShown = true
	local function applyMorph()
		local Width = Window.WidthMotor:getValue()
		local Height = Window.HeightMotor:getValue()
		local ClosedWidth = closedWidth()
		local WidthProgress = math.clamp((Width - ClosedWidth) / (OPEN_SIZE.X - ClosedWidth), 0, 1)
		local HeightProgress = math.clamp((Height - PILL_SIZE.Y) / (OPEN_SIZE.Y - PILL_SIZE.Y), 0, 1)

		Window.Root.Size = UDim2.fromOffset(Width, Height)
		Window.BackgroundCorner.CornerRadius = UDim.new(0,
			PILL_CORNER + (WINDOW_CORNER - PILL_CORNER) * HeightProgress)

		local OpenCentre = Vector2.new(
			Window.Position.X.Offset + OPEN_SIZE.X / 2,
			Window.Position.Y.Offset + OPEN_SIZE.Y / 2
		)
		local Centre = islandCentre():Lerp(OpenCentre, WidthProgress)
		Window.Root.Position = UDim2.fromOffset(Centre.X - Width / 2, Centre.Y - Height / 2)

		-- Content leaves before the shell, so the remaining shape reads as a
		-- plain dark pill travelling into the island (Apple §12).
		local Show = WidthProgress > 0.55
		if Show ~= contentShown then
			contentShown = Show
			for _, Object in ipairs(Window.MorphContent or {}) do
				Object.Visible = Show
			end
		end

		Window.Root.GroupTransparency = 1 - math.clamp(WidthProgress * 2.2, 0, 1)
		Window.Root.Visible = not Window.Hidden and not (Window.Minimized and WidthProgress <= 0.01)
	end

	Window.WidthMotor:onStep(applyMorph)
	Window.HeightMotor:onStep(applyMorph)

	-- Once folded, the window is invisible but still tracks the island so a
	-- later island move cannot leave it stranded. Ten hertz suffices here; the
	-- motor callbacks keep the morph animation smooth.
	local MORPH_TRACK_INTERVAL = 0.1
	local morphTrackTime = 0
	Creator.AddSignal(RunService.RenderStepped, function(Delta)
		if not Window.Minimized then
			morphTrackTime = 0
			return
		end
		morphTrackTime = morphTrackTime + Delta
		if morphTrackTime >= MORPH_TRACK_INTERVAL then
			morphTrackTime = 0
			applyMorph()
		end
	end)

	Window.TitleBar = require(script.Parent.TitleBar)({
		Title = Config.Title,
		SubTitle = Config.SubTitle,
		Parent = Window.Root,
		Window = Window,
	})

	Window.MorphContent = {
		Window.TabDisplay,
		Window.ContainerCanvas,
		TabFrame,
		Window.TitleBar.Frame,
	}

	local PosMotor = Flipper.GroupMotor.new({
		X = Window.Position.X.Offset,
		Y = Window.Position.Y.Offset,
	})

	Window.SelectorPosMotor = Flipper.SingleMotor.new(17)
	Window.SelectorSizeMotor = Flipper.SingleMotor.new(0)
	Window.ContainerBackMotor = Flipper.SingleMotor.new(0)
	Window.ContainerPosMotor = Flipper.SingleMotor.new(94)

	PosMotor:onStep(function(values)
		Window.Position = UDim2.new(0, values.X, 0, values.Y)
		applyMorph()
	end)

	local LastValue = 0
	local LastTime = 0
	Window.SelectorPosMotor:onStep(function(Value)
		Selector.Position = UDim2.new(0, 0, 0, Value + 17)
		local Now = tick()
		local DeltaTime = Now - LastTime

		if LastValue ~= nil then
			Window.SelectorSizeMotor:setGoal(Spring((math.abs(Value - LastValue) / (DeltaTime * 60)) + 16))
			LastValue = Value
		end
		LastTime = Now
	end)

	Window.SelectorSizeMotor:onStep(function(Value)
		Selector.Size = UDim2.new(0, 4, 0, Value)
	end)

	Window.ContainerBackMotor:onStep(function(Value)
		Window.ContainerAnim.GroupTransparency = Value
	end)

	Window.ContainerPosMotor:onStep(function(Value)
		Window.ContainerAnim.Position = UDim2.fromOffset(0, Value)
	end)

	do
		local Initial = ClampToViewport(Vector2.new(Window.Position.X.Offset, Window.Position.Y.Offset))
		Window.Position = UDim2.fromOffset(Initial.X, Initial.Y)
		applyMorph()
		PosMotor:setGoal({
			X = Instant(Initial.X),
			Y = Instant(Initial.Y),
		})
	end

	-- Read the motor's live position; these corrections arrive after startup.
	-- Pass Size when the shell is folded: its AbsoluteSize is the pill's, not
	-- the full window the position has to fit.
	local function ReclampToViewport(Size)
		local Current = Vector2.new(Window.Position.X.Offset, Window.Position.Y.Offset)
		local Clamped = ClampToViewport(Current, Size)
		PosMotor:setGoal({
			X = Instant(Clamped.X),
			Y = Instant(Clamped.Y),
		})
	end

	local ViewportConnection
	local function watchCamera()
		local Camera = Workspace.CurrentCamera
		Creator.RemoveSignal(ViewportConnection)
		ViewportConnection = nil
		if Camera then
			ViewportConnection = Creator.AddSignal(Camera:GetPropertyChangedSignal("ViewportSize"), ReclampToViewport)
		end
	end

	watchCamera()
	Creator.AddSignal(Workspace:GetPropertyChangedSignal("CurrentCamera"), function()
		watchCamera()
		ReclampToViewport()
	end)

	Creator.AddSignal(Window.TitleBar.Frame.InputBegan, function(Input)
		if
			Input.UserInputType ~= Enum.UserInputType.MouseButton1
			and Input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		if Library:IsInputLocked() then
			return
		end

		Dragging = true
		DragTouch = Input.UserInputType == Enum.UserInputType.Touch and Input or nil
		DragStartInput = Vector2.new(Input.Position.X, Input.Position.Y)

		DragStartPos = Vector2.new(Window.Position.X.Offset, Window.Position.Y.Offset)
	end)

	Creator.AddSignal(UserInputService.InputChanged, function(Input)
		if Dragging and not Library:IsInputLocked() then
			local IsDragInput = Input.UserInputType == Enum.UserInputType.MouseMovement
				or (Input.UserInputType == Enum.UserInputType.Touch and Input == DragTouch)

			if IsDragInput then
				local Current = Vector2.new(Input.Position.X, Input.Position.Y)
				local Position = ClampToViewport(DragStartPos + (Current - DragStartInput))

				Window.Position = UDim2.fromOffset(Position.X, Position.Y)
				PosMotor:setGoal({
					X = Instant(Position.X),
					Y = Instant(Position.Y),
				})
			end
		end
	end)

	Creator.AddSignal(UserInputService.InputEnded, function(Input)
		if Dragging and (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input == DragTouch) then
			Dragging = false
			DragTouch = nil
			ReclampToViewport()
		end

	end)

	Creator.AddSignal(Window.TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		Window.TabHolder.CanvasSize = UDim2.new(0, 0, 0, Window.TabHolder.UIListLayout.AbsoluteContentSize.Y)
	end)

	Creator.AddSignal(UserInputService.InputBegan, function(Input, GameProcessed)
		if GameProcessed or Input.UserInputType ~= Enum.UserInputType.Keyboard or Library:IsTyping() then
			return
		end

		if
			type(Library.MinimizeKeybind) == "table"
			and Library.MinimizeKeybind.Type == "Keybind"
			and Library.MinimizeKeybind.Value
		then
			if Input.KeyCode.Name == Library.MinimizeKeybind.Value then
				Window:Minimize()
			end
		elseif Input.KeyCode == Library.MinimizeKey then
			Window:Minimize()
		end
	end)

	function Window:Minimize(Silent, Animated)
		Window.Minimized = not Window.Minimized
		local Closing = Window.Minimized
		local GoalWidth = Closing and closedWidth() or OPEN_SIZE.X
		local GoalHeight = Closing and PILL_SIZE.Y or OPEN_SIZE.Y

		-- A clamp applied while the window was folded can leave the stored
		-- position off-screen for the full-size shell, so re-clamp on reopen.
		if not Closing then
			ReclampToViewport(OPEN_SIZE)
		end

		if Animated then
			-- Width travels further than height, so they get their own
			-- critically damped springs (Apple §3). Height settles sooner,
			-- which makes the shell turn into a capsule before it arrives.
			Window.WidthMotor:setGoal(Spring(GoalWidth, {
				frequency = Closing and 2.5 or 2.2,
				dampingRatio = 1,
			}))
			Window.HeightMotor:setGoal(Spring(GoalHeight, {
				frequency = Closing and 3.0 or 2.6,
				dampingRatio = 1,
			}))
		else
			-- Keyboard toggles stay instant: no input-path animation.
			Window.Root.Visible = not Closing
			Window.WidthMotor:setGoal(Instant(GoalWidth))
			Window.HeightMotor:setGoal(Instant(GoalHeight))
		end

		if Window.OnMinimizeChanged then
			Window.OnMinimizeChanged(Window.Minimized)
		end
		if not Silent and not MinimizeNotif then
			MinimizeNotif = true
			local Key = Library.MinimizeKeybind and Library.MinimizeKeybind.Value or Library.MinimizeKey.Name
			Library:Notify({
				Title = "Interface",
				Content = "Press " .. Key .. " to toggle the interface.",
				Duration = 6
			})
		end
	end

	local TabModule = require(Components.Tab):Init(Window)

	function Window:Destroy()
		PosMotor:stop()
		TabModule:Destroy()
		Window.WidthMotor:stop()
		Window.HeightMotor:stop()
		Window.SelectorPosMotor:stop()
		Window.SelectorSizeMotor:stop()
		Window.ContainerBackMotor:stop()
		Window.ContainerPosMotor:stop()

		if Library.Window == Window and not Library.Unloaded then
			Library:Destroy()
			return
		end

		Window.Root:Destroy()
	end

	local DialogModule = require(Components.Dialog):Init(Window)
	function Window:Dialog(Config)
		local Dialog = DialogModule:Create()
		Dialog.Title.Text = Config.Title

		Config.Buttons = Config.Buttons or {}

		local Content = New("TextLabel", {
			FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
			Text = Config.Content,
			TextColor3 = Color3.fromRGB(240, 240, 240),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Size = UDim2.new(1, -40, 1, 0),
			Position = UDim2.fromOffset(20, 60),
			BackgroundTransparency = 1,
			Parent = Dialog.Root,
			ClipsDescendants = false,
			ThemeTag = {
				TextColor3 = "Text",
			},
		})

		New("UISizeConstraint", {
			MinSize = Vector2.new(300, 165),
			MaxSize = Vector2.new(620, math.huge),
			Parent = Dialog.Root,
		})

		Dialog.Root.Size = UDim2.fromOffset(Content.TextBounds.X + 40, 165)
		if Content.TextBounds.X + 40 > Window.Size.X.Offset - 120 then
			Dialog.Root.Size = UDim2.fromOffset(Window.Size.X.Offset - 120, 165)
			Content.TextWrapped = true
			Dialog.Root.Size = UDim2.fromOffset(Window.Size.X.Offset - 120, Content.TextBounds.Y + 150)
		end

		for _, Button in next, Config.Buttons do
			Dialog:Button(Button.Title, Button.Callback)
		end

		Dialog:Open()
	end

	function Window:AddTab(TabConfig)
		return TabModule:New(
			TabConfig.Title,
			TabConfig.Icon,
			Window.TabHolder,
			TabConfig.Group,
			TabConfig.GroupIcon
		)
	end

	function Window:SetGroupOpen(Name, Open, Animated)
		TabModule:SetGroupOpen(Name, Open, Animated)
	end

	function Window:ToggleGroup(Name)
		-- Headers only ever open a group; a group closes when another opens
		-- or when a flat tab is selected.
		TabModule:OpenGroup(Name, true)
	end

	function Window:SetNavQuery(Query)
		TabModule:SetNavQuery(Query)
	end

	function Window:SelectTab(Tab)
		TabModule:SelectTab(Tab)
	end

	-- Kept hidden while the centred loader runs, so the interface appears
	-- only once loading has finished. applyMorph respects the flag, which
	-- keeps the island fold from revealing an unfinished window.
	function Window:SetHidden(Hidden)
		self.Hidden = Hidden == true
		applyMorph()
	end

	Creator.AddSignal(Window.TabHolder:GetPropertyChangedSignal("CanvasPosition"), function()
		LastValue = TabModule:GetCurrentTabPos() + 16
		LastTime = 0
		Window.SelectorPosMotor:setGoal(Instant(TabModule:GetCurrentTabPos()))
	end)

	return Window
end
