--[[
	Loads the Flipper modules and their specs outside of Roblox.

	The specs use `require(script.Parent.BaseMotor)`, which is the Roblox way
	of reaching a sibling module. This loader builds the same tree, so the
	spec files stay unchanged and run both in Roblox Studio and here.
]]

local fs = require("@lune/fs")

local Loader = {}

local FlipperDirectory = "src/Packages/Flipper"
local SpecDirectory = "spec/Flipper"

local ModuleNames = {
	"BaseMotor",
	"GroupMotor",
	"Instant",
	"Linear",
	"Signal",
	"SingleMotor",
	"Spring",
	"isMotor",
}

local Loaded = {}
local Pending = {}

local Game = {}
local RunService = {}
local RenderStepped = {}
local HttpService = {}

-- A small stand in for the files of an executor.
local Files = {}
local Folders = {}

-- A small stand in for Roblox's json functions. It only has to handle the
-- values that the save manager writes.
local function encodeValue(Value, Out)
	local Kind = type(Value)

	if Kind == "nil" then
		Out[#Out + 1] = "null"
	elseif Kind == "boolean" or Kind == "number" then
		Out[#Out + 1] = tostring(Value)
	elseif Kind == "string" then
		Out[#Out + 1] = '"' .. Value:gsub('"', '\\"') .. '"'
	elseif Kind == "table" then
		if Value[1] ~= nil or next(Value) == nil then
			Out[#Out + 1] = "["
			for Index, Entry in ipairs(Value) do
				if Index > 1 then
					Out[#Out + 1] = ","
				end
				encodeValue(Entry, Out)
			end
			Out[#Out + 1] = "]"
		else
			Out[#Out + 1] = "{"
			local First = true
			for Key, Entry in pairs(Value) do
				if not First then
					Out[#Out + 1] = ","
				end
				First = false
				Out[#Out + 1] = '"' .. tostring(Key) .. '":'
				encodeValue(Entry, Out)
			end
			Out[#Out + 1] = "}"
		end
	else
		error("cannot encode a " .. Kind)
	end
end

-- Finds the next character that starts a value. It skips the spaces, the
-- commas and the colon that separates a name from its value.
local function skipToValue(Text, Position)
	local Char = Text:sub(Position, Position)

	while Char == " " or Char == "," or Char == ":" or Char == "\t" or Char == "\n" do
		Position = Position + 1
		Char = Text:sub(Position, Position)
	end

	return Position
end

-- Reads a name. It is either in quotes or it runs up to the next
-- separator.
local function readName(Text, Position)
	if Text:sub(Position, Position) == '"' then
		local Close = Text:find('"', Position + 1, true)
		return Text:sub(Position + 1, Close - 1), Close + 1
	end

	local Stop = Text:find("[^,%s]%]", Position) or (#Text + 1)
	return Text:sub(Position, Stop - 1), Stop
end

local function decodeValue(Text, Position)
	local Char = Text:sub(Position, Position)

	if Char == "{" then
		local Result = {}
		Position = Position + 1

		while true do
			Position = skipToValue(Text, Position)

			if Text:sub(Position, Position) == "}" then
				return Result, Position + 1
			end

			local Key
			Key, Position = readName(Text, Position)

			Position = skipToValue(Text, Position)

			local Value
			Value, Position = decodeValue(Text, Position)

			Result[Key] = Value

			if Text:sub(Position, Position) == "}" then
				return Result, Position + 1
			end

			Position = Position + 1
		end
	elseif Char == "[" then
		local Result = {}
		Position = Position + 1

		while true do
			Position = skipToValue(Text, Position)

			if Text:sub(Position, Position) == "]" then
				return Result, Position + 1
			end

			local Value
			Value, Position = decodeValue(Text, Position)

			Result[#Result + 1] = Value

			if Text:sub(Position, Position) == "]" then
				return Result, Position + 1
			end

			Position = Position + 1
		end
	elseif Char == '"' then
		local Close = Text:find('"', Position + 1, true)
		return Text:sub(Position + 1, Close - 1), Close + 1
	elseif Text:sub(Position, Position + 3) == "true" then
		return true, Position + 4
	elseif Text:sub(Position, Position + 4) == "false" then
		return false, Position + 5
	elseif Text:sub(Position, Position + 3) == "null" then
		return nil, Position + 4
	else
		local Stop = Text:find("[^,%s]%]", Position) or (#Text + 1)
		return tonumber(Text:sub(Position, Stop - 1)), Stop
	end
end

function HttpService:JSONEncode(Value)
	local Out = {}
	encodeValue(Value, Out)
	return table.concat(Out)
end

function HttpService:JSONDecode(Text)
	local Result = decodeValue(Text, 1)
	return Result
end

RunService.RenderStepped = RenderStepped

local function typeof(Value)
	if type(Value) == "table" and rawget(Value, "__type") then
		return rawget(Value, "__type")
	end

	return type(Value)
end

-- Roblox starts a spawned thread after the current one yields, so the
-- threads are queued here and started by the scheduler in the harness.
function Loader.spawn(Body, ...)
	local Thread = coroutine.create(Body, ...)
	table.insert(Pending, Thread)
	return Thread
end

function Loader.takePending()
	return table.remove(Pending, 1)
end

function RenderStepped:Connect(Callback)
	local Connection = { __type = "RBXScriptConnection", Connected = true }
	Connection.Callback = Callback

	function Connection:Disconnect()
		self.Connected = false
	end

	table.insert(RenderStepped.Connections, Connection)
	return Connection
end

function RenderStepped:Wait()
	local DeltaTime = 1 / 60

	for _, Connection in ipairs(RenderStepped.Connections) do
		if Connection.Connected then
			Connection.Callback(DeltaTime)
		end
	end

	return DeltaTime
end

RenderStepped.Connections = {}

RunService.RenderStepped = RenderStepped

function Game:GetService(Name)
	if Name == "RunService" then
		return RunService
	end

	if Name == "HttpService" then
		return HttpService
	end

	error("the test loader has no service called " .. tostring(Name))
end

local function newModule(Name, Source, Parent)
	local Module = {
		Name = Name,
		Source = Source,
		Parent = Parent,
		Children = {},
	}

	setmetatable(Module, {
		__index = function(self, Key)
			return self.Children[Key]
		end,
	})

	return Module
end

local function makeEnvironment(Module, Extra)
	local Environment = {
		script = Module,
		require = Loader.require,
		game = Game,
		typeof = typeof,
		spawn = Loader.spawn,

		-- The themes use these to describe their colors.
		Color3 = {
			fromRGB = function()
				return {}
			end,
		},
		ColorSequence = {
			new = function()
				return {}
			end,
		},

		-- The functions of an executor, so the addons can be tested.
		isfile = function(Path)
			return Files[Path] ~= nil
		end,
		isfolder = function(Path)
			return Folders[Path] == true
		end,
		makefolder = function(Path)
			Folders[Path] = true
		end,
		readfile = function(Path)
			local Content = Files[Path]
			if not Content then
				error("the file " .. tostring(Path) .. " does not exist")
			end
			return Content
		end,
		writefile = function(Path, Content)
			Files[Path] = Content
		end,
		listfiles = function(Path)
			local Names = {}
			for Name in pairs(Files) do
				if Name:sub(1, #Path) == Path then
					Names[#Names + 1] = Name
				end
			end
			return Names
		end,
	}

	for Key, Value in next, Extra or {} do
		Environment[Key] = Value
	end

	return setmetatable(Environment, { __index = getfenv(0) })
end

function Loader.require(Module)
	if type(Module) == "string" then
		return require(Module)
	end

	if Loaded[Module] then
		return Loaded[Module]
	end

	-- The source is read up front, because reading a file yields and the
	-- specs run inside a thread.
	local Chunk = loadstring(Module.Source, "@" .. Module.Path)
	setfenv(Chunk, makeEnvironment(Module, Loader.Extra))

	local Result = Chunk()
	Loaded[Module] = Result

	return Result
end

-- Loads a file from a path, with the same environment the specs get.
function Loader.loadFile(Path, Script)
	if Loaded[Path] then
		return Loaded[Path]
	end

	local Chunk = loadstring(fs.readFile(Path), "@" .. Path)
	setfenv(Chunk, makeEnvironment(Script or {}, Loader.Extra))

	local Result = Chunk()
	Loaded[Path] = Result

	return Result
end

-- Reads the names of the files in a folder.
function Loader.readDir(Path)
	local Names = {}

	for _, Entry in fs.readDir(Path) do
		Names[#Names + 1] = Entry
	end

	table.sort(Names)

	return Names
end

-- A stand in for a folder, so a module can read its children the way it
-- does in Roblox.
function Loader.newFolder(Name)
	local Folder = {
		Children = {},
		Path = Name,
	}

	function Folder:add(ChildName, Path)
		self.Children[ChildName] = {
			Name = ChildName,
			Path = Path,
			Source = fs.readFile(Path),
			Parent = self,
		}
	end

	function Folder:GetChildren()
		local Result = {}

		for _, Child in pairs(self.Children) do
			Result[#Result + 1] = Child
		end

		table.sort(Result, function(A, B)
			return A.Name < B.Name
		end)

		return Result
	end

	return Folder
end

-- Builds the tree of the Flipper package. The specs are children of the
-- package as well, which is how they reach the modules with
-- `script.Parent.BaseMotor`.
function Loader.build()
	local Flipper = newModule("Flipper", nil, nil)
	Flipper.Path = FlipperDirectory .. "/init.lua"

	for _, Name in ModuleNames do
		local Module = newModule(Name, nil, Flipper)
		Module.Path = FlipperDirectory .. "/" .. Name .. ".lua"
		Flipper.Children[Name] = Module
	end

	for _, Name in ModuleNames do
		local Module = newModule(Name .. ".spec", nil, Flipper)
		Module.Path = SpecDirectory .. "/" .. Name .. ".spec.lua"
		Flipper.Children[Name .. ".spec"] = Module
	end

	-- Reading a file yields, so all of it happens before the tests start.
	local function read(Module)
		Module.Source = fs.readFile(Module.Path)
	end

	for _, Child in Flipper.Children do
		read(Child)
	end
	read(Flipper)

	Loader.Flipper = Flipper

	return Flipper
end

Loader.Specs = {}
Loader.Extra = {}
Loader.Game = Game
Loader.Files = Files

return Loader
