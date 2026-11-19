# 006 — Track the Dynamic Island's live position while folded

- **Status**: DONE
- **Commit**: 4608e95
- **Severity**: MEDIUM
- **Category**: Physicality / spatial consistency
- **Estimated scope**: 1 file, ~20 lines

## Problem

The folded window's target centre was a hard-coded `Vector2.new(Viewport.X / 2, 10 + 34 / 2)`. If the island's actual position changes (viewport/safe-area inset, layout change, or its own press-scale feedback), the window landed next to it rather than on it. The folded window also stopped updating once its springs settled.

## Target

In `src/Components/Window.lua`:

- Keep `ISLAND_CENTRE` only as a fallback for the moment before the island exists.
- Add `islandCentre()` that reads the live instance:
  ```lua
  local function islandCentre()
      local Island = Library.DynamicIsland
      if Island and Island.Root and Island.Root.Parent then
          return Island.Root.AbsolutePosition + Island.Root.AbsoluteSize / 2
      end
      return ISLAND_CENTRE
  end
  ```
- In `applyMorph()`, replace `ISLAND_CENTRE:Lerp(OpenCentre, WidthProgress)` with `islandCentre():Lerp(OpenCentre, WidthProgress)`.
- Add a per-frame tracker so the hidden window keeps following the island:
  ```lua
  Creator.AddSignal(RunService.RenderStepped, function()
      if Window.Minimized then
          applyMorph()
      end
  end)
  ```
- `RunService` must be imported at the top of the file. `Creator.AddSignal` registers the connection for the library's existing cleanup path; no new Destroy step is required.

## Repo conventions to follow

- `Library` is already the module returned by `require(Root)` inside this function — reuse it, do not require again per frame.
- `Creator.AddSignal` is the codebase's standard connection registration (`src/Creator.lua:76`).

## Steps

1. Add `local RunService = game:GetService("RunService")` to the service imports.
2. Add `islandCentre()` after the motor declarations, before `applyMorph()`.
3. Change the centre interpolation in `applyMorph()` to use `islandCentre()`.
4. Add the `RenderStepped` tracker after the motor `onStep` registrations.
5. Do not touch any other file, the island component, or plans 001–005.

## Boundaries

- Do NOT hard-code the centre or reintroduce a layout-dependent guess.
- Do NOT run the tracker while the window is open (no per-frame cost on the common path).
- If code has drifted, STOP and report.

## Verification

- **Mechanical**: selene → 0 errors / 0 warnings; tests → 38 passed; build completes.
- **Feel check** (live via MCP Real):
  - close, then compare `Window.Root.AbsolutePosition + AbsoluteSize/2` with `Island.Root.AbsolutePosition + AbsoluteSize/2` — they must match within 1px;
  - while still closed, move `Island.Root.Position` to a new Y and back — the hidden window must follow to the same centre on the same frame (verified: `(400,137) → (400,27)` for both);
  - reopen and confirm the window returns to its own `Window.Position` (the island move must not leak into the open state);
  - 0 console errors.
- **Done when**: the folded window tracks a moving island continuously and reopens to the original position.
