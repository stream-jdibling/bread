# Bread Calculator

A standalone, mobile-first sourdough bread calculator. It sizes a batch from baker's
percentages, splits the dough into levain and final-mix components, distributes a custom
flour bill, and computes the mixing-water temperature needed to hit a target dough
temperature. Recipes are saved locally in the browser.

Live: **https://bread.aldenkitchen.com**

---

## What it is

The entire application is a **single static file** — [index.html](index.html) — containing
all HTML, CSS, and JavaScript inline. There is:

- **No backend.** All math runs client-side in the browser.
- **No build step.** No bundler, transpiler, or package manager for the app itself.
- **No external runtime dependencies.** No CDN, no fonts, no analytics — the page works
  fully offline once loaded. (This is a hard requirement: it's meant to run at arm's length
  in a kitchen on a phone.)
- **No framework.** Vanilla DOM APIs only.

Persistence is browser [`localStorage`](https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage)
under the key `bread_recipes` — a JSON array of saved recipes. Nothing leaves the device.

It's served in production by an `nginx:alpine` container that does nothing but return the
one HTML file.

---

## Features

The page contains **two independent calculators** plus a recipe store:

1. **Batch calculator** — the main tool. Enter batch parameters (loaves, size, loss,
   hydration, etc.) and a flour bill; get back exact gram weights for levain, water, salt,
   and each flour.
2. **Water Temperature calculator** — a separate, visually distinct collapsible card.
   Computes the mixing-water temperature from the desired dough temperature and the
   temperatures of the other ingredients.
3. **Recipes** — save the current parameter set + flour bill under a name, reload or delete
   it later. Stored in `localStorage`.

### UI layout

The page is a single scrollable column, mobile-first, optimized for glancing at with floury
hands. Structure top to bottom:

| Region | Default state | Behavior |
|---|---|---|
| **Summary banner** | always visible | Shows `loaves × size \| total \| hydration \| loss`. Tapping it toggles the Parameters section. |
| **Parameters** | collapsed | The batch inputs. |
| **Flour Bill** | collapsed | Dynamic list of flour rows (name + %). |
| **Primary Results** | always visible | The numbers you actually weigh out: LEVAIN, WATER, each flour, SALT, TOTAL. |
| **Details** | collapsed | Intermediate/"nerd" values (F, W, Fp, Wl, Fb) with baker's percentages. |
| **Recipes** | collapsed (`<details>`) | Save / load / delete. |
| **Water Temperature** | collapsed, visually distinct | The second calculator. |

Every input recalculates the whole page live on the `input` event — there is no "Calculate"
button anywhere.

---

## The math

All inputs are entered as percentages/whole numbers in the UI and converted to decimals
internally (e.g. hydration `72` → `0.72`). Gram outputs in the Primary Results are rounded
to whole numbers for display.

### Batch calculator

Implemented in [`recalculate()`](index.html) in `index.html`:

```
B_target = num_loaves × loaf_size          // what you want to end up with (g)
B_scaled = B_target / (1 − loss)           // scaled up to absorb batch/processing loss (g)

F  = B_scaled / (1 + hydration + salt)     // total flour (g)
W  = F × hydration                         // total water (g)
S  = F × salt                              // total salt (g)

Fp = F × inoculation                       // prefermented (levain) flour (g)
Wl = Fp × starter_hydration                // levain water (g)
L  = Fp + Wl                               // total levain (g)

Fb = F − Fp                                // batch (final-mix) flour (g)
Wb = W − Wl                                // batch (final-mix) water (g)

flour_bill[i].grams = flour_bill[i].pct × Fb   // flour bill distributes Fb, NOT F
```

Two design decisions worth flagging for anyone extending this:

- **Batch loss.** `B_target` is the finished weight you want; `B_scaled` is what you must
  mix to still have `B_target` after fermentation/handling losses. Flour, water, and salt
  are all derived from `B_scaled`, so the recipe over-produces by the loss factor. Both
  totals are surfaced in the UI (`TOTAL (scaled)` and `TOTAL (target)`).
