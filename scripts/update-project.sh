#!/usr/bin/env bash
# Refresh project skill symlinks and re-copy Claude/Codex rules templates (idempotent).
# Never writes under .cursor/.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ./scripts/update-project.sh [/path/to/project] [--force] [--skills-root /path/to/agent-skills] [--skip-link] [--skip-rules]

Idempotent project refresh for the amillez plugin pack:
  1. Re-run link-project.sh (skill symlinks → .claude/skills + .agents/skills only)
  2. Copy/update templates/models.claude.md →
       .claude/rules/amillez-models.md
       .agents/rules/amillez-models.md

Does NOT write Cursor rules or any .cursor/ paths.

Options:
  --force         Passed through to link-project.sh; also overwrite diverged rules files
  --skills-root   Passed through to link-project.sh
  --skip-link     Only refresh rules templates
  --skip-rules    Only refresh skill links
USAGE
}

FORCE=0
PROJECT=""
SKILLS_ROOT_OVERRIDE=""
SKIP_LINK=0
SKIP_RULES=0
EXTRA_LINK_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --force)
      FORCE=1
      EXTRA_LINK_ARGS+=(--force)
      shift
      ;;
    --skills-root)
      SKILLS_ROOT_OVERRIDE="${2:-}"
      if [[ -z "$SKILLS_ROOT_OVERRIDE" ]]; then
        echo "error: --skills-root requires a path" >&2
        exit 1
      fi
      EXTRA_LINK_ARGS+=(--skills-root "$SKILLS_ROOT_OVERRIDE")
      shift 2
      ;;
    --skip-link)
      SKIP_LINK=1
      shift
      ;;
    --skip-rules)
      SKIP_RULES=1
      shift
      ;;
    --*)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -n "$PROJECT" ]]; then
        echo "error: unexpected argument: $1" >&2
        usage >&2
        exit 1
      fi
      PROJECT="$1"
      shift
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PROJECT="${PROJECT:-$(pwd)}"
if [[ ! -d "$PROJECT" ]]; then
  echo "error: project path is not a directory: $PROJECT" >&2
  exit 1
fi
PROJECT="$(cd "$PROJECT" && pwd)"

TEMPLATE="$REPO_ROOT/templates/models.claude.md"
if [[ ! -f "$TEMPLATE" ]]; then
  # Fall back to home clone if this checkout is incomplete
  if [[ -f "${HOME}/agent-work/agent-skills/templates/models.claude.md" ]]; then
    TEMPLATE="${HOME}/agent-work/agent-skills/templates/models.claude.md"
  fi
fi

if [[ "$SKIP_LINK" -eq 0 ]]; then
  echo "== Refresh skill links =="
  "$SCRIPT_DIR/link-project.sh" "$PROJECT" "${EXTRA_LINK_ARGS[@]+"${EXTRA_LINK_ARGS[@]}"}"
  echo
fi

if [[ "$SKIP_RULES" -eq 0 ]]; then
  if [[ ! -f "$TEMPLATE" ]]; then
    echo "error: rules template not found (expected templates/models.claude.md)" >&2
    exit 1
  fi
  echo "== Refresh Claude/Codex rules templates =="
  for rel in .claude/rules .agents/rules; do
    dest_dir="$PROJECT/$rel"
    dest="$dest_dir/amillez-models.md"
    mkdir -p "$dest_dir"
    if [[ -e "$dest" || -L "$dest" ]]; then
      if [[ -L "$dest" ]]; then
        # Replace symlink with a fresh copy so project owns the file
        rm -f "$dest"
        cp "$TEMPLATE" "$dest"
        echo "updated (was symlink): $dest"
      elif cmp -s "$TEMPLATE" "$dest"; then
        echo "ok (unchanged): $dest"
      elif [[ "$FORCE" -eq 1 ]]; then
        cp "$TEMPLATE" "$dest"
        echo "updated (--force): $dest"
      else
        # Still refresh by default for idempotent "update" semantics when content differs
        cp "$TEMPLATE" "$dest"
        echo "updated: $dest"
      fi
    else
      cp "$TEMPLATE" "$dest"
      echo "installed: $dest"
    fi
  done
  echo
fi

echo "Done. Project skills + Claude/Codex rules refreshed (no .cursor paths)."
