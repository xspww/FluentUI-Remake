# 020 — Add the final 8px gap between island dot and FPS

- **Status**: DONE
- **Commit**: 942e6d3
- **Severity**: LOW
- **Category**: Craft
- **Estimated scope**: 1 file, 1 line

## Problem

Plan 019 fixed the name→dot gap to 8px and centred the glow, but live measurement shows dot→fps = 0:

```
nameDot = 8px
dotFps  = 0px
glowDot = 0.0, 0.0
```

Derivation from current `layout()`:

```lua
X = X + NameWidth + GAP   -- X = nameRight + 8
To.dotX = X               -- dot left
To.glowX = X + 3          -- glow centre (correct)
X = X + 6                 -- lands exactly on dotRight
To.fpsX = X               -- fps left == dotRight
```

Plan 019 removed the old `+ GAP` together with the dot's `+3` offset; the `+6` is only the dot width, so no gap remains.

## Target

Add `GAP` back after the dot width:

```lua
X = X + 6 + GAP
To.fpsX = X
```

Now fps left = dotRight + 8, matching name→dot = 8.

Keep `To.dotX = X` and `To.glowX = X + 3` unchanged — glow is already centred on the dot.

## Steps

1. In `src/Components/DynamicIsland.lua` `layout()`, change `X = X + 6` to `X = X + 6 + GAP`.
2. Nothing else.

## Boundaries

- Do NOT change GAP (8), PADDING, dotX/glowX, FPS display, spring or any other file.
- If the code has drifted, STOP and report.

## Verification

- **Mechanical**: selene → 0 errors; tests → 38 passed; build completes.
- **Feel check** (live via MCP Real): measure both gaps — `nameDot ≈ 8` and `dotFps ≈ 8`, within 1px; glow centre still equals dot centre; FPS label still shows the real 5-second measurement.
- **Done when**: both gaps are equal within 1px.
