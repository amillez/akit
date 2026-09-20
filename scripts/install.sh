#!/usr/bin/env bash
# Install allowlisted skills onto this machine (Claude Code + Codex shared agents dir).
# Canonical first-party tree: skills/ (amillez plugin pack). Never installs into .cursor/.
# Never writes ~/.codex — Codex uses ~/.agents.
#
# Device groups:
#   core   — always (default): grill-me + first-party + user rules + stamp
#   argent — optional: Argent skills for UI drive on agent-m1
#
# Mobile/native RN skills are project-scoped — use scripts/add-project-skills.sh.
#
# Usage:
#   ./scripts/install.sh                     # default: core only
#   ./scripts/install.sh --groups core       # same
#   ./scripts/install.sh --groups core,argent
#   ./scripts/install.sh --groups argent     # core still included + argent
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

usage() {
  cat <<'USAGE'
Usage: ./scripts/install.sh [--groups core|argent|core,argent]

Install allowlisted **device** skills + user rules for Claude Code + Codex (~/.agents).
Never .cursor/, never ~/.codex/, never project trees.

Groups (device):
  core    Always installed (default): grill-me, orchestrate-agents,
          create-verification-skill, maintain-verification-skill, setup-amillez-models
          + user rules amillez-models.md + stamp
  argent  Optional device Argent skills for UI drive. Not installed by default.
          Also install Argent CLI separately (see README).

Default: core only.

Mobile/native skills (animate-expo, expo-*, uniwind, Codex Nitro set, …) are
**project-scoped**. Copy curated ones with:
  ./scripts/add-project-skills.sh <project> --skills a,b,c

Legacy --groups mobile is rejected (use add-project-skills / --groups argent).
USAGE
}

GROUPS_ARG=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --groups)
      GROUPS_ARG="${2:-}"
      if [[ -z "$GROUPS_ARG" ]]; then
        echo "error: --groups requires a value (e.g. core, core,argent, argent)" >&2
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

# Resolve requested groups. Core is always included. Default: core only.
WANT_CORE=1
WANT_ARGENT=0
if [[ -n "$GROUPS_ARG" ]]; then
  IFS=',' read -ra RAW_GROUPS <<< "$GROUPS_ARG"
  saw_any=0
  for g in "${RAW_GROUPS[@]}"; do
    g="${g#"${g%%[![:space:]]*}"}"
    g="${g%"${g##*[![:space:]]}"}"
    g="$(printf '%s' "$g" | tr '[:upper:]' '[:lower:]')"
    case "$g" in
      core)
        saw_any=1
        ;;
      argent)
        WANT_ARGENT=1
        saw_any=1
        ;;
      mobile)
        echo "error: group 'mobile' is no longer a device install group." >&2
        echo "  Device optional: --groups core,argent" >&2
        echo "  Project mobile/native: ./scripts/add-project-skills.sh <project> --skills …" >&2
        echo "  Suggest from deps: ./scripts/suggest-project-skills.sh <project>" >&2
        exit 1
        ;;
      "")
        ;;
      *)
        echo "error: unknown group '$g' (valid device groups: core, argent)" >&2
        exit 1
        ;;
    esac
  done
  if [[ "$saw_any" -eq 0 ]]; then
    echo "error: --groups produced no valid groups" >&2
    exit 1
  fi
fi

echo "Groups: core$([ "$WANT_ARGENT" -eq 1 ] && echo '+argent' || true) (default core only; mobile → project)"

if ! command -v npx >/dev/null 2>&1; then
  echo "npx required" >&2
  exit 1
fi

echo "== Upstream packs (npx skills add) =="

if [[ "$WANT_ARGENT" -eq 1 ]]; then
  # Argent — all skills; pin matches manifest (optional device group)
  npx -y skills add "software-mansion/argent/packages/skills/skills#v0.25.0" --skill '*' --agent '*' -g -y --copy
fi

# core: grill-me
npx -y skills add mattpocock/skills --skill grill-me --agent '*' -g -y --copy

echo "== First-party (canonical tree: skills/) [core] =="
mkdir -p "$HOME/.agents/skills" "$HOME/.claude/skills"
for s in orchestrate-agents create-verification-skill maintain-verification-skill setup-amillez-models; do
  rm -rf "$HOME/.agents/skills/$s" "$HOME/.claude/skills/$s"
  cp -R "$ROOT/skills/$s" "$HOME/.agents/skills/$s"
  cp -R "$ROOT/skills/$s" "$HOME/.claude/skills/$s"
done

echo "== User-level Claude/Codex rules templates =="
TEMPLATE="$ROOT/templates/models.md"
if [[ -f "$TEMPLATE" ]]; then
  for dest_dir in "$HOME/.claude/rules" "$HOME/.agents/rules"; do
    mkdir -p "$dest_dir"
    cp "$TEMPLATE" "$dest_dir/amillez-models.md"
    echo "installed: $dest_dir/amillez-models.md"
  done
else
  echo "warning: templates/models.md missing; skip rules" >&2
fi

echo "== Stamp =="
PLUGIN_JSON="$ROOT/amillez-plugin.json"
NAME="amillez"
VERSION="0.0.0"
if [[ -f "$PLUGIN_JSON" ]]; then
  if command -v python3 >/dev/null 2>&1; then
    NAME="$(AMILLEZ_PLUGIN_JSON="$PLUGIN_JSON" python3 -c 'import json,os; d=json.load(open(os.environ["AMILLEZ_PLUGIN_JSON"])); print(d.get("name","amillez"))')"
    VERSION="$(AMILLEZ_PLUGIN_JSON="$PLUGIN_JSON" python3 -c 'import json,os; d=json.load(open(os.environ["AMILLEZ_PLUGIN_JSON"])); print(d.get("version","0.0.0"))')"
  fi
fi
STAMP_BODY=$(cat <<STAMP
{
  "name": "$NAME",
  "version": "$VERSION",
  "installRoot": "user",
  "groups": "core$([ "$WANT_ARGENT" -eq 1 ] && echo ',argent' || true)",
  "skillsRoot": "$ROOT"
}
STAMP
)
mkdir -p "$HOME/.agents"
printf '%s\n' "$STAMP_BODY" > "$HOME/.amillez-plugin.json"
printf '%s\n' "$STAMP_BODY" > "$HOME/.agents/amillez-plugin.json"
echo "stamp: $HOME/.amillez-plugin.json"

echo "Done. Verify with: npx skills list -g  (and ls ~/.agents/skills ~/.claude/skills)"
echo "Ensure before coding: ./scripts/ensure-install.sh   (alias: ensure-project.sh)"
echo "Refresh: ./scripts/update-install.sh"
echo "Device groups: ./scripts/install.sh --groups core | --groups core,argent"
echo "Project skills: ./scripts/add-project-skills.sh <project> --skills …"
