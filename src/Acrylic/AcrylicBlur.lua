local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local Creator = require(script.Parent.Parent.Creator)
local createAcrylic = require(script.Parent.CreateAcrylic)
local viewportPointToWorld, getOffset = unpack(require(script.Parent.Utils))

local BlurFolder = Instance.new("Folder")
BlurFolder.Name = "FluentAcrylic"
BlurFolder.Parent = Workspace

local function createAcrylicBlur(distance)
	local cleanups = {}
	local cameraConnections = {}

	distance = distance or 0.001
	local positions = {
		topLeft = Vector2.new(),
		topRight = Vector2.new(),
		bottomRight = Vector2.new(),
	}
	local model = createAcrylic()
	model.Parent = BlurFolder

	local function updatePositions(size, position)
		positions.topLeft = position
		positions.topRight = position + Vector2.new(size.X, 0)
		positions.bottomRight = position + size
	end

	local function render()
		if not model.Parent then
			return
		end

		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end

		local cameraCFrame = camera.CFrame
		if not cameraCFrame then
			return
		end

		local topLeft = positions.topLeft
		local topRight = positions.topRight
		local bottomRight = positions.bottomRight

		local topLeft3D = viewportPointToWorld(topLeft, distance, camera)
		local topRight3D = viewportPointToWorld(topRight, distance, camera)
		local bottomRight3D = viewportPointToWorld(bottomRight, distance, camera)

		if not topLeft3D or not topRight3D or not bottomRight3D then
			return
		end

		local width = (topRight3D - topLeft3D).Magnitude
		local height = (topRight3D - bottomRight3D).Magnitude

		model.CFrame =
			CFrame.fromMatrix((topLeft3D + bottomRight3D) / 2, cameraCFrame.XVector, cameraCFrame.YVector, cameraCFrame.ZVector)
		model.Mesh.Scale = Vector3.new(math.max(width, 0), math.max(height, 0), 0)
	end

	local function unbindCamera()
		for _, connection in next, cameraConnections do
			connection:Disconnect()
		end
		table.clear(cameraConnections)
	end

	local function bindCamera()
		unbindCamera()

		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end

		table.insert(cameraConnections, camera:GetPropertyChangedSignal("CFrame"):Connect(render))
		table.insert(cameraConnections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(render))
		table.insert(cameraConnections, camera:GetPropertyChangedSignal("FieldOfView"):Connect(render))
		task.spawn(render)
	end

	local function onChange(rbx)
		local offset = getOffset()
		local size = rbx.AbsoluteSize
		local position = rbx.AbsolutePosition + offset

		updatePositions(size, position)
		task.spawn(render)
	end

	-- Re-bind whenever CurrentCamera is swapped (respawns, cutscenes, ...).
	table.insert(cleanups, Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		bindCamera()
		task.spawn(render)
	end))

	model.Destroying:Connect(function()
		for _, connection in next, cleanups do
			pcall(function()
				connection:Disconnect()
			end)
		end
		table.clear(cleanups)

		unbindCamera()
	end)

	bindCamera()

	return onChange, model
end

return function(distance)
	local Blur = {}
	local onChange, model = createAcrylicBlur(distance)

	local comp = Creator.New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	})

	Creator.AddSignal(comp:GetPropertyChangedSignal("AbsolutePosition"), function()
		onChange(comp)
	end)

	Creator.AddSignal(comp:GetPropertyChangedSignal("AbsoluteSize"), function()
		onChange(comp)
	end)

	-- The top bar can change size while the game is running (device rotation,
	-- new top bar layout), so the screen offset must be recalculated too.
	pcall(function()
		Creator.AddSignal(GuiService:GetPropertyChangedSignal("TopbarInset"), function()
			onChange(comp)
		end)
	end)

	Blur.AddParent = function(Parent)
		Creator.AddSignal(Parent:GetPropertyChangedSignal("Visible"), function()
			Blur.SetVisibility(Parent.Visible)
		end)
	end

	Blur.SetVisibility = function(Value)
		if model.Parent then
			model.Transparency = Value and 0.98 or 1
		end
	end

	Blur.Frame = comp
	Blur.Model = model

	return Blur
end
