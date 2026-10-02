# Tools (development only)

Launch a scratch profile with the theme applied, then capture:

```
./tools/test-profile.sh [DARK=1]   # foreground Firefox on a fresh /tmp profile
./tools/screenshot.sh <label>      # writes shots/<label>.png per Firefox window
```

Requires X11, ImageMagick (`import`, `convert`) and `xwininfo`; `xdotool` for
driveable states (focused URL bar, hamburger menu, sidebar, …). Captures land
in `shots/` (gitignored — never shipped).

## Verification

Verified 2026-10-01 against Firefox 157.0 on Linux (X11), palette pixel-sampled
from the final-suite captures in `shots/final-*-*.png` (normal, focused URL bar,
hamburger, extension popup, sidebar, findbar, maximized, fullscreen, private
window — light and dark), engine-computed styles checked on fresh profiles.

1. **Theme applies cleanly on Firefox 157 with no visual artifacts in covered
   areas.** Pass — every covered surface paints in palette hexes: toolbar/tab
   strip `#f0f0f2`/`#2a2a2e`, URL bar field `#fafafa`/`#38383d` (`#ffffff`/
   `#424249` focused), menus `#e4e4e7`/`#3a3a3f` with flat 1px borders, no drop
   shadows, 4px/6px radii. Two chrome accents were pinned grayscale in layer 3
   of `userChrome.css`: the fresh-profile feature-callout dot on the unified
   extensions button (`badge-blue.svg`, painted `#00B1F3`) and the URL-bar
   robot glyph that Firefox paints in brand red/orange/yellow during
   marionette/remote-debug sessions (`static-robot.png`, `#remote-control-icon`
   → `filter: grayscale`). Site/tab favicons stay colored on purpose — they are
   webpage content, not chrome, and are out of scope like all page content.
   Everything else sweeps clean (channel-spread > 14 sweep over the chrome
   band of both preview assets: only the 16×16 favicon flame, 191 px).
2. **Both variants match the palette table exactly (pixel-sampled).** Pass —
   exact hexes measured: light strip `#F0F0F2`, field `#FAFAFA`, focused field
   `#FFFFFF`, focus ring `#8F8F9A`, menu bg `#E4E4E7`, menu border `#D1D1D5`,
   sidebar bg `#F0F0F2`; dark strip `#2A2A2E`, field `#38383D`, focused field
   `#424249`, menu bg `#3A3A3F`, menu border `#4C4C51`, sidebar bg `#2A2A2E`.
   Scrollbar thumb is pinned to `#bcbcc1`/`#55555b` (engine-verified; the 157
   sidebar overlay thumb only paints while scrolling a long list, which the
   fresh test profile never has — worth one human hover over a populated
   sidebar).
3. **README install steps work from a clean profile.** Pass — the harness
   scratch profile performs the README steps verbatim (pref
   `toolkit.legacyUserProfileCustomizations.stylesheets` = `true`, file placed
   in the profile's `chrome/`, restart) and the theme applies; the previews in
   `assets/` show the resulting look.