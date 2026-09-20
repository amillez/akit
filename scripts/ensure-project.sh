#!/usr/bin/env bash
# Thin wrapper: ensure host (user-root) amillez plugin install.
# Project path is optional and ignored for skills — kept for backward-compatible call sites.
# Prefer: ./scripts/ensure-install.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Strip a leading project path if present so callers of the old signature still work.
ARGS=()
SAW_PATH=0
for arg in "$@"; do
  case "$arg" in
    -h|--help)
      exec "$SCRIPT_DIR/ensure-install.sh" --help
      ;;
    --*)
      ARGS+=("$arg")
      ;;
    *)
      if [[ "$SAW_PATH" -eq 0 && ( -d "$arg" || "$arg" == /* || "$arg" == .* || "$arg" == ~* ) ]]; then
        SAW_PATH=1
        # ignore project path
        continue
      fi
      ARGS+=("$arg")
      ;;
  esac
done

exec "$SCRIPT_DIR/ensure-install.sh" "${ARGS[@]+"${ARGS[@]}"}"
