<img src="Assets/logodark.png#gh-dark-mode-only" alt="fluent">
<img src="Assets/logolight.png#gh-light-mode-only" alt="fluent">

# Fluent Remake

A remake of [dawid-scripts/Fluent](https://github.com/dawid-scripts/Fluent). It keeps the same design and the same API. It fixes the faults of the original and adds touch support.

## Features

The library gives you a window, tabs, sections and the usual elements. It runs in Roblox Studio and in executors. The API is the same as the original.

- Works with a mouse and with touch
- Acrylic blur behind the window
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
    Size = UDim2.fromOffset(580, 460),
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

## API

Call these functions on the library.

- `CreateWindow(Config)` creates the window. The library holds one window.
- `SetTheme(Name)` changes the theme. The names are in `Main.Themes`. An unknown name is ignored.
- `ToggleAcrylic(Value)` turns the blur on or off.
- `ToggleTransparency(Value)` turns the background transparency on or off.
- `Notify(Config)` shows a notification.
- `GetIcon(Name)` returns the url of a Lucide icon.
- `Destroy()` removes the window, the elements and the signals.

Call these functions on a window.

- `AddTab(Config)` adds a tab with a `Title` and an `Icon`.
- `SelectTab(Index)` shows a tab.
- `Dialog(Config)` opens a dialog.
- `Minimize()` hides the window.

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

The save manager keeps every saved file under one folder. The interface manager keeps the theme, the acrylic switch and the minimize key.

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
- [7kayoh/Acrylic](https://github.com/7kayoh/Acrylic), the acrylic module
- [Latte Softworks & Kotera](https://discord.gg/rMMByr4qas), the bundler
