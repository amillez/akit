#!/usr/bin/env bash
# Install allowlisted skills, user rules, and the stamp at user root for Claude Code and Codex.
# Never writes into project trees.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

usage() {
  cat <<'USAGE'
Usage: ./scripts/install.sh [--groups core|mobile|core,mobile] [--skip-upstream] [--list-skills]

Install allowlisted skills into ~/.claude/skills and ~/.agents/skills, the
model rules into ~/.claude/rules and ~/.agents/rules, and the stamp
~/.amillez-plugin.json. Never writes into project trees.

Groups:
  core    Always installed: grill-me, grilling, and every amillez skill under skills/
          except the mobile ones (amillez-mode, orchestrate-agents,
          create-verification-skill, maintain-verification-skill,
          setup-amillez-models, typescript-best-practices, correct,
          blast-radius, reflect, show-me-your-work, figure-it-out, unslop)
  mobile  RN/Expo/native: Argent, animate-expo, apple-design, review-animations,
          expo-dev-client, expo-upgrade, react-native-best-practices, uniwind,
          Margelo Nitro modules (margelo/react-native-skills), and the amillez
          simfleet, amillez-react-native-mode, and bootstrap-empty-app skills

Default: core,mobile
--groups mobile still includes core (core is always added).
--groups core skips mobile.

--skip-upstream  Skip the npx upstream packs. Installs amillez skills,
                 rules, and the stamp only.
--list-skills    Print the amillez skill names the chosen groups install, then exit.
USAGE
}

# amillez skills under skills/ tagged "group": "mobile" in the manifest.json `amillez` list.
MOBILE_AMILLEZ_SKILLS=(simfleet amillez-react-native-mode bootstrap-empty-app)

GROUPS_ARG=""
SKIP_UPSTREAM=0
LIST_SKILLS=0
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
    --skip-upstream)
      SKIP_UPSTREAM=1
      shift
      ;;
    --list-skills)
      LIST_SKILLS=1
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

# Resolve requested groups. Core is always included.
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

amillez_skills() {
  local dir s
  for dir in "$ROOT"/skills/*/; do
    s="$(basename "$dir")"
    if [[ "$WANT_MOBILE" -eq 0 && " ${MOBILE_AMILLEZ_SKILLS[*]} " == *" $s "* ]]; then
      continue
    fi
    echo "$s"
  done
}

if [[ "$LIST_SKILLS" -eq 1 ]]; then
  amillez_skills
  exit 0
fi

echo "Groups: core$([ "$WANT_MOBILE" -eq 1 ] && echo '+mobile' || true) (core always)"

if [[ "$SKIP_UPSTREAM" -eq 0 ]]; then
  if ! command -v npx >/dev/null 2>&1; then
    echo "npx required (or pass --skip-upstream)" >&2
    exit 1
  fi

  echo "== Upstream packs (npx skills add) =="

  if [[ "$WANT_MOBILE" -eq 1 ]]; then
    # Argent: all skills, pinned to the ref in manifest.json
    npx -y skills add "software-mansion/argent/packages/skills/skills#v0.25.0" --skill '*' --agent '*' -g -y --copy

    npx -y skills add emilkowalski/skills --skill animate-expo --skill apple-design --skill review-animations --agent '*' -g -y --copy
  fi

  npx -y skills add mattpocock/skills --skill grill-me --skill grilling --agent '*' -g -y --copy

  if [[ "$WANT_MOBILE" -eq 1 ]]; then
    npx -y skills add expo/skills --skill expo-dev-client --skill expo-upgrade --agent '*' -g -y --copy

    npx -y skills add software-mansion-labs/skills --skill react-native-best-practices --agent '*' -g -y --copy

    npx -y skills add uni-stack/uniwind --skill uniwind --agent '*' -g -y --copy

    npx -y skills add margelo/react-native-skills \
      --skill api-design \
      --skill build-nitro-modules \
      --skill cpp \
      --skill kotlin \
      --skill swift \
      --skill react-native-mmkv \
      --skill react-native-nitro-fetch \
      --skill react-native-vision-camera \
      --agent '*' -g -y --copy
  fi
fi

mkdir -p "$HOME/.agents/skills" "$HOME/.claude/skills"
echo "== Amillez skills (skills/) =="
while read -r s; do
  rm -rf "$HOME/.agents/skills/$s" "$HOME/.claude/skills/$s"
  cp -R "$ROOT/skills/$s" "$HOME/.agents/skills/$s"
  cp -R "$ROOT/skills/$s" "$HOME/.claude/skills/$s"
done < <(amillez_skills)

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
echo "Ensure before coding: ./scripts/ensure-install.sh"
echo "Refresh: ./scripts/update-install.sh"
