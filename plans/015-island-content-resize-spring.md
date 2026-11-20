# 015 — Spring the island's content-driven resize

- **Status**: DONE
- **Commit**: 942e6d3
- **Severity**: MEDIUM
- **Category**: Interruptibility / craft
- **Estimated scope**: 1 file, ~35 lines

## Problem

Plans 012–014 make the island pill grow and shrink to fit its name, but `layout()` writes the new width and every child position directly, so a name change snaps instantly. Apple's rule: an interface feels alive when motion starts from the current on-screen value and can be redirected mid-flight. A snap reads as a glitch next to the breathing dot and press spring.

Current `layout()` in `src/Components/DynamicIsland.lua` ends with direct writes:

```lua
Island.NameLabel.Size = UDim2.fromOffset(NameWidth, 20)
...
Island.Root.Size = UDim2.fromOffset(X, PILL_HEIGHT)
if Island.OnSizeChanged then
    Island.OnSizeChanged(X)
end
```

## Target

Add one `LayoutMotor` that drives a normalised 0→1 blend between the previous and new layout. Every changing property is interpolated from its **live** value, so a second name change mid-animation retargets smoothly.

Module scope additions:

```lua
local Instant = Flipper.Instant.new
local LAYOUT_FREQUENCY = 6 -- ~0.16s settle, critically damped
local function lerp(A, B, T)
    return A + (B - A) * T
end
```

Inside the constructor, before `layout()`:

```lua
Island.LayoutMotor = Flipper.SingleMotor.new(1)
local From, To = {}, {}
local LayoutReady = false

Island.LayoutMotor:onStep(function(Value)
    Island.Root.Size = UDim2.fromOffset(lerp(From.width, To.width, Value), PILL_HEIGHT)
    Island.NameLabel.Size = UDim2.fromOffset(lerp(From.nameWidth, To.nameWidth, Value), 20)
    Island.Dot.Position = UDim2.new(0, lerp(From.dotX, To.dotX, Value), 0.5, 0)
    Island.DotGlow.Position = UDim2.new(0, lerp(From.glowX, To.glowX, Value), 0.5, 0)
    Island.FpsLabel.Position = UDim2.new(0, lerp(From.fpsX, To.fpsX, Value), 0.5, 0)
    if Island.OnSizeChanged then
        Island.OnSizeChanged(lerp(From.width, To.width, Value))
    end
end)
```

Rewrite `layout()` so it computes `To` exactly as today (same PADDING/GAP/margins), then:

```lua
if not LayoutReady then
    LayoutReady = true
    From = table.clone(To)
    Island.LayoutMotor:setGoal(Instant(1))
    Island.LayoutMotor:onStep(...) -- already registered; fire manually:
    -- apply To directly once:
    Island.Root.Size = UDim2.fromOffset(To.width, PILL_HEIGHT)
    Island.NameLabel.Size = UDim2.fromOffset(To.nameWidth, 20)
    Island.Dot.Position = UDim2.new(0, To.dotX, 0.5, 0)
    Island.DotGlow.Position = UDim2.new(0, To.glowX, 0.5, 0)
    Island.FpsLabel.Position = UDim2.new(0, To.fpsX, 0.5, 0)
    return
end

From = {
    width = Island.Root.AbsoluteSize.X,
    nameWidth = Island.NameLabel.AbsoluteSize.X,
    dotX = Island.Dot.Position.X.Offset,
    glowX = Island.DotGlow.Position.X.Offset,
    fpsX = Island.FpsLabel.Position.X.Offset,
}
Island.LayoutMotor:setGoal(Instant(0))
Island.LayoutMotor:setGoal(Spring(1, { frequency = LAYOUT_FREQUENCY, dampingRatio = 1 }))
```

`Destroy()` must also stop `Island.LayoutMotor`.

## Repo conventions to follow

- Flipper springs with `dampingRatio = 1` are the house style (`DynamicIsland.lua` press motor uses 14/8Hz; the layout change is a state change, so use a gentler 6Hz).
- Interrupting a spring retargets from the presentation value — reading `AbsoluteSize`/`Position.X.Offset` into `From` is exactly that.
- Do NOT introduce a new motor per property; one progress motor keeps gaps consistent during the animation.

## Steps

1. Add `Instant`, `LAYOUT_FREQUENCY` and `lerp` at module scope.
2. Add `LayoutMotor`, `From`, `To`, `LayoutReady` and the `onStep` blend before `layout()`.
3. Replace `layout()`'s direct writes with the `To` computation + first-run direct apply + subsequent spring retarget.
4. Stop `LayoutMotor` in `Destroy()`.
5. Keep `task.defer(layout)` hooks in `SetName`, the FPS tick and construction.

## Boundaries

- Do NOT change the measured widths, gap constants, theme, breath, press spring, FPS cap or Window.lua.
- Do NOT animate with `TweenService`; the repo uses Flipper.
- If the code has drifted, STOP and report.

## Verification

- **Mechanical**: selene → 0 errors; tests → 38 passed; build completes.
- **Feel check** (live via MCP Real):
  - `SetName("a much longer name here")` widens the pill over ~0.16s instead of snapping; sample `Root.AbsoluteSize.X` twice ~60ms apart and confirm an intermediate value between 140 and 240;
  - `SetName("xspww")` mid-widening reverses smoothly from the current width, no jump;
  - dot/glow stay centred on each other through the whole animation;
  - press feedback on the pill still works while the width is animating.
- **Done when**: resizes are visibly eased and interruptible, with no console errors.
