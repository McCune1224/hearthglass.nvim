# TODO

- [x] Sync the kitty light palette (base6/base7) with the light ramp in
      `lua/hearthglass/colors.lua`, then regenerate the kitty confs so the
      "same palette, matching day/night modes" claim holds.
- [x] Stop tracking the `kitty/__pycache__/*.pyc` build artifact: add
      `__pycache__/` to `.gitignore` and remove it from the index.
- [x] Trim the Ember/deepwhite mentions from the README prose and move the
      credit into a short Inspirations section at the bottom.
- [x] Keep Hearthglass, Sanguine, Vinifera and Daisy as the warm core.
- [x] Add Smoked, Frosted, Cathedral and Leaded with distinct color directions.
- [x] Add Stained as the Gruvbox-inspired variation.
- [x] Document the glass-form naming convention and the Hearthglass family
      name in the README.
- [x] Single-source every integration: kitty reads an export of `themes.lua`,
      Zed reads `colors.lua` directly, KDE reads the exported snapshot.
- [x] Ship all nine families as KDE Plasma 6 global themes in both faces,
      bump the KDE release version and rebuild the dist tarball.
- [x] Add the contrast audit, palette drift check and colorscheme load check
      under `scripts/`, and pass all three on the final tree.
