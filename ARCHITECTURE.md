# Bread Calculator — Architecture Handoff

## 1. What it is

A single-page **sourdough bread recipe calculator**, mobile-first, used by a working baker (market production). Given a target yield and baker's percentages, it computes the full mixing formula, a levain build schedule, water temperature, and a printable "bake sheet" that mirrors the user's handwritten journal. All state is client-side.

## 2. Tech stack & architecture

- **One file**: `index.html` (~1458 lines). All HTML, CSS, and JS are inline. **No build step, no dependencies, no framework** — vanilla JS + inline `<style>`.
- **Rendering model**: a single `recalculate()` function reads every input, computes all derived values, and re-renders all output regions on every keystroke. The Water Temperature calculator is a separate self-contained IIFE at the bottom.
- **Styling**: CSS custom properties in `:root` (warm/tan palette). **Light theme only** — no dark mode. `main` is capped at `max-width: 500px` (phone-oriented). `--min-tap: 44px` for touch targets.
- **Persistence**: `localStorage` key `bread_recipes` only. No backend, no accounts.

## 3. Deployment

- **Dockerfile**: `nginx:alpine` serving the single `index.html` as static content.
- **docker-compose.yml**: service `bread`, `expose: 80`, joins an **external Docker network `edge`**, `restart: unless-stopped`. Sits behind a reverse proxy (darkstar-proxy, per git history) — it does not publish ports directly.
- **Makefile**: `make deploy SERVER=<host>` → `rsync` the repo to `~/bread/` on the server, then `docker compose up -d --build`. `SERVER` is required or it errors.
- **Repo**: `main` branch, git user John Dibling. Other files: `README.md`, `bread-spec.md`, `bread_spec.md`, `bread_ux_spec.md` — **these specs predate the last three features (below) and are likely stale**; treat code as source of truth.

## 4. Domain model & math (the core — all in `recalculate()`)

**Inputs**: `num_loaves`, `loaf_size` (g), `hydration` %, `inoculation` %, `salt` %, `batch_loss` (g), levain ratio `levain_seed : levain_flour : levain_water`, `mother_hydration` %, `levain_loss` (g).

Helpers: `num(id)` → `parseFloat` or 0; `pct(id)` → `num/100`; `getInput(id)` → raw string.

```
B_target = num_loaves × loaf_size                      // desired dough
B_scaled = B_target + batch_loss                       // grams added for loss (NOT a %)
F  = B_scaled / (1 + hydration + salt)                 // total flour
W  = F × hydration                                     // total water
S  = F × salt                                          // salt
Fp = F × inoculation                                   // prefermented flour (all flour in levain)

// Levain hydration — accounts for flour+water carried in by the seed:
seedFlourParts = seed / (1 + mother_hyd)
seedWaterParts = seed × mother_hyd / (1 + mother_hyd)
levainHyd = (seedWaterParts + water) / (seedFlourParts + flour)

Wl = Fp × levainHyd                                    // levain water
L  = Fp + Wl                                            // total levain mass
Fb = F − Fp                                             // batch flour (added directly)
Wb = W − Wl                                             // batch water
// each flour in the bill:  grams = pct × Fb
```

