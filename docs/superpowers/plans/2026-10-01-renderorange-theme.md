# Renderorange Firefox Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A `userChrome.css` theme restoring square-ish shapes with a soft grayscale palette to Firefox 157.

**Architecture:** One shipped `userChrome.css` in three layers — design-token overrides (`light-dark()` autopicks light/dark), targeted shape patches, then selector patches for remaining chrome. A scratch-profile + screenshot harness in `tools/` verifies each layer visually.

**Tech Stack:** CSS only (Firefox design tokens, `light-dark()`); bash + ImageMagick `import`/`convert` + `xdotool` for the screenshot harness.

**Spec:** `docs/superpowers/specs/2026-10-01-renderorange-theme-design.md` — the plan argues from the spec; read both.

## Global Constraints

- Target: Firefox 157.0 (installed at `/usr/bin/firefox`), Linux, X11.
- Exact palette hexes: light toolbar `#f0f0f2`, panel/hover `#e4e4e7`, selected tab `#e8e8ea`, field `#fafafa`, field border `#d1d1d5`, text `#2b2b2e`, secondary `#5c5c61`, dividers `#d1d1d5`; dark toolbar `#2a2a2e`, panel/hover `#3a3a3f`, selected tab `#424247`, field `#38383d`, field border `#4c4c51`, text `#e8e8ea`, secondary `#a3a3a8`, dividers `#4c4c51`.
- Light/dark via `light-dark(light, dark)` (resolves off system `color-scheme`); no `@media (prefers-color-scheme)` blocks.
- Shipped artifact is the single root `userChrome.css`; users copy only that file.
- Low specificity, no `!important` unless a Firefox chrome rule forces it; every shape patch carries a comment naming what it fixes.
- Pure grayscale — no accent colors anywhere, including focus rings.
- License: MIT.

## Review Focus

| # | Condition | Expected behavior |
|---|-----------|-------------------|
| 1 | Window maximized / fullscreen | Titlebar buttons (`.titlebar-buttonbox`) stay aligned, no stray margins or gaps at the top edge |
| 2 | System switches light↔dark while Firefox runs | UI recolors live; no element keeps the old palette |
| 3 | Bookmarks toolbar visible | Separator and background match toolbar grays; contiguous block look preserved |
| 4 | Popup panels (hamburger menu, extension popups) | Gray background, 6px radius, flat border, no drop shadow |
| 5 | Private browsing window | Same palette applies (private-mode purple indicator is Firefox-blessed, leave it) |
| 6 | `prefers-contrast` / forced-colors | We never target these media queries, so Firefox's contrast overrides keep winning |
| 7 | Compact density vs normal | Spacing nets out the same in both densities after removing the floating-tab margins |

Each row gets its check added to the owning task's verify step.

---

### Task 1: Screenshot test harness

**Files:**
- Create: `tools/test-profile.sh`
- Create: `tools/screenshot.sh`
- Create: `tools/README.md` (only in the no-sudo fallback of Step 1)

**Interfaces:**
- Consumes: `userChrome.css` at repo root (may not exist yet — harness must still run and produce a default-look capture so Task 1 verifies alone).
- Produces:
  - `tools/test-profile.sh [DARK=1]` — creates a scratch profile, launches Firefox; leaves process in foreground.
  - `tools/screenshot.sh <label>` — captures every Firefox X window to `shots/<label>.png`; prints saved paths.
  - Both scripts exit nonzero with a message when prerequisites are missing.

- [ ] **Step 1: Ensure automation tools exist**

`xdotool` is missing (X11 + ImageMagick already present). Run `sudo apt install xdotool`; if sudo is unavailable, note in `tools/README.md` that state screenshots (focused URL bar, open menus) require the reviewer to trigger them manually and re-run `tools/screenshot.sh <label>`.

Verify: `which xdotool import convert xwininfo` all resolve.

- [ ] **Step 2: Write `tools/test-profile.sh`**

