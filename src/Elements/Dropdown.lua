local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local Root = script.Parent.Parent
local Creator = require(Root.Creator)
local Flipper = require(Root.Packages.Flipper)

local New = Creator.New
local Components = Root.Components

local Element = {}
Element.__index = Element
Element.__type = "Dropdown"

function Element:New(Idx, Config)
	local Library = self.Library
	local Values = Config.Values or {}

	local function NormalizeValue(Value)
		if Config.Multi then
			local Result = {}

			if type(Value) == "table" then
				for Key, State in next, Value do
					if type(Key) == "number" then
						if State and table.find(Values, State) then
							Result[State] = true
						end
					elseif State and table.find(Values, Key) then
						Result[Key] = true
					end
				end
			elseif type(Value) == "string" and table.find(Values, Value) then
				Result[Value] = true
			elseif type(Value) == "number" and Values[Value] ~= nil then
				Result[Values[Value]] = true
			end

			return Result
		end

		if type(Value) == "number" and Values[Value] ~= nil then
			return Values[Value]
		elseif type(Value) == "string" and table.find(Values, Value) then
			return Value
		end

		return nil
	end

	local Dropdown = {
		Values = Values,
		Value = NormalizeValue(Config.Default),
		Multi = Config.Multi,
		Buttons = {},
		Opened = false,
		Type = "Dropdown",
		Callback = Config.Callback or function() end,
	}

	local DropdownFrame = require(Components.Element)(Config.Title, Config.Description, self.Container, false)
	DropdownFrame.DescLabel.Size = UDim2.new(1, -170, 0, 14)

	Dropdown.SetTitle = DropdownFrame.SetTitle
	Dropdown.SetDesc = DropdownFrame.SetDesc

	local DropdownDisplay = New("TextLabel", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		Text = "Value",
		TextColor3 = Color3.fromRGB(240, 240, 240),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -30, 0, 14),
		Position = UDim2.new(0, 8, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ThemeTag = {
			TextColor3 = "Text",
		},
	})

	local DropdownIco = New("ImageLabel", {
		Image = "rbxassetid://10709790948",
		Size = UDim2.fromOffset(16, 16),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		BackgroundTransparency = 1,
		ThemeTag = {
			ImageColor3 = "SubText",
		},
	})

	local DropdownInner = New("TextButton", {
		Size = UDim2.fromOffset(160, 30),
		Position = UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 0.9,
		Parent = DropdownFrame.Frame,
		ThemeTag = {
			BackgroundColor3 = "DropdownFrame",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),
		New("UIStroke", {
			Transparency = 0.5,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag = {
				Color = "InElementBorder",
			},
		}),
		DropdownIco,
		DropdownDisplay,
	})

	local DropdownListLayout = New("UIListLayout", {
		Padding = UDim.new(0, 3),
	})

	local DropdownScrollFrame = New("ScrollingFrame", {
		Size = UDim2.new(1, -5, 1, -10),
		Position = UDim2.fromOffset(5, 5),
		BackgroundTransparency = 1,
		BottomImage = "rbxassetid://6889812791",
		MidImage = "rbxassetid://6889812721",
		TopImage = "rbxassetid://6276641225",
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		ScrollBarImageTransparency = 0.95,
		ScrollBarThickness = 4,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromScale(0, 0),
	}, {
		DropdownListLayout,
	})

	local DropdownHolderFrame = New("Frame", {
		Size = UDim2.fromScale(1, 0.6),
		ThemeTag = {
			BackgroundColor3 = "DropdownHolder",
		},
	}, {
		DropdownScrollFrame,
		New("UICorner", {
			CornerRadius = UDim.new(0, 7),
		}),
		New("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag = {
				Color = "DropdownBorder",
			},
		}),
		New("ImageLabel", {
			BackgroundTransparency = 1,
			Image = "rbxassetid://5554236805",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(23, 23, 277, 277),
			Size = UDim2.fromScale(1, 1) + UDim2.fromOffset(30, 30),
			Position = UDim2.fromOffset(-15, -15),
			ImageColor3 = Color3.fromRGB(0, 0, 0),
			ImageTransparency = 0.1,
		}),
	})

	local DropdownHolderCanvas = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(170, 300),
		Parent = self.Library.GUI,
		Visible = false,
	}, {
		DropdownHolderFrame,
		New("UISizeConstraint", {
			MinSize = Vector2.new(170, 0),
		}),
	})
	table.insert(Library.OpenFrames, DropdownHolderCanvas)

	local function GetViewportSize()
		local Camera = Workspace.CurrentCamera
		local Size = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)

		local Success, TopLeft, BottomRight = pcall(function()
			return GuiService:GetGuiInset()
		end)

		if Success then
			Size = Size - (TopLeft or Vector2.zero) - (BottomRight or Vector2.zero)
		end

		return Size
	end

	local function RecalculateListPosition()
		local Viewport = GetViewportSize()
		local Add = 0

		if Viewport.Y - DropdownInner.AbsolutePosition.Y < DropdownHolderCanvas.AbsoluteSize.Y - 5 then
			Add = DropdownHolderCanvas.AbsoluteSize.Y
				- 5
				- (Viewport.Y - DropdownInner.AbsolutePosition.Y)
				+ 40
		end

		local X = math.clamp(
			DropdownInner.AbsolutePosition.X - 1,
			0,
			math.max(0, Viewport.X - DropdownHolderCanvas.AbsoluteSize.X)
		)

		DropdownHolderCanvas.Position =
			UDim2.fromOffset(X, DropdownInner.AbsolutePosition.Y - 5 - Add)
	end

	local ListSizeX = 0
	local function RecalculateListSize()
		if #Dropdown.Values > 10 then
			DropdownHolderCanvas.Size = UDim2.fromOffset(ListSizeX, 392)
		else
			DropdownHolderCanvas.Size = UDim2.fromOffset(ListSizeX, DropdownListLayout.AbsoluteContentSize.Y + 10)
		end
	end

	local function RecalculateCanvasSize()
		DropdownScrollFrame.CanvasSize = UDim2.fromOffset(0, DropdownListLayout.AbsoluteContentSize.Y)
	end

	RecalculateListPosition()
	RecalculateListSize()

	local ListPositionConnection = Creator.AddSignal(
		DropdownInner:GetPropertyChangedSignal("AbsolutePosition"),
		RecalculateListPosition
	)

	Creator.AddSignal(DropdownInner.MouseButton1Click, function()
		Dropdown:Open()
	end)

	local OutsideClickConnection = Creator.AddSignal(UserInputService.InputBegan, function(Input)
		if not Dropdown.Opened then
			return
		end

		if
			Input.UserInputType ~= Enum.UserInputType.MouseButton1
			and Input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		local AbsPos, AbsSize = DropdownHolderFrame.AbsolutePosition, DropdownHolderFrame.AbsoluteSize
		local X, Y = Input.Position.X, Input.Position.Y

		if
			X < AbsPos.X
			or X > AbsPos.X + AbsSize.X
			or Y < (AbsPos.Y - 20 - 1)
			or Y > AbsPos.Y + AbsSize.Y
		then
			Dropdown:Close()
		end
	end)

	local ScrollFrame = self.ScrollFrame
	function Dropdown:Open()
		Dropdown.Opened = true
		ScrollFrame.ScrollingEnabled = false
		DropdownHolderCanvas.Visible = true
		RecalculateListSize()
		RecalculateListPosition()
		TweenService:Create(
			DropdownHolderFrame,
			TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Size = UDim2.fromScale(1, 1) }
		):Play()
	end

	function Dropdown:Close()
		Dropdown.Opened = false
		ScrollFrame.ScrollingEnabled = true
		DropdownHolderFrame.Size = UDim2.fromScale(1, 0.6)
		DropdownHolderCanvas.Visible = false
	end

	function Dropdown:Display()
		if Dropdown.Multi then
			local Selected = {}

			for _, Value in next, Dropdown.Values do
				if Dropdown.Value[Value] then
					table.insert(Selected, Value)
				end
			end

			DropdownDisplay.Text = #Selected > 0 and table.concat(Selected, ", ") or "--"
		else
			DropdownDisplay.Text = Dropdown.Value or "--"
		end
	end

	function Dropdown:GetActiveValues()
		if Dropdown.Multi then
			local Active = {}

			for Value in next, Dropdown.Value do
				table.insert(Active, Value)
			end

			return Active
		end

		return Dropdown.Value and 1 or 0
	end

	local function CountSelected()
		local Active = Dropdown:GetActiveValues()
		return type(Active) == "table" and #Active or Active
	end

	local function SanitizeValue()
		if Dropdown.Multi then
			for Value in next, Dropdown.Value do
				if not table.find(Dropdown.Values, Value) then
					Dropdown.Value[Value] = nil
				end
			end
		elseif Dropdown.Value ~= nil and not table.find(Dropdown.Values, Dropdown.Value) then
			Dropdown.Value = nil
		end
	end

	function Dropdown:BuildDropdownList()
		-- Remove every previously generated option before creating new ones,
		-- otherwise SetValues() leaves stale buttons (and their connections).
		for _, Child in next, DropdownScrollFrame:GetChildren() do
			if not Child:IsA("UIListLayout") then
				Child:Destroy()
			end
		end

		table.clear(Dropdown.Buttons)
		local Buttons = Dropdown.Buttons

		for _, Value in next, Dropdown.Values do
			local Table = {}

			local ButtonSelector = New("Frame", {
				Size = UDim2.fromOffset(4, 14),
				BackgroundColor3 = Color3.fromRGB(76, 194, 255),
				Position = UDim2.fromOffset(-1, 16),
				AnchorPoint = Vector2.new(0, 0.5),
				ThemeTag = {
					BackgroundColor3 = "Accent",
				},
			}, {
				New("UICorner", {
					CornerRadius = UDim.new(0, 2),
				}),
			})

			local ButtonLabel = New("TextLabel", {
				FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
				Text = Value,
				TextColor3 = Color3.fromRGB(200, 200, 200),
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromOffset(10, 0),
				Name = "ButtonLabel",
				ThemeTag = {
					TextColor3 = "Text",
				},
			})

			local Button = New("TextButton", {
				Size = UDim2.new(1, -5, 0, 32),
				BackgroundTransparency = 1,
				ZIndex = 23,
				Text = "",
				Parent = DropdownScrollFrame,
				ThemeTag = {
					BackgroundColor3 = "DropdownOption",
				},
			}, {
				ButtonSelector,
				ButtonLabel,
				New("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}),
			})

			local Selected

			if Config.Multi then
				Selected = Dropdown.Value[Value]
			else
				Selected = Dropdown.Value == Value
			end

			local _, SetBackTransparency = Creator.SpringMotor(1, Button, "BackgroundTransparency")
			local _, SetSelTransparency = Creator.SpringMotor(1, ButtonSelector, "BackgroundTransparency")
			local SelectorSizeMotor = Flipper.SingleMotor.new(6)

			SelectorSizeMotor:onStep(function(value)
				ButtonSelector.Size = UDim2.new(0, 4, 0, value)
			end)

			local ButtonConnections = {}

			local function ConnectButton(Signal, Function)
				local Connection = Creator.AddSignal(Signal, Function)

				if Connection then
					table.insert(ButtonConnections, Connection)
				end
			end

			Button.Destroying:Connect(function()
				SelectorSizeMotor:stop()

				for _, Connection in next, ButtonConnections do
					Creator.RemoveSignal(Connection)
				end

				table.clear(ButtonConnections)
			end)

			ConnectButton(Button.MouseEnter, function()
				SetBackTransparency(Selected and 0.85 or 0.89)
			end)
			ConnectButton(Button.MouseLeave, function()
				SetBackTransparency(Selected and 0.89 or 1)
			end)
			ConnectButton(Button.MouseButton1Down, function()
				SetBackTransparency(0.92)
			end)
			ConnectButton(Button.MouseButton1Up, function()
				SetBackTransparency(Selected and 0.85 or 0.89)
			end)

			function Table:UpdateButton()
				if Config.Multi then
					Selected = Dropdown.Value[Value] == true
				else
					Selected = Dropdown.Value == Value
				end

				SetBackTransparency(Selected and 0.89 or 1)
				SelectorSizeMotor:setGoal(Flipper.Spring.new(Selected and 14 or 6, { frequency = 6 }))
				SetSelTransparency(Selected and 0 or 1)
			end

			ConnectButton(ButtonLabel.InputBegan, function(Input)
				if
					Input.UserInputType ~= Enum.UserInputType.MouseButton1
					and Input.UserInputType ~= Enum.UserInputType.Touch
				then
					return
				end

				local Try = not Selected
				local CanChange = Try or Config.AllowNull or CountSelected() > 1

				if not CanChange then
					return
				end

				if Config.Multi then
					Selected = Try
					Dropdown.Value[Value] = Selected and true or nil
				else
					Selected = Try
					Dropdown.Value = Selected and Value or nil

					for _, OtherButton in next, Buttons do
						OtherButton:UpdateButton()
					end
				end

				Table:UpdateButton()
				Dropdown:Display()

				Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
				Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
			end)

			Table:UpdateButton()
			Table.Button = Button
			Table.ButtonLabel = ButtonLabel
			Buttons[Button] = Table
		end

		ListSizeX = 0

		for _, Data in next, Buttons do
			if Data.ButtonLabel.TextBounds.X > ListSizeX then
				ListSizeX = Data.ButtonLabel.TextBounds.X
			end
		end

		ListSizeX = ListSizeX + 30

		RecalculateCanvasSize()
		RecalculateListSize()
		Dropdown:Display()
	end

	function Dropdown:SetValues(NewValues)
		if NewValues then
			Dropdown.Values = NewValues
		end

		SanitizeValue()
		Dropdown:BuildDropdownList()
		Dropdown:Display()
	end

	function Dropdown:OnChanged(Func)
		Dropdown.Changed = Func
		Func(Dropdown.Value)
	end

	function Dropdown:SetValue(Val)
		if Dropdown.Multi then
			local NewValue = {}

			if type(Val) == "table" then
				for Key, State in next, Val do
					if type(Key) == "number" then
						if State and table.find(Dropdown.Values, State) then
							NewValue[State] = true
						end
					elseif State and table.find(Dropdown.Values, Key) then
						NewValue[Key] = true
					end
				end
			elseif type(Val) == "string" and table.find(Dropdown.Values, Val) then
				NewValue[Val] = true
			end

			Dropdown.Value = NewValue
		else
			if type(Val) == "number" and Dropdown.Values[Val] ~= nil then
				Dropdown.Value = Dropdown.Values[Val]
			elseif type(Val) == "string" and table.find(Dropdown.Values, Val) then
				Dropdown.Value = Val
			elseif Val == nil then
				Dropdown.Value = nil
			end
		end

		Dropdown:BuildDropdownList()
		Dropdown:Display()

		Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
		Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
	end

	function Dropdown:Destroy()
		Dropdown.Opened = false

		Creator.RemoveSignal(ListPositionConnection)
		Creator.RemoveSignal(OutsideClickConnection)

		local Index = table.find(Library.OpenFrames, DropdownHolderCanvas)
		if Index then
			table.remove(Library.OpenFrames, Index)
		end

		DropdownHolderCanvas:Destroy()
		DropdownFrame:Destroy()
		Library.Options[Idx] = nil
	end

	Dropdown:BuildDropdownList()
	Dropdown:Display()

	Library.Options[Idx] = Dropdown
	return Dropdown
end

return Element
