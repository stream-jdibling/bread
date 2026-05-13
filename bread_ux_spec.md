# Bread Calculator — UX Improvement Spec

## Context

The calculator is already built and deployed at http://darkstar:8090. This spec describes UX changes only — no math changes, no new features. The existing `index.html` should be modified in place.

## Decisions Already Made

Do not re-litigate these.

- The math is correct and does not change
- Single `index.html`, no build step
- Deploy via `make deploy`

## Before Writing Any Code

1. Read the existing `index.html` fully to understand current structure
2. Explain your intended approach — which sections move, how collapse/expand state is managed, what CSS changes are needed
3. Wait for confirmation before writing anything

## Redesigned Layout

```
┌─────────────────────────────────┐
│  2 × 750g  |  1500g  |  72%    │  ← summary banner, always visible
├─────────────────────────────────┤
│  ▼ Parameters        [Edit]     │  ← collapsed by default
│    ...inputs...                 │
│  ▼ Flour Bill                   │  ← collapsed by default
│    ...flour rows...             │
├─────────────────────────────────┤
│  LEVAIN          234.5 g        │  ← primary results, always visible
│  WATER           456.2 g        │
│  Bread Flour     380.1 g        │
│  Whole Wheat      95.0 g        │
│  SALT             18.3 g        │
│  ────────────────────────────── │
│  TOTAL          1500.0 g        │
├─────────────────────────────────┤
│  ▶ Details                      │  ← collapsed by default
│    ...nerd stats...             │
└─────────────────────────────────┘
```

## Summary Banner

Always visible at the top. Never collapses. Shows:
- Num Loaves × Loaf Size (e.g. "2 × 750g")
- Total Batch Size (B, e.g. "1500g")
- Hydration (e.g. "72%")

Tapping the banner toggles the Parameters section open/closed. It should be visually clear it's tappable (chevron or subtle indicator).

## Collapse Behavior

- **Parameters**: collapsed by default, expands when banner is tapped
- **Flour Bill**: collapsed by default, has its own independent toggle
- **Details**: collapsed by default, has its own independent toggle
- Collapse state is per-section, independent
- No "collapse on blur" behavior — stays open until explicitly toggled

## Primary Results (always visible, never collapsible)

Display in this exact order:
1. LEVAIN — total levain (L)
2. WATER — batch water (Wb)
3. Each flour from the flour bill by name, in order — grams
4. SALT — total salt (S)
5. Divider line
6. TOTAL — batch size (B)

Large, readable text. Optimized for glancing at while hands are floury. Good contrast.

## Details Section (collapsed by default)

Contains everything not in the primary results:
- Total Flour (F)
- Total Water (W)
- Prefermented Flour (Fp)
- Levain Water (Wl)
- Batch Flour (Fb)

## Recipes Section

Retain existing recipe save/load behavior. Position below Details. No layout changes needed.

## Implementation Notes

- All collapse/expand via CSS (toggle a class, use `max-height` transition or `display` toggle) — no JS animation libraries
- Banner updates reactively on every input change, same as the rest of the outputs
- Mobile-first sizing stays the same — large tap targets, readable at arm's length

## Deploy & Verify

After implementation:
1. Provide the `make deploy` command
2. Confirm the app is accessible at `http://darkstar:8090`
3. Do not mark complete until deployed and confirmed