- **Flour bill applies to `Fb` (batch flour), not `F` (total flour).** The prefermented
  flour (`Fp`) is assumed already committed to the levain, so the custom flour blend only
  distributes the flour added at final mix. The Primary Results show each flour's grams as
  `pct × Fb`.
- **Levain is an input, not an instruction.** The levain parameters describe an
  already-built starter; the app does not output a levain feeding schedule.

The **Details** section additionally shows each intermediate value as a baker's percentage
relative to total flour `F` (`value / F × 100`).

**Validation:** the flour-bill percentages must sum to exactly 100% (within a `0.0001`
tolerance). If they don't, a warning banner appears and the Primary Results are dimmed and
made non-interactive.

### Water Temperature calculator

Implemented in the IIFE at the bottom of `index.html`. Four-variable desired-dough-temperature
formula, all in °F:

```
Water Temp = (DDT × 4) − Flour Temp − Ambient Temp − Levain Temp − Friction Factor
```

Friction factor is hardcoded per mixing method (selected via a segmented control):

| Method | Friction (°F) |
|---|---|
| Hand | 0 |
| Orbital | 27 |
| Spiral | 18 |

Behavior details:

- **Levain temp defaults to ambient.** Whenever Ambient changes, Levain is updated to match —
  *unless* the user has manually edited Levain. A "↺ use ambient" reset link re-enables
  syncing.
- The result only computes once DDT, Flour, Ambient, and Levain are all filled in.
- If the computed water temp is `< 32°F` or `> 110°F`, an out-of-range warning is shown.

Sanity check: DDT 78, Flour 68, Ambient 70, Levain 70, Hand → `(78×4) − 68 − 70 − 70 − 0 = 104°F`.

---

## Inputs reference

### Batch parameters

| Field | Default | Notes |
|---|---|---|
| Num Loaves | 2 | integer ≥ 1 |
| Loaf Size | 750 g | > 0 |
| Batch Loss | 5 % | 0–100; scales the batch up |
| Hydration | 72 % | total water as % of flour |
| Inoculation | 15 % | prefermented flour as % of flour |
| Salt | 2 % | as % of flour |
| Starter Hydration | 50 % | water as % of prefermented flour |
| Flour bill | 1 row: "Flour" @ 100% | dynamic rows of name + %; must sum to 100% |

### Water temperature

| Field | Default | Notes |
|---|---|---|
| DDT | 78 °F | desired dough temperature |
| Flour Temp | — | required |
| Ambient Temp | — | required |
| Levain Temp | — | defaults to Ambient until overridden |
| Mixing Method | Hand | Hand / Orbital / Spiral |

---

## Recipe persistence

- **Storage:** `localStorage`, key `bread_recipes`.
- **Shape:**
  ```json
  [
    {
      "name": "Country loaf",
      "inputs": {
        "num_loaves": "2", "loaf_size": "750", "batch_loss": "5",
        "hydration": "72", "inoculation": "15", "salt": "2",
        "starter_hydration": "50"
      },
      "flourBill": [ { "name": "Bread Flour", "pct": 80 }, { "name": "Whole Wheat", "pct": 20 } ]
    }
  ]
  ```
- **Note:** the Water Temperature inputs are **not** part of a saved recipe — only batch
  parameters and the flour bill are persisted.
- Recipes are per-browser/per-device; there is no sync or export.

---

## Running locally

Because it's a single static file with no dependencies, you can just open it:

```bash
# Simplest: open the file directly
xdg-open index.html      # Linux
open index.html          # macOS
```

Or serve it (closer to production, avoids any `file://` quirks):

```bash
python3 -m http.server 8090
# → http://localhost:8090

# or with Docker, exactly as production builds it:
docker build -t bread .
docker run --rm -p 8090:80 bread
# → http://localhost:8090
```

The devcontainer ([.devcontainer/](.devcontainer/)) forwards port `8090` and adds
`darkstar` to `/etc/hosts` for deployment convenience.

---

## Deployment

### Topology

```
Browser ──HTTPS──> edge reverse proxy ──HTTP──> bread container (nginx:alpine, :80)
         bread.aldenkitchen.com          docker "edge" network
```

Production runs on a host referred to as **darkstar** (`192.168.1.192`). The bread container:

