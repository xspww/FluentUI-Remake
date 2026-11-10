local Acrylic = {
	AcrylicBlur = require(script.AcrylicBlur),
	CreateAcrylic = require(script.CreateAcrylic),
	AcrylicPaint = require(script.AcrylicPaint),
}

local baseEffect = nil
local depthOfFieldDefaults = {}

function Acrylic.init()
	if baseEffect then
		Acrylic.Enable()
		return
	end

	baseEffect = Instance.new("DepthOfFieldEffect")
	baseEffect.FarIntensity = 0
	baseEffect.InFocusRadius = 0.1
	baseEffect.NearIntensity = 1

	function Acrylic.Enable()
		if not baseEffect then
			return
		end

		for effect in next, depthOfFieldDefaults do
			if effect.Parent then
				effect.Enabled = false
			end
		end
		baseEffect.Parent = game:GetService("Lighting")
	end

	function Acrylic.Disable()
		for effect, data in next, depthOfFieldDefaults do
			if effect.Parent then
				effect.Enabled = data.enabled
			end
		end

		if baseEffect then
			baseEffect.Parent = nil
		end
	end

	function Acrylic.Destroy()
		for effect, data in next, depthOfFieldDefaults do
			if effect.Parent then
				effect.Enabled = data.enabled
			end
		end
		table.clear(depthOfFieldDefaults)

		if baseEffect then
			baseEffect.Parent = nil
			baseEffect:Destroy()
			baseEffect = nil
		end
	end

	local function registerDefaults()
		local function register(object)
			if object:IsA("DepthOfFieldEffect") then
				depthOfFieldDefaults[object] = { enabled = object.Enabled }
			end
		end

		for _, child in next, game:GetService("Lighting"):GetChildren() do
			register(child)
		end

		local camera = game:GetService("Workspace").CurrentCamera
		if camera then
			for _, child in next, camera:GetChildren() do
				register(child)
			end
		end
	end

	registerDefaults()
	Acrylic.Enable()
end

return Acrylic
