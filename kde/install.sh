#!/usr/bin/env bash
# Install the hearthglass Plasma 6 themes into the user's data directory.
set -euo pipefail

here="$(cd -- "$(dirname -- "$0")" && pwd)"
payload="$here/payload"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"

test -d "$payload" || {
  echo "Payload not found: $payload" >&2
  echo "Run: nvim --headless -l kde/export.lua && python3 kde/build.py" >&2
  exit 2
}

# Everything the builder produced, by data-home-relative path.
targets=()
while IFS= read -r -d '' path; do
  targets+=("${path#./}")
done < <(cd "$payload" && find color-schemes org.kde.syntax-highlighting/themes -type f \( -name '*.colors' -o -name '*.theme' \) -print0)
while IFS= read -r -d '' path; do
  targets+=("${path#./}")
done < <(cd "$payload" && find plasma/desktoptheme plasma/look-and-feel wallpapers icons kwin/tabbox aurorae/themes -mindepth 1 -maxdepth 1 -type d -print0)

stamp="$(date +%Y%m%d-%H%M%S)"
backup="$data_home/hearthglass-kde-backup-$stamp"
backed_up=false

for rel in "${targets[@]}"; do
  if [ -e "$data_home/$rel" ]; then
    mkdir -p "$backup/$(dirname "$rel")"
    cp -a "$data_home/$rel" "$backup/$rel"
    backed_up=true
  fi
done

for rel in "${targets[@]}"; do
  rm -rf "${data_home:?}/$rel"
  mkdir -p "$data_home/$(dirname "$rel")"
  cp -a "$payload/$rel" "$data_home/$rel"
done

if command -v kbuildsycoca6 >/dev/null 2>&1; then
  kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
fi

echo "hearthglass KDE themes installed into: $data_home"
if "$backed_up"; then
  echo "Previous files backed up to: $backup"
else
  rmdir "$backup" 2>/dev/null || true
fi
echo
echo "Apply one with:"
echo "  $here/apply.sh hearthglass light"
echo "  $here/apply.sh hearthglass dark"
echo "  $here/apply.sh cranberry dark"
echo "  $here/apply.sh seaglass dark"
echo "  $here/apply.sh flambe dark"
echo "  $here/apply.sh frosted dark"
