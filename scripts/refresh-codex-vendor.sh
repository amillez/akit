#!/usr/bin/env bash
# Copy current ~/.agents/skills snapshots (Codex uses ~/.agents) into vendor/codex (run on daily driver, then commit).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
for s in api-design build-nitro-modules cpp kotlin swift react-native-mmkv react-native-nitro-fetch react-native-vision-camera; do
  src="$HOME/.agents/skills/$s"
  if [ ! -d "$src" ]; then
    echo "missing $src" >&2
    exit 1
  fi
  rm -rf "$ROOT/vendor/codex/$s"
  mkdir -p "$ROOT/vendor/codex/$s"
  cp -R "$src/." "$ROOT/vendor/codex/$s/"
  echo "refreshed $s"
done
echo "Commit vendor/codex when ready."
