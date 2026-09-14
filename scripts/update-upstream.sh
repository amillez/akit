#!/usr/bin/env bash
# Refresh upstream skills from GitHub (does not touch first-party or vendor/codex).
set -euo pipefail
echo "== npx skills update (global allowlisted installs) =="
npx -y skills update -g -y
echo ""
echo "Argent CLI tip: when upgrading @swmansion/argent, bump the ref in manifest.json"
echo "  and re-run: npx skills add software-mansion/argent/packages/skills/skills#<ref> --skill '*' -g -y --copy"
echo ""
echo "Codex vendor snapshots: run scripts/refresh-codex-vendor.sh on a machine with latest Codex skills, then commit."
