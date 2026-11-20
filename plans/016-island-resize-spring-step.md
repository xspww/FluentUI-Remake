# 016 — Force the layout motor to 0 before starting its spring

- **Status**: DONE
- **Commit**: 942e6d3
- **Severity**: HIGH
- **Category**: Interruptibility / correctness
- **Estimated scope**: 1 file, 2 lines

## Problem

Plan 015 added a `LayoutMotor` blend, but live measurement shows the pill still snaps:

```
start=140 t60=240 t120=240 final=240
```

Cause in `layout()` (`src/Components/DynamicIsland.lua`):

```lua
Island.LayoutMotor:setGoal(Instant(0))
Island.LayoutMotor:setGoal(Spring(1, { frequency = LAYOUT_FREQUENCY, dampingRatio = 1 }))
```

`SingleMotor:setGoal` only stores `_goal` and starts the implicit connection. The `Instant` value is applied inside `SingleMotor:step(deltaTime)`, which runs on the next render step — but the second `setGoal` replaces `_goal` first, so the motor never observes 0. It springs from its existing value 1 to 1, i.e. no motion.

Verified from `src/Packages/Flipper/SingleMotor.lua:27-45, 52-61`: `step` applies `_goal` and fires `onStep`; `setGoal` does not apply immediately.

## Target

Force the Instant goal to be consumed before setting the Spring goal:

```lua
Island.LayoutMotor:setGoal(Instant(0))
Island.LayoutMotor:step(0) -- consume the Instant goal now
Island.LayoutMotor:setGoal(Spring(1, { frequency = LAYOUT_FREQUENCY, dampingRatio = 1 }))
```

`step(0)` applies value 0 and fires `onStep`, which writes `From` into all properties. `From` was captured from the live values on the line above, so this causes no visual jump.

Do NOT change anything else in `layout()`, the first-run direct-apply branch, the blend formula, or any other component.

## Repo conventions to follow

- Flipper motors are stepped by the engine's connection; calling `step(0)` explicitly is the sanctioned way to consume an `Instant` goal synchronously (see `SingleMotor.lua`).
- Keep `dampingRatio = 1` and `LAYOUT_FREQUENCY = 6` from plan 015.

## Steps

1. Insert `Island.LayoutMotor:step(0)` between the `Instant(0)` and `Spring(1)` calls in the animated branch of `layout()`.
2. Nothing else.

## Boundaries

- Do NOT replace this with `task.wait()` or a second motor.
- Do NOT change the measurement math or any other file.
- If the excerpt has drifted, STOP and report.

## Verification

- **Mechanical**: selene → 0 errors; tests → 38 passed; build completes.
- **Feel check** (live via MCP Real): sample `Root.AbsoluteSize.X` at 0ms, 60ms, 120ms, 300ms after `SetName("a much longer name here")`. Expected an intermediate value strictly between 140 and 240 at 60ms or 120ms (e.g. ~180–220), settling at 240. Then reverse mid-flight and confirm the width moves back from the current value without jumping.
- **Done when**: the resize is visibly interpolated and interruptible.