Behavior pinned: profile at `/tmp/ro-profile-<ts>`; `user.js` sets `toolkit.legacyUserProfileCustomizations.stylesheets=true`, `browser.nova.enabled=true` (the redesign we are reverting — always on for testing), and if `DARK=1`, `ui.systemUsesDarkTheme=true`; if a repo-root `userChrome.css` exists, symlink it into `<profile>/chrome/userChrome.css` (mkdir chrome first), otherwise launch without; exec `firefox -no-remote -profile <dir>`.

- [ ] **Step 3: Write `tools/screenshot.sh`**

Behavior pinned: single arg `label`; `mkdir -p shots`; find Firefox window ids via `xwininfo -root -tree | grep -i "mozilla firefox"`; capture each with `import -window <id> shots/<label>.png`; print each saved path.

- [ ] **Step 4: Verify harness end-to-end**

Run `./tools/test-profile.sh`, then `./tools/screenshot.sh stage0`. Expected: `shots/stage0.png` exists, `file` reports PNG, it opens showing a Firefox window with the default 157 look.

- [ ] **Step 5: Commit**

```bash
git add tools/ shots/ && git commit -m "feat: add Firefox screenshot test harness"
```

(Add `shots/` to `.gitignore` — captures are not shipped.)

---

### Task 2: Layer 1 — grayscale token overrides

**Files:**
- Create: `userChrome.css`

**Interfaces:**
- Consumes: `tools/test-profile.sh`, `tools/screenshot.sh` from Task 1.
- Produces: `userChrome.css` layer-1 block, with header comment (`/* Renderorange — layers: 1 tokens / 2 shape / 3 chrome */`) and layer banners; later tasks append to it.

- [ ] **Step 1: Write the layer-1 token block in `userChrome.css`**

`:root { ... }` defining exactly these pairs, every color as `light-dark(a, b)` with spec hexes:

| Token | light | dark |
|---|---|---|
| `--toolbox-background-color` | `#f0f0f2` | `#2a2a2e` |
| `--toolbox-background-color-inactive` | `#f0f0f2` | `#2a2a2e` |
| `--toolbox-text-color` | `#2b2b2e` | `#e8e8ea` |
| `--toolbar-background-color` | `#f0f0f2` | `#2a2a2e` |
| `--toolbar-text-color` | `#2b2b2e` | `#e8e8ea` |
| `--tab-background-color-hover` | `#e4e4e7` | `#3a3a3f` |
| `--tab-background-color-selected` | `#e8e8ea` | `#424247` |
| `--toolbarbutton-background-color-hover` | `#e4e4e7` | `#3a3a3f` |
| `--toolbarbutton-background-color-active` | `#d8d8dc` | `#4a4a4f` |
| `--toolbar-field-background-color` | `#fafafa` | `#38383d` |
| `--toolbar-field-background-color-focus` | `#ffffff` | `#424249` |
| `--toolbar-field-border-color` | `#d1d1d5` | `#4c4c51` |
| `--toolbar-field-border-color-focus` | `#8f8f9a` | `#9a9aa2` |
| `--toolbar-field-text-color` | `#2b2b2e` | `#e8e8ea` |
| `--toolbar-field-text-color-focus` | `#2b2b2e` | `#e8e8ea` |
| `--panel-background-color` | `#e4e4e7` | `#3a3a3f` |
| `--tabs-navbar-separator-color` | `#d1d1d5` | `#4c4c51` |
| `--tabs-navbar-separator-style` | `solid` | `solid` |

Header comment records that Firefox 157's defaults live in `@layer` blocks inside `chrome://global/skin/design-system/tokens-shared.css`, so these unlayered overrides win without `!important`.

- [ ] **Step 2: Verify light capture**

