# 010 — Align the island status glow with its dot

- **Status**: DONE
- **Commit**: 942e6d3
- **Severity**: MEDIUM
- **Category**: Physicality / craft
- **Estimated scope**: 1 file, 1 line

## Problem

Live measurement on client 16020 shows the breathing halo is not centred on the status dot:

```
dot  centre = 989.0, 27.0
glow centre = 982.0, 27.0
```

The halo sits 7px to the left of the dot. This came from plan 008: the glow is 14x14 with `AnchorPoint = (0.5, 0.5)` at `x = 117`, while the dot is 8x8 with `AnchorPoint = (0, 0.5)` at `x = 120`. The dot's centre is therefore 124, not 117.

Current code (`src/Components/DynamicIsland.lua`):

```lua
Island.DotGlow = New("Frame", {
    Size = UDim2.fromOffset(14, 14),
    Position = UDim2.new(0, 117, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    ...
```

## Target

Move the glow so its centre equals the dot's centre (124):

```lua
Position = UDim2.new(0, 124, 0.5, 0),
```

No other change. Keep the 14x14 size, the full-radius `UICorner`, the `Accent` theme colour and the existing alpha breathing.

## Repo conventions to follow

- The dot is left-anchored (`AnchorPoint = (0, 0.5)`), so its centre is `x + width/2 = 120 + 4 = 124`. The glow is centre-anchored, so its `Position.X` must be the centre value directly.
- Preserve the pattern from plan 008: alpha-only breathing, no size animation.

## Steps

1. In `src/Components/DynamicIsland.lua`, change only `Island.DotGlow` `Position` X from 117 to 124.
2. Do not touch any other file, value or property.

## Boundaries

- Do NOT change the dot position, size, name, FPS, avatar or breath logic.
- If the code has drifted, STOP and report.

## Verification

- **Mechanical**: selene → 0 errors; tests → 38 passed; build completes.
- **Feel check** (live via MCP Real): measure both centres again — they must be equal (e.g. `989,27` for both); confirm the halo still breathes via `BackgroundTransparency`.
- **Done when**: glow centre == dot centre on both axes.
