#!/usr/bin/env bash
# Refresh upstream skills from GitHub (does not touch amillez skills under skills/).
set -euo pipefail
echo "== npx skills update (global allowlisted installs) =="
npx -y skills update -g -y
echo ""
echo "Argent CLI tip: when upgrading @swmansion/argent, bump the ref in manifest.json"
echo "  and in install.sh, then re-run: npx skills add software-mansion/argent/packages/skills/skills#<ref> --skill '*' --agent claude-code codex -g -y --copy (with CODEX_HOME=\"\$HOME/.agents\", as install.sh does)"
echo ""
