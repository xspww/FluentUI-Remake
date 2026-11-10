local Themes = {
	Names = {
		"Dark",
		"Darker",
		"Light",
		"Aqua",
		"Amethyst",
		"Rose",
		"Navy",
	},
}

-- Every theme file is loaded, so a new theme works without touching the
-- list above. The list only decides the order of the themes.
local Files = {}
for _, Theme in next, script:GetChildren() do
	local Required = require(Theme)
	Themes[Required.Name] = Required
	Files[#Files + 1] = Required.Name
end

table.sort(Files)

for _, Name in ipairs(Files) do
	if not table.find(Themes.Names, Name) then
		table.insert(Themes.Names, Name)
	end
end

-- Returns the name of a theme. An unknown name falls back to Dark, so a
-- typo can never break the window.
function Themes.Resolve(Name)
	if not Name then
		return "Dark"
	end

	if table.find(Themes.Names, Name) then
		return Name
	end

	return "Dark"
end

-- Tells if a name belongs to a theme.
function Themes.Exists(Name)
	return table.find(Themes.Names, Name) ~= nil
end

return Themes
