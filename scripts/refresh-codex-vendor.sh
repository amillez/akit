#!/usr/bin/env bash
# Refresh each vendor/codex/<skill> snapshot from ~/.agents/skills (where Codex reads user skills), then commit.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
for dir in "$ROOT"/vendor/codex/*/; do
  s="$(basename "$dir")"
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
