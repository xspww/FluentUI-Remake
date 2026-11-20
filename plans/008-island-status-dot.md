# 008 — Replace the island "search icon" with a real status dot

- **Status**: DONE
- **Commit**: 942e6d3
- **Severity**: HIGH
- **Category**: Craft / state indication
- **Estimated scope**: 1 file, ~15 lines

## Problem

Live inspection on client 16020 shows the island's status element is an `ImageLabel` with `Image = "rbxassetid://10734943674"`, which is Lucide's **search** icon. It was intended to be a small breathing status dot. The screenshot the user supplied shows a magnifier between the name and the FPS, which reads as a stray control rather than a status indicator.

Current code (`src/Components/DynamicIsland.lua`, island construction):

```lua
Island.DotScale = New("UIScale", { Scale = 1 })
Island.Dot = New("ImageLabel", {
    Size = UDim2.fromOffset(8, 8),
    Position = UDim2.new(0, 120, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    BackgroundTransparency = 1,
    Image = "rbxassetid://10734943674",
    ThemeTag = { ImageColor3 = "Accent" },
}, {
    Island.DotScale,
})
```

And the breath loop:

```lua
Island.DotScale.Scale = 1 + Wave * 0.18
Island.Dot.ImageTransparency = Wave * 0.25
```

## Target

A plain filled circle. Use `Frame` + `UICorner` full radius; breathe via alpha only (Apple: an ambient indicator should change intensity, not jump in size). Keep the position `x=120`, size `8x8`, colour `Accent`.

```lua
Island.DotGlow = New("Frame", {
    Size = UDim2.fromOffset(14, 14),
    Position = UDim2.new(0, 117, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    ThemeTag = { BackgroundColor3 = "Accent" },
}, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })

Island.Dot = New("Frame", {
    Size = UDim2.fromOffset(8, 8),
    Position = UDim2.new(0, 120, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    BackgroundTransparency = 0,
    ThemeTag = { BackgroundColor3 = "Accent" },
}, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })
```

Breath loop target:

```lua
Island.Dot.BackgroundTransparency = Wave * 0.35
Island.DotGlow.BackgroundTransparency = 0.75 + Wave * 0.2
```

Remove `Island.DotScale` entirely and the `Island.Dot.ImageTransparency` write. The glow frame gives a soft halo without scaling the dot.

## Repo conventions to follow

- `New(...)` with `ThemeTag` is the standard themed-instance pattern (`src/Components/DynamicIsland.lua` throughout).
- Breath is driven by `RunService.Heartbeat` with a sine at `BREATH_HZ = 0.6`, already present — only the driven property changes.
- Do not introduce a new spring for this; it is ambient, not interruptible.

## Steps

1. Replace the `Island.Dot` `ImageLabel` block with the two `Frame` blocks above.
2. Remove `Island.DotScale` declaration and its child.
3. Replace the two breath writes with the alpha writes above.
4. Verify no remaining references to `Island.Dot.Image` or `Island.DotScale`.

## Boundaries

- Do NOT change the pill width (190), name, avatar or FPS logic.
- Do NOT change `BREATH_HZ` or the press feedback.
- If the code has drifted from the excerpt, STOP and report.

## Verification

- **Mechanical**: selene → 0 errors; `lune run spec/run.luau` → 38 passed; `lune run build/init` completes.
- **Feel check** (live via MCP Real): island shows a plain 8px accent circle, no magnifier glyph; sample `Dot.BackgroundTransparency` twice 0.25s apart and confirm it changes (breath alive) while `Dot.AbsoluteSize` stays 8x8; press the island and confirm the whole pill still scales 0.94 from the live value.
- **Done when**: no `rbxassetid://10734943674` anywhere in the island, and the status element is a circle.
