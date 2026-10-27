#!/usr/bin/env bash
# Verify an installed hearthglass KDE theme set.
set -euo pipefail

here="$(cd -- "$(dirname -- "$0")" && pwd)"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
errors=0

check_file() {
  if [ -e "$1" ]; then
    printf 'OK   %s\n' "$1"
  else
    printf 'MISS %s\n' "$1"
    errors=$((errors + 1))
  fi
}

while IFS=$'\t' read -r key face lnf scheme plasma decoration icons wallpaper kate name; do
  [ "$key" = "key" ] && continue
  [ -z "$key" ] && continue
  check_file "$data_home/plasma/look-and-feel/$lnf/metadata.json"
  check_file "$data_home/color-schemes/$scheme.colors"
  check_file "$data_home/plasma/desktoptheme/$plasma/metadata.json"
  check_file "$data_home/aurorae/themes/$decoration/metadata.desktop"
  check_file "$data_home/wallpapers/$wallpaper/metadata.json"
  check_file "$data_home/icons/$icons/index.theme"
  check_file "$data_home/org.kde.syntax-highlighting/themes/${key}-${face}.theme"
done < "$here/themes.tsv"

check_file "$data_home/kwin/tabbox/hearthglass_grid/metadata.json"

for f in "$data_home"/plasma/desktoptheme/*/widgets/*.svgz; do
  [ -e "$f" ] || continue
  if gzip -t "$f" 2>/dev/null; then
    :
  else
    printf 'BAD  %s\n' "$f"
    errors=$((errors + 1))
  fi
done

for f in "$data_home"/plasma/look-and-feel/*/metadata.json; do
  python3 -m json.tool "$f" >/dev/null 2>&1 || {
    printf 'BAD  %s\n' "$f"
    errors=$((errors + 1))
  }
done

echo
echo "Active state:"
printf '  Global:  '; kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage || true
printf '  Icons:   '; kreadconfig6 --file kdeglobals --group Icons --key Theme || true
printf '  TabBox:  '; kreadconfig6 --file kwinrc --group TabBox --key LayoutName || true
printf '  Splash:  '; kreadconfig6 --file ksplashrc --group KSplash --key Theme || true

if (( errors > 0 )); then
  echo "$errors verification error(s)." >&2
  exit 1
fi
echo "hearthglass KDE verification passed."
