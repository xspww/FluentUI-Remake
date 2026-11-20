# 014 — Remove island name truncation and add a measurement margin

- **Status**: DONE
- **Commit**: 942e6d3
- **Severity**: MEDIUM
- **Category**: Craft / correctness
- **Estimated scope**: 1 file, ~4 lines

## Problem

The user's screenshot shows the island name rendered as `xsp...`. Live inspection confirms `NameLabel.TextTruncate = Enum.TextTruncate.AtEnd` is still set from the original fixed-width layout. Even though plan 013 sizes the label from `TextService:GetTextSize(..., Enum.Font.Gotham, ...)`, that font is only an approximation of the visual `FontFace` (Inter via `rbxassetid://12187365364`). A few pixels of under-measurement causes the label to truncate instead of the pill growing.

Current code (`src/Components/DynamicIsland.lua`):

```lua
Island.NameLabel = New("TextLabel", {
    ...
    TextTruncate = Enum.TextTruncate.AtEnd,
    ThemeTag = { TextColor3 = "Text" },
})
```

and in `layout()`:

```lua
local NameWidth = math.ceil(TextService:GetTextSize(
    Island.NameLabel.Text, 12, Enum.Font.Gotham, Vector2.new(9999, 20)).X)
```

## Target

1. Delete the `TextTruncate` line from `NameLabel` so Roblox never draws an ellipsis.
2. Add a small safety margin to the measured widths in `layout()` so the label is always a few pixels wider than the glyphs:

```lua
local NameWidth = math.ceil(TextService:GetTextSize(
    Island.NameLabel.Text, 12, Enum.Font.Gotham, Vector2.new(9999, 20)).X) + 4
local FpsWidth = math.ceil(TextService:GetTextSize(
    Island.FpsLabel.Text, 11, Enum.Font.Gotham, Vector2.new(9999, 20)).X) + 2
```

Everything else in `layout()` (PADDING 10, GAP 8, avatar, dot/glow centring, final `Root.Size`, `task.defer` hooks) stays unchanged.

## Repo conventions to follow

- Keep measuring with `TextService:GetTextSize` + `Enum.Font.Gotham` from plan 013.
- Keep all `ThemeTag` entries and the existing font objects untouched.

## Steps

1. Remove the `TextTruncate` property line from `Island.NameLabel`.
2. Add `+ 4` to the name measurement and `+ 2` to the FPS measurement in `layout()`.
3. Nothing else.

## Boundaries

- Do NOT change the breath, press, FPS cap, avatar or Window.lua fold logic.
- If the code has drifted, STOP and report.

## Verification

- **Mechanical**: selene → 0 errors; tests → 38 passed; build completes.
- **Feel check** (live via MCP Real):
  - default name shows `xspww` in full, no ellipsis;
  - `Island:SetName("a much longer name here")` expands the pill and shows the full text with no `...`;
  - measuring `NameLabel.TextBounds.X <= NameLabel.AbsoluteSize.X` for a long name (text fits inside its label);
  - folding the window still lands on the live island size.
- **Done when**: no configured name ever renders with an ellipsis.
