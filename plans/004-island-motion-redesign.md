# 004 — Redesign the island transition with Apple-style motion principles

- **Status**: DONE
- **Commit**: 4608e95
- **Severity**: HIGH
- **Category**: Cohesion / physicality / performance
- **Estimated scope**: 1 file, ~60 lines

## Problem

Plans 001–003 removed stacked threads, split position ownership and slowed the spatial spring, but the transition was still one progress value driving alpha, scale and both axes in lockstep. That reads as a uniform shrink rather than a surface materialising from its source. Measured close sequence before this plan: scale `0.97/0.71/0.50/0.32...` with alpha `0.00/0.00/0.01/0.42...` — alpha only started when geometry was already half done.

Apple talks this addresses: §3 (decompose 2D motion into independent springs), §7 (anchored origin / symmetric path), §12 (materialise, don't just fade), §11 (keep per-frame positional change below the strobing threshold).

## Target

In `src/Components/Window.lua`:

- Keep `ISLAND_CENTRE_Y = 10 + 34/2`, `CLOSED_SCALE = 0.08`, `OPEN_SCALE = 1` and `applyPosition()` from plan 002.
- Replace the single `OpenMotor` with three independent springs:
  - `ScaleMotor` — `frequency = 2.5` close / `2.2` open, `dampingRatio = 1`
  - `TravelXMotor` — `frequency = 2.5` close / `2.2` open, `dampingRatio = 1` (distance ~290px)
  - `TravelYMotor` — `frequency = 3.0` close / `2.6` open, `dampingRatio = 1` (distance ~240px, settles sooner so the unfold has direction)
- Alpha is **derived from scale**, not sprung separately: `Progress = (Scale - CLOSED_SCALE) / (OPEN_SCALE - CLOSED_SCALE)`, `GroupTransparency = 1 - clamp(Progress * 2.2, 0, 1)`. This makes alpha lead on open and trail on close.
- `Minimize(Silent, Animated)`: compute `GoalScale`; travel goals are `travelFor(CLOSED_SCALE)` only when closing, `(0,0)` when opening. **Do not call `travelFor(OPEN_SCALE)`** — that returns the island-centred top-left for a full-size window and puts the window at `y = -243`.
- Keyboard path: `Instant(GoalScale)` / `Instant(GoalX)` / `Instant(GoalY)`, `Visible = not Closing`.
- `Destroy()` stops all three motors.

## Repo conventions to follow

- `Spring = Flipper.Spring.new` alias at `src/Components/Window.lua:10`; use it for every goal.
- Flipper frequency ≈ `0.64 / settle-seconds` at damping 1, so 2.5Hz ≈ 0.26s and 2.2Hz ≈ 0.29s — inside Apple's 0.3–0.4s reposition budget.
- Island press feedback in `src/Components/DynamicIsland.lua` stays untouched (14Hz down / 8Hz release).

## Steps

1. `src/Components/Window.lua:176-215` — replace `returnPosition`/`OpenMotor` with `islandTopLeft(Scale)`, `travelFor(Scale)`, `TravelX/TravelY`, `applyPosition()`, and the three motors + `ScaleMotor:onStep` alpha reshape.
2. `src/Components/Window.lua:351+` — update `Minimize` to set goals on all three motors, with the closing-only travel guard.
3. `src/Components/Window.lua:384+` — in `Destroy`, stop `ScaleMotor`, `TravelXMotor`, `TravelYMotor` instead of `OpenMotor`.
4. Do not touch `Tab.lua`, `DynamicIsland.lua`, themes, or plans 001–003.

## Boundaries

- Do NOT use a shared progress for both axes — keep X and Y independent.
- Do NOT spring alpha as a fourth motor; derive it from scale.
- Do NOT change `dampingRatio` from 1 or the island geometry.
- If code has drifted from the excerpt, STOP and report.

## Verification

- **Mechanical**: selene → 0 errors; `lune run spec/run.luau` → 38 passed; `lune run build/init` completes.
- **Feel check** (live via MCP Real, client 4388): reload `dist/main.lua` + `Example.client.lua`, then:
  - close: `closed min=true pos≈934,5 scale≈0.08 alpha≈1` and the window centre ≈ `(960,27)` = island centre;
  - open: `opened min=false pos≈642,242 scale≈1 alpha=0`;
  - sampled open sequence must show alpha reaching 0 while scale is still ~0.64 (materialise before unfold);
  - per-frame maxima ≈ scale 0.11, alpha 0.17, X 35px, Y 34px, frame 20ms;
  - 10 rapid island toggles leave the window at the open position with no console errors.
- **Done when**: all of the above hold and no fourth spring was introduced for alpha.
