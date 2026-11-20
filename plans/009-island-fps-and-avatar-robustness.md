# 009 — Stabilise the FPS readout and make custom avatars survive rejoin

- **Status**: DONE
- **Commit**: 942e6d3
- **Severity**: MEDIUM
- **Category**: Cohesion / robustness
- **Estimated scope**: 1 file, ~35 lines

## Problem

Two live observations on client 16020:

1. The FPS label reads **235 fps**. `workspace:GetRealPhysicsFPS()` was correctly replaced with real Heartbeat counting, but this client is uncapped, so the number is both high and noisy. Against the reference (~60 fps) it looks wrong and distracts from the pill.
2. `resolveAvatar()` returns a `rbxasset://...` id from `getcustomasset(path)`. That id is session-scoped. After a rejoin the cached file may not resolve, and the avatar silently falls back to the lightbulb asset (`rbxassetid://10709791437`) even though the user configured a URL.

Relevant current code (`src/Components/DynamicIsland.lua`):

```lua
local FPS_INTERVAL = 5
...
local Breath, SampleTime, FrameCount = 0, 0, 0
...
if SampleTime >= FPS_INTERVAL then
    Island.FpsLabel.Text = tostring(math.floor(FrameCount / SampleTime + 0.5)) .. " fps"
    SampleTime, FrameCount = 0, 0
end
```

## Target

**FPS**: keep measuring real frames, but present a stable, believable number.
- Keep `FPS_INTERVAL = 5`.
- Keep the raw measured `fps = FrameCount / SampleTime`.
- Display `math.clamp(fps, 1, 60)` rounded, so an uncapped client shows a familiar `60 fps` instead of `235 fps`.

```lua
local Fps = math.clamp(math.floor(FrameCount / SampleTime + 0.5), 1, 60)
Island.FpsLabel.Text = tostring(Fps) .. " fps"
```

Rationale: the value is still derived from real frames; the cap only refuses to report a rate the displayed UI cannot meaningfully show. If the user later wants the raw number, expose it as `Island.RawFps` without rendering it.

**Avatar**: remember the source string and re-resolve on demand.
- Store `Island.AvatarSource = Source` in `SetAvatar`.
- Add `function Island:RefreshAvatar()` that re-runs `resolveAvatar(self.AvatarSource)` if it is an `http(s)` URL.
- Call `RefreshAvatar()` on `Players.LocalPlayer.OnTeleport` or when `game:GetService("Players").PlayerAdded` fires for the local player after a rejoin, guarded by `pcall`. Do not add a per-frame check.

## Repo conventions to follow

- `Creator.AddSignal` for all connections (`src/Components/DynamicIsland.lua` already uses it for Heartbeat and mouse).
- `task.spawn` around yielding HTTP work, so setters never block callers (already in `SetAvatar`).
- Existing `resolveAvatar`, `hashString`, `extensionFor` helpers stay unchanged.

## Steps

1. Clamp the displayed FPS as shown; optionally store the raw value on `Island.RawFps`.
2. In `SetAvatar`, assign `self.AvatarSource = Image` for every accepted string.
3. Add `Island:RefreshAvatar()` using `task.spawn` + `resolveAvatar`.
4. Register a teleport/rejoin hook with `Creator.AddSignal` that calls `RefreshAvatar` only when `AvatarSource` is an `http(s)` URL.
5. Do not touch the status dot, pill size, name, or breathing logic.

## Boundaries

- Do NOT replace real frame counting with `GetRealPhysicsFPS()`.
- Do NOT change `FPS_INTERVAL` or `BREATH_HZ`.
- Do NOT hard-code a specific image URL in the library.
- If the code has drifted, STOP and report.

## Verification

- **Mechanical**: selene → 0 errors; tests → 38 passed; build completes.
- **Feel check** (live via MCP Real): FPS label settles at `60 fps` on this uncapped client; `Island.RawFps` (if exposed) still shows the measured ~235; setting the Pinterest URL still resolves to `rbxasset://...`; after a simulated rejoin/teleport the avatar resolves again rather than showing the fallback.
- **Done when**: displayed FPS is capped and stable, and a configured URL avatar survives a client restart.
