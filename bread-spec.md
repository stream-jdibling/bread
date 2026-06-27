# Bread Calculator — Water Temperature Tool Spec

## Context

The calculator is live at https://bread.aldenkitchen.com. This spec adds a collapsible Water Temperature calculator as a separate tool on the same page, below the batch calculator. No changes to existing functionality.

## Decisions Already Made

- Separate collapsible card, visually distinct from the batch calculator
- Four-variable DDT formula (flour, ambient, levain, water)
- Levain temp defaults to ambient temp — updates automatically when ambient changes unless the user has manually edited levain temp
- Friction factors hardcoded by mixing method: Hand = 0°F, Orbital = 27°F, Spiral = 18°F
- Units: °F throughout
- Collapsed by default

## Before Writing Any Code

1. Read the existing `index.html` fully
2. Explain where the new card is inserted in the DOM, how the levain-defaults-to-ambient behavior is implemented, and how the mixing method selector works
3. Wait for confirmation before writing anything

## Math

```
Water Temp = (DDT × 4) - Flour Temp - Ambient Temp - Levain Temp - Friction Factor
```

Friction factors:
- Hand mixing: 0
- Orbital mixer: 27
- Spiral mixer: 18

## Inputs

| Field | Default | Notes |
|---|---|---|
| DDT (°F) | 78 | Desired dough temperature |
| Flour Temp (°F) | — | No default, required |
| Ambient Temp (°F) | — | No default, required |
| Levain Temp (°F) | — | Defaults to Ambient Temp value; user can override |
| Mixing Method | Hand | Segmented control: Hand / Orbital / Spiral |

Levain Temp behavior: on every Ambient Temp change, if Levain Temp has not been manually edited, update Levain Temp to match. Once the user edits Levain Temp directly, stop syncing. Provide a small reset link ("↺ use ambient") to re-sync.

## Output

Single prominent result:

```
Water Temp: 68.0°F
```

If result is below 32°F or above 110°F, show a warning: "Check your inputs — result out of range."

Recalculate on every input change. No calculate button.

## UI

- Collapsible card, collapsed by default, positioned below the Recipes section
- Card header: "Water Temperature" with a chevron toggle
- Visually distinct from the batch calculator — different header style or subtle background difference to make clear it's a separate tool
- Mixing method: three-button segmented control (Hand | Orbital | Spiral), not a dropdown
- Show the assumed friction factor below the selector: e.g. "Friction factor: 27°F"
- Result displayed at the same scale as batch results — large, readable

## Deploy & Verify

1. Run `make deploy`
2. Verify at https://bread.aldenkitchen.com
3. Sanity check: DDT 78°F, Flour 68°F, Ambient 70°F, Levain 70°F, Hand → Water Temp = (78×4) - 68 - 70 - 70 - 0 = 104°F
4. Verify levain syncs to ambient until manually overridden, and reset link re-syncs
5. Do not mark complete until verified