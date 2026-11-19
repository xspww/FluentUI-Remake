# 007 — Sidebar navigation groups (design spec, not yet implemented)

- **Status**: DONE (implemented after user approval; HTML preview at `preview/sidebar-groups.html`)
- **Commit**: bb621a4
- **Severity**: MEDIUM (feature / ergonomics)
- **Category**: Cohesion, physicality, accessibility
- **Estimated scope**: 2 files (`src/Components/Tab.lua`, `src/Components/Window.lua`) + optional `Example.client.lua` demo

## Goal

Make the sidebar scannable when there are many destinations: group related tabs under a non-collapsible section header, while keeping the existing flat tabs working exactly as before. Reference look: a section header with icon + label, indented child tabs with small icons, the existing `Selector` bar marking the selected child, and dimmed text for unselected children.

## Information architecture

- A **group header** is non-navigational: clicking it only OPENS its group, never closes it. It is never a tab, never appears in `Library.Options`, and never takes over the content pane.
- A **child tab** is an ordinary tab with a `Group` field. It behaves exactly like today's tab (selection, `Visible` container swap, `OnChanged`, etc.).
- Tabs **without** `Group` stay flat at the top, in declaration order, above all groups.
- Groups are created lazily on the first tab that names them. Order follows first appearance.
- **Only one group may be open at a time** (decided by the user after the HTML preview). Opening a different group closes the previous one, and selection **automatically moves to that group's first child** so the selected row is never hidden. **No header can close its own group** — a group closes only when another group opens or when a flat tab such as `Settings` is selected. Track the single open group in `TabModule.OpenGroup`.
- On first build, open the group that owns the initially selected tab; if no tab is selected, open the first group. Other groups start closed.
- `Window:SelectTab(Tab)` must make the owning group the single open group before/while selecting, so an API-driven selection is never hidden.

## Anatomy & exact measurements

All positions are relative to the sidebar `TabFrame` (`src/Components/Window.lua`, currently `Size = UDim2.new(0, Window.TabWidth, 1, -66)`, `Position = (12, 54)`). `TabWidth` default is 128–160px.

| Part | Size | Position | Style |
| --- | --- | --- | --- |
| Flat tab / group header | `(TabWidth - 24, 34)` | `(0, y)` from `UIListLayout` | icon 16 at x=8, label 12px at x=30, `ThemeTag.TextColor3 = "Text"` for header, `Text`/`SubText` for selected/unselected tab. **No chevron.** |
| Child tab | `(1, -CHILD_INDENT, 0, 30)` where `CHILD_INDENT = 22` | laid out by sub-list `UIPadding.PaddingLeft = 22` | icon 14 at x=8 relative to child, label at x=30, `TextSize = 12`. The real left offset comes from `UIPadding`, not just a narrower width — otherwise children line up with the group headers. |

Rules:
- Selected state is carried by the library's **existing `Selector` bar** (inside `TabFrame`, 4px wide) plus **weight (SemiBold vs Regular) and colour (Text vs SubText)** — never a filled background. A second, left-edge accent bar was added during implementation and removed at the user's request; do not reintroduce it.
- Child icons are kept (the reference show that small action icons at child level aid recognition), but they are 14px vs the parent's 16px to keep the hierarchy legible.
- Labels use `TextTruncate = Enum.TextTruncate.AtEnd` so long titles never overflow a 128px rail.
- Navigation rows have **no hover state at all** — no background fill and no colour change on hover (user decision after the HTML preview). Only selection changes appearance. Press feedback on `MouseButton1Down` is a separate, deliberate signal and remains.
- **Without a chevron the expand affordance is the group icon itself**: it stays `SubText` when closed and switches to `Accent` when open. The indented children appearing underneath reinforce the state. This keeps the header visually quiet and matches the flat tabs' language.

## Motion (Apple rules)

