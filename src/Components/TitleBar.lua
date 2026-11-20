local Root = script.Parent.Parent
local Creator = require(Root.Creator)

local New = Creator.New
local AddSignal = Creator.AddSignal

return function(Config)
	local TitleBar = {}

	local Library = require(Root)

	TitleBar.Brand = New("Frame", {
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.new(0, 16, 0, 0),
		BackgroundTransparency = 1,
	}, {
			New("UIListLayout", {
				Padding = UDim.new(0, 5),
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			New("TextLabel", {
				RichText = true,
				Text = Config.Title,
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Regular,
					Enum.FontStyle.Normal
				),
				TextSize = 12,
				TextXAlignment = "Left",
				TextYAlignment = "Center",
				Size = UDim2.fromScale(0, 1),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				ThemeTag = {
					TextColor3 = "Text",
				},
			}),
			New("TextLabel", {
				RichText = true,
				Text = Config.SubTitle,
				TextTransparency = 0.4,
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Regular,
					Enum.FontStyle.Normal
				),
				TextSize = 12,
				TextXAlignment = "Left",
				TextYAlignment = "Center",
				Size = UDim2.fromScale(0, 1),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				ThemeTag = {
					TextColor3 = "Text",
				},
			}),
	})

	TitleBar.Frame = New("Frame", {
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundTransparency = 1,
		Parent = Config.Parent,
	}, {
		TitleBar.Brand,
		New("Frame", {
			BackgroundTransparency = 0.5,
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			ThemeTag = {
				BackgroundColor3 = "TitleBarLine",
			},
		}),
	})

	-- The search field replaces the old minimise/close buttons entirely: it
	-- sits at the right edge of the title bar and is always available.
	local SearchIcon = Library:GetIcon("search")

	TitleBar.SearchField = New("Frame", {
		Size = UDim2.new(0, 120, 0, 24),
		Position = UDim2.new(1, -14, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 0.6,
		Parent = TitleBar.Frame,
		ThemeTag = { BackgroundColor3 = "Element" },
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 6) }),
		New("UIStroke", {
			Transparency = 0.5,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag = { Color = "InElementBorder" },
		}),
		New("ImageLabel", {
			Size = UDim2.fromOffset(13, 13),
			Position = UDim2.new(0, 9, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Image = SearchIcon,
			ThemeTag = { ImageColor3 = "SubText" },
		}),
	})

	TitleBar.SearchBox = New("TextBox", {
		Size = UDim2.new(1, -34, 1, 0),
		Position = UDim2.fromOffset(28, 0),
		BackgroundTransparency = 1,
		Text = "",
		PlaceholderText = "search...",
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		Parent = TitleBar.SearchField,
		ThemeTag = {
			TextColor3 = "Text",
			PlaceholderColor3 = "SubText",
		},
	})

	AddSignal(TitleBar.SearchBox:GetPropertyChangedSignal("Text"), function()
		if Config.Window and Config.Window.SetNavQuery then
			Config.Window:SetNavQuery(TitleBar.SearchBox.Text)
		end
	end)

	AddSignal(TitleBar.SearchBox.InputEnded, function(Input)
		if Input.KeyCode == Enum.KeyCode.Escape then
			TitleBar.SearchBox.Text = ""
		end
	end)

	return TitleBar
end
