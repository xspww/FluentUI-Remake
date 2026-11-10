local httpService = game:GetService("HttpService")

local function SafeIsFile(path)
	local Success, Result = pcall(isfile, path)
	return Success and Result == true
end

local function SafeIsFolder(path)
	local Success, Result = pcall(isfolder, path)
	return Success and Result == true
end

local function SafeMakeFolder(path)
	local Success = pcall(makefolder, path)
	return Success
end

local function SafeReadFile(path)
	local Success, Result = pcall(readfile, path)
	if Success and type(Result) == "string" then
		return Result
	end

	return nil
end

local function SafeWriteFile(path, contents)
	local Success = pcall(writefile, path, contents)
	return Success
end

local function SafeListFiles(path)
	local Success, Result = pcall(listfiles, path)
	if Success and type(Result) == "table" then
		return Result
	end

	return {}
end

local SaveManager = {} do
	SaveManager.Folder = "FluentSettings"
	SaveManager.Ignore = {}

	-- Fires the callbacks of an element again after its value was loaded.
	-- While the config is applied the callbacks are suppressed, so without
	-- this the game would never learn about the loaded values.
	local function FlushOption(option)
		local Library = SaveManager.Library
		if not Library then
			return
		end

		Library:SafeCallback(option.Callback, option.Value)
		Library:SafeCallback(option.Changed, option.Value)
	end

	SaveManager.Parser = {
		Toggle = {
			Save = function(idx, object) 
				return { type = "Toggle", idx = idx, value = object.Value } 
			end,
			Load = function(idx, data)
				if SaveManager.Options[idx] then 
					SaveManager.Options[idx]:SetValue(data.value)
				end
			end,
			Flush = FlushOption,
		},
		Slider = {
			Save = function(idx, object)
				return { type = "Slider", idx = idx, value = object.Value }
			end,
			Load = function(idx, data)
				if SaveManager.Options[idx] then 
					-- Older configs stored the value as a string.
					SaveManager.Options[idx]:SetValue(tonumber(data.value) or data.value)
				end
			end,
			Flush = FlushOption,
		},
		Dropdown = {
			Save = function(idx, object)
				return { type = "Dropdown", idx = idx, value = object.Value, multi = object.Multi }
			end,
			Load = function(idx, data)
				if SaveManager.Options[idx] then 
					SaveManager.Options[idx]:SetValue(data.value)
				end
			end,
			Flush = FlushOption,
		},
		Colorpicker = {
			Save = function(idx, object)
				return { type = "Colorpicker", idx = idx, value = object.Value:ToHex(), transparency = object.Transparency }
			end,
			Load = function(idx, data)
				if SaveManager.Options[idx] and type(data.value) == "string" then
					local Success, Color = pcall(Color3.fromHex, data.value)
					if Success then
						SaveManager.Options[idx]:SetValueRGB(Color, data.transparency)
					end
				end
			end,
			Flush = FlushOption,
		},
		Keybind = {
			Save = function(idx, object)
				return { type = "Keybind", idx = idx, mode = object.Mode, key = object.Value }
			end,
			Load = function(idx, data)
				if SaveManager.Options[idx] then 
					SaveManager.Options[idx]:SetValue(data.key, data.mode)
				end
			end,
		},

		Input = {
			Save = function(idx, object)
				return { type = "Input", idx = idx, text = object.Value }
			end,
			Load = function(idx, data)
				if SaveManager.Options[idx] and type(data.text) == "string" then
					SaveManager.Options[idx]:SetValue(data.text)
				end
			end,
			Flush = FlushOption,
		},
	}

	function SaveManager:SetIgnoreIndexes(list)
		if type(list) ~= "table" then
			return
		end

		for _, key in next, list do
			self.Ignore[key] = true
		end
	end

	function SaveManager:SetFolder(folder)
		if type(folder) ~= "string" or folder == "" then
			return false, "invalid folder"
		end

		self.Folder = folder
		self:BuildFolderTree()
		return true
	end

	function SaveManager:Save(name)
		if not name then
			return false, "no config file is selected"
		end

		if not self.Options then
			return false, "library is not set"
		end

		local fullPath = self.Folder .. "/settings/" .. name .. ".json"

		local data = {
			objects = {}
		}

		for idx, option in next, self.Options do
			if not self.Parser[option.Type] then continue end
			if self.Ignore[idx] then continue end

			table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
		end	

		local success, encoded = pcall(httpService.JSONEncode, httpService, data)
		if not success then
			return false, "failed to encode data"
		end

		self:BuildFolderTree()

		if not SafeWriteFile(fullPath, encoded) then
			return false, "failed to write file"
		end

		return true
	end

	function SaveManager:Load(name)
		if not name then
			return false, "no config file is selected"
		end

		if not self.Options then
			return false, "library is not set"
		end
		
		local file = self.Folder .. "/settings/" .. name .. ".json"
		if not SafeIsFile(file) then
			return false, "invalid file"
		end

		local contents = SafeReadFile(file)
		if not contents then
			return false, "failed to read file"
		end

		local success, decoded = pcall(httpService.JSONDecode, httpService, contents)
		if not success or type(decoded) ~= "table" or type(decoded.objects) ~= "table" then
			return false, "decode error"
		end

		local Library = self.Library
		local WasLoading = Library and Library.LoadingConfig
		if Library then
			Library.LoadingConfig = true
		end

		local loaded = {}
		local applied = true

		for _, option in next, decoded.objects do
			if type(option) ~= "table" or type(option.type) ~= "string" or not self.Parser[option.type] then
				continue
			end

			local ok = pcall(self.Parser[option.type].Load, option.idx, option)
			if not ok then
				applied = false
				continue
			end

			if self.Parser[option.type].Flush and self.Options[option.idx] then
				table.insert(loaded, option)
			end
		end

		if Library then
			Library.LoadingConfig = WasLoading
		end

		if not WasLoading then
			for _, option in next, loaded do
				-- The flush needs the live element, because only that one holds
				-- the callbacks. The decoded json only holds the raw value.
				local ok = pcall(self.Parser[option.type].Flush, self.Options[option.idx])
				if not ok then
					applied = false
				end
			end
		end

		if not applied then
			return false, "some options failed to load"
		end

		return true
	end

	function SaveManager:IgnoreThemeSettings()
		self:SetIgnoreIndexes({ 
			"InterfaceTheme", "AcrylicToggle", "TransparentToggle", "MenuKeybind"
		})
	end

	function SaveManager:BuildFolderTree()
		local paths = {
			self.Folder,
			self.Folder .. "/settings"
		}

		for i = 1, #paths do
			local str = paths[i]
			if not SafeIsFolder(str) then
				SafeMakeFolder(str)
			end
		end
	end

	function SaveManager:RefreshConfigList()
		local list = SafeListFiles(self.Folder .. "/settings")

		local out = {}
		for i = 1, #list do
			local file = list[i]

			if type(file) == "string" then
				local name = file:match("([^/\\]+)%.json$")
				if name and name ~= "options" then
					table.insert(out, name)
				end
			end
		end
		
		return out
	end

	function SaveManager:SetLibrary(library)
		self.Library = library
		self.Options = library and library.Options or nil
	end

	function SaveManager:LoadAutoloadConfig()
		local path = self.Folder .. "/settings/autoload.txt"
		if not SafeIsFile(path) then
			return
		end

		local name = SafeReadFile(path)
		if name then
			name = name:gsub("^%s*(.-)%s*$", "%1")
		end

		if not name or name == "" then
			return
		end

		local success, err = self:Load(name)
		if not success then
			return self.Library:Notify({
				Title = "Interface",
				Content = "Config loader",
				SubContent = "Failed to load autoload config: " .. err,
				Duration = 7
			})
		end

		self.Library:Notify({
			Title = "Interface",
			Content = "Config loader",
			SubContent = string.format("Auto loaded config %q", name),
			Duration = 7
		})
	end

	function SaveManager:BuildConfigSection(tab)
		assert(self.Library, "Must set SaveManager.Library")

		local section = tab:AddSection("Configuration")

		section:AddInput("SaveManager_ConfigName",    { Title = "Config name" })
		section:AddDropdown("SaveManager_ConfigList", { Title = "Config list", Values = self:RefreshConfigList(), AllowNull = true })

		section:AddButton({
			Title = "Create config",
			Callback = function()
				local name = SaveManager.Options.SaveManager_ConfigName.Value

				if type(name) ~= "string" or name:gsub(" ", "") == "" then 
					return self.Library:Notify({
						Title = "Interface",
						Content = "Config loader",
						SubContent = "Invalid config name (empty)",
						Duration = 7
					})
				end

				local success, err = self:Save(name)
				if not success then
					return self.Library:Notify({
						Title = "Interface",
						Content = "Config loader",
						SubContent = "Failed to save config: " .. err,
						Duration = 7
					})
				end

				self.Library:Notify({
					Title = "Interface",
					Content = "Config loader",
					SubContent = string.format("Created config %q", name),
					Duration = 7
				})

				SaveManager.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
				SaveManager.Options.SaveManager_ConfigList:SetValue(nil)
			end
		})

		section:AddButton({Title = "Load config", Callback = function()
			local name = SaveManager.Options.SaveManager_ConfigList.Value

			local success, err = self:Load(name)
			if not success then
				return self.Library:Notify({
					Title = "Interface",
					Content = "Config loader",
					SubContent = "Failed to load config: " .. err,
					Duration = 7
				})
			end

			self.Library:Notify({
				Title = "Interface",
				Content = "Config loader",
				SubContent = string.format("Loaded config %q", name),
				Duration = 7
			})
		end})

		section:AddButton({Title = "Overwrite config", Callback = function()
			local name = SaveManager.Options.SaveManager_ConfigList.Value

			local success, err = self:Save(name)
			if not success then
				return self.Library:Notify({
					Title = "Interface",
					Content = "Config loader",
					SubContent = "Failed to overwrite config: " .. err,
					Duration = 7
				})
			end

			self.Library:Notify({
				Title = "Interface",
				Content = "Config loader",
				SubContent = string.format("Overwrote config %q", name),
				Duration = 7
			})
		end})

		section:AddButton({Title = "Refresh list", Callback = function()
			SaveManager.Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
			SaveManager.Options.SaveManager_ConfigList:SetValue(nil)
		end})

		local AutoloadButton
		AutoloadButton = section:AddButton({Title = "Set as autoload", Description = "Current autoload config: none", Callback = function()
			local name = SaveManager.Options.SaveManager_ConfigList.Value

			if type(name) ~= "string" or name == "" then
				return self.Library:Notify({
					Title = "Interface",
					Content = "Config loader",
					SubContent = "No config selected",
					Duration = 7
				})
			end

			self:BuildFolderTree()

			if not SafeWriteFile(self.Folder .. "/settings/autoload.txt", name) then
				return self.Library:Notify({
					Title = "Interface",
					Content = "Config loader",
					SubContent = "Failed to save autoload config",
					Duration = 7
				})
			end

			AutoloadButton:SetDesc("Current autoload config: " .. name)
			self.Library:Notify({
				Title = "Interface",
				Content = "Config loader",
				SubContent = string.format("Set %q to auto load", name),
				Duration = 7
			})
		end})

		local autoloadPath = self.Folder .. "/settings/autoload.txt"
		if SafeIsFile(autoloadPath) then
			local name = SafeReadFile(autoloadPath)
			if name then
				AutoloadButton:SetDesc("Current autoload config: " .. name)
			end
		end

		SaveManager:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName" })
	end

	SaveManager:BuildFolderTree()
end

return SaveManager