- One `ExpandMotor` per group, `Flipper.SingleMotor`, value 0 = closed, 1 = open.
- Goal: `Spring(target, { frequency = 5, dampingRatio = 1 })` — ~0.2s, no overshoot. Retargets from the live value, so a second tap mid-flight reverses cleanly.
- `onStep` drives, from the same value:
  - sub-list `Size.Y = contentHeight * v` with `ClipsDescendants = true` (Roblox has no compositor-only height property; this is a small, local list so the layout cost is bounded);
  - sub-list `CanvasGroup.GroupTransparency = 1 - clamp(v * 1.6, 0, 1)` (content fades in as it reveals);
  - group header icon colour interpolates `SubText → Accent` (driven by the same value, no second spring).
- Press feedback on the group header happens on **MouseButton1Down** (colour toward `Hover`), not on release — Apple §1.
- Keyboard-initiated navigation (arrow keys / Enter) changes state **instantly** — no animation (disqualifier rule).
- No stagger: group expansion is a single surface, not a list entrance.

## API additions

```lua
Window:AddTab({
    Title = "Child one",    -- any title; these names are only examples
    Icon = "box",
    Group = "Section A",    -- new: omit for a flat tab
    GroupIcon = "layers",   -- new: optional icon for an auto-created header
})

Window:SetGroupOpen("Section A", true, true)  -- name, open, animated
Window:ToggleGroup("Section A")
```

`TabModule` gains `Groups = { [name] = { Open, Header, Sublist, ExpandMotor, Tabs = {} } }`. Flat tabs remain in `Tabs`; grouped tabs live in both `Tabs` (for selection) and their group's `Tabs` (for layout). `GetCurrentTabPos()` keeps working because group headers are not in `Tabs`.

## Layout implementation notes

- Replace the single `UIListLayout` on `TabHolder` with a two-pass `LayoutNav()` that sets each element's `LayoutOrder` (or absolute `Position.Y`) explicitly: flat tabs first, then each header followed by its sub-list. A naive `UIListLayout` cannot make a sub-list collapse to zero height while keeping its parent header in flow.
- Sub-list `Visible` is flipped only at the extremes (`v <= 0.01` / `v > 0.01`) to avoid needless layout work while open.
- Do not add a second scroll container — the existing `TabHolder` ScrollingFrame already handles overflow; update `CanvasSize` from the nav layout.
- `SelectorPosMotor` must be re-targeted on **every frame a group folds/unfolds**: rows below the changed group shift after `UIListLayout` settles, so computing the selector target only in `SelectTab` leaves the bar at a stale position (~74px off when switching Section A → Section B). `refreshSelector()` is called from `ExpandMotor:onStep` and once more via `task.delay(0.3)` guarded by `SwitchToken`.

## Repo conventions to follow

- `Spring = Flipper.Spring.new`, `Instant = Flipper.Instant.new` at `src/Components/Tab.lua:6`.
- Spring motors are stopped in `Window:Destroy()` (`src/Components/Window.lua:398+`); each group motor must be registered there.
- Theme keys only: `Accent`, `Text`, `SubText`, `Hover`, `Element`, `ElementBorder`.
- `Creator.AddSignal` / `Creator.SpringMotor` for connections and feedback — no ad-hoc `task.spawn` for expansion.

## Verification (when implemented)

- **Mechanical**: selene → 0 errors; `lune run spec/run.luau` → 38 passed (add a spec for `SetGroupOpen` state if feasible); `lune run build/init` completes.
- **Feel check** (live via MCP Real):
  - spam a header 10× — sub-list and header icon colour retarget from the live value with no jump;
  - select a tab inside a closed group via `Window:SelectTab` — the group opens and the `Selector` bar lands on the correct row;
  - flat tabs still render above groups and keep the existing selection animation;
  - a 128px rail truncates a long child title with an ellipsis instead of overflowing;
  - keyboard arrow/Enter changes selection instantly;
  - opening Section B while Child one is selected closes Section A and selects Child three automatically;
  - clicking flat `Settings` while Section A is open closes Section A;
  - the single open group persists across tab switches.
  - clicking an already-open header does nothing — no group can be closed by its own header.
- **Done when**: exactly one group is open at a time, no header can close its group, the selected leaf is always visible, and no console errors appear.

## Open questions for the user

1. Should the group header itself be clickable to navigate to a summary page, or toggle-only? (Design above assumes toggle-only.)
3. Should group open/closed state persist to a config file via `SaveManager`, or be session-only?
