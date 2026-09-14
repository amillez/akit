#!/usr/bin/env bash
# Install allowlisted skills onto this machine (Claude Code + Codex + shared agents dir).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v npx >/dev/null 2>&1; then
  echo "npx required" >&2
  exit 1
fi

echo "== Upstream packs (npx skills add) =="
# Argent — all skills; pin matches manifest
npx -y skills add "software-mansion/argent/packages/skills/skills#v0.25.0" --skill '*' --agent '*' -g -y --copy

npx -y skills add emilkowalski/skills --skill animate-expo --skill apple-design --agent '*' -g -y --copy

npx -y skills add mattpocock/skills --skill grill-me --agent '*' -g -y --copy

npx -y skills add expo/skills --skill expo-native-ui --skill expo-ui --skill expo-dev-client --skill expo-upgrade --agent '*' -g -y --copy

npx -y skills add software-mansion-labs/skills --skill react-native-best-practices --agent '*' -g -y --copy

npx -y skills add uni-stack/uniwind --skill uniwind --agent '*' -g -y --copy

echo "== First-party =="
mkdir -p "$HOME/.agents/skills" "$HOME/.claude/skills" "$HOME/.codex/skills"
rm -rf "$HOME/.agents/skills/orchestrate-agents" "$HOME/.claude/skills/orchestrate-agents" "$HOME/.codex/skills/orchestrate-agents"
cp -R "$ROOT/first-party/orchestrate-agents" "$HOME/.agents/skills/orchestrate-agents"
cp -R "$ROOT/first-party/orchestrate-agents" "$HOME/.claude/skills/orchestrate-agents"
cp -R "$ROOT/first-party/orchestrate-agents" "$HOME/.codex/skills/orchestrate-agents"

echo "== Vendored Codex native skills =="
for s in api-design build-nitro-modules cpp kotlin swift react-native-mmkv react-native-nitro-fetch react-native-vision-camera; do
  rm -rf "$HOME/.agents/skills/$s" "$HOME/.claude/skills/$s" "$HOME/.codex/skills/$s"
  cp -R "$ROOT/vendor/codex/$s" "$HOME/.agents/skills/$s"
  cp -R "$ROOT/vendor/codex/$s" "$HOME/.claude/skills/$s"
  cp -R "$ROOT/vendor/codex/$s" "$HOME/.codex/skills/$s"
done

echo "Done. Verify with: npx skills list -g  (and ls ~/.agents/skills)"
