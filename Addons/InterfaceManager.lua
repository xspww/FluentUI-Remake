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

local InterfaceManager = {} do
	InterfaceManager.Folder = "FluentSettings"
	InterfaceManager.Settings = {
		Theme = "Dark",
		Acrylic = true,
		Transparency = true,
		MenuKeybind = "LeftControl"
	}

	function InterfaceManager:SetFolder(folder)
		if type(folder) ~= "string" or folder == "" then
			return false, "invalid folder"
		end

		self.Folder = folder
		self:BuildFolderTree()
		return true
	end

	function InterfaceManager:SetLibrary(library)
		self.Library = library
	end

	function InterfaceManager:BuildFolderTree()
		local paths = {}

		local parts = self.Folder:split("/")
		for idx = 1, #parts do
			paths[#paths + 1] = table.concat(parts, "/", 1, idx)
		end

		table.insert(paths, self.Folder)
		table.insert(paths, self.Folder .. "/settings")

		for i = 1, #paths do
			local str = paths[i]
			if not SafeIsFolder(str) then
				SafeMakeFolder(str)
			end
		end
	end

	function InterfaceManager:SaveSettings()
		local success, encoded = pcall(httpService.JSONEncode, httpService, InterfaceManager.Settings)
		if not success then
			return false, "failed to encode settings"
		end

		self:BuildFolderTree()

		if not SafeWriteFile(self.Folder .. "/options.json", encoded) then
			return false, "failed to write settings"
		end

		return true
	end

	function InterfaceManager:LoadSettings()
		local path = self.Folder .. "/options.json"
		if not SafeIsFile(path) then
			return false, "invalid file"
		end

		local data = SafeReadFile(path)
		if not data then
			return false, "failed to read settings"
		end

		local success, decoded = pcall(httpService.JSONDecode, httpService, data)
		if not success or type(decoded) ~= "table" then
			return false, "decode error"
		end

		for i, v in next, decoded do
			local Current = InterfaceManager.Settings[i]
			if Current ~= nil and type(v) == type(Current) then
				InterfaceManager.Settings[i] = v
			end
		end

		return true
	end

	function InterfaceManager:BuildInterfaceSection(tab)
		assert(self.Library, "Must set InterfaceManager.Library")
		local Library = self.Library
		local Settings = InterfaceManager.Settings

		InterfaceManager:LoadSettings()

		local section = tab:AddSection("Interface")

		local InterfaceTheme = section:AddDropdown("InterfaceTheme", {
			Title = "Theme",
			Description = "Changes the interface theme.",
			Values = Library.Themes,
			Default = Settings.Theme,
			Callback = function(Value)
				Library:SetTheme(Value)
				Settings.Theme = Value
				InterfaceManager:SaveSettings()
			end
		})

		InterfaceTheme:SetValue(Settings.Theme)
	
		if Library.UseAcrylic then
			section:AddToggle("AcrylicToggle", {
				Title = "Acrylic",
				Description = "The blurred background requires graphic quality 8+",
				Default = Settings.Acrylic,
				Callback = function(Value)
					Library:ToggleAcrylic(Value)
					Settings.Acrylic = Value
					InterfaceManager:SaveSettings()
				end
			})
		end
	
		section:AddToggle("TransparentToggle", {
			Title = "Transparency",
			Description = "Makes the interface transparent.",
			Default = Settings.Transparency,
			Callback = function(Value)
				Library:ToggleTransparency(Value)
				Settings.Transparency = Value
				InterfaceManager:SaveSettings()
			end
		})
	
		local MenuKeybind = section:AddKeybind("MenuKeybind", { Title = "Minimize Bind", Default = Settings.MenuKeybind })
		MenuKeybind:OnChanged(function()
			Settings.MenuKeybind = MenuKeybind.Value
			InterfaceManager:SaveSettings()
		end)
		Library.MinimizeKeybind = MenuKeybind
	end
end

return InterfaceManager
