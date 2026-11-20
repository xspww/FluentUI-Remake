# 011 — Shrink the island status dot

- **Status**: DONE
- **Commit**: 942e6d3
- **Severity**: LOW
- **Category**: Craft
- **Estimated scope**: 1 file, 2 lines

## Problem

The status dot is 8x8 with a 14x14 glow. The user wants it smaller so it reads as a subtle indicator rather than a prominent marker.

Current code (`src/Components/DynamicIsland.lua`):

```lua
Island.DotGlow = New("Frame", {
    Size = UDim2.fromOffset(14, 14),
    Position = UDim2.new(0, 124, 0.5, 0),
    ...
Island.Dot = New("Frame", {
    Size = UDim2.fromOffset(8, 8),
    Position = UDim2.new(0, 120, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    ...
```

## Target

Dot `6x6`, glow `12x12`, both centred at `x = 124` (dot is left-anchored, so its position becomes `124 - 3 = 121`; glow is centre-anchored so its position stays `124`).

```lua
Island.DotGlow: Size = UDim2.fromOffset(12, 12)   -- Position unchanged at 124
Island.Dot:    Size = UDim2.fromOffset(6, 6)
               Position = UDim2.new(0, 121, 0.5, 0)
```

Keep the full-radius `UICorner`, `Accent` theme colour, centre-anchor on the glow, and the alpha-only breathing from plan 008. Do NOT change the FPS, name, avatar or pill size.

## Steps

1. Change `Island.DotGlow` size `14,14` → `12,12`.
2. Change `Island.Dot` size `8,8` → `6,6` and position X `120` → `121`.
3. Nothing else.

## Boundaries

- Keep both centres equal (verify live).
- Do NOT touch breath logic or any other component.

## Verification

- **Mechanical**: selene → 0 errors; tests → 38 passed; build completes.
- **Feel check** (live via MCP Real): measure the two centres — both must still be equal; sizes must read `6,6` and `12,12`; breath alpha still changes.
- **Done when**: dot is smaller and still centred with its glow.
