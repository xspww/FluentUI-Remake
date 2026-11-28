<img src="Assets/logodark.png#gh-dark-mode-only" alt="fluent">
<img src="Assets/logolight.png#gh-light-mode-only" alt="fluent">

# Fluent Remake

This library remakes [dawid-scripts/Fluent](https://github.com/dawid-scripts/Fluent). It keeps the element API of the original. It adds touch support, grouped navigation and a Dynamic Island.

## Install

Load the release file.

```lua
local Fluent = loadstring(game:HttpGet("https://github.com/xspww/FluentUI-Remake/releases/latest/download/main.lua"))()
```

The addons are optional. Load each addon from raw GitHub before you use it.

```lua
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/xspww/FluentUI-Remake/main/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/xspww/FluentUI-Remake/main/Addons/InterfaceManager.lua"))()
```

## Usage

A window holds tabs. A tab holds sections. A section holds elements.

```lua
local Window = Fluent:CreateWindow({
    Title = "Fluent",
    SubTitle = "Remake",
    Theme = "Dark",
})

local Tab = Window:AddTab({ Title = "Main", Icon = "box" })
local Section = Tab:AddSection("Section")

Section:AddButton({
    Title = "Button",
    Callback = function()
        print("clicked")
    end,
})

Section:AddToggle("MyToggle", {
    Title = "Toggle",
    Default = false,
    Callback = function(Value)
        print(Value)
    end,
})
```

The name before the settings table is the key. The save manager uses the key to find the element again.

The full example is in [Example.client.lua](Example.client.lua).

## Navigation groups

Pass `Group` to `AddTab` to put a tab under a header. The header opens its group. The header does not change the page. Only one group stays open at a time.

```lua
Window:AddTab({ Title = "Main", Icon = "box" })
Window:AddTab({ Title = "Child one", Icon = "box", Group = "Section A", GroupIcon = "layers" })
Window:AddTab({ Title = "Child two", Icon = "box", Group = "Section A" })

Window:SetGroupOpen("Section A", true, true) -- name, open, animated
Window:ToggleGroup("Section A")              -- opens the group
```

When you reopen a group, the library selects the child that you last selected in that group. If you have not selected a child there, it selects the first child. A grouped tab shows a breadcrumb with the form `Group > Tab`.

Child rows are indented. They have no chevron and no badge. They do not react to hover. The selector bar marks the selected row.

## Dynamic Island

A small pill sits at the top center of the screen. Tap the pill to toggle the interface. When you close the interface, the window shrinks into the pill. When you open it, the pill expands back into the window. The folded window follows the live position of the pill.

The pill shows an avatar, a name, a breathing status dot and the frame rate. The library measures the frame rate over a five-second window. The raw value is also at `Fluent.DynamicIsland.RawFps`.

Set `IslandName` and `IslandAvatar` in the window configuration. You can also call the island methods later.

- `SetName(Text)` changes the name.
- `SetAvatar(Image)` accepts an `rbxassetid://` id or an `http(s)://` image URL. With `request`, `writefile` and `getcustomasset` on the executor, the library fetches the URL and converts it to an `rbxasset://` content id.
- `SetText(Text)` pins any readout text and stops the automatic update. `SetText(nil)` resumes the frame rate.
- `SetFpsFormat(Function)` shapes the automatic text. The function takes the raw value and the rounded value. Pass `nil` to restore the default format.
- `SetStat(Text)` and `ResetStat()` are aliases of `SetText`.
- `RefreshAvatar()` resolves the avatar URL again.

To disable the pill, set `DynamicIsland = false` in the window configuration.

## Loading overlay

The library shows a centered panel with one progress line while it builds the interface. The window and the pill stay hidden until loading finishes. The panel sits over the game. It has no dark full-screen background.

### Automatic splash

`CreateWindow` shows the splash by default. When you add the first element, the library closes the splash. A minimum display time stops a single-frame flash. If you add no element, a safety timeout closes the splash.

Pass a table to change the copy and the timings.

```lua
local Window = Fluent:CreateWindow({
    Title = "Fluent",
    Loading = {
        Title = "Starting",
        Text = "Building the interface...",
        MinDuration = 0.6, -- at least 0.6s on screen
        Timeout = 15,      -- default 8s
    },
})
```

To turn the splash off, set `Loading = false`.

### Manual loading

Use manual loading for work that your script performs. Your script passes the percentage to `SetProgress`. The library does not measure progress for you. Omit `Progress` for an indeterminate sweep.

```lua
local Loading = Fluent:ShowLoading({
    Title = "Loading",
    Text = "Starting...",
    Timeout = 30,
})

for i, work in ipairs(steps) do
    Loading:SetText(("Working %d/%d"):format(i, #steps))
    work()
    Loading:SetProgress(i / #steps)
end

Loading:Close() -- or Fluent:HideLoading()
```

`ShowLoading` returns a handle.

- `SetProgress(Value)` moves the bar from 0 to 1 and updates the percentage.
- `SetIndeterminate(true)` switches to the linear sweep.
- `SetText(Text)` and `SetTitle(Text)` change the copy.
- `Close()` fades out and removes the panel. `Destroy()` removes the panel at once.

If the panel is open, another call to `ShowLoading` updates that panel. The library does not stack two panels.

The library also has these helpers for the open panel.

- `Fluent:SetLoadingProgress(Value)` updates the bar.
- `Fluent:SetLoadingText(Text)` updates the copy.
- `Fluent:FinishLoading()` closes the panel after its minimum display time.
- `Fluent:HideLoading()` closes the panel at once.

The animation uses critically damped springs. It starts at scale 0.97, not at zero. It exits along the path that it entered. To drop movement and keep only the fade, set `Fluent.ReducedMotion = true` or pass `ReducedMotion = true` to `ShowLoading`.

## API

Each row names one receiver and one method. The library sets `getgenv().Fluent` to the library table. Public fields include `Version`, `Options`, `Themes`, `Theme`, `Unloaded`, `ReducedMotion`, `NotificationLimit`, `MinimizeKeybind` and `DynamicIsland`. `CreateWindow` accepts one window per library instance. `Config.Size` has no effect. The window is fixed at 635 by 541 pixels.

### Library

| Method | Behavior |
| --- | --- |
| `CreateWindow(Config)` | Creates the window. `Config` takes `Title`, `SubTitle`, `Theme`, `MinimizeKey`, `TabWidth`, `DynamicIsland`, `IslandName`, `IslandAvatar` and `Loading`. |
| `SetTheme(Name)` | Changes the theme. Names are in `Fluent.Themes`. An unknown name leaves the theme unchanged. |
| `Notify(Config)` | Shows a notification and returns a handle. `Config` takes `Title`, `Content`, `SubContent`, `Duration` and `MaxNotifications`. |
| `ShowLoading(Config)` | Shows the loading panel and returns a handle. A second call updates the open panel. `Config` takes `Title`, `Text`, `Progress`, `MinDuration`, `Timeout`, `Parent`, `ReducedMotion` and `Auto`. |
| `HideLoading()` | Closes the open panel. |
| `FinishLoading()` | Closes the open panel after its minimum display time. |
| `SetLoadingProgress(Value)` | Updates the bar of the open panel. |
| `SetLoadingText(Text)` | Updates the text of the open panel. |
| `GetIcon(Name)` | Returns the URL of a Lucide icon. It returns nil for an unknown name. |
| `Destroy()` | Removes the window, the elements and the signals. |
| `LockInput(Name)` | Adds a named input lock. `Name` defaults to `default`. |
| `UnlockInput(Name)` | Removes the named input lock. |
| `IsInputLocked()` | Returns true when any input lock is set. |
| `IsTyping()` | Returns true when a text box has focus. |
| `SafeCallback(Function, ...)` | Calls a callback and shows a notification when it raises an error. It does nothing while a config is loading. |
| `Round(Number, Factor)` | Rounds a number. `Factor` sets the decimal places and defaults to 0. |

### Window

| Method | Behavior |
| --- | --- |
| `AddTab(Config)` | Adds a tab. `Config` takes `Title` and `Icon`. A grouped tab also takes `Group` and `GroupIcon`. |
| `SelectTab(Index)` | Selects the tab with that numeric index. |
| `SetGroupOpen(Name, Open, Animated)` | Opens or closes a navigation group. |
| `ToggleGroup(Name)` | Opens a navigation group. |
| `SetSearchQuery(Query)` | Finds elements by title and description and shows the matches under the title bar. |
| `SetNavQuery(Query)` | Calls `SetSearchQuery`. Existing scripts can keep this name. |
| `FindElements(Query)` | Returns result tables for the elements that match the query. |
| `RevealElement(Result)` | Selects the tab of a result and scrolls to the element. |
| `Dialog(Config)` | Opens a dialog. |
| `Minimize(Silent, Animated)` | Toggles the window between the open size and the island pill. `Silent` suppresses the hint notification. `Animated` uses springs. |
| `SetHidden(Hidden)` | Hides or shows the window without changing the minimized state. |
| `Destroy()` | Removes the window and its signals. |

`SetGroupOpen` does not change the page. `ToggleGroup` only opens a group.

### Tab and section

| Method | Behavior |
| --- | --- |
| `AddSection(SectionTitle)` | Adds a section to a tab and returns it. |
| `AddButton(Config)` | Adds a button. |
| `AddParagraph(Config)` | Adds a paragraph. |
| `AddToggle(Name, Config)` | Adds a toggle. |
| `AddSlider(Name, Config)` | Adds a slider. |
| `AddDropdown(Name, Config)` | Adds a dropdown. |
| `AddColorpicker(Name, Config)` | Adds a colorpicker. |
| `AddKeybind(Name, Config)` | Adds a keybind. |
| `AddInput(Name, Config)` | Adds an input. |

`AddButton` and `AddParagraph` take only `Config` because they have no name key. The other six take `Name` and store the element in `Fluent.Options` under that name. A tab and a section accept the same eight constructors.

### Elements

`Button` and `Paragraph` have `SetTitle`, `SetDesc` and `Destroy`. `Toggle`, `Slider`, `Dropdown`, `Colorpicker`, `Keybind` and `Input` have `SetValue`, `OnChanged` and `Destroy`. All elements have `SetTitle` and `SetDesc`. `OnChanged` fires immediately with the current value.

| Method | Receiver | Behavior |
| --- | --- | --- |
| `SetTitle(Text)` | All elements | Changes the title label. |
| `SetDesc(Text)` | All elements | Changes the description label. An empty string hides it. |
| `Destroy()` | All elements | Removes the element. |
| `SetValue(Value)` | Toggle, Slider, Dropdown, Colorpicker, Keybind, Input | Sets the value. |
| `OnChanged(Callback)` | Toggle, Slider, Dropdown, Colorpicker, Keybind, Input | Registers a callback for value changes. |
| `SetValue(HSV, Transparency)` | Colorpicker | Takes an array of hue, saturation and value. |
| `SetValueRGB(Color, Transparency)` | Colorpicker | Takes a Color3. |
| `Open()` | Dropdown | Opens the option list. |
| `Close()` | Dropdown | Closes the option list. |
| `Display()` | Dropdown | Refreshes the displayed selection. |
| `BuildDropdownList()` | Dropdown | Rebuilds the option buttons. |
| `SetValues(Values)` | Dropdown | Replaces the options. |
| `GetActiveValues()` | Dropdown | Returns an array when `Multi` is true. It returns 1 or 0 for single select. |
| `SetValue(Key, Mode)` | Keybind | Sets the key and the mode. |
| `OnClick(Callback)` | Keybind | Registers the click callback. |
| `DoClick()` | Keybind | Fires the callback and the click callback. |
| `GetState()` | Keybind | Returns the current state. |

`Input` takes `Numeric`, `Finished`, `Placeholder` and `MaxLength`. `Numeric` accepts numbers only. `Finished` fires the callback on Enter. `Placeholder` sets the placeholder text. `MaxLength` truncates the text. `Dropdown` takes `AllowNull`. `AllowNull` lets the last selected option be cleared.

A dropdown with `Multi = true` takes a table. You can pass a map, an array or one value.

```lua
Dropdown:SetValue({ two = true, three = true })
Dropdown:SetValue({ "two", "three" })
Dropdown:SetValue("two")
```

A dropdown has a search field at the top of its list. `Enter` selects the first match. `Esc` closes the list. The list shows `No results` when nothing matches.

### Loading handle

`ShowLoading` returns this handle. The library reads `ReducedMotion` when it creates the panel.

| Method | Behavior |
| --- | --- |
| `SetProgress(Value)` | Moves the bar from 0 to 1. |
| `SetIndeterminate(Value)` | Switches to the linear sweep. |
| `SetText(Text)` | Changes the body text. |
| `SetTitle(Text)` | Changes the title. |
| `Close()` | Fades out and removes the panel. |
| `Destroy()` | Removes the panel at once. |
| `GetProgress()` | Returns the current progress. |
| `GetMinDuration()` | Returns the minimum display time. |
| `GetElapsed()` | Returns the seconds since the panel was created. |

### Dynamic island

| Method | Behavior |
| --- | --- |
| `SetName(Name)` | Changes the name. |
| `SetAvatar(Image)` | Accepts an `rbxassetid://` id or an `http(s)://` URL. |
| `SetText(Text)` | Pins the readout text. `nil` resumes the frame rate. |
| `SetFpsFormat(Format)` | Shapes the automatic text with the raw and rounded values. `nil` restores the default. |
| `SetStat(Text)` | Calls `SetText`. |
| `ResetStat()` | Calls `SetText(nil)`. |
| `RefreshAvatar()` | Resolves the avatar URL again. |
| `Destroy()` | Removes the island and its signals. |

`SetText`, `SetFpsFormat`, `SetStat` and `ResetStat` return the island for chaining.

### Notification

`Notify` returns a handle with `Open`, `Close`, `Destroy` and `RemoveFromActive`. `Open` animates the notification in. `Close` animates it out and destroys it. `Destroy` removes it at once. `RemoveFromActive` drops it from the active list.

## Addons

The addons write your settings to the file system of the executor. Each addon needs the library first. `BuildConfigSection` and `BuildInterfaceSection` take a tab. Each call adds a section to that tab.

| Receiver | Method | Behavior |
| --- | --- | --- |
| Both | `SetLibrary(Library)` | Hands the library to the addon. |
| Both | `BuildFolderTree()` | Creates the settings folders. |
| SaveManager | `BuildConfigSection(Tab)` | Adds the configuration section to a tab. |
| InterfaceManager | `BuildInterfaceSection(Tab)` | Adds the interface section to a tab. |
| SaveManager | `SetFolder(Folder)` | Sets the root folder. |
| SaveManager | `SetIgnoreIndexes(List)` | Skips the listed element keys when saving. |
| SaveManager | `IgnoreThemeSettings()` | Skips `InterfaceTheme` and `MenuKeybind`. |
| SaveManager | `Save(Name)` | Writes a config file. |
| SaveManager | `Load(Name)` | Reads a config file. |
| SaveManager | `RefreshConfigList()` | Returns the names of the config files. |
| SaveManager | `LoadAutoloadConfig()` | Loads the config named in `autoload.txt`. |
| InterfaceManager | `SetFolder(Folder)` | Sets the root folder. |
| InterfaceManager | `SaveSettings()` | Writes `options.json`. |
| InterfaceManager | `LoadSettings()` | Reads `options.json`. |

```lua
SaveManager:SetLibrary(Fluent)
SaveManager:BuildFolderTree()
SaveManager:BuildConfigSection(Tab)

InterfaceManager:SetLibrary(Fluent)
InterfaceManager:BuildFolderTree()
InterfaceManager:BuildInterfaceSection(Tab)
```

The save manager keeps every saved file under one folder. The interface manager keeps the theme and the minimize key.

## Build and verify

Install the tools with `aftman install`. Aftman installs Rojo, Darklua, Lune and Selene. `pnpm` is not on the PATH.

Run the specs, the linter and the bundle from PowerShell.

```powershell
$env:PATH = "$env:USERPROFILE\.aftman\bin;$env:PATH"
lune.exe run spec/run.luau
selene.exe src --config selene.toml
lune.exe run build/init
```

The specs use the same `describe`, `it` and `expect` functions as the tests of the original Flipper library. You can also run them in Roblox Studio.

The build writes two files to the `dist` folder.

- `dist/main.rbxm` is the place model. Open it in Studio.
- `dist/main.lua` is the bundled script. Load it with `loadstring`.

## Credits

This remake keeps the credits of the original project.

- [dawid-scripts/Fluent](https://github.com/dawid-scripts/Fluent), the original project
- [richie0866/remote-spy](https://github.com/richie0866/remote-spy), the UI assets
- [violin-suzutsuki/LinoriaLib](https://github.com/violin-suzutsuki/LinoriaLib), the elements and the save manager
- [Latte Softworks & Kotera](https://discord.gg/rMMByr4qas), the bundler
