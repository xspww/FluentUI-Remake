local fs = require("@lune/fs")
local process = require("@lune/process")
local BuildCodegen = require("./build/modules/BuildCodegen")

local DistFolder = "dist"
local ModelPath = "dist/main.rbxm"
local FilePath = "dist/main.lua"
local TempFile = "dist/temp.lua"
local Header = fs.readFile("build/header.luau")

-- The output folder is not tracked by git, so it may be missing on a fresh
-- checkout. Neither Rojo nor Lune can write into a folder that is not there.
if not fs.isDir(DistFolder) then
	fs.writeDir(DistFolder, {})
end

local function run(program, args)
	local ok, result = pcall(process.exec, program, args)

	if not ok then
		error(program .. " could not be started, is it installed and on the PATH?", 0)
	end

	if not result.ok then
		error(program .. " failed: " .. tostring(result.stderr))
	end

	return result
end

local function buildModel()
	run("rojo", { "build", "default.project.json", "-o", ModelPath })
end

local function minify(text)
	fs.writeFile(TempFile, text)
	run("darklua", { "process", TempFile, TempFile, "--config", "build/darklua.json" })

	local value = fs.readFile(TempFile)
	fs.removeFile(TempFile)
	return value
end

buildModel()

local Module = fs.readFile(ModelPath)
local ModelCodegen = BuildCodegen(Module, false)

fs.writeFile(FilePath, Header .. "\n" .. minify(ModelCodegen))
