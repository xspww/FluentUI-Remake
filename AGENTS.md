# Agent notes for FluentUI-Remake

Goal. Keep the library API compatible with the original Fluent while preserving the remake's fixed size, grouped navigation, Dynamic Island and loading overlay.

## Read first

- `README.md` is the public API reference.
- `src/init.lua` owns `Library`, `CreateWindow`, themes, loading overlay and notifications.
- `src/Components/Window.lua` owns window size, drag, clamp and the island morph.
- `src/Components/Tab.lua` owns tabs, groups, selection, nav filtering and the breadcrumb.
- `src/Components/DynamicIsland.lua` owns the pill, FPS measurement and the blur text scroller.
- `Addons/` holds SaveManager and InterfaceManager. Each addon needs `SetLibrary` before its `Build...Section` call.

## Build and verify

Use PowerShell. `pnpm` is not on PATH in this environment.

```powershell
$env:PATH = "$env:USERPROFILE\.aftman\bin;$env:PATH"
lune.exe run spec/run.luau
selene.exe src --config selene.toml
lune.exe run build/init
```

`dist/main.lua` is the bundled library. `dist/main.rbxm` is the place model. Both are gitignored.

## Live run recipe

1. Rebuild with `lune.exe run build/init`.
2. Copy `dist/main.lua` into `C:\Users\Administrator\AppData\Local\Real\workspace`.
3. Inject Real into the Roblox client, then load in ONE eval chunk. Keep the returned `Library` local.
4. Call `Window:SelectTab(1)` after all tabs are added. Call it again after grouped tabs finish opening if a grouped child keeps taking selection.
5. Use `eval`, not fire-and-forget `execute`, for UI setup.

The executor can only read files inside its workspace. Custom avatar URLs need `request`, `writefile` and `getcustomasset`; the resulting asset id is session-scoped.

## Code style

- Tabs for indentation. PascalCase for locals.
- Use `Creator.New` for instances and `Creator.AddSignal` for connections.
- Theme colours go through `ThemeTag` or `Creator.GetThemeProperty`.
- Keep comments for non-obvious reasons only.
- Do not commit unless the user asks.

## Known constraints and gotchas

- The window is fixed at 635x541. `Config.Size` has no effect.
- One window per Library instance. `getgenv().Fluent` is set globally.
- AddTab does not select a tab automatically. Containers start hidden.
- Group headers open a group but do not change the page. Reopening a group returns to the last selected child in that group.
- Breadcrumbs show `Group > Tab` for grouped children and use RichText. Theme changes refresh them through `Creator.AddThemeCallback`.
- Tab labels shrink from size 12 to a floor of 10, then use ellipsis. Group headers use the same rule.
- Every text instance uses the built-in `rbxasset://fonts/families/GothamSSm.json` family. Do not reintroduce `rbxassetid://12187365364` or `Enum.Font.SourceSans`.
- The FPS readout is measured over a 5s Heartbeat window. It uses a clipped viewport with one sharp label and four ghost labels for the blur scroll.
- `Island:SetText(Text)` pins arbitrary readout text and stops automatic overwrite. `SetText(nil)` resumes FPS. `SetFpsFormat(fn)` shapes the auto string as `fn(RawFps, RoundedFps)`. `SetStat` and `ResetStat` are aliases.
- Window clamp is instant. It runs at startup, on viewport and camera changes, and when a drag ends. Do not add easing to the automatic correction.
- ReducedMotion changes text instantly for FPS and keeps only the fade for the loading overlay.
- `SaveManager` uses executor file APIs and will not work in plain Studio.
- The specs cover Flipper, SaveManager, Themes and a reimplementation of tab selection. They do not cover rendering, Loading, DynamicIsland or InterfaceManager. Live verification is required for UI changes.
