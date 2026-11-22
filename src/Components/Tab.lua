local TextService = game:GetService("TextService")

local Root = script.Parent.Parent
local Flipper = require(Root.Packages.Flipper)
local Creator = require(Root.Creator)

local New = Creator.New
local Spring = Flipper.Spring.new
local Instant = Flipper.Instant.new
local Components = Root.Components

local FONT_REGULAR = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
local FONT_SEMIBOLD = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)

local TAB_HEIGHT = 34
local CHILD_HEIGHT = 30
local PADDING = 4
local CHILD_INDENT = 18
local TAB_TEXT_SIZE = 12
local MIN_TAB_TEXT_SIZE = 10

local TabModule = {
	Window = nil,
	Tabs = {},
	Containers = {},
	Groups = {},
	GroupOrder = {},
	FlatTabs = {},
	OpenGroupName = nil,
	SelectedTab = 0,
	SwitchToken = 0,
	TabCount = 0,
}

local function refreshSelector()
	local Window = TabModule.Window
	if not Window or not Window.SelectorPosMotor then
		return
	end
	if not TabModule.Tabs[TabModule.SelectedTab] then
		return
	end
	Window.SelectorPosMotor:setGoal(Spring(TabModule:GetCurrentTabPos(), { frequency = 6 }))
end

function TabModule:Init(Window)
	TabModule.Window = Window

	TabModule.NoResults = New("TextLabel", {
		Size = UDim2.new(1, -20, 0, 26),
		Position = UDim2.fromOffset(10, 4),
		BackgroundTransparency = 1,
		Text = "No results",
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Visible = false,
		LayoutOrder = -1,
		Parent = Window.TabHolder,
		ThemeTag = { TextColor3 = "SubText" },
	})

	return TabModule
end

function TabModule:Destroy()
	for _, Group in next, TabModule.Groups do
		if Group.ExpandMotor then
			Group.ExpandMotor:stop()
		end
	end

	table.clear(TabModule.Tabs)
	table.clear(TabModule.Containers)
	table.clear(TabModule.Groups)
	table.clear(TabModule.GroupOrder)
	table.clear(TabModule.FlatTabs)
end

function TabModule:GetCurrentTabPos()
	local TabHolderPos = TabModule.Window.TabHolder.AbsolutePosition.Y
	local TabPos = TabModule.Tabs[TabModule.SelectedTab].Frame.AbsolutePosition.Y
	return TabPos - TabHolderPos
end

local function styleTab(Tab, Selected)
	Tab.Label.FontFace = Selected and FONT_SEMIBOLD or FONT_REGULAR
	Creator.OverrideTag(Tab.Label, { TextColor3 = Selected and "Text" or "SubText" })
	Creator.OverrideTag(Tab.IconLabel, { ImageColor3 = Selected and "Text" or "SubText" })
end

local function layoutNav()
	local Order = 0
	for _, Tab in ipairs(TabModule.FlatTabs) do
		Tab.Frame.LayoutOrder = Order
		Order = Order + 1
	end
	for _, Name in ipairs(TabModule.GroupOrder) do
		local Group = TabModule.Groups[Name]
		Group.Header.LayoutOrder = Order
		Order = Order + 1
		Group.Clips.LayoutOrder = Order
		Order = Order + 1
	end
end

local function setGroupGoal(Group, Value, Animated)
	Group.ExpandMotor:setGoal(Animated
		and Spring(Value, { frequency = 5, dampingRatio = 1 })
		or Instant(Value))
end

local function fitTabLabel(Label, Text, AvailableWidth)
	local Font = Label.Font
	if Font == Enum.Font.Unknown then
		Font = Enum.Font.Gotham
	end

	local FullWidth = TextService:GetTextSize(Text, TAB_TEXT_SIZE, Font, Vector2.new(9999, 20)).X
	local Size = math.clamp(math.floor(TAB_TEXT_SIZE * AvailableWidth / math.max(FullWidth, 1)), MIN_TAB_TEXT_SIZE, TAB_TEXT_SIZE)

	Label.TextSize = Size
	Label.TextTruncate = FullWidth * Size / TAB_TEXT_SIZE > AvailableWidth
		and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None