Run `./tools/test-profile.sh`, `./tools/screenshot.sh tokens-light`. Paste the shots into chat. Expected: toolbar/tab strip is `#f0f0f2`, URL bar field is `#fafafa` with a visible flat border, selected tab `#e8e8ea`. Sample the printed PNG to confirm: `convert shots/tokens-light.png -format "%[pixel:p{X,Y}]" info:` (pick a flat toolbar point, not an edge/icon) should print an RGB within ±3 per channel of `(240,240,242)`.

- [ ] **Step 3: Verify dark capture**

Run `DARK=1 ./tools/test-profile.sh`, `./tools/screenshot.sh tokens-dark`. Expected: toolbar `#2a2a2e`, field `#38383d`, text light `#e8e8ea`; pixel-sample as in Step 2 for `(42,42,46)`.

- [ ] **Step 4: Verify review-focus rows 2, 5, 6**

- Row 2 (live recolor): with DARK=1 session running, toggle the OS/`ui.systemUsesDarkTheme` switch and re-shoot; whole UI recolors.
- Row 5 (private window): capture `about:privatebrowsing` window; palette holds, only Firefox's purple indicator differs.
- Row 6 (contrast): in `user.js` add `ui.useAccessibilityTheme`/OS high-contrast; capture; Firefox defaults should visibly override us. NOTE: if forcing this gets messy on the box, record in `tools/README.md` as a manual checklist item instead of a scripted capture.

- [ ] **Step 5: Commit**

```bash
git add userChrome.css && git commit -m "feat: add grayscale token overrides (layer 1)"
```

---

### Task 3: Layer 2 — squares back: radii, shadows, reconnection

**Files:**
- Modify: `userChrome.css` (append layer-2 block)

**Interfaces:**
- Consumes: layer-1 `userChrome.css`; harness from Task 1.
- Produces: layer-2 radii/shadow tokens plus the `.tab-background` patch; later tasks assume these names are set.

- [ ] **Step 1: Add radius + shadow tokens to `:root`**

`--button-border-radius: 4px;` `--toolbarbutton-border-radius: 4px;` `--tab-border-radius: 4px;` `--urlbar-border-radius: 6px;` `--popup-border-radius: 6px;` `--panel-border-radius: 6px;` `--tab-box-shadow-selected: none;` `--toolbar-field-box-shadow: none;` (last one only if the URL bar still shows a shadow in the Step 2 capture).

Each line gets a one-comment: kills the Nova `--button-border-radius: 24px` pill, restores 4px, etc.

- [ ] **Step 2: Capture and fix the tab tops + detached toolbar**

Shoot the running profile. Inspect: tabs must have 4px *top* radius only and sit flush on the strip (Nova gives them all-corner radius with vertical margins). Apply the pinned patches, one at a time, re-shooting after each:

