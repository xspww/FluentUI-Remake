# 005 — Morph the main window into the Dynamic Island pill

- **Status**: DONE
- **Commit**: 4608e95
- **Severity**: HIGH
- **Category**: Physicality / state indication
- **Estimated scope**: 1 file, ~70 lines

## Problem

Plans 001–004 moved the window into the island and tuned timing, but the window stayed a tiny **rectangle** (`0.08` uniform scale ≈ 50×43) at the island. The user wants the main UI to actually **change form** into the pill (52×34, capsule corners) so the transition reads as one object morphing, not a window shrinking.

## Target

In `src/Components/Window.lua`:

- Store the background corner as `Window.BackgroundCorner` (was an anonymous `UICorner` child).
- Drop `UIScale`, `OpenScale`, `ScaleMotor`, `TravelXMotor`, `TravelYMotor`, `returnPosition`, `travelFor`, islandTopLeft, `CLOSED_SCALE`, `OPEN_SCALE`.
- Add constants: `ISLAND_CENTRE = (viewport.X/2, 27)`, `PILL_SIZE = (52, 34)`, `OPEN_SIZE = Window.Size offsets`, `WINDOW_CORNER = 8`, `PILL_CORNER = 17`.
- Add independent `WidthMotor` (`2.5` close / `2.2` open) and `HeightMotor` (`3.0` close / `2.6` open), both `dampingRatio = 1`.
- `applyMorph()` (called by both motors' `onStep`, by `PosMotor:onStep` and by the initial clamp block):
  - `Root.Size = UDim2.fromOffset(width, height)`
  - corner radius = lerp(17, 8, heightProgress)
  - centre = `ISLAND_CENTRE:Lerp(Window.Position + OPEN_SIZE/2, widthProgress)`; `Root.Position = centre - size/2` (keeps drag ownership in `Window.Position`)
  - hide `Window.MorphContent` when `widthProgress <= 0.55`, show above it
  - `GroupTransparency = 1 - clamp(widthProgress * 2.2, 0, 1)`
  - `Root.Visible = not (Minimized and widthProgress <= 0.01)`
- `Window.MorphContent = { TabDisplay, ContainerCanvas, TabFrame, TitleBar.Frame }` set after TitleBar creation.
- `Minimize` sets width/height goals (or `Instant` for the keyboard path); `Destroy` stops both motors.

## Repo conventions to follow

- `Spring = Flipper.Spring.new` alias at `src/Components/Window.lua:10`.
- Apple §3: width and height are separate springs; §7: island is the shared anchor; §12: content leaves before the shell so the remaining shape is a plain pill.

## Steps

1. Replace the anonymous `UICorner` on `Window.Background` with `Window.BackgroundCorner`.
2. Replace the whole geometry/motor block with the constants, two motors and `applyMorph()` above.
3. Add `Window.MorphContent` after the TitleBar is created.
4. Change `applyPosition()` calls in `PosMotor:onStep` and the initial clamp block to `applyMorph()`.
5. Rewrite `Minimize` to set width/height goals; rewrite `Destroy` to stop both motors.
6. Do not touch `Tab.lua`, `DynamicIsland.lua`, themes, or plans 001–004.

## Boundaries

- Do NOT reintroduce `UIScale` or a single shared progress for both dimensions.
- Do NOT change the pill constants (52×34, radius 17) — they must match `DynamicIsland.lua`.
- If code has drifted, STOP and report.

## Verification

- **Mechanical**: selene → 0 errors / 0 warnings; tests → 38 passed; build completes.
- **Feel check** (live via MCP Real, client 4388):
  - close sequence must pass through `617x519 r8 → 323x219 r13 → 140x79 r16 → 52x34 r17`, content hidden, final centre ≈ `(960,27)`, `Root.Visible = false`;
  - open sequence must grow back `69x54 r16 → 331x322 r11 → 632x540 r8`, content visible, final `Root.AbsolutePosition ≈ (642,243)`;
  - 10 rapid island toggles leave the full window open, 0 console errors.
- **Done when**: the window demonstrably takes the pill's dimensions and corner radius at the tail, and reopens to the original size/position.
