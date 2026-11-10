<img src="Assets/logodark.png#gh-dark-mode-only" alt="fluent">
<img src="Assets/logolight.png#gh-light-mode-only" alt="fluent">

# Fluent — Remake

A modernized rewrite of [dawid-scripts/Fluent](https://github.com/dawid-scripts/Fluent).

The original library is a great piece of work, but it still carries a few
rough edges: it depends on `syn`, it was written for a mouse only, and several
elements leaked connections, motors or stale state when they were destroyed.
This remake keeps the original look, the original API and the original
structure, and fixes what was broken.

> **Credits** — every part of the design, the element logic and the save
> system comes from the original project and its own credits. This repository
> is a fork of it, not a new library. See [Credits](#-credits).

<br/>

## 📋 What changed

### Core

- **No `syn` dependency.** The library now runs in vanilla Roblox Studio and
  in every modern executor. The UI parent is resolved at runtime: Studio
  uses `PlayerGui`, executors use `gethui()` when it exists, then a writable
  `CoreGui`, and `PlayerGui` as the final fallback.
- **Reliable cleanup.** `Main:Destroy()` disconnects every signal, stops every
  spring motor, clears the theme registry and removes every instance the
  library created. Elements that are destroyed on their own release their
  connections too, so nothing keeps ticking in the background.
- **Input locks.** A library level lock (`LockInput`, `UnlockInput`,
  `IsInputLocked`) stops a drag from triggering anything else at the same time.

### Touch support

- The window can be dragged and resized with a finger.
- The slider, the color picker, the dropdown and the keybind all accept touch
  input, and a touch drag is tracked by its own input object so a second
  finger cannot hijack it.

### Window

- The window is clamped to the visible part of the screen, using
  `GuiService:GetGuiInset()` so it never hides under the Roblox top bar.
- The position is clamped on creation, after a maximize and after a restore.
- The minimize key ignores input while the player is typing in a text box.

### Acrylic

- The blur is projected with the GUI inset applied, so it lines up with the
  window instead of drifting.
- It re-binds when `Workspace.CurrentCamera` changes, for example after a
  respawn, and reacts to `TopbarInset` changes.
- A missing camera is handled instead of erroring, and everything is released
  when the acrylic is destroyed.

### Elements

| Element | Fix |
| --- | --- |
| **Dropdown** | `SetValues()` replaces the list and keeps a valid selection. Multi `SetValue()` accepts a map, an array or a single value. Stale option buttons are removed. The list is clamped to the screen. |
| **Slider** | Uses `InputObject.Position`, which matches `AbsolutePosition` exactly. Zero width and zero range are guarded. Releasing the pointer outside of the dot still ends the drag and releases the input lock. |
| **Colorpicker** | Dragging is event driven and works with mouse and touch. The drag is mapped through the same position logic as the slider. Closing the dialog while dragging no longer leaves the input locked. |
| **Keybind** | Rewritten. It respects `gameProcessedEvent`, ignores input while the player is typing, cancels with `Escape`, validates the key against `Enum.KeyCode` and supports `Toggle`, `Hold` and `Always`. |
| **Input** | Text input is ignored by the global shortcuts while it has focus. |

### Icons

- Every icon is a valid `rbxassetid://` url. The broken Lucide ids were
  replaced and verified against the Roblox thumbnails API.
- The remaining legacy `http://www.roblox.com/asset/?id=` urls were converted
  to the modern format.

### Addons

- Every file call is wrapped in `pcall`, so the addons never throw when the
  executor blocks file access.
- A config is loaded in one pass and the option callbacks fire afterwards, in
  the order they were saved, instead of firing halfway through the load.

### Tooling

- Rojo `7.7.1`, Darklua `0.19.0`, Lune `0.11.1`.
- One command builds everything: `pnpm run bundle`.
- The GitHub Actions workflow uses current action versions and uploads both
  the release assets and the build artifacts.

<br/>

## ⚡ Features

- Modern design
- Many customization options
- Almost any UI element you would ever need
- Mouse and touch support
- Acrylic blur that follows the camera and the GUI inset
- Six built-in themes
- Runs in Roblox Studio and in every modern executor
<br/>

## 🔌 Installation

Load it through a GitHub Release:

```lua
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
```

Or build it yourself, see [Building from source](#-building-from-source).

> If you publish your own release, replace the url above with the one of your
> repository. The same applies to the addon urls further down.
<br/>

## 📜 Quick start

```lua
local Main = require(game:GetService("ReplicatedStorage"):WaitForChild("Fluent"))

local Window = Main:CreateWindow({
    Title = "Fluent " .. Main.Version,
    SubTitle = "by dawid",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
})

local Tab = Window:AddTab({ Title = "Main", Icon = "box" })
local Section = Tab:AddSection("Section")

Section:AddButton({
    Title = "Button",
    Description = "Very important button",
    Callback = function()
        print("Clicked")
    end,
})

Section:AddToggle("Toggle", {
    Title = "Toggle",
    Default = false,
    Callback = function(Value)
        print("Toggle:", Value)
    end,
})
```

A complete example lives in [Example.client.lua](Example.client.lua).
<br/>

## 🧩 API

### Window

| Method | Description |
| --- | --- |
| `Main:CreateWindow(Config)` | Creates the window. `Config = { Title, SubTitle, TabWidth, Size, Acrylic, Theme }`. |
| `Window:AddTab(Config)` | Adds a tab. `Config = { Title, Icon }`. |
| `Window:SelectTab(Index)` | Selects a tab by index. |
| `Window:Dialog(Config)` | Opens a dialog. `Config = { Title, Content, Buttons }`. |
| `Window:Minimize()` | Minimizes the window. |
| `Window:Destroy()` | Destroys the window and every element inside it. |

### Tabs and sections

```lua
local Tab = Window:AddTab({ Title = "Main", Icon = "box" })
local Section = Tab:AddSection("Section")
```

`Tab` and `Section` share the same element methods, so `Tab:AddToggle(...)`
and `Section:AddToggle(...)` behave the same way.

<br/>

### Elements

Most elements are added with a unique name first and a config table second.
The name is the key used by `Main.Options` and by the save manager.

```lua
Section:AddToggle("MyToggle", { Title = "Toggle", Default = false })
```

| Element | Config | Methods |
| --- | --- | --- |
| `AddParagraph(Config)` | `Title`, `Content` | `SetTitle`, `SetDesc`, `Destroy` |
| `AddButton(Config)` | `Title`, `Description`, `Callback` | `SetTitle`, `SetDesc`, `Destroy` |
| `AddToggle(Name, Config)` | `Title`, `Description`, `Default`, `Callback` | `SetValue`, `OnChanged`, `Destroy` |
| `AddSlider(Name, Config)` | `Title`, `Description`, `Default`, `Min`, `Max`, `Rounding`, `Callback` | `SetValue`, `OnChanged`, `Destroy` |
| `AddDropdown(Name, Config)` | `Title`, `Description`, `Values`, `Default`, `Multi`, `AllowNull`, `Callback` | `SetValues`, `SetValue`, `GetActiveValues`, `OnChanged`, `Destroy` |
| `AddColorpicker(Name, Config)` | `Title`, `Description`, `Default`, `Transparency`, `Callback` | `SetValue`, `SetValueRGB`, `OnChanged`, `Destroy` |
| `AddKeybind(Name, Config)` | `Title`, `Description`, `Default`, `Mode`, `Callback`, `ChangedCallback` | `SetValue`, `GetState`, `OnChanged`, `OnClick`, `Destroy` |
| `AddInput(Name, Config)` | `Title`, `Description`, `Default`, `Placeholder`, `Numeric`, `Finished`, `Callback` | `SetValue`, `OnChanged`, `Destroy` |

Notes:

- A single dropdown takes the index or the name of the value. A multi
  dropdown uses a table:

  ```lua
  local Dropdown = Section:AddDropdown("Dropdown", {
      Title = "Dropdown",
      Values = { "one", "two", "three" },
      Multi = true,
      Default = { one = true },
  })

  Dropdown:SetValue({ two = true, three = true })
  Dropdown:SetValue({ "two", "three" })  -- array form
  Dropdown:SetValue("two")               -- single value
  ```

- `Dropdown:SetValues()` replaces the whole list and keeps the current
  selection while the value still exists.
- A keybind accepts the modes `Toggle`, `Hold` and `Always`. `GetState()`
  returns `true` while the key is held down in `Hold` mode.

<br/>

### Library

| Method | Description |
| --- | --- |
| `Main:SetTheme(Name)` | Switches the theme. The available themes are in `Main.Themes`. |
| `Main:ToggleAcrylic(Value)` | Turns the acrylic blur on or off. |
| `Main:ToggleTransparency(Value)` | Turns the background transparency on or off. |
| `Main:Notify(Config)` | Shows a notification. `Config = { Title, Content, SubContent, Duration }`. |
| `Main:GetIcon(Name)` | Returns the `rbxassetid://` url of a Lucide icon. |
| `Main:Round(Number, Factor)` | Rounds a number to the given amount of decimals. |
| `Main:Destroy()` | Unloads the library and removes everything it created. |

Extra properties: `Main.Options`, `Main.Themes`, `Main.Version`,
`Main.MinimizeKey`, `Main.MinimizeKeybind`, `Main.Unloaded`,
`Main.UseAcrylic`, `Main.Acrylic`, `Main.Transparency`.

<br/>

### Input locks

The elements that are dragged, the slider and the color picker, lock the
global input so a drag cannot trigger something else at the same time. The
same mechanism is available for your own code:

```lua
Main:LockInput("MyFeature")   -- block other elements from reacting
Main:IsInputLocked()          -- true while any lock is held
Main:UnlockInput("MyFeature") -- release the lock
```

`Main:IsTyping()` returns `true` while the player is typing into a text box.
Keybinds and the minimize key ignore input while it returns `true`.
<br/>

## 🗂 Addons

Both addons live in the `Addons` folder and only need the library instance.

### Save manager

```lua
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()

SaveManager:SetLibrary(Main)
SaveManager:BuildFolderTree()
SaveManager:BuildConfigSection(Tab)
```

| Method | Description |
| --- | --- |
| `SaveManager:SetLibrary(Main)` | Connects the addon to the library. |
| `SaveManager:SetFolder(Folder)` | Changes the folder used for the configs. |
| `SaveManager:SetIgnoreIndexes(List)` | Indexes that are not written to the config. |
| `SaveManager:IgnoreThemeSettings()` | Ignores the interface settings. |
| `SaveManager:Save(Name)` | Writes a config file. |
| `SaveManager:Load(Name)` | Reads a config file. |
| `SaveManager:LoadAutoloadConfig()` | Loads the config marked as autoload. |
| `SaveManager:RefreshConfigList()` | Rebuilds the list of saved configs. |
| `SaveManager:BuildConfigSection(Tab)` | Adds a section with the config buttons to a tab. |

### Interface manager

```lua
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

InterfaceManager:SetLibrary(Main)
InterfaceManager:BuildFolderTree()
InterfaceManager:BuildInterfaceSection(Tab)
```

| Method | Description |
| --- | --- |
| `InterfaceManager:SetLibrary(Main)` | Connects the addon to the library. |
| `InterfaceManager:SetFolder(Folder)` | Changes the folder used for the settings. |
| `InterfaceManager:SaveSettings()` | Writes the interface settings. |
| `InterfaceManager:LoadSettings()` | Reads the interface settings. |
| `InterfaceManager:BuildInterfaceSection(Tab)` | Adds a section with the settings buttons to a tab. |

Both addons guard every file call, so they never throw when the executor
blocks file access.
<br/>

## 🛠 Building from source

The toolchain is managed by [Aftman](https://github.com/LPGhatguy/aftman):

| Tool | Version |
| --- | --- |
| Rojo | 7.7.1 |
| Darklua | 0.19.0 |
| Lune | 0.11.1 |

```bash
aftman install
pnpm install
pnpm run bundle
```

Aftman installs the tools into `~/.aftman/bin`, so make sure that folder is on
your `PATH` before running the build.

`pnpm run bundle` builds the place model with Rojo and bundles it into a single
Luau file. Both outputs land in the `dist` folder:

| File | Description |
| --- | --- |
| `dist/main.rbxm` | The place model, open it in Studio. |
| `dist/main.lua` | The bundled script, load it through `loadstring`. |

Useful commands:

```bash
pnpm run rojo     # builds only dist/main.rbxm
pnpm run bundle   # builds the model and the bundle
```

<br/>

## 🗂 Project structure

```
src/
  init.lua          Library entry point, GUI parent, input locks, destroy flow
  Creator.lua       Instance factory, theme registry, signal and motor registry
  Icons.lua         Lucide icon urls
  Acrylic/          Blur, paint and the acrylic helpers
  Components/       Window, tab, section, element, dialog, notification, textbox
  Elements/         Toggle, slider, dropdown, colorpicker, keybind, input, ...
  Themes/           Dark, Darker, Light, Aqua, Amethyst, Rose
  Packages/         Flipper, the spring motor library
Addons/             Save manager and interface manager
build/              Lune bundler and the darklua config
```

<br/>

## 📝 Notes

- Acrylic needs graphic quality 8 or higher. It is skipped automatically when
  the blur cannot be created.
- The window can be dragged and resized with a mouse or with touch, and it is
  always clamped to the visible part of the screen.
- `Main:Destroy()` removes every signal, motor and instance the library
  created, so it is safe to call it before loading a new version of a script.
- The library keeps the original API. Code written for the original project
  keeps working, unless it relied on the broken behaviour that this remake
  fixed.
<br/>

## 📄 Credits

- [dawid-scripts/Fluent](https://github.com/dawid-scripts/Fluent) - the
  original project, this is a remake of it
- [richie0866/remote-spy](https://github.com/richie0866/remote-spy) - Assets for the UI, some of the code
- [violin-suzutsuki/LinoriaLib](https://github.com/violin-suzutsuki/LinoriaLib) - Code for most of the elements, save manager
- [7kayoh/Acrylic](https://github.com/7kayoh/Acrylic) - Porting richie0866's acrylic module to lua
- [Latte Softworks & Kotera](https://discord.gg/rMMByr4qas) - Bundler
