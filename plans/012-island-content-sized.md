# 012 — Size the island pill to its content

- **Status**: DONE
- **Commit**: 942e6d3
- **Severity**: MEDIUM
- **Category**: Craft / spatial consistency
- **Estimated scope**: 2 files (~45 lines)

## Problem

The pill is fixed at **190x34** while `NameLabel` is fixed at **76px**. A short name leaves empty space between the name and the status dot; changing the name never changes the pill. The user wants the pill to grow/shrink horizontally to fit its content with no gaps.

Current layout (`src/Components/DynamicIsland.lua`):

```lua
local PILL_WIDTH = 190
...
Island.NameLabel = New("TextLabel", { ..., Size = UDim2.fromOffset(76, 20), Position = UDim2.new(0, 38, 0.5, 0), ... })
Island.DotGlow = ... Position = UDim2.new(0, 124, 0.5, 0)
Island.Dot = ... Position = UDim2.new(0, 121, 0.5, 0)
Island.FpsLabel = ... Size = UDim2.fromOffset(46, 20), Position = UDim2.new(0, 136, 0.5, 0)
```

`src/Components/Window.lua` also hard-codes the folded target:

```lua
local PILL_SIZE = Vector2.new(190, 34) -- must match DynamicIsland.lua
...
local GoalWidth = Closing and PILL_SIZE.X or OPEN_SIZE.X
local WidthProgress = math.clamp((Width - PILL_SIZE.X)/(OPEN_SIZE.X - PILL_SIZE.X), 0, 1)
```

## Target

### DynamicIsland.lua

Keep the avatar at `x=8` (22px). Add a `layout()` function that sizes the text labels from their own `TextBounds` and packs every element with fixed 8px gaps:

```lua
local PADDING, GAP = 10, 8

local function layout()
    local NameWidth = math.ceil(Island.NameLabel.TextBounds.X)
    local FpsWidth = math.ceil(Island.FpsLabel.TextBounds.X)

    Island.NameLabel.Size = UDim2.fromOffset(NameWidth, 20)
    Island.FpsLabel.Size = UDim2.fromOffset(FpsWidth, 20)

    local X = PADDING + 22 + GAP                 -- after avatar
    Island.NameLabel.Position = UDim2.new(0, X, 0.5, 0)
    Island.NameLabel.AnchorPoint = Vector2.new(0, 0.5)
    X = X + NameWidth + GAP

    Island.Dot.Position = UDim2.new(0, X + 3, 0.5, 0)       -- dot is 6 wide, left anchored
    Island.DotGlow.Position = UDim2.new(0, X + 6, 0.5, 0)   -- glow is 12 wide, centre anchored
    X = X + 6 + GAP

    Island.FpsLabel.Position = UDim2.new(0, X, 0.5, 0)
    Island.FpsLabel.AnchorPoint = Vector2.new(0, 0.5)
    X = X + FpsWidth + PADDING

    Island.Root.Size = UDim2.fromOffset(X, PILL_HEIGHT)
    if Island.OnSizeChanged then Island.OnSizeChanged(X) end
end
```

- Call `layout()` via `task.defer(layout)` whenever `SetName` changes the text and whenever the FPS label text changes (5s tick). Also call once at the end of construction.
- `TextBounds` can lag one frame after a text change, hence `task.defer`.
- Keep `PILL_HEIGHT = 34`, the 0.94 press spring, alpha-only breath, avatar, and all theme tags.
- Remove the fixed `PILL_WIDTH` constant (or keep only as a pre-layout initial value).

### Window.lua

The fold target must follow the island's live width instead of a constant:

```lua
local function closedWidth()
    local Island = Library.DynamicIsland
    return Island and Island.Root.AbsoluteSize.X or 190
end
```

Use `closedWidth()` in `Minimize` for `GoalWidth` and in `WidthProgress` normalization, replacing both `PILL_SIZE.X` uses. Keep `PILL_SIZE.Y = 34`, `ISLAND_CENTRE`, `ISLAND_CENTRE:Lerp(...)` and all alpha/scale logic unchanged. Update the comment on `PILL_SIZE` so it no longer claims to be the full pill size.

## Repo conventions to follow

- `Creator.AddSignal` for connections; `task.defer` to avoid yielding in setters (same pattern as `SetAvatar`'s URL path).
- Keep the left-anchored dot / centre-anchored glow relationship from plans 010–011 (dot centre = glow centre).
- Do NOT add a second layout system such as UIListLayout.

## Steps

1. Replace the hard-coded name/fps/dot/glow positions with the `layout()` function above in `DynamicIsland.lua`.
2. Hook `layout()` into `SetName` and the FPS update tick; call once at construction.
3. In `Window.lua`, add `closedWidth()` and replace the two `PILL_SIZE.X` uses in `Minimize` / `applyMorph`.
4. Update the stale comment on `PILL_SIZE`.

## Boundaries

- Do NOT change the avatar, breathing, FPS capping, or the island toggle behaviour.
- Do NOT change `OPEN_SIZE`, `ISLAND_CENTRE`, or `SEARCH_HEADER_HEIGHT`.
- If the code has drifted, STOP and report.

## Verification

- **Mechanical**: selene → 0 errors; tests → 38 passed; build completes.
- **Feel check** (live via MCP Real):
  - default `xspww` + `60 fps` produces a pill noticeably narrower than 190 with no visible gap between name, dot and fps;
  - `Island:SetName("a very long name here")` widens the pill and keeps all elements evenly spaced (8px gaps);
  - folding the window lands exactly on the island's current size and centre;
  - pressing the island still scales the whole pill from the live value.
- **Done when**: pill width tracks content, gaps are consistent, and morph target matches the live island size.