- `.tab-background { border-radius: 4px 4px 0 0; }` — top-corner-only radius
- `#TabsToolbar { --tab-margin-block: 0 !important; }` — only if the tab strip still floats off the toolbar (the `!important` case the spec allows: Firefox's layered token wins otherwise)
- `#navigator-toolbox { border-bottom: 1px solid var(--tabs-navbar-separator-color); }` — re-add the hairline separator the Nova layout dropped (only if absent in the capture)

If Firefox 157 needs different selectors than these, discover the real ones via the Browser Toolbox (Ctrl+Alt+Shift+I, pick the element, read computed `margin`/`border-radius`), and use those instead — same effect, same comments.

Expected final capture: one contiguous light-gray block from titlebar through bookmarks bar; urlbar a 6px-radius field; buttons square-ish 4px; no shadows anywhere.

- [ ] **Step 3: Verify review-focus rows 1, 3, 7**

- Row 1: capture maximized and F11 fullscreen; top edge clean, no double borders or gaps.
- Row 3: enable bookmarks toolbar (`about:config` `browser.toolbars.bookmarks.visibility`=always); capture; matches toolbar grays; contiguous.
- Row 7: flip `browser.compactmode.show`/density if available; capture; spacing consistent.

- [ ] **Step 4: Commit**

```bash
git add userChrome.css && git commit -m "feat: restore square radii and contiguous toolbar (layer 2)"
```

---

### Task 4: Layer 3 — menus, popups, scrollbars, dialogs

**Files:**
- Modify: `userChrome.css` (append layer-3 block)

**Interfaces:**
- Consumes: layers 1–2; harness.
- Produces: final layer-3 block; nothing downstream depends on it.

- [ ] **Step 1: Nearest-gray scrollbars in chrome**

Pin: `scrollbar-color: light-dark(#bcbcc1, #55555b) transparent;` on `:root`. Capture sidebar (Ctrl+B) and confirm thumb renders neutral gray in both palettes; skip styling native GTK scrollbars — noted in a comment.

- [ ] **Step 2: Flat gray menu/popup surfaces**

Open the hamburger menu, the extension popup, and a context menu (xdotool; or review manually). Confirm: `#e4e4e7`/`#3a3a3f` background, 6px radius, 1px flat border, no drop shadow. Whitespace for shadow removal: remove `box-shadow` on `panel` / `.panel-arrow` equivalents Firefox 157 actually uses (Browser Toolbox discovery, as in Task 3 Step 2); do not chase arrow-panel fakes if the popup already reads flat.

- [ ] **Step 3: Dialogs + findbar pass**

Capture an open findbar (Ctrl+F) and a dialog (e.g. Clear Recent History via Ctrl+Shift+Del). Expected: grays from layers 1–2 with no blue/purple accents; if ChromeNow renders them, add the minimal selector patches (documented with comments) and re-shoot. Focus rings anywhere must be gray, from `--toolbar-field-border-color-focus`.

- [ ] **Step 4: Verify review-focus row 4**

Capture hamburger + extension popup specifically; assertions from Step 2 hold; record shots in chat.

- [ ] **Step 5: Commit**

```bash
git add userChrome.css && git commit -m "feat: gray out menus, popups, scrollbars, dialogs (layer 3)"
```

---

### Task 5: Ship: README, LICENSE, previews, final suite

**Files:**
- Create: `README.md`
- Create: `LICENSE` (MIT, copyright "Renderorange contributors")
- Create: `assets/preview-light.png`, `assets/preview-dark.png` (renamed finals from `shots/`)
- Modify: `tools/README.md` (add test-run instructions if Task 1's fallback note created it)

**Interfaces:**
- Consumes: complete `userChrome.css`, harness.
- Produces: distributable repo state; nothing downstream.

- [ ] **Step 1: Write `README.md`**

Sections pinned: title + one-line description; both preview images inline; Install (exact: about:config → `toolkit.legacyUserProfileCustomizations.stylesheets` → `true`; about:support → Profile Directory → create `chrome/` → drop `userChrome.css`; restart); "Tested against Firefox 157.0 on Linux"; Uninstall (delete file, optional pref revert); license line.

- [ ] **Step 2: Capture preview finals**

Fresh light and dark captures (both: normal window). Save as `assets/preview-light.png` and `assets/preview-dark.png`. Paste in chat for human approval of the look.

- [ ] **Step 3: Run the full final suite**

All states, both palettes: normal, focused URL bar, open hamburger menu, open extension popup, sidebar, findbar, maximized, private window. Each shot checked against the spec's palette/shape tables and the success criteria; any failure loops back into the owning task's layer.

- [ ] **Step 4: Spec success-criteria checklist**

Against spec "Success criteria": theme applies to Firefox 157 with no artifacts; both variants match palette table exactly (pixel-sampled); README install steps verified from the scratch profile. Write the three lines as `## Verification` notes at the end of `tools/README.md`.

- [ ] **Step 5: Commit**

```bash
git add README.md LICENSE assets/ tools/ userChrome.css
git commit -m "docs: ship README, license, and previews; final verification suite"
```