local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

local Root = script
local Creator = require(Root.Creator)
local ElementsTable = require(Root.Elements)
local Themes = require(Root.Themes)
local Components = Root.Components
local NotificationModule = require(Components.Notification)
local DynamicIsland = require(Components.DynamicIsland)
local LoadingModule = require(Components.Loading)

local New = Creator.New

-- Executors expose the UI through a hidden parent (gethui) and/or a protection
-- function. Vanilla Studio only allows PlayerGui, so each candidate is probed
-- before being used instead of hard-coding CoreGui.
local function GetGuiParent()
	local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

	if RunService:IsStudio() then
		return PlayerGui
	end

	if type(gethui) == "function" then
		local Success, HiddenUI = pcall(gethui)
		if Success and HiddenUI then
			return HiddenUI
		end
	end

	local Success, CoreGui = pcall(function()
		return game:GetService("CoreGui")
	end)

	if Success and CoreGui then
		-- Writing to CoreGui throws in a normal local script (no permission),
		-- so test it first and fall back to PlayerGui when it is read-only.
		local Writable = pcall(function()
			local Probe = Instance.new("Folder")
			Probe.Parent = CoreGui
			Probe:Destroy()
		end)

		if Writable then
			return CoreGui
		end
	end

	return PlayerGui
end

local GUI = New("ScreenGui", {
	Parent = GetGuiParent(),
})

local ProtectGui = protectgui or function() end
pcall(ProtectGui, GUI)
NotificationModule:Init(GUI)

local Library = {
	Version = "1.1.0",

	OpenFrames = {},
	Options = {},
	Themes = Themes.Names,

	Window = nil,
	WindowFrame = nil,
	Unloaded = false,

	-- One centred overlay at a time. The token invalidates pending timers
	-- when the overlay is replaced or closed.
	Loading = nil,
	LoadingToken = nil,
	LoadingIsAuto = false,
	ReducedMotion = false,

	Theme = "Dark",
	DialogOpen = false,
	MinimizeKeybind = nil,
	MinimizeKey = Enum.KeyCode.LeftControl,

	-- Set while a config is being applied so option callbacks do not fire
	-- halfway through the load (SaveManager flushes them once afterwards).
	LoadingConfig = false,
	InputLocks = {},

	GUI = GUI,
}

function Library:LockInput(Name)
	self.InputLocks[Name or "default"] = true
end

function Library:UnlockInput(Name)
	self.InputLocks[Name or "default"] = nil
end

function Library:IsInputLocked()
	return next(self.InputLocks) ~= nil
end

function Library:IsTyping()
	return UserInputService:GetFocusedTextBox() ~= nil
end

function Library:SafeCallback(Function, ...)
	if not Function then
		return
	end

	if Library.LoadingConfig then
		return
	end

	local Success, Event = pcall(Function, ...)
	if not Success then
		local _, i = Event:find(":%d+: ")

		if not i then
			return Library:Notify({
				Title = "Interface",
				Content = "Callback error",
				SubContent = Event,
				Duration = 5,
			})
		end

		return Library:Notify({
			Title = "Interface",
			Content = "Callback error",
			SubContent = Event:sub(i + 1),
			Duration = 5,
		})
	end
end

function Library:Round(Number, Factor)
	Factor = Factor or 0
	if Factor == 0 then
		return math.floor(Number + 0.5)
	end

	local Multiplier = 10 ^ Factor
	return math.floor(Number * Multiplier + 0.5) / Multiplier
end

local Icons = require(Root.Icons).assets
function Library:GetIcon(Name)
	if Name ~= nil and Icons["lucide-" .. Name] then
		return Icons["lucide-" .. Name]
	end
	return nil
end

local Elements = {}
Elements.__index = Elements

for _, ElementComponent in ipairs(ElementsTable) do
	Elements["Add" .. ElementComponent.__type] = function(self, Idx, Config)
		-- The auto splash hands off to the interface as soon as there is
		-- something real to look at. A manual overlay stays up until the
		-- script closes it or its own timeout fires.
		if Library.LoadingIsAuto then
			Library:FinishLoading()
		end

		ElementComponent.Container = self.Container
		ElementComponent.Type = self.Type
		ElementComponent.ScrollFrame = self.ScrollFrame
		ElementComponent.Library = Library

		return ElementComponent:New(Idx, Config)
	end
end

Library.Elements = Elements

-- Loading overlay -----------------------------------------------------------

function Library:ShowLoading(Config)
	if Library.Unloaded then
		return
	end

	Config = Config or {}

	-- A second show updates the live overlay instead of stacking another one.
	if Library.Loading and not Library.Loading.Closed then
		local Handle = Library.Loading
		if Config.Title ~= nil then
			Handle:SetTitle(Config.Title)
		end
		if Config.Text ~= nil then
			Handle:SetText(Config.Text)
		end
		if Config.Progress ~= nil then
			Handle:SetProgress(Config.Progress)
		end
		return Handle
	end

	local Handle = LoadingModule(Library, Config.Parent or GUI, {
		Title = Config.Title,
		Text = Config.Text,
		Progress = Config.Progress,
		ReducedMotion = Config.ReducedMotion,
		MinDuration = Config.MinDuration,
	})
	Library.Loading = Handle
	Library.LoadingIsAuto = Config.Auto == true

	-- The safety timeout makes sure a script that never adds an element does
	-- not leave the overlay up forever.
	local Token = {}
	Library.LoadingToken = Token
	task.delay(Config.Timeout or 8, function()
		if Library.LoadingToken == Token then
			Library:HideLoading()
		end
	end)

	return Handle
