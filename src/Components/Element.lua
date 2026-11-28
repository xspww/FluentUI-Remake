local Root = script.Parent.Parent
local Creator = require(Root.Creator)
local New = Creator.New

return function(Title, Desc, Parent, _Hover, Kind)
	local Element = {}

	Element.TitleLabel = New("TextLabel", {
		Name = "TitleLabel",
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
		Text = Title,
		TextColor3 = Color3.fromRGB(240, 240, 240),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		ThemeTag = {
			TextColor3 = "Text",
		},
	})

	Element.DescLabel = New("TextLabel", {
		Name = "DescLabel",
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		Text = Desc,
		TextColor3 = Color3.fromRGB(200, 200, 200),
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		ThemeTag = {
			TextColor3 = "SubText",
		},
	})

	Element.LabelHolder = New("Frame", {
		Name = "LabelHolder",
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -28, 0, 0),
	}, {
		New("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		New("UIPadding", {
			PaddingBottom = UDim.new(0, 13),
			PaddingTop = UDim.new(0, 13),
		}),
		Element.TitleLabel,
		Element.DescLabel,
	})

	Element.Border = New("UIStroke", {
		Transparency = 0.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = Color3.fromRGB(0, 0, 0),
		ThemeTag = {
			Color = "ElementBorder",
		},
	})

	Element.Frame = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(130, 130, 130),
		Parent = Parent,
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = "",
		LayoutOrder = 7,
		ThemeTag = {
			BackgroundColor3 = "Element",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 4),
		}),
		Element.Border,
		Element.LabelHolder,
	})

	-- Marks the row so the title-bar search can read live titles and
	-- descriptions instead of every element module registering itself.
	Element.Frame:SetAttribute("FluentElement", true)
	if Kind then
		Element.Frame:SetAttribute("FluentElementType", Kind)
	end

	function Element:SetTitle(Set)
		Element.TitleLabel.Text = Set
	end

	function Element:SetDesc(Set)
		if Set == nil then
			Set = ""
		end
		if Set == "" then
			Element.DescLabel.Visible = false
		else
			Element.DescLabel.Visible = true
		end
		Element.DescLabel.Text = Set
	end

	function Element:Destroy()
		Element.Frame:Destroy()
	end

	Element:SetTitle(Title)
	Element:SetDesc(Desc)

	return Element
end
