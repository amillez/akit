#!/usr/bin/env bash
# Ensure the amillez plugin pack is installed at user/device root before coding.
# Detects existing installs via stamp (or legacy user skills/rules); installs/refreshes otherwise.
# Never touches project trees or .cursor/.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ./scripts/ensure-install.sh [--force] [--skills-root /path/to/agent-skills] [--groups core|mobile|core,mobile]

Required before coding sessions on agent-m1 (bots/agents run this automatically
per ai-eng-practices policy). Ensures the **host** (user-root) amillez plugin pack.

Detects "installed" if ANY of:
  A) Stamp present: ~/.amillez-plugin.json OR ~/.agents/amillez-plugin.json
  B) Legacy / minimum heuristic (both must pass):
     - ~/.claude/rules/amillez-models.md OR ~/.agents/rules/amillez-models.md exists, AND
     - ~/.claude/skills/setup-amillez-models OR ~/.agents/skills/setup-amillez-models
       OR ~/.codex/skills/setup-amillez-models exists

If missing → run update-install.sh (skills + user rules + stamp).
If present → exit 0 quietly (print "already present") unless --force (then refresh + stamp).

Groups (same as install.sh; default core,mobile):
  core is always included. Pass --groups when known.

Skills root resolution (first match):
  1. --skills-root
  2. env AMILLEZ_SKILLS_ROOT
  3. ~/agent-work/agent-skills (if it has skills/)
  4. script-relative repo root (parent of scripts/)

Prints exactly one status line:
  amillez plugin: installed
  amillez plugin: already present
  amillez plugin: updated

Note: project path is NOT required. Project-specific skills (verify-*) live in the
repo; the amillez plugin does not install into project .claude/skills or .agents/skills.
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
      # Accept and ignore a legacy project path for backward compatibility
      if [[ -d "$1" ]]; then
        echo "note: project path ignored — amillez plugin installs at user root (use ensure-install.sh)" >&2
        shift
        continue
      fi
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
  local home_clone="${HOME}/agent-work/agent-skills"
  if [[ -d "$home_clone/skills" ]]; then
    echo "$home_clone"
    return
  fi
  echo "$REPO_ROOT"
}

SKILLS_ROOT="$(resolve_skills_root)"
if [[ ! -d "$SKILLS_ROOT/skills" ]]; then
  echo "error: skills directory not found under $SKILLS_ROOT" >&2
  echo "Set AMILLEZ_SKILLS_ROOT, pass --skills-root, or clone to ~/agent-work/agent-skills." >&2
  exit 1
fi

plugin_present() {
  if [[ -f "$HOME/.amillez-plugin.json" || -f "$HOME/.agents/amillez-plugin.json" ]]; then
    return 0
  fi
  local has_rules=0 has_skill=0
  if [[ -f "$HOME/.claude/rules/amillez-models.md" || -f "$HOME/.agents/rules/amillez-models.md" ]]; then
    has_rules=1
  fi
  if [[ -e "$HOME/.claude/skills/setup-amillez-models" || -e "$HOME/.agents/skills/setup-amillez-models" || -e "$HOME/.codex/skills/setup-amillez-models" ]]; then
    has_skill=1
  fi
  if [[ "$has_rules" -eq 1 && "$has_skill" -eq 1 ]]; then
    return 0
  fi
  return 1
}

run_install() {
  local update="$SKILLS_ROOT/scripts/update-install.sh"
  if [[ ! -x "$update" ]]; then
    update="$SCRIPT_DIR/update-install.sh"
  fi
  local args=()
  if [[ "$FORCE" -eq 1 ]]; then
    args+=(--force)
  fi
  if [[ -n "$SKILLS_ROOT_OVERRIDE" || -n "${AMILLEZ_SKILLS_ROOT:-}" ]]; then
    args+=(--skills-root "$SKILLS_ROOT")
  elif [[ "$SKILLS_ROOT" != "$REPO_ROOT" ]]; then
    args+=(--skills-root "$SKILLS_ROOT")
  fi
  if [[ -n "$GROUPS_ARG" ]]; then
    args+=(--groups "$GROUPS_ARG")
  fi
  # Prefer skip-upstream on ensure when already partially present? No — full install on missing.
  # On --force full refresh including upstream is correct.
  "$update" "${args[@]+"${args[@]}"}" >/dev/null
}

WAS_PRESENT=0
if plugin_present; then
  WAS_PRESENT=1
fi

if [[ "$WAS_PRESENT" -eq 1 && "$FORCE" -eq 0 ]]; then
  echo "amillez plugin: already present"
  exit 0
fi

run_install

if [[ "$WAS_PRESENT" -eq 1 ]]; then
  echo "amillez plugin: updated"
else
  echo "amillez plugin: installed"
fi
