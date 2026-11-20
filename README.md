<img src="Assets/logodark.png#gh-dark-mode-only" alt="fluent">
<img src="Assets/logolight.png#gh-light-mode-only" alt="fluent">

# Fluent Remake

A remake of [dawid-scripts/Fluent](https://github.com/dawid-scripts/Fluent). It keeps the element API of the original and adds touch support, grouped navigation and a Dynamic Island toggle.

## Features

The library gives you a window, tabs, sections and the usual elements. It runs in Roblox Studio and in executors.

- Works with a mouse and with touch
- Fixed 635x541 window — resizing and maximizing were removed
- Solid, opaque themes — the acrylic blur and transparency switches were removed
- A Dynamic Island pill toggles the interface; the window morphs into it and back
- Sidebar navigation groups when you have many tabs
- Seven themes, including a navy blue one
- Does not need `syn`

## Install

Load the release file. The url works after the first release is published.

```lua
local Fluent = loadstring(game:HttpGet("https://github.com/xspww/FluentUI-Remake/releases/latest/download/main.lua"))()
```

The addons are optional. Load them from raw GitHub when you use them.

```lua
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/xspww/FluentUI-Remake/main/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/xspww/FluentUI-Remake/main/Addons/InterfaceManager.lua"))()
```

## Usage

A window holds tabs. A tab holds sections. A section holds the elements.

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

Pass `Group` to `AddTab` to place a tab under a section header. The header only opens its group; it never changes the page. Only one group is open at a time. Opening another group selects its first child, and selecting a flat tab closes the group.

```lua
Window:AddTab({ Title = "Main", Icon = "box" })
Window:AddTab({ Title = "Child one", Icon = "box", Group = "Section A", GroupIcon = "layers" })
Window:AddTab({ Title = "Child two", Icon = "box", Group = "Section A" })

Window:SetGroupOpen("Section A", true, true) -- name, open, animated
Window:ToggleGroup("Section A")              -- opens the group
```

Child rows are indented, have no chevron or badge and do not react to hover. The selected row is marked by the existing selector bar.

## Dynamic Island

A small pill sits at the top centre of the screen. Tapping it toggles the interface: the window shrinks into the pill on close, and the pill expands back into the window on open. The folded window tracks the pill's live position. The pill shows an avatar, a name, a breathing status dot and the real frame rate measured over a 5-second window; the raw value is also on `Fluent.DynamicIsland.RawFps`. Set `IslandAvatar` and `IslandName` in `CreateWindow`, or call `Fluent.DynamicIsland:SetAvatar(image)` / `:SetName(text)` later. `IslandAvatar` accepts an `rbxassetid://` id or any `http(s)://` image URL — on executors with `request`, `writefile` and `getcustomasset`, the URL is fetched and converted to an `rbxasset://` content id. Set `DynamicIsland = false` to disable it.

An interactive HTML mock of the sidebar is in [preview/sidebar-groups.html](preview/sidebar-groups.html). The design notes are in [plans/](plans/).

## API

Call these functions on the library.

- `CreateWindow(Config)` creates the window. The library holds one window. `Config` takes `Title`, `SubTitle`, `Theme`, `MinimizeKey`, `DynamicIsland`, `IslandName` and `IslandAvatar` (an image id or `rbxassetid://` url). The window size is fixed at 635x541.
- `SetTheme(Name)` changes the theme. The names are in `Main.Themes`. An unknown name is ignored.
- `Notify(Config)` shows a notification.
- `GetIcon(Name)` returns the url of a Lucide icon.
- `Destroy()` removes the window, the elements and the signals.

Call these functions on a window.

- `AddTab(Config)` adds a tab. `Config` takes `Title`, `Icon` and, for grouped tabs, `Group` and `GroupIcon`.
- `SelectTab(Index)` shows a tab.
- `SetGroupOpen(Name, Open, Animated)` opens or closes a navigation group.
- `ToggleGroup(Name)` opens a navigation group.
- `SetNavQuery(Text)` filters the sidebar rows by title. The search field in the title bar drives it.
- `Dialog(Config)` opens a dialog.
- `Minimize()` hides the window. The island toggle is animated; the keybind is instant.

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

A dropdown has a search field at the top of its list. Type to filter the options; `Enter` selects the first match and `Esc` closes the list. This works for both single and multi select, and shows "No results" when nothing matches.

A dropdown with `Multi = true` takes a table. You can pass a map, an array or one value.

```lua
Dropdown:SetValue({ two = true, three = true })
Dropdown:SetValue({ "two", "three" })
Dropdown:SetValue("two")
```

## Addons

The addons write your settings to the file system of the executor. Each addon needs the library first. `BuildConfigSection` and `BuildInterfaceSection` take a tab. They add a section to that tab.

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

Install the tools and build the files.

```bash
aftman install
pnpm install
pnpm run bundle
```

Aftman installs Rojo, Darklua, Lune and Selene. Make sure that `~/.aftman/bin` is in your `PATH`.

The build writes two files to the `dist` folder.

- `dist/main.rbxm` is the place model. Open it in Studio.
- `dist/main.lua` is the bundled script. Load it with `loadstring`.

Run `pnpm run rojo` when you only want the place model.

## Tests

The specs live in the `spec` folder. Run them with Lune.

```bash
pnpm run test
```

The specs use the same `describe`, `it` and `expect` functions as the tests of the original Flipper library, so they also run in Roblox Studio.

Run the linter with Selene.

```bash
pnpm run lint
```

## Credits

This remake keeps the credits of the original project. The list below names every source that the design and the code come from. Thank you to the people who wrote the original library.

- [dawid-scripts/Fluent](https://github.com/dawid-scripts/Fluent), the original project
- [richie0866/remote-spy](https://github.com/richie0866/remote-spy), the UI assets
- [violin-suzutsuki/LinoriaLib](https://github.com/violin-suzutsuki/LinoriaLib), the elements and the save manager
- [Latte Softworks & Kotera](https://discord.gg/rMMByr4qas), the bundler
