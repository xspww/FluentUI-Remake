local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

local Root = script
local Creator = require(Root.Creator)
local ElementsTable = require(Root.Elements)
local Acrylic = require(Root.Acrylic)
local Themes = require(Root.Themes)
local Components = Root.Components
local NotificationModule = require(Components.Notification)

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

	Theme = "Dark",
	DialogOpen = false,
	UseAcrylic = false,
	Acrylic = false,
	Transparency = true,
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
		ElementComponent.Container = self.Container
		ElementComponent.Type = self.Type
		ElementComponent.ScrollFrame = self.ScrollFrame
		ElementComponent.Library = Library

		return ElementComponent:New(Idx, Config)
	end
end

Library.Elements = Elements

function Library:CreateWindow(Config)
	assert(Config.Title, "Window - Missing Title")

	if Library.Window then
		print("You cannot create more than one window.")
		return
	end

	Library.MinimizeKey = Config.MinimizeKey or Enum.KeyCode.LeftControl
	Library.UseAcrylic = Config.Acrylic or false
	Library.Acrylic = Config.Acrylic or false

	-- The theme has to be a known one. The window is built right below and
	-- every themed object looks the theme up while it is created, so an
	-- unknown name would crash the window instead of falling back.
	local Theme = Themes.Resolve(Config.Theme)
	Library.Theme = Theme

	if Config.Acrylic then
		Acrylic.init()
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

	if Library.UseAcrylic then
		local Paint = Library.Window and Library.Window.AcrylicPaint
		if Paint and Paint.Model then
			Paint.Model:Destroy()
		end
		if Acrylic.Destroy then
			Acrylic.Destroy()
		end
	end

	Creator.Destroy()

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

function Library:ToggleAcrylic(Value)
	if Library.Window and Library.UseAcrylic then
		local Paint = Library.Window.AcrylicPaint
		if not Paint or not Paint.Model then
			return
		end

		Library.Acrylic = Value
		Paint.Model.Transparency = Value and 0.98 or 1
		if Value then
			Acrylic.Enable()
		else
			Acrylic.Disable()
		end
	end
end

function Library:ToggleTransparency(Value)
	if Library.Window then
		Library.Window.AcrylicPaint.Frame.Background.BackgroundTransparency = Value and 0.35 or 0
	end
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