**Levain build** (scale the ratio to what's needed, round for practicality):

```
buildTarget = L + levain_loss
scale ratio to buildTarget; take smallest nonzero part in grams;
round it UP to nearest 5g (min 5); rescale the other two by the same factor (ratio preserved)
→ dSeed / dFlour / dWater, dBuildTotal = their sum
```

**Bake-sheet batches**:

```
dough    = B_scaled − L − (salt_in_mix ? S : 0)  // base dough excluding levain; salt excluded
                                                 // when weighed separately per batch at mix
nBatches = ceil(B_scaled / max_per_batch)  // capacity = FULL dough incl. levain; min 1
per batch:  dough/nBatches  and  L/nBatches  (and S/nBatches when salt_in_mix)
```

**Baker's % (Details panel)**: everything relative to `F`: `bp(v) = v/F × 100`.

**Water temperature** (independent IIFE): `waterTemp = DDT×4 − flourTemp − ambient − levainTemp − friction`. Friction factors: Hand 0, Orbital 27, Spiral 18. Levain temp auto-tracks ambient until manually edited (with a reset link).

## 5. UI structure (top to bottom)

- **`#banner`** — always-visible summary: `loaves | total(target) | hydration | loss | levain%`. Clicking it toggles the Parameters section. `flex-wrap` enabled.
- **`#form`** — contains **Parameters** and **Flour Bill** sections. A delegated `form.addEventListener('input', recalculate)` catches all inputs *inside the form*.
- **`#primary-results`** — always visible: LEVAIN, WATER, per-flour rows, SALT, TOTAL (scaled), TOTAL (target). Dims (`.dimmed`) when the flour bill doesn't sum to 100%.
- **Details** (collapsible) — F, W, Fp, Wl, Fb with baker's %.
- **Levain Build** (collapsible) — seed/flour/water/total grams.
- **Bake Sheet** (collapsible) — inputs: `recipe_name`, `bake_note`, `max_per_batch`, a **`salt_in_mix`** checkbox ("Add Salt During Mix"), a dynamic **mix-steps** editor, and a **Print** button. ⚠️ **This section is OUTSIDE `#form`**, so it has its **own** `#bake-sheet-inputs` input listener. Any new input added outside the form needs the same treatment. When `salt_in_mix` is checked, the printout's Parameters box tags salt with "(mix)" and the Batches box gains a per-batch **Salt** line (`S / nBatches`, from the total-recipe salt `S = F × salt`).
- **Recipes** (`<details>`) — save (prompts for name, prefilled from `recipe_name`) / load / update / delete from localStorage. `loadedRecipeIndex` (module-level, null unless a recipe was loaded or just saved) tracks which saved recipe is loaded: the loaded item is highlighted (`.recipe-item.loaded`), a **"Save Changes to “name”"** button (`#btn-update-recipe`) overwrites that entry in place (keeping its save-time name), and the save button flips to secondary-styled **"Save as New Recipe"**. Deleting adjusts/clears `loadedRecipeIndex`.
- **Water Temperature** (collapsible) — the separate module.
- **`#bake-sheet`** — the print layout, `display:none` on screen; `@media print` hides `main` and reveals only this. Populated inside `recalculate()`. Matches the journal: header (date·name·yield·note), top row (Parameters / Flour Bill / Levain Build), bottom row (Formula / Batches with mix steps).

Collapsible pattern: `.collapsible-section` + toggling `.open` on header click.

## 6. Persistence schema

`localStorage['bread_recipes']` = array of:

```js
{ name, inputs: { num_loaves, loaf_size, batch_loss, hydration, inoculation, salt,
                  levain_seed, levain_flour, levain_water, mother_hydration, levain_loss,
                  recipe_name, bake_note, max_per_batch,
                  salt_in_mix },   // boolean (checkbox), unlike the other string values
  flourBill: [{ name, pct }],
  mixSteps:  [{ label, min }] }
```

**No schema versioning.** `loadRecipe()` sets only keys that exist (`if (inp[id] !== undefined)`), so older recipes silently fall back to HTML defaults for new fields. The migration policy chosen so far is deliberately "ignore old data."

## 7. Recent change history (last 3 features — code is ahead of the spec docs)

1. **Batch loss** changed from a **percentage** to **absolute grams** (`B_scaled = B_target + loss_g`, was `B_target / (1 − loss)`).
2. **Levain** reworked: removed the `starter_hydration` % input; replaced with a **seed:flour:water ratio + mother hydration %**, deriving true levain hydration (accounting for seed's own flour/water). Added a **Levain Build** panel with 5g-rounding, and a `levain_loss` (g) parameter. Levain hydration now shows on the banner.
3. **Bake Sheet**: print-only journal layout + inputs (name/note/capacity/mix-steps), batches computed from mixer capacity, browser-print via `@media print`. Validated to reproduce the user's handwritten 7/21 bake within rounding.

## 8. Known limitations / things to weigh in an architecture session

- **Monolith**: 1458-line single file, no modules, **no tests, no build/lint**. The main scaling question if features keep landing.
- **Rebuild-on-keystroke**: `recalculate()` recomputes everything and rebuilds flour/formula rows via `innerHTML` on every input. Fine at this scale. Flour/mix-step names are injected **unescaped** (self-XSS only, single-user local tool — consistent with existing code, but note it).
- **Two input-listener mechanisms** (form-delegated + `#bake-sheet-inputs`) — a foot-gun when adding inputs.
- **No localStorage migrations / versioning** — evolving the schema keeps silently dropping old data.
- **Naming duality**: `recipe_name` (Bake Sheet field) and the save-time `prompt()` name are unlinked — two "names."
- **Validation is thin**: relies on `min/max` attrs; flour bill sum-to-100% is warned, not enforced; division-by-zero is guarded only in specific spots (`levainFlourParts`, `ratioSum`, `max_per_batch`).
- **Interpretation assumptions** baked in (may deserve making explicit/configurable): loss is additive grams; seed is exactly at `mother_hydration`; mixer capacity = full dough incl. levain; bake-sheet date = today (not editable).
- **Light theme only**; print layout not verified across browsers/paper sizes.
