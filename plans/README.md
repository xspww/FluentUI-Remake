# Animation / craft plans

Stamp commit: `942e6d3`

| # | Title | Severity | Status |
| --- | --- | --- | --- |
| 008 | Replace the island "search icon" with a real status dot | HIGH | DONE |
| 009 | Stabilise the FPS readout and make custom avatars survive rejoin | MEDIUM | DONE |
| 010 | Align the island status glow with its dot | MEDIUM | DONE |
| 011 | Shrink the island status dot | LOW | DONE |
| 012 | Size the island pill to its content | MEDIUM | DONE |
| 013 | Measure island text with TextService instead of TextBounds | MEDIUM | DONE |
| 014 | Remove island name truncation and add a measurement margin | MEDIUM | DONE |
| 015 | Spring the island's content-driven resize | MEDIUM | DONE |
| 016 | Force the layout motor to 0 before starting its spring | HIGH | DONE |
| 017 | Nudge the island FPS label slightly right | LOW | DONE |
| 018 | Equal island gaps and uncapped real FPS display | MEDIUM | DONE |
| 019 | Correct the island gap math so both gaps are 8px | MEDIUM | DONE |
| 020 | Add the final 8px gap between island dot and FPS | LOW | DONE |

Plans 001–007 were removed at the user's request.

## Verification notes

Both plans were executed in place on `src/Components/DynamicIsland.lua` and verified live on client 16020: the status element is now an 8x8 `Frame` circle with a 14x14 glow, breathing via alpha only; FPS displays a capped 60 while `RawFps` keeps the measured ~230; `RefreshAvatar` is available and hooked to teleport.