end

local function getGroup(Name, Icon)
	if not Name then
		return nil
	end

	local Group = TabModule.Groups[Name]
	if Group then
		return Group
	end

	local Library = require(Root)
	if Icon and Icon ~= "" then
		Icon = Library:GetIcon(Icon) or Icon
	end

	Group = {
		Name = Name,
		Tabs = {},
		Open = false,
		ContentHeight = 0,
	}

	local HeaderLabel = New("TextLabel", {
		Name = "Label",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 30, 0.5, 0),
		Text = Name,
		FontFace = FONT_SEMIBOLD,
		TextSize = TAB_TEXT_SIZE,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -36, 1, 0),
		BackgroundTransparency = 1,
		ThemeTag = { TextColor3 = "SubText" },
	})
	fitTabLabel(HeaderLabel, Name, (TabModule.Window.TabWidth or 160) - 36)

	Group.Header = New("TextButton", {
		Size = UDim2.new(1, 0, 0, TAB_HEIGHT),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Parent = TabModule.Window.TabHolder,
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 6) }),
		New("ImageLabel", {
			Name = "Icon",
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.new(0, 8, 0.5, 0),
			BackgroundTransparency = 1,
			Image = Icon,
			ThemeTag = { ImageColor3 = "SubText" },
		}),
		HeaderLabel,
	})

	-- The clipping frame owns the height; the CanvasGroup inside it owns alpha.
	Group.Clips = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = TabModule.Window.TabHolder,
	})

	Group.Sublist = New("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Parent = Group.Clips,
	}, {
		New("UIListLayout", { Padding = UDim.new(0, PADDING) }),
		New("UIPadding", { PaddingLeft = UDim.new(0, CHILD_INDENT) }),
	})

	Creator.AddSignal(Group.Header.MouseButton1Click, function()
		TabModule:OpenGroup(Name, true)
	end)

	Group.ExpandMotor = Flipper.SingleMotor.new(0)
	Group.ExpandMotor:onStep(function(Value)
		Group.Clips.Size = UDim2.new(1, 0, 0, Group.ContentHeight * Value)
		Group.Sublist.GroupTransparency = 1 - math.clamp(Value * 1.6, 0, 1)
		-- Icon and label share one colour ramp, so a group never shows a
		-- bright icon beside a dim title (and vice versa when it opens).
		local Dim = Creator.GetThemeProperty("SubText")
		local Bright = Creator.GetThemeProperty("Text")
		Group.Header.Icon.ImageColor3 = Dim:Lerp(Bright, Value)
		Group.Header.Label.TextColor3 = Dim:Lerp(Bright, Value)
		-- Rows shift while a group folds, so the selector must retarget too.
		refreshSelector()
	end)

	TabModule.Groups[Name] = Group
	TabModule.GroupOrder[#TabModule.GroupOrder + 1] = Name
	return Group
end

function TabModule:OpenGroup(Name, Animated)
	local Group = TabModule.Groups[Name]
	if not Group then
		return
	end

	if TabModule.OpenGroupName and TabModule.OpenGroupName ~= Name then
		local Previous = TabModule.Groups[TabModule.OpenGroupName]
		if Previous then
			Previous.Open = false
			setGroupGoal(Previous, 0, Animated)
		end
	end

	local WasOpen = Group.Open
	Group.Open = true
	TabModule.OpenGroupName = Name
	setGroupGoal(Group, 1, Animated)

	if not WasOpen and Group.Tabs[1] then
		-- Opening a group moves the selection to its first child.
		self:SelectTab(Group.Tabs[1].Index)
	end
end

function TabModule:CloseGroups(Animated)
	if not TabModule.OpenGroupName then
		return
	end
	local Group = TabModule.Groups[TabModule.OpenGroupName]
	if Group then
		Group.Open = false
		setGroupGoal(Group, 0, Animated)
	end
	TabModule.OpenGroupName = nil
end

function TabModule:SetNavQuery(Query)
	local Lower = string.lower(Query or "")
	local Visible = 0

	for _, Tab in ipairs(TabModule.FlatTabs) do
		Tab.Frame.Visible = Lower == ""
			or string.find(string.lower(Tab.Name), Lower, 1, true) ~= nil
		if Tab.Frame.Visible then
			Visible = Visible + 1
		end
	end

	for Name, Group in pairs(TabModule.Groups) do
		local HeaderMatch = Lower ~= ""
			and string.find(string.lower(Name), Lower, 1, true) ~= nil
		for _, Tab in ipairs(Group.Tabs) do
			local Match = Lower == ""
				or HeaderMatch
				or string.find(string.lower(Tab.Name), Lower, 1, true) ~= nil
			Tab.Frame.Visible = Match
			if Match then
				Visible = Visible + 1
			end
		end
		local Show = Lower == "" or HeaderMatch
		if not Show then
			for _, Tab in ipairs(Group.Tabs) do
				if Tab.Frame.Visible then
					Show = true
					break
				end
			end
		end
		Group.Header.Visible = Show
		Group.Clips.Visible = Show
	end

	TabModule.NoResults.Visible = Visible == 0
	if TabModule.Window.Selector then
		TabModule.Window.Selector.Visible = Visible > 0
	end
end

function TabModule:SetGroupOpen(Name, Open, Animated)
	if Open then
		self:OpenGroup(Name, Animated)
	elseif TabModule.OpenGroupName == Name then
		self:CloseGroups(Animated)
	end
end

function TabModule:New(Title, Icon, Parent, GroupName, GroupIcon)
	local Library = require(Root)
	local Window = TabModule.Window
	local Elements = Library.Elements

	TabModule.TabCount = TabModule.TabCount + 1
	local TabIndex = TabModule.TabCount

	if Library:GetIcon(Icon) then
		Icon = Library:GetIcon(Icon)
	end
	if Icon == "" or nil then
		Icon = nil
	end

	local Group = getGroup(GroupName, GroupIcon)
	local TabParent = Group and Group.Sublist or Parent
	local Height = Group and CHILD_HEIGHT or TAB_HEIGHT
	local WidthIndent = Group and CHILD_INDENT or 0

	local Tab = {
		Selected = false,
		Name = Title,
		Type = "Tab",
		Index = TabIndex,
		Group = GroupName,
	}

	Tab.Label = New("TextLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = Icon and UDim2.new(0, 30, 0.5, 0) or UDim2.new(0, 12, 0.5, 0),
		Text = Title,
		RichText = true,
		TextColor3 = Color3.fromRGB(140, 152, 172),
		TextSize = TAB_TEXT_SIZE,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Size = UDim2.new(1, -36, 1, 0),
		BackgroundTransparency = 1,
		ThemeTag = { TextColor3 = "SubText" },
	})

	local LabelWidth = (Window.TabWidth or 160) - (Group and CHILD_INDENT * 2 or 0) - 36
	fitTabLabel(Tab.Label, Title, LabelWidth)

	Tab.IconLabel = New("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.fromOffset(Group and 14 or 16, Group and 14 or 16),
		Position = UDim2.new(0, 8, 0.5, 0),
		BackgroundTransparency = 1,
		Image = Icon,
		ThemeTag = { ImageColor3 = "SubText" },
	})

	Tab.Frame = New("TextButton", {
		Size = UDim2.new(1, -WidthIndent, 0, Height),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Parent = TabParent,
		ThemeTag = { BackgroundColor3 = "Tab" },
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Tab.IconLabel,
		Tab.Label,
	})

	local ContainerLayout = New("UIListLayout", {
		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	Tab.ContainerFrame = New("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = Window.ContainerHolder,
		Visible = false,
		BottomImage = "rbxassetid://6889812791",
		MidImage = "rbxassetid://6889812721",
		TopImage = "rbxassetid://6276641225",
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		ScrollBarImageTransparency = 0.95,
		ScrollBarThickness = 3,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromScale(0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, {
		ContainerLayout,
		New("UIPadding", {
			PaddingRight = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 1),
			PaddingTop = UDim.new(0, 1),
			PaddingBottom = UDim.new(0, 1),
		}),
	})

	Creator.AddSignal(ContainerLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		Tab.ContainerFrame.CanvasSize = UDim2.new(0, 0, 0, ContainerLayout.AbsoluteContentSize.Y + 2)
	end)

	Creator.AddSignal(Tab.Frame.MouseButton1Click, function()
		TabModule:SelectTab(TabIndex)
	end)

	TabModule.Containers[TabIndex] = Tab.ContainerFrame
	TabModule.Tabs[TabIndex] = Tab

	if Group then
		Group.Tabs[#Group.Tabs + 1] = Tab
		Group.ContentHeight = #Group.Tabs * CHILD_HEIGHT
			+ math.max(0, #Group.Tabs - 1) * PADDING + 8
	else
		TabModule.FlatTabs[#TabModule.FlatTabs + 1] = Tab
	end

	layoutNav()

	Tab.Container = Tab.ContainerFrame
	Tab.ScrollFrame = Tab.Container

	function Tab:AddSection(SectionTitle)
		local Section = { Type = "Section" }
		local SectionFrame = require(Components.Section)(SectionTitle, Tab.Container)
		Section.Container = SectionFrame.Container
		Section.ScrollFrame = Tab.Container
		setmetatable(Section, Elements)
		return Section
	end

	styleTab(Tab, false)
	setmetatable(Tab, Elements)
	return Tab
end

function TabModule:SelectTab(Tab)
	local Target = TabModule.Tabs[Tab]
	if not Target then
		return
	end

	if Target.Group then
		self:OpenGroup(Target.Group, true)
	else
		self:CloseGroups(true)
	end

	TabModule.SelectedTab = Tab

	for _, TabObject in next, TabModule.Tabs do
		if TabObject.Selected then
			TabObject.Selected = false
			styleTab(TabObject, false)
		end
	end
	Target.Selected = true
	styleTab(Target, true)

	local Window = TabModule.Window
	Window.TabDisplay.Text = Target.Name
	refreshSelector()

	-- A new selection invalidates the in-flight switch so two threads never
	-- write the container motors or visibility at the same time.
	TabModule.SwitchToken = TabModule.SwitchToken + 1
	local Token = TabModule.SwitchToken

	-- UIListLayout settles a frame after the fold finishes; align once more.
	task.delay(0.3, function()
		if Token == TabModule.SwitchToken then
			refreshSelector()
		end
	end)

	Window.ContainerHolder.Parent = Window.ContainerAnim
	Window.ContainerPosMotor:setGoal(Spring(15, { frequency = 10 }))
	Window.ContainerBackMotor:setGoal(Spring(1, { frequency = 10 }))

	task.spawn(function()
		task.wait(0.12)
		if Token ~= TabModule.SwitchToken then return end
		for _, Container in next, TabModule.Containers do
			Container.Visible = false
		end
		TabModule.Containers[Tab].Visible = true
		Window.ContainerPosMotor:setGoal(Spring(0, { frequency = 5 }))
		Window.ContainerBackMotor:setGoal(Spring(0, { frequency = 8 }))
		task.wait(0.12)
		if Token ~= TabModule.SwitchToken then return end
		Window.ContainerHolder.Parent = Window.ContainerCanvas
	end)
end

return TabModule
