# 018 — Equal island gaps and uncapped real FPS display

- **Status**: DONE
- **Commit**: 942e6d3
- **Severity**: MEDIUM
- **Category**: Craft / correctness
- **Estimated scope**: 2 files (~8 lines)

## Problem

Two live observations:

1. Gaps are unequal. In `src/Components/DynamicIsland.lua`, name→dot is `GAP = 8`, but dot→fps is `GAP + FPS_EXTRA = 8 + 3 = 11` because plan 017 added `To.fpsX = X + FPS_EXTRA`. The user wants both gaps equal.
2. FPS display is not the real measurement. The heart of the tick is correct (real Heartbeat counting over `FPS_INTERVAL = 5`), but plan 009 clamped the display: `math.clamp(..., 1, 60)`. The user wants the real value shown with the 5-second delay.

Current code:

```lua
local PADDING, GAP = 10, 8
local FPS_EXTRA = 3
...
To.fpsX = X + FPS_EXTRA
...
Island.RawFps = FrameCount / SampleTime
local Fps = math.clamp(math.floor(FrameCount / SampleTime + 0.5), 1, 60)
Island.FpsLabel.Text = tostring(Fps) .. " fps"
```

## Target

**Equal gaps** — remove the extra so both gaps are `GAP = 8`:

```lua
local PADDING, GAP = 10, 8
-- delete the FPS_EXTRA line
...
To.fpsX = X
```

**Real FPS** — display the measured value, keep the 5-second window:

```lua
Island.RawFps = FrameCount / SampleTime
local Fps = math.max(1, math.floor(Island.RawFps + 0.5))
Island.FpsLabel.Text = tostring(Fps) .. " fps"
```

Update the comment above the tick to say the value is the real measured frame rate over 5 seconds (remove the "clamp to a believable 1..60" wording).

`README.md` currently says "capped at 60 fps for display; raw value is on `Fluent.DynamicIsland.RawFps`". Replace that clause with "the real measured frame rate (the raw value is also on `Fluent.DynamicIsland.RawFps`)".

Everything else — layout spring, TextService measurement, `+4`/`+2` margins, breath, press, avatar, Window.lua fold — stays unchanged.

## Repo conventions to follow

- Keep `FPS_INTERVAL = 5` and real Heartbeat counting from plans 009/013.
- Keep Flipper `LAYOUT_FREQUENCY = 6` spring; changing the fps text still triggers `task.defer(layout)` via the FPS tick.

## Steps

1. Delete `local FPS_EXTRA = 3` and change `To.fpsX = X + FPS_EXTRA` to `To.fpsX = X`.
2. Replace the clamped FPS display with the `math.max(1, floor(RawFps+0.5))` version and fix the comment.
3. Update the README sentence that mentions the 60 fps cap.
4. Nothing else.

## Boundaries

- Do NOT reintroduce `GetRealPhysicsFPS()`.
- Do NOT change `FPS_INTERVAL`, `GAP`, `PADDING`, breath, press, avatar or Window.lua.
- If the code has drifted, STOP and report.

## Verification

- **Mechanical**: selene → 0 errors; tests → 38 passed; build completes.
- **Feel check** (live via MCP Real):
  - measure name-right→dot-left and dot-right→fps-left with default `xspww` — both must be ~8px;
  - wait >5s and confirm the label shows the measured value (e.g. ~230 on this uncapped client), matching `Island.RawFps` rounded;
  - changing the name still widens the pill with equal gaps via the spring;
  - folding still lands on the live island size.
- **Done when**: both gaps are equal and the FPS label equals the real 5-second measurement.
