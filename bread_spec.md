# Bread Calculator — Claude Code Handoff Spec

## Context

Standalone sourdough bread calculator web app. Deployed to darkstar (192.168.1.192) as a Docker container. No backend — pure client-side calculator with localStorage recipe persistence.

## Decisions Already Made

Do not re-litigate these.

- **Stack**: Vanilla HTML/CSS/JS, single `index.html` — no framework, no build step
- **Server**: nginx:alpine Docker container, port 8090 on darkstar
- **Persistence**: localStorage only, key `bread_recipes`, JSON array of saved recipes
- **Flour bill**: percentages apply to **Fb (batch flour)** only — not total flour
- **No levain build output**: levain parameters are inputs describing an already-built levain, not instructions for making one

## Repo Layout

```
bread/
├── index.html
├── Dockerfile
├── docker-compose.yml
└── Makefile
```

## Before Writing Any Code

1. Explain your intended approach for the full `index.html` — HTML structure, CSS strategy, JS architecture (how inputs wire to outputs, how flour bill rows are managed, how localStorage is used)
2. Wait for confirmation before writing anything

## Math

Implement these exact formulas. Variable names must match this spec in the code.

```
B  = num_loaves × loaf_size          // batch size (g)
F  = B / (1 + hydration + salt)      // total flour (g)
W  = F × hydration                   // total water (g)
S  = F × salt                        // total salt (g)
Fp = F × inoculation                 // prefermented flour (g)
Wl = Fp × starter_hydration          // levain water (g)
L  = Fp + Wl                         // total levain (g)
Fb = F − Fp                          // batch flour (g)
Wb = W − Wl                          // batch water (g)

flour_bill[i].grams = flour_bill[i].pct × Fb
```

All inputs stored internally as decimals (hydration 72% → 0.72). All output gram values displayed rounded to 1 decimal place.

## Inputs

| Field | Default | Type |
|---|---|---|
| Num Loaves | 2 | integer ≥ 1 |
| Loaf Size (g) | 750 | number > 0 |
| Hydration | 72% | 0–100, decimal internally |
| Inoculation | 15% | 0–100, decimal internally |
| Salt | 2% | 0–100, decimal internally |
| Starter Hydration | 50% | 0–100, decimal internally |
| Flour bill | 1 row @ 100% | dynamic rows: name (text) + percentage (number) |

## Outputs (live — recalculate on every `input` event)

**Summary:**
- Batch Size (B)
- Total Flour (F)
- Total Water (W)
- Total Salt (S)

**Levain:**
- Prefermented Flour (Fp)
- Levain Water (Wl)
- Total Levain (L)

**Bench:**
- Batch Flour (Fb)
- Batch Water (Wb)

**Flour Bill Table:** name | % | grams — one row per flour, plus a totals row (sum of % and sum of grams)

## Flour Bill Behavior

- Minimum 1 row at all times
- "Add Flour" button appends a new empty row
- Each row has: name input, % input, remove button (hidden when only 1 row remains)
- Percentages must sum to exactly 100% — if not, show a visible warning and dim the outputs
- Default first row: name "Flour", 100%

## Recipes (localStorage)

- Storage key: `bread_recipes`
- Format: JSON array of `{ name: string, inputs: { ... }, flourBill: [ { name, pct } ] }`
- UI: "Save Recipe" button prompts for a name, saves current state
- Saved recipes shown as a tappable list — tap to load, with a delete button per recipe
- Recipe section can be a collapsible panel or simple section below the main form

## UI Requirements

- **Mobile-first** — designed for phone use in a kitchen (large tap targets, readable at arm's length)
- Single scrollable page
- Three logical sections in order: **Parameters → Flour Bill → Results**
- Recipes section below results or accessible via a button
- Clean, minimal aesthetic — this is a utility app, not a showcase
- No external dependencies — no CDN imports, no Google Fonts, nothing that requires network access to function

## Files

### Dockerfile
```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
```

### docker-compose.yml
```yaml
services:
  bread:
    build: .
    ports:
      - "8090:80"
    restart: unless-stopped
```

### Makefile
```makefile
DARKSTAR := 192.168.1.192

deploy:
	rsync -av --exclude='.git' . stream@$(DARKSTAR):~/bread/
	ssh stream@$(DARKSTAR) "cd ~/bread && docker compose up -d --build"
```

## Implementation Order

1. `index.html` — full implementation: HTML structure, CSS, JS
2. `Dockerfile`
3. `docker-compose.yml`
4. `Makefile`

## Testing

After implementation, provide exact commands to:
1. Open `index.html` directly in a browser (no server needed) and verify the calculator works
2. Deploy to darkstar with `make deploy`
3. Verify the app is accessible at `http://192.168.1.192:8090`

Do not mark the task complete until the deployed URL is confirmed accessible.
