local Main = require(game:GetService("ReplicatedStorage"):WaitForChild("Fluent"))

local Window = Main:CreateWindow({
    Title = "Fluent " .. Main.Version,
    SubTitle = "by dawid",
    TabWidth = 160,
    -- The window size is fixed at 635x541 and can no longer be resized.
    Theme = "Dark"
    -- DynamicIsland = false, -- disable the top-centre toggle pill
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "box" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),

    -- Grouped tabs live under a section header. The header only opens the
    -- group; it never changes the page. Only one group can be open at a time.
    Recent = Window:AddTab({
        Title = "Recent",
        Icon = "clock",
        Group = "Library",
        GroupIcon = "layers"
    }),
    Favorites = Window:AddTab({ Title = "Favorites", Icon = "star", Group = "Library" }),
    Profile = Window:AddTab({
        Title = "Profile",
        Icon = "user",
        Group = "Account",
        GroupIcon = "user"
    }),
}

do
    Tabs.Main:AddParagraph({
        Title = "Paragraph",
        Content = "This is a paragraph.\nSecond line!"
    })

    Tabs.Main:AddButton({
        Title = "Button",
        Description = "Very important button",
        Callback = function()
            Window:Dialog({
                Title = "Title",
                Content = "This is a dialog",
                Buttons = {
                    {
                        Title = "Confirm",
                        Callback = function()
                            Window:Dialog({
                                Title = "Another Dialog",
                                Content = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse mollis dolor eget erat mattis, id mollis mauris cursus. Proin ornare sollicitudin odio, id posuere diam luctus id.",
                                Buttons = { { Title = "Ok", Callback = function() print("Ok") end} }
                            })
                            Main.Options.Toggle:Destroy()
                        end
                    },
                    {
                        Title = "Cancel",
                        Callback = function()
                            print("Cancelled the dialog.")
                        end
                    }
                }
            })
        end
    })

    local Toggle = Tabs.Main:AddToggle("Toggle", {Title = "Toggle", Default = false })
    
    local Slider = Tabs.Main:AddSlider("Slider", {
        Title = "Slider",
        Description = "This is a slider",
        Default = 2.0,
        Min = 0.0,
        Max = 15.5,
        Rounding = 1
    })


    local Dropdown = Tabs.Main:AddDropdown("Dropdown", {
        Title = "Dropdown",
        Values = {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen"},
        Multi = false,
        Default = 1,
    })

    Dropdown:SetValue("four")
    
    local MultiDropdown = Tabs.Main:AddDropdown("MultiDropdown", {
        Title = "Dropdown",
        Description = "You can select multiple values.",
        Values = {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen"},
        Multi = true,
        Default = {"seven", "twelve"},
    })

    MultiDropdown:SetValue({
        three = true,
        five = true,
        seven = false
    })

    local Colorpicker = Tabs.Main:AddColorpicker("Colorpicker", {
        Title = "Colorpicker",
        Default = Color3.fromRGB(96, 205, 255)
    })

    local TColorpicker = Tabs.Main:AddColorpicker("TransparencyColorpicker", {
        Title = "Colorpicker",
        Description = "but you can change the transparency.",
        Transparency = 0,
        Default = Color3.fromRGB(96, 205, 255)
    })

    local Keybind = Tabs.Main:AddKeybind("Keybind", {
        Title = "KeyBind",
        Mode = "Hold",
        Default = "LeftControl",
        ChangedCallback = function(New)
            print("Keybind changed:", New)
        end
    })

    local Input = Tabs.Main:AddInput("Input", {
        Title = "Input",
        Default = "Default",
        Numeric = false,
        Finished = false,
        Placeholder = "Placeholder text",
        Callback = function(Value)
            print("Input changed:", Value)
        end
    })
       
    Toggle:OnChanged(function()
        print("Toggle changed:", Main.Options["Toggle"].Value)
    end)

    Slider:OnChanged(function(Value)
        print("Slider changed:", Value)
    end)

    Dropdown:OnChanged(function(Value)
        print("Dropdown changed:", Value)
    end)

    MultiDropdown:OnChanged(function(Value)
        local Values = {}
        for Value, State in next, Value do
            table.insert(Values, Value)
        end
        print("Mutlidropdown changed:", table.concat(Values, ", "))
    end)

    Colorpicker:OnChanged(function()
        print("Colorpicker changed:", TColorpicker.Value)
    end)

    TColorpicker:OnChanged(function()
        print(
            "TColorpicker changed:", TColorpicker.Value,
            "Transparency:", TColorpicker.Transparency
        )
    end)

    task.spawn(function()
        while true do
            wait(1)
            local state = Keybind:GetState()
            if state then
                print("Keybind is being held down")
            end
            if Main.Unloaded then break end
        end
    end)

end

do

    local InterfaceSection = Tabs.Settings:AddSection("Interface")

    InterfaceSection:AddDropdown("InterfaceTheme", {
        Title = "Theme",
        Description = "Changes the interface theme.",
        Values = Main.Themes,
        Default = Main.Theme,
        Callback = function(Value)
            Main:SetTheme(Value)
        end
    })

    InterfaceSection:AddKeybind("MenuKeybind", { Title = "Minimize Bind", Default = "RightShift" })
    Main.MinimizeKeybind = Main.Options.MenuKeybind

    InterfaceSection:AddButton({
        Title = "Open Library group",
        Description = "Opening a group selects its first child.",
        Callback = function()
            Window:ToggleGroup("Library")
        end
    })

    InterfaceSection:AddButton({
        Title = "Open Account group",
        Callback = function()
            Window:SetGroupOpen("Account", true, true)
        end
    })

    InterfaceSection:AddButton({
        Title = "Preview loading overlay",
        Description = "Centred progress line, two seconds.",
        Callback = function()
            local Loading = Main:ShowLoading({
                Title = "Loading",
                Text = "Preparing example data..."
            })
            task.spawn(function()
                for Step = 1, 20 do
                    Loading:SetProgress(Step / 20)
                    task.wait(0.1)
                end
                Loading:Close()
            end)
        end
    })

    InterfaceSection:AddInput("IslandAvatarUrl", {
        Title = "Island avatar",
        Description = "http(s) image url or rbxassetid://...",
        Default = "https://i.pinimg.com/736x/50/06/db/5006db29533cb3264f1317613ff7be01.jpg",
        Placeholder = "https://...",
    })

    InterfaceSection:AddButton({
        Title = "Set island avatar",
        Callback = function()
            Main.DynamicIsland:SetAvatar(Main.Options.IslandAvatarUrl.Value)
        end
    })

    InterfaceSection:AddInput("IslandName", {
        Title = "Island name",
        Default = "xspww",
        Placeholder = "Name",
    })

    InterfaceSection:AddButton({
        Title = "Set island name",
        Callback = function()
            Main.DynamicIsland:SetName(Main.Options.IslandName.Value)
        end
    })
end

do
    local RecentSection = Tabs.Recent:AddSection("Library")
    RecentSection:AddParagraph({
        Title = "Recent",
        Content = "This tab lives under the Library group header."
    })
    RecentSection:AddButton({
        Title = "Go to Favorites",
        Callback = function()
            Window:SelectTab(Tabs.Favorites.Index)
        end
    })

    local ProfileSection = Tabs.Profile:AddSection("Account")
    ProfileSection:AddParagraph({
        Title = "Profile",
        Content = "Opening Account closes Library and selects this tab."
    })
end

Main:Notify({
    Title = "Fluent",
    Content = "The script has been loaded.",
    Duration = 8
})