#!/usr/bin/env bash
# Ensure the amillez plugin pack is installed at user root before coding.
# Installs or refreshes when the stamp or any amillez skill is missing. Never touches project trees.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ./scripts/ensure-install.sh [--force] [--skills-root /path/to/akit] [--groups core|mobile|core,mobile]

Run before coding sessions. Ensures the user-root amillez plugin pack.

Installed means both:
  - the stamp exists: ~/.amillez-plugin.json or ~/.agents/amillez-plugin.json
  - every amillez skill the groups install (install.sh --list-skills) is in
    ~/.claude/skills and ~/.agents/skills

Stamp missing: runs update-install.sh (skills, user rules, stamp) and prints "installed".
Stamp present but a amillez skill missing: refreshes and prints "updated".
Otherwise prints "already present", unless --force refreshes anyway.

Groups (same as install.sh; default core,mobile). core is always included.

Skills root resolution (first match):
  1. --skills-root
  2. env AMILLEZ_SKILLS_ROOT
  3. ~/agent-work/akit (if it has skills/)
  4. script-relative repo root (parent of scripts/)

Prints exactly one status line:
  amillez plugin: installed
  amillez plugin: already present
  amillez plugin: updated
USAGE
}

FORCE=0
SKILLS_ROOT_OVERRIDE=""
GROUPS_ARG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --skills-root)
      SKILLS_ROOT_OVERRIDE="${2:-}"
      if [[ -z "$SKILLS_ROOT_OVERRIDE" ]]; then
        echo "error: --skills-root requires a path" >&2
        exit 1
      fi
      shift 2
      ;;
    --groups)
      GROUPS_ARG="${2:-}"
      if [[ -z "$GROUPS_ARG" ]]; then
        echo "error: --groups requires a value (e.g. core, core,mobile, mobile)" >&2
        exit 1
      fi
      shift 2
      ;;
    --*)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      echo "error: unexpected argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

resolve_skills_root() {
  if [[ -n "$SKILLS_ROOT_OVERRIDE" ]]; then
    echo "$SKILLS_ROOT_OVERRIDE"
    return
  fi
  if [[ -n "${AMILLEZ_SKILLS_ROOT:-}" ]]; then
    echo "$AMILLEZ_SKILLS_ROOT"
    return
  fi
  local home_clone="${HOME}/agent-work/akit"
  if [[ -d "$home_clone/skills" ]]; then
    echo "$home_clone"
    return
  fi
  echo "$REPO_ROOT"
}

SKILLS_ROOT="$(resolve_skills_root)"
if [[ ! -d "$SKILLS_ROOT/skills" ]]; then
  echo "error: skills directory not found under $SKILLS_ROOT" >&2
  echo "Set AMILLEZ_SKILLS_ROOT, pass --skills-root, or clone to ~/agent-work/akit." >&2
  exit 1
fi

plugin_present() {
  [[ -f "$HOME/.amillez-plugin.json" || -f "$HOME/.agents/amillez-plugin.json" ]]
}

amillez_skill_missing() {
  local args=(--list-skills) s
  if [[ -n "$GROUPS_ARG" ]]; then
    args+=(--groups "$GROUPS_ARG")
  fi
  while read -r s; do
    if [[ ! -f "$HOME/.claude/skills/$s/SKILL.md" || ! -f "$HOME/.agents/skills/$s/SKILL.md" ]]; then
      return 0
    fi
  done < <("$SKILLS_ROOT/scripts/install.sh" "${args[@]}")
  return 1
}

run_install() {
  local update="$SKILLS_ROOT/scripts/update-install.sh"
  if [[ ! -x "$update" ]]; then
    update="$SCRIPT_DIR/update-install.sh"
  fi
  local args=(--skills-root "$SKILLS_ROOT")
  if [[ -n "$GROUPS_ARG" ]]; then
    args+=(--groups "$GROUPS_ARG")
  fi
  "$update" "${args[@]}" >/dev/null
}

WAS_PRESENT=0
if plugin_present; then
  WAS_PRESENT=1
fi

if [[ "$WAS_PRESENT" -eq 1 && "$FORCE" -eq 0 ]] && ! amillez_skill_missing; then
  echo "amillez plugin: already present"
  exit 0
fi

run_install

if [[ "$WAS_PRESENT" -eq 1 ]]; then
  echo "amillez plugin: updated"
else
  echo "amillez plugin: installed"
fi
