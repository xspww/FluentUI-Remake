--[[
	Checks the save manager.

	The addon is loaded as it is, so the checks cover the real code.
]]

local Loader = require("./loader")

-- The save manager is loaded once, because it reads the files of the
-- executor when it starts.
local SaveManager = Loader.loadFile("Addons/SaveManager.lua")

-- A stand in for the library, with a few elements in it.
local function makeLibrary()
	local Library = {
		LoadingConfig = false,
		Options = {},
		Notifications = {},
	}

	function Library:SafeCallback(Function, ...)
		if not Function then
			return
		end

		if self.LoadingConfig then
			return
		end

		Function(...)
	end

	function Library:Notify(Config)
		self.Notifications[#self.Notifications + 1] = Config
	end

	return Library
end

-- A stand in for an element.
local function makeElement(Type, Value)
	local Element = {
		Type = Type,
		Value = Value,
		Fired = {},
	}

	function Element:SetValue(New)
		self.Value = New
	end

	Element.Callback = function(New)
		Element.Fired[#Element.Fired + 1] = { Name = "Callback", Value = New }
	end

	Element.Changed = function(New)
		Element.Fired[#Element.Fired + 1] = { Name = "Changed", Value = New }
	end

	return Element
end

return function()
	describe("the save manager", function()
		it("should save and load a value", function()
			local Library = makeLibrary()
			local Toggle = makeElement("Toggle", false)
			Library.Options.MyToggle = Toggle

			SaveManager:SetLibrary(Library)

			local Saved = SaveManager:Save("test")
			expect(Saved).to.equal(true)

			Toggle.Value = false
			Toggle.Fired = {}

			local Loaded = SaveManager:Load("test")
			expect(Loaded).to.equal(true)
			expect(Toggle.Value).to.equal(false)
		end)

		it("should fire the callback of an element after it loaded", function()
			local Library = makeLibrary()
			local Toggle = makeElement("Toggle", false)
			Library.Options.MyToggle = Toggle

			SaveManager:SetLibrary(Library)

			SaveManager:Save("flush")
			Toggle.Fired = {}

			SaveManager:Load("flush")

			-- The callback and the changed handler both ran, and they got
			-- the value that was loaded.
			expect(#Toggle.Fired).to.equal(2)
			expect(Toggle.Fired[1].Name).to.equal("Callback")
			expect(Toggle.Fired[2].Name).to.equal("Changed")
			expect(Toggle.Fired[1].Value).to.equal(false)
		end)

		it("should keep a slider value a number", function()
			local Library = makeLibrary()
			local Slider = makeElement("Slider", 0)
			Library.Options.MySlider = Slider

			SaveManager:SetLibrary(Library)

			SaveManager:Save("slider")
			Slider.Value = nil

			SaveManager:Load("slider")

			-- The slider needs a number, so the value may not be a string.
			expect(type(Slider.Value)).to.equal("number")
			expect(Slider.Value).to.equal(0)
		end)

		it("should fail to load a config that does not exist", function()
			SaveManager:SetLibrary(makeLibrary())

			local Loaded = SaveManager:Load("does-not-exist")
			expect(Loaded).to.equal(false)
		end)
	end)
end

