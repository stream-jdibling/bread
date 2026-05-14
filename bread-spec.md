# Bread Calculator — Batch Loss Factor Spec

## Context

The calculator is live at https://bread.aldenkitchen.com. This spec adds a loss factor input that inflates the scaled batch size so the final yield hits the target loaf weights. No other behavior changes.

## Decisions Already Made

- Loss factor applies to **total batch**, not per-loaf
- Default: 5%
- Target batch size (what you want) and scaled batch size (what you mix) are both displayed
- All downstream math (F, W, S, Fp, etc.) flows from `B_scaled`, not `B_target`

## Before Writing Any Code

1. Read the existing `index.html` fully
2. Explain which inputs, math, and output elements change
3. Wait for confirmation before writing anything

## Math Change

```
B_target = num_loaves × loaf_size          // unchanged — what you want to end up with
B_scaled = B_target / (1 - loss)           // new — what you actually mix
```

Replace all downstream uses of `B` with `B_scaled`. `B_target` is display-only.

Full updated formula set:
```
B_target = num_loaves × loaf_size
B_scaled = B_target / (1 - loss)
F  = B_scaled / (1 + hydration + salt)
W  = F × hydration
S  = F × salt
Fp = F × inoculation
Wl = Fp × starter_hydration
L  = Fp + Wl
Fb = F − Fp
Wb = W − Wl
flour_bill[i].grams = flour_bill[i].pct × Fb
```

## Input Change

Add one field to the Parameters section:

| Field | Default | Type |
|---|---|---|
| Batch Loss | 5% | 0–100, decimal internally |

Position it after Loaf Size, before Hydration — it's conceptually part of the yield parameters.

## Output Changes

Summary banner: add loss % to the existing fields.

Primary results card — update the TOTAL row:
- **TOTAL (scaled)**: B_scaled — this is what you mix
- **TOTAL (target)**: B_target — this is what you expect to yield

All other output rows remain the same, now correctly derived from B_scaled.

## Deploy & Verify

1. Run `make deploy`
2. Verify at https://bread.aldenkitchen.com
3. Sanity check: 3 loaves × 800g, 5% loss → B_target = 2400g, B_scaled = 2526.3g
4. Do not mark complete until verified