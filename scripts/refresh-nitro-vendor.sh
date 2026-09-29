#!/usr/bin/env bash
# Refresh each vendor/nitro/<skill> snapshot from ~/.agents/skills, then commit.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
for dir in "$ROOT"/vendor/nitro/*/; do
  s="$(basename "$dir")"
  src="$HOME/.agents/skills/$s"
  if [ ! -d "$src" ]; then
    echo "missing $src" >&2
    exit 1
  fi
  rm -rf "$ROOT/vendor/nitro/$s"
  mkdir -p "$ROOT/vendor/nitro/$s"
  cp -R "$src/." "$ROOT/vendor/nitro/$s/"
  echo "refreshed $s"
done
echo "Commit vendor/nitro when ready."