- Serves only `index.html` via `nginx:alpine` (see [Dockerfile](Dockerfile)).
- **Exposes** port 80 to the Docker network but publishes **no host port**
  (see [docker-compose.yml](docker-compose.yml)).
- Joins an **external Docker network named `edge`**, which a separate reverse proxy
  (originally `darkstar-proxy`) uses to route `bread.aldenkitchen.com` and terminate TLS.
- `restart: unless-stopped`.

> The `edge` network is declared `external: true`, so it must already exist on the host
> (created/owned by the reverse-proxy stack) before `docker compose up` will succeed.

The git history shows this evolved from a directly-published port (`8090:80`), to being
placed behind the `darkstar-proxy` reverse proxy, to the current external `edge` network.

### Deploy command

Deployment is a plain rsync + remote `docker compose` rebuild ([Makefile](Makefile)):

```bash
make deploy SERVER=<ssh-host>
```

This:
1. `rsync`s the repo (minus `.git`) to `~/bread/` on `$SERVER`.
2. SSHes in and runs `docker compose up -d --build`.

`SERVER` is **required** — the Makefile errors out if it's unset. It should be an SSH host
alias/target that resolves to darkstar and has the `edge` network and reverse proxy already
running.

---

## Repository layout

```
bread/
├── index.html            # the entire application (HTML + CSS + JS inline)
├── Dockerfile            # nginx:alpine serving index.html
├── docker-compose.yml    # container on external "edge" network, no published port
├── Makefile              # `make deploy SERVER=<host>` (rsync + remote compose)
├── bread_spec.md         # original build spec (batch calculator)
├── bread_ux_spec.md      # collapsible/banner UX redesign spec
├── bread-spec.md         # water-temperature tool spec
├── .devcontainer/        # VS Code dev container (Node, Docker-outside-of-docker, forwards 8090)
└── .claude/              # Claude Code settings
```

The three spec files are the historical handoff documents that drove each iteration and are
useful as design intent, but note they have drifted from the shipped code (see below).

---

## Notes for a roadmap

Things an architect should know before planning changes:

- **Single-file architecture is deliberate** — offline-first, zero-dependency, kitchen-phone
  use case. Any tooling (bundler, framework, CDN asset) works against the stated design
  constraint that the app must function with no network access. Weigh that before proposing a
  build step.
- **No tests, no CI.** There is no automated verification of the formulas or the UI. The
  math is the product's correctness surface; a small unit-test harness around the batch and
  water-temp formulas would be the highest-value addition and is currently impossible to
  attach cleanly because the logic is inline in the DOM handlers. Extracting the pure math
  into a testable module (while keeping the single-file deployment) is the main architectural
  lever.
- **Spec/code drift.** The specs predate some shipped behavior:
  - `bread_spec.md` says gram outputs are rounded to 1 decimal; the code rounds Primary
    Results to whole numbers.
  - The spec's formulas have no batch-loss term; the shipped code adds `batch_loss` and
    splits `TOTAL` into scaled vs. target.
  - Deploy target moved from a hardcoded `darkstar` / published `8090:80` to a required
    `SERVER` var and an external `edge` reverse-proxy network.
  Treat the code as source of truth; treat the specs as intent/history.
- **Persistence is device-local and lossy.** Recipes live only in one browser's
  `localStorage` — clearing site data loses them, and there's no export/import or
  cross-device sync. Water-temp settings aren't saved at all. Recipe portability is an
  obvious feature gap.
- **No input hardening beyond `NaN`→0.** Inputs are coerced with `parseFloat` and defaulted
  to 0; there's no upper-bound sanity checking (e.g. hydration > 100, negative loss) beyond
  HTML `min`/`max` attributes, which users can bypass by typing.
- **Deployment prerequisites are implicit.** `docker-compose.yml` depends on an
  externally-managed `edge` network and a separate reverse proxy for TLS and routing. Those
  aren't in this repo, so this repo alone is not a complete deployment.
- **Accessibility / i18n.** Units are hardcoded to grams and °F; there's no metric/imperial
  toggle for temperature and no localization. Minimal ARIA (a few `aria-label`s on icon
  buttons).
```

