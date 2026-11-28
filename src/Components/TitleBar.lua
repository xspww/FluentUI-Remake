local Root = script.Parent.Parent
local Creator = require(Root.Creator)

local New = Creator.New
local AddSignal = Creator.AddSignal

local ResultIcons = {
	Paragraph = "text-cursor-input",
	Button = "box",
	Toggle = "toggle-left",
	Slider = "sliders-horizontal",
	Dropdown = "list",
	Colorpicker = "palette",
	Keybind = "settings-2",
	Input = "text-cursor-input",
}

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

	-- The shadow is a sibling because a child of the card would scroll with
	-- the rows and leave the border bare at the bottom.
	TitleBar.SearchResultsShadow = New("Frame", {
		Size = UDim2.fromOffset(300, 0),
		Position = UDim2.new(1, -14, 0, 46),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 9,
		Parent = TitleBar.Frame,
	}, {
		New("ImageLabel", {
			Image = "rbxassetid://5554236805",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(23, 23, 277, 277),
			Size = UDim2.fromScale(1, 1) + UDim2.fromOffset(30, 30),
			Position = UDim2.fromOffset(-15, -15),
			ImageColor3 = Color3.new(0, 0, 0),
			ImageTransparency = 0.1,
			BackgroundTransparency = 1,
		}),
	})

	local ResultsLayout = New("UIListLayout", {
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	TitleBar.SearchResults = New("ScrollingFrame", {
		Size = UDim2.fromOffset(300, 0),
		Position = UDim2.new(1, -14, 0, 46),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		BottomImage = "rbxassetid://6889812791",
		MidImage = "rbxassetid://6889812721",
		TopImage = "rbxassetid://6276641225",
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		ScrollBarImageTransparency = 0.95,
		ScrollBarThickness = 4,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.fromScale(0, 0),
		Visible = false,
		ZIndex = 10,
		Parent = TitleBar.Frame,
		ThemeTag = { BackgroundColor3 = "DropdownHolder" },
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 7) }),
		New("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag = { Color = "DropdownBorder" },
		}),
		ResultsLayout,
		New("UIPadding", {
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
		}),
	})

	AddSignal(ResultsLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		local Height = ResultsLayout.AbsoluteContentSize.Y
		local CardHeight = math.min(Height + 12, 320)
		TitleBar.SearchResults.CanvasSize = UDim2.new(0, 0, 0, Height)
		TitleBar.SearchResults.Size = UDim2.fromOffset(300, CardHeight)
		TitleBar.SearchResultsShadow.Size = UDim2.fromOffset(300, CardHeight)
	end)

	function TitleBar:RefreshResults(Query)
		local ResultsFrame = TitleBar.SearchResults
		local function SetVisible(Visible)
			ResultsFrame.Visible = Visible
			TitleBar.SearchResultsShadow.Visible = Visible
		end

		for _, Child in ipairs(ResultsFrame:GetChildren()) do
			if Child:IsA("Frame") or Child:IsA("TextButton") or Child:IsA("TextLabel") then
				Child:Destroy()
			end
		end

		Query = Query or ""
		if Query == "" or not Config.Window then
			SetVisible(false)
			return
		end

		local Results = Config.Window.FindElements and Config.Window:FindElements(Query) or {}
		if #Results == 0 then
			New("TextLabel", {
				Size = UDim2.new(1, -24, 0, 44),
				Position = UDim2.fromOffset(12, 0),
				FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
				BackgroundTransparency = 1,
				Text = "No elements found",
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 11,
				Parent = ResultsFrame,
				ThemeTag = { TextColor3 = "SubText" },
			})
			SetVisible(true)
			return
		end

		local PreviousPath = nil

		for Index, Result in ipairs(Results) do
			local Path = Result.Path or ""
			if Path ~= PreviousPath then
				New("TextLabel", {
					Size = UDim2.new(1, -8, 0, 18),
					Position = UDim2.fromOffset(4, 0),
					FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
					BackgroundTransparency = 1,
					Text = Path,
					TextSize = 10,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					LayoutOrder = Index * 2 - 1,
					ZIndex = 11,
					Parent = ResultsFrame,
					ThemeTag = { TextColor3 = "SubText" },
				})
			end
			PreviousPath = Path

			local Primary = Result.Title ~= "" and Result.Title or Result.Description
			local Kind = Result.Kind or ""
			local IsSelected = Index == 1
			local Row = New("TextButton", {
				Size = UDim2.new(1, 0, 0, 34),
				BackgroundTransparency = IsSelected and 0.35 or 1,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = "",
				LayoutOrder = Index * 2,
				ZIndex = 11,
				Parent = ResultsFrame,
				ThemeTag = { BackgroundColor3 = "DropdownOption" },
			}, {
				New("UICorner", { CornerRadius = UDim.new(0, 6) }),
				New("ImageLabel", {
					Size = UDim2.fromOffset(16, 16),
					Position = UDim2.fromOffset(10, 9),
					Image = Library:GetIcon(ResultIcons[Kind] or "search") or SearchIcon,
					BackgroundTransparency = 1,
					ZIndex = 12,
					ThemeTag = { ImageColor3 = "SubText" },
				}),
				New("TextLabel", {
					Size = UDim2.new(1, -52, 0, 18),
					Position = UDim2.fromOffset(34, 8),
					FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
					BackgroundTransparency = 1,
					Text = Primary,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					ZIndex = 12,
					ThemeTag = { TextColor3 = "Text" },
				}),
			})

			-- Rows are rebuilt on every keystroke, so their connections are
			-- owned by the row instead of the library-wide signal registry.
			local Click = Row.MouseButton1Click:Connect(function()
				TitleBar.SearchBox.Text = ""
				Config.Window:RevealElement(Result)
			end)
			local Enter = Row.MouseEnter:Connect(function()
				Row.BackgroundTransparency = 0.35
			end)
			local Leave = Row.MouseLeave:Connect(function()
				Row.BackgroundTransparency = IsSelected and 0.35 or 1
			end)
			Row.Destroying:Connect(function()
				Click:Disconnect()
				Enter:Disconnect()
				Leave:Disconnect()
			end)
		end

		SetVisible(true)
	end

	AddSignal(TitleBar.SearchBox:GetPropertyChangedSignal("Text"), function()
		if Config.Window and Config.Window.SetSearchQuery then
			Config.Window:SetSearchQuery(TitleBar.SearchBox.Text)
		end
	end)

	AddSignal(TitleBar.SearchBox.InputEnded, function(Input)
		if Input.KeyCode == Enum.KeyCode.Escape then
			TitleBar.SearchBox.Text = ""
			TitleBar.SearchBox:ReleaseFocus()
		end
	end)

	if Config.Window then
		Config.Window.OnMinimizeChanged = function(Minimized)
			if Minimized then
				TitleBar.SearchBox.Text = ""
			end
		end
	end

	return TitleBar
end
