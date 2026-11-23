local Root = script.Parent
local Themes = require(Root.Themes)
local Flipper = require(Root.Packages.Flipper)

local DEFAULT_FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)

local Creator = {
	Registry = {},
	Signals = {},
	ThemeCallbacks = {},
	DefaultProperties = {
		ScreenGui = {
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		},
		Frame = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
		},
		ScrollingFrame = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			ScrollBarImageColor3 = Color3.new(0, 0, 0),
		},
		TextLabel = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			FontFace = DEFAULT_FONT,
			Text = "",
			TextColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 1,
			TextSize = 14,
		},
		TextButton = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			AutoButtonColor = false,
			FontFace = DEFAULT_FONT,
			Text = "",
			TextColor3 = Color3.new(0, 0, 0),
			TextSize = 14,
		},
		TextBox = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			ClearTextOnFocus = false,
			FontFace = DEFAULT_FONT,
			Text = "",
			TextColor3 = Color3.new(0, 0, 0),
			TextSize = 14,
		},
		ImageLabel = {
			BackgroundTransparency = 1,
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
		},
		ImageButton = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			AutoButtonColor = false,
		},
		CanvasGroup = {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
		},
	},
}

local function ApplyCustomProps(Object, Props)
	if Props.ThemeTag then
		Creator.AddThemeObject(Object, Props.ThemeTag)
	end
end

local function applyTheme(Object, Properties)
	for Property, ColorIdx in next, Properties do
		Object[Property] = Creator.GetThemeProperty(ColorIdx)
	end
end

function Creator.AddSignal(Signal, Function)
	if not Signal or not Function then
		return
	end

	local Connection = Signal:Connect(Function)
	table.insert(Creator.Signals, Connection)
	return Connection
end

function Creator.Disconnect()
	for Idx = #Creator.Signals, 1, -1 do
		local Connection = table.remove(Creator.Signals, Idx)
		pcall(function()
			Connection:Disconnect()
		end)
	end
end

-- Releases a single connection and drops it from the registry. Connections
-- that are created again and again, for example while a keybind is being
-- picked, would otherwise pile up in the registry forever.
function Creator.RemoveSignal(Connection)
	if not Connection then
		return
	end

	pcall(function()
		Connection:Disconnect()
	end)

	local Index = table.find(Creator.Signals, Connection)

	if Index then
		table.remove(Creator.Signals, Index)
	end
end

-- Stops every animation and releases the theme registry. Called when the
-- library is unloaded so nothing keeps running in the background.
function Creator.Destroy()
	Creator.Disconnect()

	table.clear(Creator.Registry)
	table.clear(Creator.ThemeCallbacks)
end

function Creator.GetThemeProperty(Property)
	local Current = Themes[require(Root).Theme] or Themes.Dark

	if Current[Property] then
		return Current[Property]
	end

	return Themes.Dark[Property]
end

function Creator.UpdateTheme()
	for Instance, Object in next, Creator.Registry do
		for Property, ColorIdx in next, Object.Properties do
			Instance[Property] = Creator.GetThemeProperty(ColorIdx)
		end
	end
	for _, Callback in ipairs(Creator.ThemeCallbacks) do
		Callback()
	end
end

function Creator.AddThemeCallback(Callback)
	Creator.ThemeCallbacks[#Creator.ThemeCallbacks + 1] = Callback
end

function Creator.AddThemeObject(Object, Properties)
	local Data = {
		Properties = Properties,
	}

	Creator.Registry[Object] = Data

	-- Without this the registry keeps a strong reference to every destroyed
	-- instance for the lifetime of the script.
	Object.Destroying:Connect(function()
		Creator.Registry[Object] = nil
	end)

	applyTheme(Object, Properties)
	return Object
end

function Creator.OverrideTag(Object, Properties)
	local Data = Creator.Registry[Object]
	if not Data then
		return
	end

	Data.Properties = Properties
	applyTheme(Object, Properties)
end

function Creator.New(Name, Properties, Children)
	local Object = Instance.new(Name)

	-- Default properties
	for Name, Value in next, Creator.DefaultProperties[Name] or {} do
		Object[Name] = Value
	end

	-- Properties
	for Name, Value in next, Properties or {} do
		if Name ~= "ThemeTag" then
			Object[Name] = Value
		end
	end

	-- Children
	for _, Child in next, Children or {} do
		Child.Parent = Object
	end

	ApplyCustomProps(Object, Properties)
	return Object
end

function Creator.SpringMotor(Initial, Instance, Prop)
	local Motor = Flipper.SingleMotor.new(Initial)
	Motor:onStep(function(value)
		Instance[Prop] = value
	end)

	-- A destroyed element should never leave its motor connected to
	-- RenderStepped, otherwise every removed option keeps ticking forever.
	Instance.Destroying:Connect(function()
		Motor:stop()
	end)

	return Motor, function(Value)
		Motor:setGoal(Flipper.Spring.new(Value, { frequency = 8 }))
	end
end

return Creator
