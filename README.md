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

Call these functions on the library.

- `CreateWindow(Config)` creates the window. The library holds one window. The configuration table takes `Title`, `SubTitle`, `Theme`, `MinimizeKey`, `TabWidth`, `DynamicIsland`, `IslandName`, `IslandAvatar` and `Loading`. The window size is fixed at 635 by 541.
- `SetTheme(Name)` changes the theme. The theme names are in `Fluent.Themes`. The library ignores an unknown name.
- `Notify(Config)` shows a notification.
- `ShowLoading(Config)` shows the centered loading overlay and returns a handle. The configuration table takes `Title`, `Text`, `Progress`, `MinDuration`, `Timeout`, `Parent` and `ReducedMotion`. The handle has `SetProgress`, `SetIndeterminate`, `SetText`, `SetTitle`, `Close` and `Destroy`.
- `HideLoading()` closes the overlay.
- `FinishLoading()` closes the overlay after its minimum display time.
- `SetLoadingProgress(Value)` and `SetLoadingText(Text)` update the live overlay.
- `GetIcon(Name)` returns the URL of a Lucide icon.
- `Destroy()` removes the window, the elements and the signals.

Call these functions on a window.

- `AddTab(Config)` adds a tab. The configuration table takes `Title` and `Icon`. A grouped tab also takes `Group` and `GroupIcon`.
- `SelectTab(Index)` shows a tab.
- `SetGroupOpen(Name, Open, Animated)` opens or closes a navigation group.
- `ToggleGroup(Name)` opens a navigation group.
- `SetNavQuery(Text)` filters the sidebar rows by title. The search field in the title bar drives it.
- `Dialog(Config)` opens a dialog.
- `Minimize()` hides the window. The island toggle is animated. The keybind is instant.

Call these functions on a tab or on a section to add an element. Most elements take a name and a settings table.

- `AddButton(Config)`
- `AddParagraph(Config)`
- `AddToggle(Name, Config)`
- `AddSlider(Name, Config)`
- `AddDropdown(Name, Config)`
- `AddColorpicker(Name, Config)`
- `AddKeybind(Name, Config)`
- `AddInput(Name, Config)`

Most elements have `SetValue`, `OnChanged` and `Destroy`. A dropdown also has `SetValues` and `GetActiveValues`. A keybind also has `GetState`.

A dropdown has a search field at the top of its list. Type to filter the options. `Enter` selects the first match. `Esc` closes the list. This works for single select and for multi select. When nothing matches, the list shows `No results`.

A dropdown with `Multi = true` takes a table. You can pass a map, an array or one value.

```lua
Dropdown:SetValue({ two = true, three = true })
Dropdown:SetValue({ "two", "three" })
Dropdown:SetValue("two")
```

## Addons

The addons write your settings to the file system of the executor. Each addon needs the library first. `BuildConfigSection` and `BuildInterfaceSection` take a tab. Each call adds a section to that tab.

```lua
SaveManager:SetLibrary(Fluent)
SaveManager:BuildFolderTree()
SaveManager:BuildConfigSection(Tab)

InterfaceManager:SetLibrary(Fluent)
InterfaceManager:BuildFolderTree()
InterfaceManager:BuildInterfaceSection(Tab)
```

The save manager keeps every saved file under one folder. The interface manager keeps the theme and the minimize key.

## Build

Install the tools. Build the files.

```bash
aftman install
pnpm install
pnpm run bundle
```

Aftman installs Rojo, Darklua, Lune and Selene. Make sure that `~/.aftman/bin` is in your `PATH`.

The build writes two files to the `dist` folder.

- `dist/main.rbxm` is the place model. Open it in Studio.
- `dist/main.lua` is the bundled script. Load it with `loadstring`.

When you only want the place model, run `pnpm run rojo`.

## Tests

The specs live in the `spec` folder. Run them with Lune.

```bash
pnpm run test
```

The specs use the same `describe`, `it` and `expect` functions as the tests of the original Flipper library. You can also run them in Roblox Studio.

Run the linter with Selene.

```bash
pnpm run lint
```

## Credits

This remake keeps the credits of the original project.

- [dawid-scripts/Fluent](https://github.com/dawid-scripts/Fluent), the original project
- [richie0866/remote-spy](https://github.com/richie0866/remote-spy), the UI assets
- [violin-suzutsuki/LinoriaLib](https://github.com/violin-suzutsuki/LinoriaLib), the elements and the save manager
- [Latte Softworks & Kotera](https://discord.gg/rMMByr4qas), the bundler
