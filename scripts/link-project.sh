#!/usr/bin/env bash
# Thin wrapper → add-project-skills.sh (copy curated skills into the project).
# Legacy --project-local dumping of device/mobile skills is removed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
  cat <<'USAGE'
Usage: ./scripts/link-project.sh <project> --skills a,b,c [--force]
       ./scripts/link-project.sh <project> --from-group project [--force]

Thin wrapper around add-project-skills.sh: **copies** curated project skills into
  <project>/.claude/skills/<name> and <project>/.agents/skills/<name>
ready to commit.

Legacy --project-local (symlink / dump all mobile into the project) is removed.
Device core (+ optional argent) stays at ~/.claude / ~/.agents via ensure-install.sh.

Prefer:
  ./scripts/suggest-project-skills.sh <project>
  ./scripts/add-project-skills.sh <project> --skills …
USAGE
}

# Translate legacy flags / help
ARGS=()
EXPECT=""
for arg in "$@"; do
  if [[ -n "$EXPECT" ]]; then
    ARGS+=("$arg")
    EXPECT=""
    continue
  fi
  case "$arg" in
    -h|--help)
      usage
      exit 0
      ;;
    --project-local)
      echo "error: --project-local was removed (no dumping all mobile into projects)." >&2
      echo "Use: ./scripts/add-project-skills.sh <project> --skills a,b,c" >&2
      echo "Or:  ./scripts/link-project.sh <project> --skills a,b,c" >&2
      exit 1
      ;;
    --groups)
      echo "error: --groups on link-project is removed (device groups ≠ project skills)." >&2
      echo "Device: ./scripts/install.sh --groups core|core,argent" >&2
      echo "Project: --skills a,b,c or --from-group project" >&2
      exit 1
      ;;
    --skills|--from-group|--skills-root)
      ARGS+=("$arg")
      EXPECT=1
      ;;
    --force|--list)
      ARGS+=("$arg")
      ;;
    --*)
      ARGS+=("$arg")
      ;;
    *)
      ARGS+=("$arg")
      ;;
  esac
done

if [[ ${#ARGS[@]} -eq 0 ]]; then
  usage >&2
  exit 1
fi

exec "$SCRIPT_DIR/add-project-skills.sh" "${ARGS[@]}"
