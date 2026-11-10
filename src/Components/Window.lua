-- i will rewrite this someday
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local Root = script.Parent.Parent
local Flipper = require(Root.Packages.Flipper)
local Creator = require(Root.Creator)
local Acrylic = require(Root.Acrylic)
local Assets = require(script.Parent.Assets)
local Components = script.Parent

local Spring = Flipper.Spring.new
local Instant = Flipper.Instant.new
local New = Creator.New

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
		Maximized = false,
		Size = Config.Size,
		CurrentPos = 0,
		TabWidth = 0,
		Position = UDim2.fromOffset(
			Viewport.X / 2 - Config.Size.X.Offset / 2,
			Viewport.Y / 2 - Config.Size.Y.Offset / 2
		),
	}

	local Dragging = false
	local DragTouch = nil
	local DragStartInput = nil
	local DragStartPos = nil
	local Resizing = false
	local ResizeTouch = nil
	local ResizeStartInput = nil
	local ResizeStartSize = nil
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

	Window.AcrylicPaint = Acrylic.AcrylicPaint()
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

	local ResizeStartFrame = New("Frame", {
		Size = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -20, 1, -20),
	})

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
		FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
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

	Window.Root = New("Frame", {
		BackgroundTransparency = 1,
		Size = Window.Size,
		Position = Window.Position,
		Parent = Config.Parent,
	}, {
		Window.AcrylicPaint.Frame,
		Window.TabDisplay,
		Window.ContainerCanvas,
		TabFrame,
		ResizeStartFrame,
	})

	Window.TitleBar = require(script.Parent.TitleBar)({
		Title = Config.Title,
		SubTitle = Config.SubTitle,
		Parent = Window.Root,
		Window = Window,
	})

	if require(Root).UseAcrylic then
		Window.AcrylicPaint.AddParent(Window.Root)
	end

	local SizeMotor = Flipper.GroupMotor.new({
		X = Window.Size.X.Offset,
		Y = Window.Size.Y.Offset,
	})

	local PosMotor = Flipper.GroupMotor.new({
		X = Window.Position.X.Offset,
		Y = Window.Position.Y.Offset,
	})

	Window.SelectorPosMotor = Flipper.SingleMotor.new(17)
	Window.SelectorSizeMotor = Flipper.SingleMotor.new(0)
	Window.ContainerBackMotor = Flipper.SingleMotor.new(0)
	Window.ContainerPosMotor = Flipper.SingleMotor.new(94)

	SizeMotor:onStep(function(values)
		Window.Root.Size = UDim2.new(0, values.X, 0, values.Y)
	end)

	PosMotor:onStep(function(values)
		Window.Root.Position = UDim2.new(0, values.X, 0, values.Y)
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
		Window.Root.Position = Window.Position
		PosMotor:setGoal({
			X = Instant(Initial.X),
			Y = Instant(Initial.Y),
		})
	end

	local OldSizeX
	local OldSizeY
	Window.Maximize = function(Value, NoPos, Instant)
		local WasMaximized = Window.Maximized
		Window.Maximized = Value
		Window.TitleBar.MaxButton.Frame.Icon.Image = Value and Assets.Restore or Assets.Max

		if Value then
			if not WasMaximized then
				OldSizeX = Window.Size.X.Offset
				OldSizeY = Window.Size.Y.Offset
			end
		else
			OldSizeX = OldSizeX or Window.Size.X.Offset
			OldSizeY = OldSizeY or Window.Size.Y.Offset
		end

		local Bounds = GetViewportBounds()
		local SizeX = Value and Bounds.X or OldSizeX
		local SizeY = Value and Bounds.Y or OldSizeY
		SizeMotor:setGoal({
			X = Flipper[Instant and "Instant" or "Spring"].new(SizeX, { frequency = 6 }),
			Y = Flipper[Instant and "Instant" or "Spring"].new(SizeY, { frequency = 6 }),
		})
		Window.Size = UDim2.fromOffset(SizeX, SizeY)

		if not NoPos then
			PosMotor:setGoal({
				X = Spring(Value and 0 or Window.Position.X.Offset, { frequency = 6 }),
				Y = Spring(Value and 0 or Window.Position.Y.Offset, { frequency = 6 }),
			})
		end
	end

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

		if Window.Maximized then
			local Size = Window.Root.AbsoluteSize
			local Relative = Vector2.new(
				(DragStartInput.X - Window.Root.AbsolutePosition.X) / math.max(Size.X, 1),
				(DragStartInput.Y - Window.Root.AbsolutePosition.Y) / math.max(Size.Y, 1)
			)

			Window.Maximize(false, true, true)
			DragStartPos = ClampToViewport(Vector2.new(
				DragStartInput.X - OldSizeX * Relative.X,
				DragStartInput.Y - OldSizeY * Relative.Y
			), Vector2.new(OldSizeX, OldSizeY))

			Window.Position = UDim2.fromOffset(DragStartPos.X, DragStartPos.Y)
			PosMotor:setGoal({
				X = Instant(DragStartPos.X),
				Y = Instant(DragStartPos.Y),
			})
		else
			DragStartPos = Vector2.new(Window.Root.AbsolutePosition.X, Window.Root.AbsolutePosition.Y)
		end
	end)

	Creator.AddSignal(ResizeStartFrame.InputBegan, function(Input)
		if
			Input.UserInputType ~= Enum.UserInputType.MouseButton1
			and Input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		if Library:IsInputLocked() then
			return
		end

		Resizing = true
		ResizeTouch = Input.UserInputType == Enum.UserInputType.Touch and Input or nil
		ResizeStartInput = Vector2.new(Input.Position.X, Input.Position.Y)
		ResizeStartSize = Window.Root.AbsoluteSize
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

		if Resizing then
			local IsResizeInput = Input.UserInputType == Enum.UserInputType.MouseMovement
				or (Input.UserInputType == Enum.UserInputType.Touch and Input == ResizeTouch)

			if IsResizeInput then
				local Current = Vector2.new(Input.Position.X, Input.Position.Y)
				local Delta = Current - ResizeStartInput
				local Bounds = GetViewportBounds()
				local Position = Vector2.new(Window.Root.AbsolutePosition.X, Window.Root.AbsolutePosition.Y)
				local MaxX = math.max(470, Bounds.X - Position.X)
				local MaxY = math.max(380, Bounds.Y - Position.Y)

				local TargetSize = Vector2.new(
					math.clamp(ResizeStartSize.X + Delta.X, 470, MaxX),
					math.clamp(ResizeStartSize.Y + Delta.Y, 380, MaxY)
				)

				Window.Size = UDim2.fromOffset(TargetSize.X, TargetSize.Y)
				SizeMotor:setGoal({
					X = Instant(TargetSize.X),
					Y = Instant(TargetSize.Y),
				})
			end
		end
	end)

	Creator.AddSignal(UserInputService.InputEnded, function(Input)
		if Dragging and (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input == DragTouch) then
			Dragging = false
			DragTouch = nil
		end

		if Resizing and (Input.UserInputType == Enum.UserInputType.MouseButton1 or Input == ResizeTouch) then
			Resizing = false
			ResizeTouch = nil
			Window.Size = UDim2.fromOffset(SizeMotor:getValue().X, SizeMotor:getValue().Y)
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

	function Window:Minimize()
		Window.Minimized = not Window.Minimized
		Window.Root.Visible = not Window.Minimized
		if not MinimizeNotif then
			MinimizeNotif = true
			local Key = Library.MinimizeKeybind and Library.MinimizeKeybind.Value or Library.MinimizeKey.Name
			Library:Notify({
				Title = "Interface",
				Content = "Press " .. Key .. " to toggle the interface.",
				Duration = 6
			})
		end
	end

	function Window:Destroy()
		SizeMotor:stop()
		PosMotor:stop()
		Window.SelectorPosMotor:stop()
		Window.SelectorSizeMotor:stop()
		Window.ContainerBackMotor:stop()
		Window.ContainerPosMotor:stop()

		if Library.Window == Window and not Library.Unloaded then
			Library:Destroy()
			return
		end

		if Window.AcrylicPaint.Model then
			Window.AcrylicPaint.Model:Destroy()
		end

		Window.Root:Destroy()
	end

	local DialogModule = require(Components.Dialog):Init(Window)
	function Window:Dialog(Config)
		local Dialog = DialogModule:Create()
		Dialog.Title.Text = Config.Title

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

	local TabModule = require(Components.Tab):Init(Window)
	function Window:AddTab(TabConfig)
		return TabModule:New(TabConfig.Title, TabConfig.Icon, Window.TabHolder)
	end

	function Window:SelectTab(Tab)
		TabModule:SelectTab(1)
	end

	Creator.AddSignal(Window.TabHolder:GetPropertyChangedSignal("CanvasPosition"), function()
		LastValue = TabModule:GetCurrentTabPos() + 16
		LastTime = 0
		Window.SelectorPosMotor:setGoal(Instant(TabModule:GetCurrentTabPos()))
	end)

	return Window
end
