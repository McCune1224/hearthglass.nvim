# hearthglass for KDE Plasma 6

Full global themes for Plasma 6, built from every hearthglass palette and
shaped after [Clay](https://github.com/arttvad9r/clay-kde-theme) by Artt: paper
surfaces, hairline outlines, a single restrained accent, and the same
component set. Light and dark are separate Global Themes, exactly as Clay
ships them.

| Family | Light Global Theme | Dark Global Theme |
| --- | --- | --- |
| Hearthglass | `Hearthglass` | `Hearthglass Dark` |
| Stained | `Stained` | `Stained Dark` |
| Sanguine | `Sanguine` | `Sanguine Dark` |
| Vinifera | `Vinifera` | `Vinifera Dark` |
| Daisy | `Daisy` | `Daisy Dark` |
| Smoked | `Smoked` | `Smoked Dark` |
| Frosted | `Frosted` | `Frosted Dark` |
| Cathedral | `Cathedral` | `Cathedral Dark` |
| Leaded | `Leaded` | `Leaded Dark` |

## What's inside

For every family and face:

- a KDE colour scheme (`.colors`)
- a Plasma style, all widgets and dialog frames
- an Aurorae window decoration
- a wallpaper (`<name> Field`)
- a look-and-feel package with splash, lock screen preview, logout screen and
  the hearthglass launcher mark
- a Kate/KWrite syntax theme

Shared across the family:

- nine icon themes (`hearthglass-icons`, `stained-icons`, ...,
  `leaded-icons`), one per palette, inheriting Breeze
- one cursor theme (`hearthglass-cursors`), like Clay's single cursor set
- one Alt+Tab switcher (`hearthglass_grid`)

`apply.sh` also installs the repository's kitty themes (`kitty/<key>.conf` and
`kitty/<key>-light.conf`) into `~/.config/kitty/themes` for `kitten themes`,
and mirrors them into kitty's `dark-theme.auto.conf` /
`light-theme.auto.conf` so the terminal follows the same family.

The widget style stays Breeze, as in Clay. There is no Kvantum or SDDM theme.

## Build

The palettes live in `lua/hearthglass/themes.lua`. Exporting them with Neovim
and rebuilding every asset keeps the desktop and editor in lockstep:

```bash
nvim --headless -l kde/export.lua
python3 kde/build.py
```

`kde/palettes.json` is the exported palette snapshot; `kde/build.py` writes
`kde/payload/` and `kde/themes.tsv`. Build requirements: Python 3, Neovim (for
the export), ImageMagick with the librsvg delegate, and the Breeze icon and
cursor sources (`breeze-icons`, `breeze_cursors`).

To add another family, append it to `kde/themes.json`; the export reads the
theme order from `lua/hearthglass/themes.lua`, then rebuild.

## Install

```bash
./kde/install.sh
```

Files go into `$XDG_DATA_HOME` (`~/.local/share` by default). Anything replaced
is backed up to `hearthglass-kde-backup-<timestamp>`.

## Apply

```bash
./kde/apply.sh hearthglass light
./kde/apply.sh hearthglass dark
./kde/apply.sh vinifera dark
./kde/apply.sh sanguine dark
./kde/apply.sh stained dark
./kde/apply.sh leaded light
```

Or pick the Global Theme in System Settings → Colors & Themes → Global Theme.
The colour scheme, Plasma style, icons, cursors, decoration, wallpaper, splash,
Kate theme and window switcher are all set by the script.

When `~/.config/kitty` exists, `apply.sh` also installs the same family's kitty
confs as `themes/<key>.conf` / `themes/<key>-light.conf` (visible in
`kitten themes`) and writes `dark-theme.auto.conf` / `light-theme.auto.conf`,
so the terminal follows the desktop's light/dark preference. The generated confs live in the
repository's `kitty/` directory (`kitty/<key>.conf` and
`kitty/<key>-light.conf`).

Convenience wrappers default to the flagship family:

```bash
./kde/apply-light.sh            # hearthglass light
./kde/apply-dark.sh             # hearthglass dark
./kde/apply-light.sh daisy
```

Check an installation with `./kde/verify.sh`; back out with
`./kde/uninstall.sh`. `./kde/build-release.sh` writes a redistributable
archive to `kde/dist/`.

## Colour mapping

The compact palette roles from `themes.lua` drive the desktop:

| Role | Neovim | KDE |
| --- | --- | --- |
| `crimson` | cursor, search, keywords | focus, active, links, close-button hover |
| `terracotta` | preprocessor | visited links, warning, wallpaper slab |
| `gold` | types, numbers | neutral/diagnostic neutral |
| `blue` | functions | links in views, metadata accents |
| `green` | diffs added, success | positive/diagnostic positive |
| `comment` | comments, line numbers | inactive foreground, secondary text |
| `bg` / `bg2` | Normal / CursorLine | view and window surfaces |

The dark window surface is stepped between the view and the raised button
paper, as in Clay, rather than jumping straight to the cursorline tone.

## Credits and licence

Clay's layout, generators, QML, widget frames, splash structure and icon
language are by Artt, licensed LGPL-2.1-or-later; the wallpapers are CC0-1.0.
This port keeps that licence for derived files — see `LICENSES.md` and
`LICENSES/`. The hearthglass palettes and the generated themes are part of
hearthglass.nvim.
