#!/usr/bin/env bash
# Install allowlisted skills onto this machine (Claude Code + Codex + shared agents dir).
# Canonical first-party tree: skills/ (amillez plugin pack). Never installs into .cursor/.
#
# Groups:
#   core   — always added (grill-me + first-party)
#   mobile — RN/Expo/native (Argent, Emil, Expo, SWM, Uniwind, Codex vendor)
#
# Usage:
#   ./scripts/install.sh                     # default: core + mobile
#   ./scripts/install.sh --groups core       # core only (skips mobile)
#   ./scripts/install.sh --groups mobile     # core still added (always) + mobile
#   ./scripts/install.sh --groups core,mobile
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

usage() {
  cat <<'USAGE'
Usage: ./scripts/install.sh [--groups core|mobile|core,mobile]

Install allowlisted skills + user rules for Claude Code + Codex + ~/.agents (never .cursor/, never project trees).

Groups:
  core    Always installed: grill-me, orchestrate-agents, create-verification-skill,
          maintain-verification-skill, setup-amillez-models
  mobile  RN/Expo/native: Argent, animate-expo, apple-design, review-animations,
          expo-dev-client, expo-upgrade, react-native-best-practices, uniwind,
          Codex native vendor set

Default: core,mobile
--groups mobile still includes core (core is always added).
--groups core skips mobile.
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

# Resolve requested groups. Core is always included.
WANT_CORE=1
WANT_MOBILE=0
if [[ -z "$GROUPS_ARG" ]]; then
  WANT_MOBILE=1
else
  IFS=',' read -ra RAW_GROUPS <<< "$GROUPS_ARG"
  saw_any=0
  for g in "${RAW_GROUPS[@]}"; do
    # trim + lowercase
    g="${g#"${g%%[![:space:]]*}"}"
    g="${g%"${g##*[![:space:]]}"}"
    g="$(printf '%s' "$g" | tr '[:upper:]' '[:lower:]')"
    case "$g" in
      core)
        saw_any=1
        ;;
      mobile)
        WANT_MOBILE=1
        saw_any=1
        ;;
      "")
        ;;
      *)
        echo "error: unknown group '$g' (valid: core, mobile)" >&2
        exit 1
        ;;
    esac
  done
  if [[ "$saw_any" -eq 0 ]]; then
    echo "error: --groups produced no valid groups" >&2
    exit 1
  fi
fi

echo "Groups: core$([ "$WANT_MOBILE" -eq 1 ] && echo '+mobile' || true) (core always)"

if ! command -v npx >/dev/null 2>&1; then
  echo "npx required" >&2
  exit 1
fi

echo "== Upstream packs (npx skills add) =="

if [[ "$WANT_MOBILE" -eq 1 ]]; then
  # Argent — all skills; pin matches manifest
  npx -y skills add "software-mansion/argent/packages/skills/skills#v0.25.0" --skill '*' --agent '*' -g -y --copy

  npx -y skills add emilkowalski/skills --skill animate-expo --skill apple-design --skill review-animations --agent '*' -g -y --copy
fi

# core: grill-me
npx -y skills add mattpocock/skills --skill grill-me --agent '*' -g -y --copy

if [[ "$WANT_MOBILE" -eq 1 ]]; then
  npx -y skills add expo/skills --skill expo-dev-client --skill expo-upgrade --agent '*' -g -y --copy

  npx -y skills add software-mansion-labs/skills --skill react-native-best-practices --agent '*' -g -y --copy

  npx -y skills add uni-stack/uniwind --skill uniwind --agent '*' -g -y --copy
fi

echo "== First-party (canonical tree: skills/) [core] =="
mkdir -p "$HOME/.agents/skills" "$HOME/.claude/skills"
for s in orchestrate-agents create-verification-skill maintain-verification-skill setup-amillez-models; do
  rm -rf "$HOME/.agents/skills/$s" "$HOME/.claude/skills/$s"
  cp -R "$ROOT/skills/$s" "$HOME/.agents/skills/$s"
  cp -R "$ROOT/skills/$s" "$HOME/.claude/skills/$s"
done

if [[ "$WANT_MOBILE" -eq 1 ]]; then
  echo "== Vendored Codex native skills [mobile] =="
  for s in api-design build-nitro-modules cpp kotlin swift react-native-mmkv react-native-nitro-fetch react-native-vision-camera; do
    rm -rf "$HOME/.agents/skills/$s" "$HOME/.claude/skills/$s"
    cp -R "$ROOT/vendor/codex/$s" "$HOME/.agents/skills/$s"
    cp -R "$ROOT/vendor/codex/$s" "$HOME/.claude/skills/$s"
  done
fi

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
echo "Groups: ./scripts/install.sh --groups core | --groups mobile | --groups core,mobile"
