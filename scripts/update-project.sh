#!/usr/bin/env bash
# Deprecated name: project linking is no longer the amillez plugin model.
# Forwards to update-install.sh (user-root refresh). Prefer that name.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

ARGS=()
EXPECT_VAL=""
for arg in "$@"; do
  if [[ -n "$EXPECT_VAL" ]]; then
    ARGS+=("$arg")
    EXPECT_VAL=""
    continue
  fi
  case "$arg" in
    -h|--help)
      echo "note: update-project.sh is a deprecated alias of update-install.sh (user-root)." >&2
      exec "$SCRIPT_DIR/update-install.sh" --help
      ;;
    --skills-root|--groups)
      ARGS+=("$arg")
      EXPECT_VAL=1
      ;;
    --force|--skip-skills|--skip-rules|--skip-upstream)
      ARGS+=("$arg")
      ;;
    --skip-link)
      # legacy no-op (no project links in user-root model)
      ;;
    --*)
      ARGS+=("$arg")
      ;;
    *)
      if [[ -d "$arg" ]]; then
        echo "note: project path ignored — use update-install.sh for user-root refresh" >&2
        continue
      fi
      ARGS+=("$arg")
      ;;
  esac
done

exec "$SCRIPT_DIR/update-install.sh" "${ARGS[@]+"${ARGS[@]}"}"
