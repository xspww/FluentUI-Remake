# 002 — Give Root.Position one owner so drag and collapse cannot fight

- **Status**: DONE
- **Commit**: 4608e95
- **Severity**: HIGH
- **Category**: Performance / interruptibility
- **Estimated scope**: 1 file, ~25 lines

## Problem

Two Flipper motors write `Window.Root.Position` every frame:

- `src/Components/Window.lua:197-202` — `OpenMotor.onStep` writes it from `returnPosition(Value)` while the window collapses into / emerges from the Dynamic Island.
- `src/Components/Window.lua:221-223` — `PosMotor.onStep` writes it from drag coordinates.

If a drag (or the instant keybind path at `Window.lua:340-342`) happens while the open spring is still settling, both motors write the same property on the same frame and the window jitters. `Position` is also a layout property on a `CanvasGroup` holding the whole window subtree, and it changes in the same frame as `GroupTransparency` (a group-alpha pass) and `UIScale`.

Current code (verbatim):

```lua
	-- 1 = open, 0 = folded into the island. Springs retarget from the live
	-- value, so a second tap mid-flight reverses along the same path.
	Window.OpenMotor = Flipper.SingleMotor.new(1)
	Window.OpenMotor:onStep(function(Value)
		Window.Root.GroupTransparency = 1 - Value
		Window.OpenScale.Scale = CLOSED_SCALE + (1 - CLOSED_SCALE) * Value
		Window.Root.Position = returnPosition(Value)
		Window.Root.Visible = not (Window.Minimized and Value <= 0.01)
	end)
```

```lua
	PosMotor:onStep(function(values)
		Window.Root.Position = UDim2.new(0, values.X, 0, values.Y)
	end)
```

## Target

Keep `Window.Position` as the single source of truth for the **open** top-left. Add a `Travel` offset owned only by the open animation. Both motors call one `applyPosition()` that composes them, so they can never overwrite each other:

```lua
	local Travel = Vector2.new(0, 0)
	local function applyPosition()
		Window.Root.Position = UDim2.new(
			0, Window.Position.X.Offset + Travel.X,
			0, Window.Position.Y.Offset + Travel.Y
		)
	end
```

`OpenMotor.onStep` becomes:

```lua
	Window.OpenMotor:onStep(function(Value)
		Window.Root.GroupTransparency = 1 - Value
		Window.OpenScale.Scale = CLOSED_SCALE + (1 - CLOSED_SCALE) * Value
		local Target = returnPosition(Value)
		Travel = Vector2.new(
			Target.X.Offset - Window.Position.X.Offset,
			Target.Y.Offset - Window.Position.Y.Offset
		)
		applyPosition()
		Window.Root.Visible = not (Window.Minimized and Value <= 0.01)
	end)
```

`PosMotor.onStep` becomes:

```lua
	PosMotor:onStep(function(values)
		Window.Position = UDim2.new(0, values.X, 0, values.Y)
		applyPosition()
	end)
```

The initial clamp block at `src/Components/Window.lua:251-259` replaces its direct `Window.Root.Position = Window.Position` with `applyPosition()`.

The title-bar drag start at `src/Components/Window.lua:308` uses the logical position instead of the animated root position, so grabbing mid-transition cannot inherit the travel offset:

```lua
		DragStartPos = Vector2.new(Window.Position.X.Offset, Window.Position.Y.Offset)
```

Keep every spring config unchanged: open `frequency = 9` (close) / `7` (open), drag `Instant`, `dampingRatio = 1`, `CLOSED_SCALE = 0.08`, island centre `y = 27`.

## Repo conventions to follow

- `Window.Position` is already the logical position mutated by drag (`Window.lua:288`, `Window.lua:339`) — extend it, do not replace it.
- `returnPosition(Value)` at `Window.lua:180-192` already computes the absolute top-left whose centre lands on the island — reuse it unchanged.
- Exemplar for a single write function: `applyPosition()` mirrors how `Creator.SpringMotor` funnels all writes through one `onStep` (`src/Creator.lua:193-206`).

## Steps

1. `src/Components/Window.lua:194` — insert `Travel` and `applyPosition()` immediately **before** the `Window.OpenMotor` declaration.
2. `src/Components/Window.lua:197-202` — replace the `OpenMotor.onStep` body with the target version: compute `Target = returnPosition(Value)`, store the delta in `Travel`, call `applyPosition()`, keep alpha/scale/Visible lines unchanged.
3. `src/Components/Window.lua:221-223` — replace the `PosMotor.onStep` body with the target version (assign `Window.Position`, then `applyPosition()`).
4. `src/Components/Window.lua:254` — replace `Window.Root.Position = Window.Position` with `applyPosition()`.
5. `src/Components/Window.lua:308` — replace the `DragStartPos = Vector2.new(Window.Root.AbsolutePosition.X, Window.Root.AbsolutePosition.Y)` line with the logical-position line above.
6. Do not touch any other file.

## Boundaries

- Do NOT change the island collapse geometry, `CLOSED_SCALE`, spring frequencies, or drag clamping.
- Do NOT wrap the window in a new container or change `AnchorPoint` — `PosMotor` still uses top-left coordinates.
- Do NOT touch `Tab.lua`, `Creator.lua`, or any theme.
- If the code has drifted from the verbatim excerpts, STOP and report instead of improvising.

## Verification

- **Mechanical**: selene → `0 errors`; `lune run spec/run.luau` → `38 passed, 0 failed`; `lune run build/init` completes.
- **Feel check** (live via MCP Real): rebuild and re-run `Example.client.lua`. Confirm:
  - opening/closing still lands the window centre on the island at the tail (`Root.AbsolutePosition + half scaled size ≈ (viewport.X/2, 27)`);
  - start a close, then immediately drag the title bar — the window must not jump by the travel offset;
  - spam the island toggle 10× — position/scale/alpha must retarget smoothly with no frame where two motors disagree.
  - Because `Position` is a layout property, profile on a real client: record `Root` position changes during a close and confirm no 1px snapping at the start/end of the spring. This cannot be settled from code alone.
- **Done when**: exactly one function writes `Window.Root.Position` (`applyPosition`), and the drag-mid-transition test shows no positional jump.
