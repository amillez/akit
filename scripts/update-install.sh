#!/usr/bin/env bash
# Refresh the user-root amillez plugin skills, rules, and stamp (idempotent). Never writes under project trees.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ./scripts/update-install.sh [--skills-root /path/to/agent-skills] [--groups core|mobile|core,mobile] [--skip-skills] [--skip-upstream]

Idempotent user-root refresh for the amillez plugin pack:
  1. Run install.sh (upstream, amillez, and vendor skills → ~/.claude/skills and ~/.agents/skills)
  2. Copy templates/models.md →
       ~/.claude/rules/amillez-models.md
       ~/.agents/rules/amillez-models.md
  3. Write the stamp ~/.amillez-plugin.json (and ~/.agents/amillez-plugin.json)

Never writes into project .claude/ or .agents/ trees. Project skills (e.g. verify-*) stay in the project repo.

Options:
  --skills-root   Agent-skills checkout (default: this repo or ~/agent-work/agent-skills)
  --groups        Passed through to install.sh (default core,mobile; core always)
  --skip-skills   Only refresh the rules and the stamp
  --skip-upstream Skip the npx upstream packs; amillez, vendor, rules, and stamp only (faster)
USAGE
}

SKILLS_ROOT_OVERRIDE=""
GROUPS_ARG=""
SKIP_SKILLS=0
SKIP_UPSTREAM=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
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
    --skip-skills)
      SKIP_SKILLS=1
      shift
      ;;
    --skip-upstream)
      SKIP_UPSTREAM=1
      shift
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
  if [[ -d "$REPO_ROOT/skills" ]]; then
    echo "$REPO_ROOT"
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
  exit 1
fi

TEMPLATE="$SKILLS_ROOT/templates/models.md"
if [[ ! -f "$TEMPLATE" ]]; then
  echo "error: rules template not found at $TEMPLATE" >&2
  exit 1
fi

write_stamp() {
  local plugin_json="$SKILLS_ROOT/amillez-plugin.json"
  local name="amillez"
  local version="0.0.0"
  if [[ -f "$plugin_json" ]]; then
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
  local stamp_body
  stamp_body=$(cat <<STAMP
{
  "name": "$name",
  "version": "$version",
  "installRoot": "user",
  "skillsRoot": "$SKILLS_ROOT"
}
STAMP
)
  mkdir -p "$HOME/.agents"
  printf '%s\n' "$stamp_body" > "$HOME/.amillez-plugin.json"
  printf '%s\n' "$stamp_body" > "$HOME/.agents/amillez-plugin.json"
  echo "stamp: $HOME/.amillez-plugin.json"
}

if [[ "$SKIP_SKILLS" -eq 0 ]]; then
  echo "== Refresh user-root skills (install.sh) =="
  INSTALL_ARGS=()
  if [[ -n "$GROUPS_ARG" ]]; then
    INSTALL_ARGS+=(--groups "$GROUPS_ARG")
  fi
  if [[ "$SKIP_UPSTREAM" -eq 1 ]]; then
    INSTALL_ARGS+=(--skip-upstream)
  fi
  "$SKILLS_ROOT/scripts/install.sh" "${INSTALL_ARGS[@]+"${INSTALL_ARGS[@]}"}"
  echo
fi

echo "== Refresh user-level Claude/Codex rules templates =="
for dest_dir in "$HOME/.claude/rules" "$HOME/.agents/rules"; do
  dest="$dest_dir/amillez-models.md"
  mkdir -p "$dest_dir"
  if [[ -L "$dest" ]]; then
    rm -f "$dest"
    cp "$TEMPLATE" "$dest"
    echo "updated (was symlink): $dest"
  elif [[ ! -e "$dest" ]]; then
    cp "$TEMPLATE" "$dest"
    echo "installed: $dest"
  elif cmp -s "$TEMPLATE" "$dest"; then
    echo "ok (unchanged): $dest"
  else
    cp "$TEMPLATE" "$dest"
    echo "updated: $dest"
  fi
done
echo

write_stamp
echo
echo "Done. User-root amillez skills and rules refreshed."
