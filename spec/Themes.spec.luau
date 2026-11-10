--[[
	Checks the themes.

	The theme module is loaded as it is, so the checks cover the real code.
]]

local Loader = require("./loader")

-- The theme module. It reads the theme files of the folder, so the
-- loader has to give it the same children that Roblox would.
local ThemeFolder = Loader.newFolder("src/Themes")

for _, Entry in Loader.readDir("src/Themes") do
	local Name = Entry:match("^(.+)%.lua$")
	if Name and Name ~= "init" then
		ThemeFolder:add(Name, "src/Themes/" .. Name .. ".lua")
	end
end

local Themes = Loader.loadFile("src/Themes/init.lua", ThemeFolder)

-- The names of the theme files, read before the tests run, because
-- reading a folder yields and the tests run inside a thread.
local Files = {}
for _, Entry in Loader.readDir("src/Themes") do
	local Name = Entry:match("^(.+)%.lua$")
	if Name and Name ~= "init" then
		table.insert(Files, Name)
	end
end

return function()
	describe("the themes", function()
		it("should list every theme file in the names", function()
			for _, Name in ipairs(Files) do
				expect(table.find(Themes.Names, Name)).to.be.ok()
			end
		end)

		it("should define the same keys as the Dark theme", function()
			for _, Name in ipairs(Themes.Names) do
				for Key in pairs(Themes.Dark) do
					if Key ~= "Name" then
						expect(Themes[Name][Key]).to.be.ok()
					end
				end
			end
		end)

		it("should give every theme a name that matches its file", function()
			for _, Name in ipairs(Themes.Names) do
				expect(Themes[Name].Name).to.equal(Name)
			end
		end)

		it("should find a known theme", function()
			expect(Themes.Resolve("Light")).to.equal("Light")
			expect(Themes.Resolve("Navy")).to.equal("Navy")
		end)

		it("should fall back to Dark for an unknown theme", function()
			expect(Themes.Resolve("Lignt")).to.equal("Dark")
			expect(Themes.Resolve("Bl")).to.equal("Dark")
			expect(Themes.Resolve(nil)).to.equal("Dark")
		end)

		it("should tell if a name belongs to a theme", function()
			expect(Themes.Exists("Light")).to.equal(true)
			expect(Themes.Exists("Navy")).to.equal(true)
			expect(Themes.Exists("Lignt")).to.equal(false)
			expect(Themes.Exists(nil)).to.equal(false)
		end)
	end)
end
