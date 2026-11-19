# 001 — Make tab switching single-owner and interruptible

- **Status**: DONE
- **Commit**: 4608e95
- **Severity**: HIGH
- **Category**: Interruptibility / performance
- **Estimated scope**: 1 file, ~30 lines

## Problem

`src/Components/Tab.lua:171-185` spawns a new thread on **every** tab click. Each thread owns two `task.wait(0.12)` timers and writes the shared `ContainerPosMotor`, `ContainerBackMotor` and every container's `Visible` after its own timer. Spam-clicking tabs leaves several threads alive; they write the same motors at different times and flip `Visible` on stale targets. That is the visible flicker/stutter reported as "UI ไม่ smooth". It also puts a fixed artificial timer on the input path (AUDIT.md §1, §4).

Current code (`src/Components/Tab.lua:168-186`, verbatim):

```lua
	Window.TabDisplay.Text = Target.Name
	Window.SelectorPosMotor:setGoal(Spring(TabModule:GetCurrentTabPos(), { frequency = 6 }))

	task.spawn(function()
		Window.ContainerHolder.Parent = Window.ContainerAnim
		
		Window.ContainerPosMotor:setGoal(Spring(15, { frequency = 10 }))
		Window.ContainerBackMotor:setGoal(Spring(1, { frequency = 10 }))
		task.wait(0.12)
		for _, Container in next, TabModule.Containers do
			Container.Visible = false
		end
		TabModule.Containers[Tab].Visible = true
		Window.ContainerPosMotor:setGoal(Spring(0, { frequency = 5 }))
		Window.ContainerBackMotor:setGoal(Spring(0, { frequency = 8 }))
		task.wait(0.12)
		Window.ContainerHolder.Parent = Window.ContainerCanvas
	end)
```

## Target

One switch at a time. A monotonically increasing `SwitchToken` invalidates any in-flight thread; only the newest thread is allowed to perform the mid-point visibility swap and the final reparent. Phase-1 motor goals are set **synchronously** on click, so the spring retargets from its live value immediately (springs are inherently interruptible — AUDIT.md §4). Keep the existing spring configs exactly: out `frequency = 10`, in `frequency = 5` (position) and `frequency = 8` (alpha), all with Flipper's default `dampingRatio = 1`. Keep the two `task.wait(0.12)` timers as the phase boundaries — this plan removes the *stacking*, not the timing values.

```lua
	Window.TabDisplay.Text = Target.Name
	Window.SelectorPosMotor:setGoal(Spring(TabModule:GetCurrentTabPos(), { frequency = 6 }))

	-- A new selection invalidates the in-flight switch so two threads never
	-- write the container motors or visibility at the same time.
	TabModule.SwitchToken = TabModule.SwitchToken + 1
	local Token = TabModule.SwitchToken

	Window.ContainerHolder.Parent = Window.ContainerAnim
	Window.ContainerPosMotor:setGoal(Spring(15, { frequency = 10 }))
	Window.ContainerBackMotor:setGoal(Spring(1, { frequency = 10 }))

	task.spawn(function()
		task.wait(0.12)
		if Token ~= TabModule.SwitchToken then return end
		for _, Container in next, TabModule.Containers do
			Container.Visible = false
		end
		TabModule.Containers[Tab].Visible = true
		Window.ContainerPosMotor:setGoal(Spring(0, { frequency = 5 }))
		Window.ContainerBackMotor:setGoal(Spring(0, { frequency = 8 }))
		task.wait(0.12)
		if Token ~= TabModule.SwitchToken then return end
		Window.ContainerHolder.Parent = Window.ContainerCanvas
	end)
```

## Repo conventions to follow

- Tab state already lives on `TabModule` (`SelectedTab`, `Tabs`, `Containers` near `src/Components/Tab.lua:10-13`) — put `SwitchToken = 0` there.
- Spring goals use the local `Spring = Flipper.Spring.new` alias at `src/Components/Tab.lua:6`; never call `Flipper.Spring.new` inline.
- Exemplar for interruptible state from the live value: `src/Components/Window.lua:196-202` (`OpenMotor.onStep` retargets from the presentation value; no per-click thread).

## Steps

1. `src/Components/Tab.lua:10-13` — add `SwitchToken = 0,` to the `TabModule` table next to `SelectedTab = 0,`.
2. `src/Components/Tab.lua:169-170` — keep both lines unchanged.
3. `src/Components/Tab.lua:171-185` — replace the whole `task.spawn` block with the target code above: increment/invalidate `SwitchToken` before spawning, set phase-1 goals synchronously, add `if Token ~= TabModule.SwitchToken then return end` after **each** `task.wait(0.12)`.
4. Do not touch any other file.

## Boundaries

- Do NOT change spring frequencies (10 / 5 / 8) or the `0.12` waits — this plan fixes stacking only.
- Do NOT touch `SelectTab`'s `Selected` bookkeeping, `Window.TabDisplay.Text`, or `SelectorPosMotor`.
- Do NOT add dependencies, threads pools, or new modules.
- If the code has drifted from the verbatim excerpt, STOP and report instead of improvising.

## Verification

- **Mechanical**: `$env:PATH = "$env:USERPROFILE\.aftman\bin;$env:PATH"; selene src Addons spec --config selene.toml` → `0 errors`; `lune run spec/run.luau` → `38 passed, 0 failed`; `lune run build/init` → completes.
- **Feel check** (live via MCP Real client): rebuild `dist/main.lua`, re-run `Example.client.lua`, call `Window:SelectTab(1)` then rapidly alternate `SelectTab(1)` / `SelectTab(2)` ~10 times with ~60ms gaps. Confirm:
  - only the **last** selected tab's content is visible after the burst;
  - no frame shows two containers visible at once;
  - `ContainerHolder` ends up parented back under `ContainerCanvas` (not stranded in `ContainerAnim`).
  - Review at 2–5× duration using a slowed `task.wait` in a scratch copy if needed; watch the mid-point swap, not just the final frame.
- **Done when**: the burst test leaves exactly one visible container matching `SelectedTab`, and no stale thread can reparent `ContainerHolder` after the final switch.
