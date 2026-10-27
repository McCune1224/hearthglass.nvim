#!/usr/bin/env bash
# Remove the hearthglass Plasma themes and return to Breeze.
set -euo pipefail

here="$(cd -- "$(dirname -- "$0")" && pwd)"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"

if command -v plasma-apply-lookandfeel >/dev/null 2>&1; then
  plasma-apply-lookandfeel -a org.kde.breeze.desktop >/dev/null 2>&1 || true
fi
if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
  plasma-apply-colorscheme BreezeLight >/dev/null 2>&1 || true
fi
kwriteconfig6 --file kdeglobals --group Icons --key Theme breeze --notify 2>/dev/null || true
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__Breeze 2>/dev/null || true
kwriteconfig6 --file kwinrc --group TabBox --key LayoutName Breeze 2>/dev/null || true
kwriteconfig6 --file ksplashrc --group KSplash --key Theme org.kde.breeze.desktop 2>/dev/null || true

while IFS=$'\t' read -r key face lnf scheme plasma decoration icons cursors wallpaper kate name; do
  [ "$key" = "key" ] && continue
  [ -z "$key" ] && continue
  rm -rf "${data_home:?}/plasma/look-and-feel/$lnf"
  rm -f "${data_home:?}/color-schemes/$scheme.colors"
  rm -rf "${data_home:?}/plasma/desktoptheme/$plasma"
  rm -rf "${data_home:?}/aurorae/themes/$decoration"
  rm -rf "${data_home:?}/wallpapers/$wallpaper"
  rm -f "${data_home:?}/org.kde.syntax-highlighting/themes/${key}-${face}.theme"
done < "$here/themes.tsv"

while IFS=$'\t' read -r _key _face _lnf _scheme _plasma _decoration icons _cursors _wallpaper _kate _name; do
  [ "$_key" = "key" ] && continue
  [ -z "$icons" ] && continue
  rm -rf "${data_home:?}/icons/$icons"
done < "$here/themes.tsv"
rm -rf "${data_home:?}/icons/hearthglass-cursors"
rm -rf "${data_home:?}/kwin/tabbox/hearthglass_grid"

if command -v kbuildsycoca6 >/dev/null 2>&1; then
  kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
fi
if systemctl --user is-active plasma-plasmashell.service >/dev/null 2>&1; then
  systemctl --user restart plasma-plasmashell.service
fi

echo "hearthglass KDE themes removed; Breeze restored."
