local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local function map(value, inMin, inMax, outMin, outMax)
	return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
end

local function getCamera()
	return Workspace.CurrentCamera
end

local function viewportPointToWorld(location, distance, camera)
	camera = camera or getCamera()
	if not camera then
		return nil
	end

	local unitRay = camera:ScreenPointToRay(location.X, location.Y)
	return unitRay.Origin + unitRay.Direction * distance
end

-- AbsolutePosition is expressed in the CoreUISafeInsets coordinate space,
-- which starts below the Roblox top bar. ScreenPointToRay expects screen
-- coordinates, so the real (current) top-left inset has to be added.
local function getOffset()
	local success, topLeft = pcall(function()
		return GuiService:GetGuiInset()
	end)

	if success and typeof(topLeft) == "Vector2" then
		return topLeft
	end

	-- Older clients always used a 36px top bar. Keep a sane fallback instead
	-- of returning an offset based on the viewport height.
	return Vector2.new(0, 36)
end

return { viewportPointToWorld, getOffset, getCamera, map }
