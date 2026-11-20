# 013 — Measure island text with TextService instead of TextBounds

- **Status**: DONE
- **Commit**: 942e6d3
- **Severity**: MEDIUM
- **Category**: Craft / correctness
- **Estimated scope**: 1 file, ~6 lines

## Problem

Plan 012 sizes the island pill from `NameLabel.TextBounds.X`. Live test shows this is circular: once the label is narrowed to the measured width, `TextBounds` reports that narrowed width instead of the text's natural width. After `SetName("a much longer name here")` the label still reads 35px and the pill stays ~134px.

`TextService:GetTextSize` with an `Enum.Font` works synchronously. Verified on client 16020: `GetTextSize("xspww", 12, Enum.Font.Gotham, ...)` returns 36.0 vs the real custom-font measurement 35 — close enough to size the pill without gaps. Attempting to pass the `FontFace` object fails (`Unable to cast Font to Font`).

## Target

In `src/Components/DynamicIsland.lua`, add at module scope:

```lua
local TextService = game:GetService("TextService")
```

Replace the two measurements in `layout()`:

```lua
local NameWidth = math.ceil(TextService:GetTextSize(
    Island.NameLabel.Text, 12, Enum.Font.Gotham, Vector2.new(9999, 20)).X)
local FpsWidth = math.ceil(TextService:GetTextSize(
    Island.FpsLabel.Text, 11, Enum.Font.Gotham, Vector2.new(9999, 20)).X)
```

Everything else in `layout()` — PADDING 10, GAP 8, avatar at x=8, dot centre = glow centre, final `Root.Size = UDim2.fromOffset(X, PILL_HEIGHT)`, `task.defer(layout)` hooks in `SetName` / FPS tick / construction — stays unchanged.

## Repo conventions to follow

- Services are fetched with `game:GetService` at module top (already done for `RunService`, `Players`).
- Use `Enum.Font.Gotham` for measurement only; visual `FontFace` objects remain untouched.

## Steps

1. Add `local TextService = game:GetService("TextService")` near the existing service declarations.
2. Replace the two `TextBounds.X` reads in `layout()` with the `GetTextSize` calls above.
3. Nothing else.

## Boundaries

- Do NOT change the font objects on the labels, gap constants, press/breath/FPS logic, or Window.lua.
- If the excerpt has drifted, STOP and report.

## Verification

- **Mechanical**: selene → 0 errors; tests → 38 passed; build completes.
- **Feel check** (live via MCP Real):
  - default `xspww` pill is compact (~130–140px) with no visible gap;
  - `Island:SetName("a much longer name here")` widens the pill to ~220px and the FPS label shifts right with even 8px gaps;
  - setting back to `xspww` shrinks it again;
  - folding the window still lands on the live island size.
- **Done when**: pill width visibly tracks the configured name in both directions.
