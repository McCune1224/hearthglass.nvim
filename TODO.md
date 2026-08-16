# TODO

- [x] Sync the kitty light palette (base6/base7) in `kitty/hearthglass.py` with
      the light ramp in `lua/hearthglass/colors.lua`, then regenerate
      `kitty/hearthglass.conf` and `kitty/hearthglass-light.conf` so the
      "same palette, matching day/night modes" claim holds.
- [x] Stop tracking the `kitty/__pycache__/*.pyc` build artifact: add
      `__pycache__/` to `.gitignore` and remove it from the index.
- [x] Trim the Ember/deepwhite mentions from the README prose and move the
      credit into a short Inspirations section at the bottom.