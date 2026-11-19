# 003 — Slow the island collapse so the spatial move does not strobe

- **Status**: DONE
- **Commit**: 4608e95
- **Severity**: HIGH
- **Category**: Performance (frame-level smoothness) / easing & duration
- **Estimated scope**: 1 file, ~5 lines

## Problem

Measured live on client 4388 during `Window:Minimize(true, true)`:

- average frame time was healthy (`16.1ms`, worst `22.2ms` — no dropped-frame problem),
- but the window travelled ~290px into the island in ~6 frames, with **83px and 0.24 scale units of change in a single frame**.

That is spatial strobing, not jank from a busy main thread. AUDIT.md §2 gives Apple's move/reposition budget as **response 0.3–0.4s, damping 1.0**; the old `frequency = 9` close / `7` open settled in ~0.1–0.14s, roughly 3× too fast for the distance.

Current code (`src/Components/Window.lua:348-351`):

```lua
			Window.OpenMotor:setGoal(Spring(Window.Minimized and 0 or 1, {
				frequency = Window.Minimized and 9 or 7,
				dampingRatio = 1,
			}))
```

## Target

```lua
			Window.OpenMotor:setGoal(Spring(Window.Minimized and 0 or 1, {
				frequency = Window.Minimized and 2.5 or 2.2,
				dampingRatio = 1,
			}))
```

Keep `dampingRatio = 1` (no overshoot), the shared single motor, `CLOSED_SCALE = 0.08`, and the island-centre geometry untouched. Only the response changes.

## Repo conventions to follow

- `Spring = Flipper.Spring.new` is already the local alias at `src/Components/Window.lua:10`; keep using it.
- Flipper frequency ≈ 0.64/settle-seconds at damping 1, so 2.5Hz ≈ 0.26s and 2.2Hz ≈ 0.29s — inside AUDIT.md's 0.3–0.4s budget for reposition.
- This extends plan 002 (single owner of `Root.Position`); it does not revert it.

## Steps

1. `src/Components/Window.lua:348-351` — replace `frequency = Window.Minimized and 9 or 7` with `frequency = Window.Minimized and 2.5 or 2.2`, and add a short comment explaining that 9Hz covered ~70px per frame.
2. Do not touch any other file.

## Boundaries

- Do NOT change `dampingRatio`, `CLOSED_SCALE`, island geometry, drag frequencies, tab frequencies, or the island press feedback.
- Do NOT reintroduce a second motor for position/alpha — one motor keeps both in lockstep.
- If the code has drifted from the excerpt, STOP and report.

## Verification

- **Mechanical**: selene → 0 errors; `lune run spec/run.luau` → 38 passed; `lune run build/init` completes.
- **Feel check** (live via MCP Real, client 4388): reload bundle + `Example.client.lua`, sample `Root.AbsolutePosition.X` and `OpenScale.Scale` on `RenderStepped` across one close and one open. Expected after fix:
  - max per-frame X jump ≈ **27px** (was 83px), max per-frame scale jump ≈ **0.095** (was 0.24), max frame time ≈ **18ms**;
  - the position sequence decelerates monotonically toward x≈934 on close and back to x≈642 on open;
  - no frame where the window centre misses the island centre at the tail.
- **Done when**: the measured max per-frame jump is below ~30px and no console errors appear.
