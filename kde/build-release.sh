#!/usr/bin/env bash
# Build a redistributable archive from the installed payload.
set -euo pipefail

here="$(cd -- "$(dirname -- "$0")" && pwd)"
version="1.0.0"
[ -f "$here/VERSION" ] && version="$(tr -d '[:space:]' < "$here/VERSION")"
name="hearthglass-kde-themes-$version"
dist="$here/dist"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

test -d "$here/payload" || {
  echo "No payload. Run python3 kde/build.py first." >&2
  exit 2
}

stage="$tmp/$name"
mkdir -p "$stage" "$dist"
cp -a "$here/payload" "$stage/payload"
cp -a "$here/install.sh" "$here/apply.sh" "$here/apply-light.sh" "$here/apply-dark.sh" \
      "$here/uninstall.sh" "$here/verify.sh" "$here/themes.tsv" "$here/README.md" \
      "$here/LICENSE" "$here/LICENSES.md" "$here/VERSION" "$stage/"
cp -a "$here/LICENSES" "$stage/LICENSES"
mkdir -p "$stage/kitty"
cp "$here"/../kitty/*.conf "$stage/kitty/"

archive="$dist/$name.tar.gz"
tar -czf "$archive" -C "$tmp" "$name"
(
  cd "$dist"
  sha256sum "$name.tar.gz" > "$name.tar.gz.sha256"
)
echo "Built: $archive"
