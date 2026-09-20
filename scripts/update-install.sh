#!/usr/bin/env bash
# Refresh user-root amillez plugin skills + rules (idempotent). Never writes under project trees or .cursor/.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ./scripts/update-install.sh [--force] [--skills-root /path/to/agent-skills] [--groups core|argent|core,argent] [--skip-skills] [--skip-rules] [--skip-upstream]

Idempotent **user-root** refresh for the amillez **core** plugin pack:
  1. Re-run install.sh (core upstream + first-party → ~/.claude|~/.agents/skills)
  2. Copy/update templates/models.md →
       ~/.claude/rules/amillez-models.md
       ~/.agents/rules/amillez-models.md
  3. Write/refresh stamp ~/.amillez-plugin.json (and ~/.agents/amillez-plugin.json)

Does NOT symlink/copy into project .claude/skills or .agents/skills.
Does NOT write Cursor rules, any .cursor/ paths, or ~/.codex.
Does NOT install mobile/native project skills (use add-project-skills.sh).

Project-specific skills (e.g. verify-*, curated mobile/native) stay in the repo.

Options:
  --force         Passed through to install where applicable; overwrite diverged rules
  --skills-root   Agent-skills checkout (default: this repo or ~/agent-work/agent-skills)
  --groups        Passed through to install.sh (default **core only**; optional argent)
  --skip-skills   Only refresh rules templates + stamp
  --skip-rules    Only refresh skills (install.sh) + stamp
  --skip-upstream Skip npx upstream packs; only first-party + rules (faster refresh)
USAGE
}

FORCE=0
SKILLS_ROOT_OVERRIDE=""
GROUPS_ARG=""
SKIP_SKILLS=0
SKIP_RULES=0
SKIP_UPSTREAM=0

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
        echo "error: --groups requires a value (e.g. core, core,argent, argent)" >&2
        exit 1
      fi
      shift 2
      ;;
    --skip-skills)
      SKIP_SKILLS=1
      shift
      ;;
    --skip-rules)
      SKIP_RULES=1
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
      echo "error: unexpected argument: $1 (user-root update takes no project path)" >&2
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

install_first_party_and_vendor() {
  # Lightweight path when --skip-upstream: copy first-party only (no project mobile to device)
  echo "== First-party (canonical tree: skills/) [core] =="
  mkdir -p "$HOME/.agents/skills" "$HOME/.claude/skills"
  for s in orchestrate-agents create-verification-skill maintain-verification-skill setup-amillez-models; do
    rm -rf "$HOME/.agents/skills/$s" "$HOME/.claude/skills/$s"
    cp -R "$SKILLS_ROOT/skills/$s" "$HOME/.agents/skills/$s"
    cp -R "$SKILLS_ROOT/skills/$s" "$HOME/.claude/skills/$s"
  done
  # Note: Codex native vendor skills are project-scoped (add-project-skills.sh).
  # Optional device argent still requires full install.sh (npx) when --groups includes argent.
}

if [[ "$SKIP_SKILLS" -eq 0 ]]; then
  if [[ "$SKIP_UPSTREAM" -eq 1 ]]; then
    echo "== Refresh first-party + vendor (skip upstream) =="
    install_first_party_and_vendor
  else
    echo "== Refresh user-root skills (install.sh) =="
    INSTALL_ARGS=()
    if [[ -n "$GROUPS_ARG" ]]; then
      INSTALL_ARGS+=(--groups "$GROUPS_ARG")
    fi
    # install.sh lives next to us; it cds to its repo root
    "$SKILLS_ROOT/scripts/install.sh" "${INSTALL_ARGS[@]+"${INSTALL_ARGS[@]}"}"
  fi
  echo
fi

if [[ "$SKIP_RULES" -eq 0 ]]; then
  echo "== Refresh user-level Claude/Codex rules templates =="
  for dest_dir in "$HOME/.claude/rules" "$HOME/.agents/rules"; do
    dest="$dest_dir/amillez-models.md"
    mkdir -p "$dest_dir"
    if [[ -e "$dest" || -L "$dest" ]]; then
      if [[ -L "$dest" ]]; then
        rm -f "$dest"
        cp "$TEMPLATE" "$dest"
        echo "updated (was symlink): $dest"
      elif cmp -s "$TEMPLATE" "$dest"; then
        echo "ok (unchanged): $dest"
      else
        cp "$TEMPLATE" "$dest"
        if [[ "$FORCE" -eq 1 ]]; then
          echo "updated (--force): $dest"
        else
          echo "updated: $dest"
        fi
      fi
    else
      cp "$TEMPLATE" "$dest"
      echo "installed: $dest"
    fi
  done
  echo
fi

write_stamp
echo
echo "Done. User-root amillez skills + rules refreshed (no project trees, no .cursor paths)."
