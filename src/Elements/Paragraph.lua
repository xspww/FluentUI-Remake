local Root = script.Parent.Parent
local Components = Root.Components

local Paragraph = {}
Paragraph.__index = Paragraph
Paragraph.__type = "Paragraph"

function Paragraph:New(Config)
	assert(Config.Title, "Paragraph - Missing Title")
	Config.Content = Config.Content or ""

	local Element = require(Components.Element)(Config.Title, Config.Content, self.Container, false, Paragraph.__type)
	Element.Frame.BackgroundTransparency = 0
	Element.Border.Transparency = 0.6

	return Element
end

return Paragraph
