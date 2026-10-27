#!/usr/bin/env bash
# Apply a hearthglass KDE theme: ./apply.sh <key> <light|dark>
set -euo pipefail

here="$(cd -- "$(dirname -- "$0")" && pwd)"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"

key="${1:-hearthglass}"
face="${2:-dark}"

case "$face" in
  light|dark) ;;
  *) echo "Usage: $0 <key> <light|dark>   # keys: hearthglass, stained, flambe, cranberry, seaglass, smoked, frosted, cathedral, leaded" >&2; exit 2 ;;
esac

row="$(awk -F'\t' -v k="$key" -v f="$face" 'NR > 1 && $1 == k && $2 == f { print; exit }' "$here/themes.tsv")"
if [ -z "$row" ]; then
  echo "Unknown theme: $key $face" >&2
  echo "Available:" >&2
  awk -F'\t' 'NR > 1 { printf "  %-16s %s\n", $1, $2 }' "$here/themes.tsv" >&2
  exit 2
fi

IFS=$'\t' read -r _key _face lnf scheme plasma decoration icons cursors wallpaper kate name <<<"$row"

test -d "$data_home/plasma/look-and-feel/$lnf" || {
  echo "$name is not installed in $data_home." >&2
  echo "Run $here/install.sh first." >&2
  exit 4
}

required=(plasma-apply-lookandfeel plasma-apply-colorscheme plasma-apply-wallpaperimage kwriteconfig6)
for cmd in "${required[@]}"; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Missing required command: $cmd" >&2
    exit 3
  }
done

# Same separation as Clay: the vivid accent drives focus, the selection
# surface stays quiet. A custom accent from System Settings would overwrite it.
kwriteconfig6 --file kdeglobals --group General --key AccentColor --delete "" || true
kwriteconfig6 --file kdeglobals --group General --key LastUsedCustomAccentColor --delete "" || true
kwriteconfig6 --file kdeglobals --group General --key accentColorFromWallpaper false

plasma-apply-lookandfeel -a "$lnf"
plasma-apply-colorscheme "$scheme"

kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Breeze
kwriteconfig6 --file kdeglobals --group Icons --key Theme "$icons" --notify
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme "__aurorae__svg__$decoration"
kwriteconfig6 --file kwinrc --group TabBox --key LayoutName hearthglass_grid
kwriteconfig6 --file plasmarc --group Theme --key name "$plasma"

if command -v plasma-apply-cursortheme >/dev/null 2>&1; then
  plasma-apply-cursortheme "$cursors" >/dev/null || true
else
  kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme "$cursors" --notify
fi

# Kate/KWrite: the matching hearthglass syntax theme.
for rc in katerc kwriterc; do
  kwriteconfig6 --file "$rc" --group "KTextEditor Renderer" --key "Auto Color Theme Selection" false
  kwriteconfig6 --file "$rc" --group "KTextEditor Renderer" --key "Color Theme" "$kate"
done

kwriteconfig6 --file ksplashrc --group KSplash --key Engine KSplashQML
kwriteconfig6 --file ksplashrc --group KSplash --key Theme "$lnf"

plasma-apply-wallpaperimage "$data_home/wallpapers/$wallpaper/contents/images/3840x2160.png"

# kitty: keep the terminal on the same family. The repo ships both faces, so
# write them as kitty's auto light/dark themes; kitty picks the one matching
# the desktop's colour preference. Skipped when there is no kitty config.
kitty_src="$here/../kitty"
[ -d "$kitty_src" ] || kitty_src="$here/kitty"
kitty_dir="${XDG_CONFIG_HOME:-$HOME/.config}/kitty"
if [ -d "$kitty_dir" ] && [ -f "$kitty_src/$_key.conf" ] && [ -f "$kitty_src/$_key-light.conf" ]; then
  install -m 644 "$kitty_src/$_key.conf" "$kitty_dir/dark-theme.auto.conf"
  install -m 644 "$kitty_src/$_key-light.conf" "$kitty_dir/light-theme.auto.conf"
  install -m 644 "$kitty_src/$_key.conf" "$kitty_dir/no-preference-theme.auto.conf"
  mkdir -p "$kitty_dir/themes"
  install -m 644 "$kitty_src/$_key.conf" "$kitty_dir/themes/$_key.conf"
  install -m 644 "$kitty_src/$_key-light.conf" "$kitty_dir/themes/$_key-light.conf"
  face_conf="$kitty_dir/$([ "$_face" = dark ] && echo dark || echo light)-theme.auto.conf"
  if command -v kitten >/dev/null 2>&1; then
    kitten @ set-colors "$face_conf" >/dev/null 2>&1 || true
  fi
  echo "kitty: synced $_key light/dark auto themes"
fi

if command -v kbuildsycoca6 >/dev/null 2>&1; then
  kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
fi
if command -v qdbus6 >/dev/null 2>&1; then
  qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
fi
if systemctl --user is-active plasma-plasmashell.service >/dev/null 2>&1; then
  systemctl --user restart plasma-plasmashell.service
fi

echo "Applied $name."
echo "  Global Theme:  $lnf"
echo "  Color Scheme:  $scheme"
echo "  Plasma Style:  $plasma"
echo "  Icons:         $icons"
echo "  Cursors:       $cursors"
echo "  Decoration:    $decoration (Aurorae)"
echo "  Wallpaper:     $wallpaper"
echo "  Editor theme:  $kate"
echo "  Switcher:      hearthglass_grid"
