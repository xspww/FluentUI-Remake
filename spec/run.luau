--[[
	Runs the Flipper specs.

	Usage: lune run spec/run.luau
]]

local fs = require("@lune/fs")
local process = require("@lune/process")

local Loader = require("./loader")

local Passed = 0
local Failed = 0
local Failures = {}

local CurrentSuite = nil

-- Runs a function in a thread, so a spec can wait for a signal. Every
-- thread that the function spawns is started when the function waits.
local function execute(Body)
	local Error = nil
	local Thread = coroutine.create(function()
		local Ok, Reason = pcall(Body)
		if not Ok then
			Error = Reason
		end
	end)

	local Ok, Reason = coroutine.resume(Thread)
	if not Ok then
		Error = Reason
	end

	while coroutine.status(Thread) == "suspended" do
		local Spawned = Loader.takePending()
		if not Spawned then
			Error = "the test is waiting but nothing can wake it up"
			break
		end

		local SpawnedOk, SpawnedError = coroutine.resume(Spawned)
		if not SpawnedOk then
			Error = SpawnedError
			break
		end
	end

	if Error then
		error(Error, 0)
	end
end

local function describe(Name, Body)
	local Previous = CurrentSuite
	CurrentSuite = Name

	local Ok, Error = pcall(Body)
	if not Ok then
		Failed = Failed + 1
		table.insert(Failures, ("%s: %s"):format(Name, tostring(Error)))
		print(("  FAIL  %s"):format(Name))
		print(("        %s"):format(tostring(Error)))
	end

	CurrentSuite = Previous
end

local function it(Name, Body)
	local FullName = CurrentSuite and ("%s > %s"):format(CurrentSuite, Name) or Name

	local Ok, Error = pcall(execute, Body)

	if Ok then
		Passed = Passed + 1
		print(("  PASS  %s"):format(FullName))
	else
		Failed = Failed + 1
		print(("  FAIL  %s"):format(FullName))
		print(("        %s"):format(tostring(Error)))
		table.insert(Failures, ("%s: %s"):format(FullName, tostring(Error)))
	end
end

local function expect(Value)
	local Matchers = {}

	local function Equal(Other)
		if Value ~= Other then
			error(("expected %s, got %s"):format(tostring(Other), tostring(Value)), 3)
		end
	end

	local function Truthy()
		if not Value then
			error("expected a truthy value", 3)
		end
	end

	Matchers.to = {
		equal = Equal,
		be = {
			ok = Truthy,
		},
	}

	return Matchers
end

Loader.Extra = {
	describe = describe,
	it = it,
	expect = expect,
}

Loader.build()

local Names = {}
for _, Entry in fs.readDir("spec/Flipper") do
	local Name = Entry:match("^(.+)%.spec%.lua$")
	if Name then
		table.insert(Names, Name .. ".spec")
	end
end

table.sort(Names)

print("Running the Flipper specs")
print("")

for _, Name in Names do
	local Module = Loader.Flipper.Children[Name]
	local Body = Loader.require(Module)

	if type(Body) == "function" then
		local Ok, Error = pcall(execute, Body)
		if not Ok then
			Failed = Failed + 1
			table.insert(Failures, ("%s: %s"):format(Name, tostring(Error)))
			print(("  FAIL  %s"):format(Name))
			print(("        %s"):format(tostring(Error)))
		end
	end
end

print("")
print("Running the other specs")
print("")

for _, Entry in fs.readDir("spec") do
	local Name = Entry:match("^(.+)%.spec%.luau$")
	if Name then
		local Body = Loader.loadFile("spec/" .. Entry)

		local Ok, Error = pcall(execute, Body)
		if not Ok then
			Failed = Failed + 1
			table.insert(Failures, ("%s: %s"):format(Name, tostring(Error)))
			print(("  FAIL  %s"):format(Name))
			print(("        %s"):format(tostring(Error)))
		end
	end
end

print("")
print(("%d passed, %d failed"):format(Passed, Failed))

if Failed > 0 then
	print("")
	for _, Failure in Failures do
		print("  " .. Failure)
	end

	process.exit(1)
end
