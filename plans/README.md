# Animation improvement plans

Stamp commit: `4608e95`

| # | Title | Severity | Status |
| --- | --- | --- | --- |
| 001 | Make tab switching single-owner and interruptible | HIGH | DONE |
| 002 | Give Root.Position one owner so drag and collapse cannot fight | HIGH | DONE |
| 003 | Slow the island collapse so the spatial move does not strobe | HIGH | DONE |
| 004 | Redesign the island transition with Apple-style motion principles | HIGH | DONE |
| 005 | Morph the main window into the Dynamic Island pill | HIGH | DONE |
| 006 | Track the Dynamic Island's live position while folded | MEDIUM | DONE |

## Recommended execution order

1. **001** — removes the stacked tab-switch threads; highest perceived impact on the common interaction, touches one file.
2. **002** — removes the two-motor write conflict on `Root.Position`; also one file, no dependency on 001.

The two plans are independent and may be executed in either order, but do 001 first if only one is applied.

## Dependencies

None between plans. Both depend only on the code at commit `4608e95`.

## Out of scope (reported, not planned)

- `src/Components/Dialog.lua:135` and `src/Components/Notification.lua:196` fixed `task.wait` timers — low frequency, lower leverage.
- Spring frequency tokens scattered across `Creator.lua:206`, `Window.lua:233,334`, `DynamicIsland.lua:15-16`, `Tab.lua:169-182` — cohesion cleanup.
- `Window.lua:227-237` `SelectorSizeMotor:setGoal` re-targeted every frame — needs a device recording first.
