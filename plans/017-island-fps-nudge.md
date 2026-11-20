# 017 — Nudge the island FPS label slightly right

- **Status**: DONE
- **Commit**: 942e6d3
- **Severity**: LOW
- **Category**: Craft
- **Estimated scope**: 1 file, 2 lines

## Problem

The FPS label sits immediately after the status dot with the standard `GAP = 8`. The user wants it nudged a few pixels to the right.

Current `layout()` in `src/Components/DynamicIsland.lua`:

```lua
X = X + 6 + GAP

To.fpsX = X

X = X + FpsWidth + PADDING
```

## Target

Add a dedicated 3px offset so the fps text is slightly further from the dot, and let the pill grow by the same amount (it is content-sized):

```lua
local FPS_EXTRA = 3 -- at module scope beside PADDING/GAP
...
X = X + 6 + GAP

To.fpsX = X + FPS_EXTRA

X = X + FpsWidth + PADDING
```

Everything else — text measurement, avatar, dot/glow centring, spring blend, breath, press, Window.lua fold — stays unchanged.

## Steps

1. Add `local FPS_EXTRA = 3` next to `local PADDING, GAP = 10, 8`.
2. Change `To.fpsX = X` to `To.fpsX = X + FPS_EXTRA`.
3. Nothing else.

## Boundaries

- Do NOT change `PADDING`, `GAP`, the dot position or the pill's right padding.
- If the code has drifted, STOP and report.

## Verification

- **Mechanical**: selene → 0 errors; tests → 38 passed; build completes.
- **Feel check** (live via MCP Real): measure dot centre and fps label left edge before/after — the gap should increase by ~3px; the pill still animates its resize via LayoutMotor and folding still lands on the live island size.
- **Done when**: fps text sits slightly further right with no other layout change.
