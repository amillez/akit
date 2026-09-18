#!/usr/bin/env bash
# Ensure the amillez plugin pack is installed on a project before coding.
# Detects existing installs (stamp OR rules+skills); installs/refreshes otherwise.
# Never touches .cursor/.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ./scripts/ensure-project.sh <project-path> [--force] [--skills-root /path/to/agent-skills] [--groups core|mobile|core,mobile]

Required before the first coding session on a project (bots/agents run this
automatically per ai-eng-practices policy).

Detects "installed" if ANY of:
  A) Stamp present: .amillez-plugin or .amillez-plugin.json in the project root
     (preferred going forward; written after install)
  B) Legacy / minimum heuristic (both must pass):
     - .claude/rules/amillez-models.md OR .agents/rules/amillez-models.md exists, AND
     - .claude/skills/setup-amillez-models OR .agents/skills/setup-amillez-models
       exists (symlink or directory)

If missing → run update-project.sh (re-links skills + refreshes rules) and write stamp.
If present → exit 0 quietly (print "already present") unless --force (then refresh + stamp).

Groups (same as install.sh / link-project.sh; default core,mobile):
  core is always included. Pass --groups when known (Grok Bot / ensure should pass
  groups when known; default core+mobile for RN projects is fine).

Skills root resolution (first match):
  1. --skills-root
  2. env AMILLEZ_SKILLS_ROOT
  3. ~/agent-work/agent-skills (if it has skills/)
  4. script-relative repo root (parent of scripts/)

Prints exactly one status line:
  amillez plugin: installed
  amillez plugin: already present
  amillez plugin: updated
USAGE
}

FORCE=0
PROJECT=""
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

if [[ -z "$PROJECT" ]]; then
  echo "error: project path is required" >&2
  usage >&2
  exit 1
fi

if [[ ! -d "$PROJECT" ]]; then
  echo "error: project path is not a directory: $PROJECT" >&2
  exit 1
fi
PROJECT="$(cd "$PROJECT" && pwd)"

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

# Prefer stamp; fall back to rules+skills for older installs without a stamp.
plugin_present() {
  if [[ -f "$PROJECT/.amillez-plugin" || -f "$PROJECT/.amillez-plugin.json" ]]; then
    return 0
  fi
  local has_rules=0 has_skill=0
  if [[ -f "$PROJECT/.claude/rules/amillez-models.md" || -f "$PROJECT/.agents/rules/amillez-models.md" ]]; then
    has_rules=1
  fi
  if [[ -e "$PROJECT/.claude/skills/setup-amillez-models" || -e "$PROJECT/.agents/skills/setup-amillez-models" ]]; then
    has_skill=1
  fi
  if [[ "$has_rules" -eq 1 && "$has_skill" -eq 1 ]]; then
    return 0
  fi
  return 1
}

write_stamp() {
  local plugin_json="$SKILLS_ROOT/amillez-plugin.json"
  local name="amillez"
  local version="0.0.0"
  if [[ -f "$plugin_json" ]]; then
    # Prefer python for robust JSON; fall back to grep/sed.
    if command -v python3 >/dev/null 2>&1; then
      name="$(AMILLEZ_PLUGIN_JSON="$plugin_json" python3 -c 'import json,os; d=json.load(open(os.environ["AMILLEZ_PLUGIN_JSON"])); print(d.get("name","amillez"))')"
      version="$(AMILLEZ_PLUGIN_JSON="$plugin_json" python3 -c 'import json,os; d=json.load(open(os.environ["AMILLEZ_PLUGIN_JSON"])); print(d.get("version","0.0.0"))')"
    else
      name="$(grep -oE '"name"[[:space:]]*:[[:space:]]*"[^"]+"' "$plugin_json" | head -1 | sed 's/.*"\([^"]*\)"$/\1/')"
      version="$(grep -oE '"version"[[:space:]]*:[[:space:]]*"[^"]+"' "$plugin_json" | head -1 | sed 's/.*"\([^"]*\)"$/\1/')"
      name="${name:-amillez}"
      version="${version:-0.0.0}"
    fi
  fi
  # Canonical stamp filename going forward
  cat > "$PROJECT/.amillez-plugin.json" <<STAMP
{
  "name": "$name",
  "version": "$version"
}
STAMP
}

run_install() {
  local update="$SKILLS_ROOT/scripts/update-project.sh"
  if [[ ! -x "$update" ]]; then
    # Fall back to this checkout's scripts if skills-root is incomplete
    update="$SCRIPT_DIR/update-project.sh"
  fi
  local args=("$PROJECT")
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
  # Quiet the verbose update/link chatter for the ensure one-liner UX;
  # still fail hard on errors.
  "$update" "${args[@]}" >/dev/null
  write_stamp
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