end

function Library:HideLoading()
	local Handle = Library.Loading
	if not Handle then
		return
	end
	Library.Loading = nil
	Library.LoadingToken = nil
	Library.LoadingIsAuto = false

	-- The window (and its pill) stay hidden until this moment, so the
	-- interface appears as the loader fades rather than sitting behind it.
	if Library.Window then
		Library.Window:SetHidden(false)
	end
	if Library.DynamicIsland and Library.DynamicIsland.Root then
		Library.DynamicIsland.Root.Visible = true
	end
	Handle:Close()
end

function Library:FinishLoading()
	local Handle = Library.Loading
	if not Handle or Handle.Finishing then
		return
	end
	Handle.Finishing = true

	-- Even a script that builds instantly gets a short, readable splash
	-- instead of a one-frame flash.
	local Wait = math.max(0, Handle:GetMinDuration() - Handle:GetElapsed())
	task.delay(Wait, function()
		if Library.Loading == Handle then
			Library:HideLoading()
		end
	end)
end

function Library:SetLoadingProgress(Value)
	if Library.Loading then
		Library.Loading:SetProgress(Value)
	end
end

function Library:SetLoadingText(Text)
	if Library.Loading then
		Library.Loading:SetText(Text)
	end
end

function Library:CreateWindow(Config)
	assert(Config.Title, "Window - Missing Title")

	if Library.Window then
		print("You cannot create more than one window.")
		return
	end

	Library.MinimizeKey = Config.MinimizeKey or Enum.KeyCode.LeftControl

	-- The theme has to be a known one. The window is built right below and
	-- every themed object looks the theme up while it is created, so an
	-- unknown name would crash the window instead of falling back.
	local Theme = Themes.Resolve(Config.Theme)
	Library.Theme = Theme

	-- The splash covers the window while it is built and is dismissed by the
	-- first element (or by its safety timeout). Loading=false opts out; a
	-- table configures Title, Text, MinDuration, Timeout and ReducedMotion.
	local Splash = Config.Loading
	if Splash ~= false then
		local SplashConfig = type(Splash) == "table" and table.clone(Splash) or {}
		SplashConfig.Auto = true
		SplashConfig.Title = SplashConfig.Title or ("Loading " .. Config.Title)
		SplashConfig.Text = SplashConfig.Text or "Preparing interface..."
		Library:ShowLoading(SplashConfig)
	end

	local Window = require(Components.Window)({
		Parent = GUI,
		Size = Config.Size,
		Title = Config.Title,
		SubTitle = Config.SubTitle,
		TabWidth = Config.TabWidth,
	})

	Library.Window = Window
	Library:SetTheme(Theme)

	if Splash ~= false then
		Window:SetHidden(true)
	end

	if Config.DynamicIsland ~= false then
		Library.DynamicIsland = DynamicIsland(Library, GUI)
		if Config.IslandAvatar then
			Library.DynamicIsland:SetAvatar(Config.IslandAvatar)
		end
		if Config.IslandName then
			Library.DynamicIsland:SetName(Config.IslandName)
		end
		if Splash ~= false then
			Library.DynamicIsland.Root.Visible = false
		end
	end

	return Window
end

function Library:SetTheme(Value)
	-- An unknown name is ignored, so the theme of the window stays the
	-- same.
	if Library.Window and Themes.Exists(Value) then
		Library.Theme = Value
		Creator.UpdateTheme()
	end
end

function Library:Destroy()
	if Library.Unloaded then
		return
	end

	Library.Unloaded = true

	if Library.Loading then
		Library.Loading:Destroy()
		Library.Loading = nil
		Library.LoadingToken = nil
		Library.LoadingIsAuto = false
	end

	Creator.Destroy()

	if Library.DynamicIsland then
		Library.DynamicIsland:Destroy()
		Library.DynamicIsland = nil
	end

	if Library.Window then
		Library.Window:Destroy()
	end

	Library.GUI:Destroy()

	-- Drop the references to the instances and the elements, otherwise they
	-- stay alive until the script is unloaded. The tables are cleared and not
	-- replaced, because other parts of the library hold on to them.
	table.clear(Library.Options)
	table.clear(Library.OpenFrames)
	Library.Window = nil
	Library.WindowFrame = nil
end

function Library:Notify(Config)
	return NotificationModule:New(Config)
end

-- The library is published as a global, so a script can reach it without
-- holding on to the return value.
if getgenv then
	getgenv().Fluent = Library
end

return Library
