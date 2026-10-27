#!/usr/bin/env bash
set -euo pipefail
here="$(cd -- "$(dirname -- "$0")" && pwd)"
exec "$here/apply.sh" "${1:-hearthglass}" light
