# Renderorange Firefox Theme — Design

Date: 2026-10-01
Status: Approved design, pending implementation plan

## Purpose

Restore the pre-redesign Firefox look — square-ish UI elements with a slight
border radius — combined with a soft gray palette. Firefox 137+ introduced
rounded floating toolbar buttons and a redesigned chrome; this theme walks that
back via `userChrome.css`.

Distribution is GitHub + manual install. A WebExtension theme cannot change
element shapes (AMO themes are colors/images only), so `userChrome.css` is the
single delivery mechanism.

## Goals

- Full UI restyle: toolbar, tabs, URL bar, menus, popups, sidebar, findbar, dialogs.
- Pure grayscale palette (no accent colors).
- Light and dark variants, selected automatically via `prefers-color-scheme`.
- Works against Firefox 157.0 on Linux (the installed test target).

## Non-goals

- No web content styling (`userContent.css` is out of scope).
- No extension, no JavaScript.
- Not distributable via AMO.

## Architecture

One shipped file: `userChrome.css`, built from three layers:

1. **Token overrides.** Firefox exposes design tokens as CSS custom properties
   (`--toolbar-bgcolor`, `--toolbar-field-*`, `--tab-*`,
   `--button-border-radius`, etc.). Redefine them in `:root` for light and
   inside `@media (prefers-color-scheme: dark)` for dark. This covers every
   area that reads the tokens with zero selector risk.
2. **Shape patches.** Targeted selectors for what tokens cannot express:
   reconnecting the detached/floating toolbar layout, tab corner radius, URL
   bar radius, flat borders instead of shadows. Each patch is commented with
   what it fixes.
3. **Full-UI patches.** Remaining chrome details tokens do not cover:
   grayscale scrollbars, context-menu corners, dialog details.

Growth path: when layers 2–3 accumulate enough selectors that a single file
gets unwieldy, split into `src/*.css` partials plus a trivial concatenation
build; the shipped artifact always remains one `userChrome.css`.

## Palette

Pure grayscale. Flat surfaces, no gradients.

Light — soft cool grays:

| Role                    | Value     |
|-------------------------|-----------|
| Toolbar / tab strip     | `#f0f0f2` |
| Panels, hovered buttons | `#e4e4e7` |
| Selected tab            | `#e8e8ea` |
| URL bar field           | `#fafafa` |
| URL bar border          | `#d1d1d5` |
| Text                    | `#2b2b2e` |
| Secondary text          | `#5c5c61` |
| Divider lines           | `#d1d1d5` |

Dark — grays, not blacks:

| Role                    | Value     |
|-------------------------|-----------|
| Toolbar / tab strip     | `#2a2a2e` |
| Panels, hovered buttons | `#3a3a3f` |
| Selected tab            | `#424247` |
| URL bar field           | `#38383d` |
| URL bar border          | `#4c4c51` |
| Text                    | `#e8e8ea` |
| Secondary text          | `#a3a3a8` |
| Divider lines           | `#4c4c51` |

## Shape

- Toolbar buttons: 4px radius, no background until hover.
- Tabs: 4px top corners, flush with the tab strip; the current detached /
  floating toolbar layout is reconnected so tab strip, toolbar, and bookmarks
  read as one contiguous block.
- URL bar: 6px radius, flat 1px border, no shadow emphasis.
- Menus / popups: 6px radius, flat 1px borders, no drop shadows.
- No gradients anywhere.

## Repo layout

```
userChrome.css   ← the theme; users copy only this file
README.md        ← install steps, tested-on versions
LICENSE          ← MIT
tools/           ← dev-only: test-profile launcher + screenshot script
```

## Install flow

1. about:config → set `toolkit.legacyUserProfileCustomizations.stylesheets` to
   `true`.
2. about:support → open Profile Directory → create `chrome/` → place
   `userChrome.css` inside.
3. Restart Firefox.

## Resilience

- Token overrides (layer 1) absorb minor Firefox updates; only selector
  patches (layers 2–3) can break, and each is sectioned and commented so a
  future break is a localized fix.
- Low specificity throughout; `!important` only where a Firefox rule forces it.
- README records the Firefox version tested against.

## Testing

- Scratch profile in `/tmp` with the customization pref enabled.
- Screenshot script (X11 + ImageMagick `import`) captures: normal window,
  focused URL bar, open menu, sidebar — in light and dark, dark forced via
  prefs.
- Each shot is checked against the palette/shape tables; final screenshots get
  human review.

## Success criteria

- Theme applies cleanly on Firefox 157 with no visual artifacts in covered areas.
- Light and dark variants match the palette table exactly.
- README install steps work from a clean profile.