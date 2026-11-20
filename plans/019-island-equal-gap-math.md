# 019 — Correct the island gap math so both gaps are 8px

- **Status**: DONE
- **Commit**: 942e6d3
- **Severity**: MEDIUM
- **Category**: Craft / correctness
- **Estimated scope**: 1 file, 4 lines

## Problem

Plan 018 removed `FPS_EXTRA`, but live measurement still shows unequal gaps:

```
nameDot = 11px
dotFps  = 5px
```

Derivation from current `layout()` (`src/Components/DynamicIsland.lua`):

```lua
X = X + NameWidth + GAP     -- X = nameRight + 8
To.dotX = X + 3             -- dot left = nameRight + 11  <-- extra 3
To.glowX = X + 6            -- glow centre
X = X + 6 + GAP            -- fps left = nameRight + 22
To.fpsX = X
```

The `+3` dot offset was originally to centre the glow; it also pushes the dot 3px right, and then `GAP` is added again after the dot, so the remaining gap shrinks to 5.

## Target

Make the dot start exactly one GAP after the name and place fps exactly one GAP after the dot, while keeping glow centred on the dot:

```lua
X = X + NameWidth + GAP     -- unchanged

To.dotX = X                 -- dot left = nameRight + 8
To.glowX = X + 3            -- glow centre = dot left + 3 (dot is 6 wide)
X = X + 6                   -- move past the dot only
To.fpsX = X                 -- fps left = dotRight + 8
```

Result: name→dot = 8, dot→fps = 8, glow centre == dot centre.

Do NOT change `GAP` itself, `PADDING`, the measured widths, the spring, FPS or anything else.

## Repo conventions to follow

- The dot is 6px wide and left-anchored; the glow is 12px and centre-anchored (plans 010–011). Preserve those anchors.
- Keep `To.*` values feeding the existing `LayoutMotor` blend.

## Steps

1. `To.dotX = X + 3` → `To.dotX = X`.
2. `To.glowX = X + 6` → `To.glowX = X + 3`.
3. `X = X + 6 + GAP` → `X = X + 6`.
4. Nothing else.

## Boundaries

- Do NOT change the FPS display (now correctly showing real ~226 fps every 5s).
- Do NOT touch Window.lua or other components.
- If the code has drifted, STOP and report.

## Verification

- **Mechanical**: selene → 0 errors; tests → 38 passed; build completes.
- **Feel check** (live via MCP Real): measure nameRight→dotLeft and dotRight→fpsLeft — both must be ~8px with `xspww`; also confirm glow centre == dot centre and that changing the name preserves equal gaps through the spring animation.
- **Done when**: both gaps are equal within 1px.
