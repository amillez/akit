#!/usr/bin/env bash
# Run install.sh, update-install.sh, ensure-install.sh, and prune-skills.sh against a throwaway HOME with a stub npx.
set -uo pipefail

usage() {
  cat <<'USAGE'
Usage: ./scripts/test-install.sh [--keep]

Runs the install scripts in a temporary HOME with a stub npx that only logs
its arguments, so nothing touches your real ~/.claude, ~/.agents, or the network.
Prints PASS or FAIL per check and exits 1 on any failure.

  --keep   Keep the temporary directory and print its path
USAGE
}

KEEP=0
case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  --keep) KEEP=1 ;;
  "") ;;
  *) echo "error: unexpected argument: $1" >&2; usage >&2; exit 1 ;;
esac

REPO="$(cd "$(dirname "$0")/.." && pwd)"
BASE="$(mktemp -d)"
if [[ "$KEEP" -eq 1 ]]; then
  echo "sandbox: $BASE"
else
  trap 'rm -rf "$BASE"' EXIT
fi

mkdir -p "$BASE/bin"
cat > "$BASE/bin/npx" <<'NPX'
#!/usr/bin/env bash
echo "npx $*" >> "$HOME/npx.log"
NPX
chmod +x "$BASE/bin/npx"
export PATH="$BASE/bin:$PATH"
unset AMILLEZ_SKILLS_ROOT

failures=0
check() {
  if eval "$2"; then echo "PASS $1"; else echo "FAIL $1"; failures=$((failures + 1)); fi
}
has_skill() { [[ -f "$HOME/.claude/skills/$1/SKILL.md" && -f "$HOME/.agents/skills/$1/SKILL.md" ]]; }
ensure() { "$REPO/scripts/ensure-install.sh" --skills-root "$REPO" 2>&1 | tail -1; }
settings() { python3 -c 'import json,sys; print(json.dumps(json.load(open(sys.argv[1])), sort_keys=True))' "$HOME/.claude/settings.json"; }

AMILLEZ_SKILLS=()
for d in "$REPO"/skills/*/; do AMILLEZ_SKILLS+=("$(basename "$d")"); done

export HOME="$BASE/fresh"
mkdir -p "$HOME"
check "fresh HOME: ensure prints installed" '[[ "$(ensure)" == "amillez plugin: installed" ]]'
for s in "${AMILLEZ_SKILLS[@]}"; do
  check "fresh HOME: $s installed" 'has_skill "$s"'
done
check "fresh HOME: rules installed" '[[ -f "$HOME/.claude/rules/amillez-models.md" && -f "$HOME/.agents/rules/amillez-models.md" ]]'
check "fresh HOME: stamp written" '[[ -f "$HOME/.amillez-plugin.json" && -f "$HOME/.agents/amillez-plugin.json" ]]'
check "fresh HOME: Claude settings allow Read on the proof dir only" '[[ "$(settings)" == '"'"'{"permissions": {"allow": ["Read(~/agent-work/proof/**)"]}}'"'"' ]] || { echo "  got: $(settings 2>&1)"; false; }'

: > "$HOME/npx.log"
check "installed HOME: ensure prints already present" '[[ "$(ensure)" == "amillez plugin: already present" ]]'
check "installed HOME: ensure runs no npx" '[[ ! -s "$HOME/npx.log" ]]'

python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["permissions"]["allow"]=[]; json.dump(d, open(p, "w"))' "$HOME/.claude/settings.json"
check "missing proof Read rule: ensure prints updated" '[[ "$(ensure)" == "amillez plugin: updated" ]]'
check "missing proof Read rule: restored" '[[ "$(settings)" == '"'"'{"permissions": {"allow": ["Read(~/agent-work/proof/**)"]}}'"'"' ]]'

for s in "${AMILLEZ_SKILLS[@]}"; do
  rm -rf "$HOME/.claude/skills/$s"
  check "missing $s: ensure prints updated" '[[ "$(ensure)" == "amillez plugin: updated" ]]'
  check "missing $s: reinstalled" 'has_skill "$s"'
done

export HOME="$BASE/existing-settings"
mkdir -p "$HOME/.claude"
cat > "$HOME/.claude/settings.json" <<'JSON'
{
  "theme": "dark",
  "hooks": {"SessionStart": []},
  "permissions": {"allow": ["mcp__argent"], "deny": ["Read(./.env)"]}
}
JSON
"$REPO/scripts/update-install.sh" --skip-upstream >/dev/null 2>&1
EXPECTED='{"hooks": {"SessionStart": []}, "permissions": {"allow": ["mcp__argent", "Read(~/agent-work/proof/**)"], "deny": ["Read(./.env)"]}, "theme": "dark"}'
check "existing settings: proof Read rule appended, other keys kept" '[[ "$(settings)" == "$EXPECTED" ]] || { echo "  got: $(settings 2>&1)"; false; }'
cp "$HOME/.claude/settings.json" "$HOME/settings.before"
"$REPO/scripts/update-install.sh" --skip-upstream >/dev/null 2>&1
check "existing settings: second install leaves settings.json byte-identical" 'cmp -s "$HOME/settings.before" "$HOME/.claude/settings.json"'

export HOME="$BASE/core"
mkdir -p "$HOME"
"$REPO/scripts/install.sh" --groups core >/dev/null 2>&1
check "install --groups core: adds grill-me" 'grep -q "mattpocock/skills --skill grill-me" "$HOME/npx.log"'
check "install --groups core: adds grilling, which grill-me forwards to" 'grep -q "mattpocock/skills .*--skill grilling" "$HOME/npx.log"'
check "install --groups core: skips Argent" '! grep -q argent "$HOME/npx.log"'
check "install --groups core: skips Margelo Nitro" '! grep -q margelo/react-native-skills "$HOME/npx.log"'
MOBILE_AMILLEZ=$(python3 -c 'import json,sys; print(" ".join(sorted(e["id"] for e in json.load(open(sys.argv[1]))["amillez"] if e["group"] == "mobile")))' "$REPO/manifest.json")
CORE_ONLY=$("$REPO/scripts/install.sh" --list-skills --groups core | tr '\n' ' ')
check "install --groups core: skips manifest mobile amillez skills ($MOBILE_AMILLEZ)" '[[ "$(comm -23 <(printf "%s\n" "${AMILLEZ_SKILLS[@]}") <(printf "%s\n" $CORE_ONLY) | tr "\n" " ")" == "$MOBILE_AMILLEZ " ]]'
for s in $MOBILE_AMILLEZ; do
  check "install --groups core: $s not installed" '! has_skill "$s"'
done
check "installed --groups core: ensure --groups core prints already present" '[[ "$("$REPO/scripts/ensure-install.sh" --skills-root "$REPO" --groups core 2>&1 | tail -1)" == "amillez plugin: already present" ]]'

export HOME="$BASE/mobile"
mkdir -p "$HOME"
"$REPO/scripts/install.sh" >/dev/null 2>&1
ARGENT_PIN=$(python3 -c 'import json,sys; e=next(u for u in json.load(open(sys.argv[1]))["upstream"] if u["id"] == "argent"); print(e["package"] + "#" + e["ref"])' "$REPO/manifest.json")
check "install: Argent uses the manifest ref ($ARGENT_PIN)" 'grep -qF "skills add $ARGENT_PIN " "$HOME/npx.log" || { echo "  install.sh ran: $(grep argent "$HOME/npx.log")"; false; }'

export HOME="$BASE/skip-upstream"
mkdir -p "$HOME"
"$REPO/scripts/update-install.sh" --skip-upstream >/dev/null 2>&1
check "update-install --skip-upstream: runs no npx" '[[ ! -s "$HOME/npx.log" ]]'
for s in "${AMILLEZ_SKILLS[@]}"; do
  check "update-install --skip-upstream: $s installed" 'has_skill "$s"'
done
check "update-install --skip-upstream: stamp written" '[[ -f "$HOME/.amillez-plugin.json" ]]'

check "fresh HOME: no prune backup dir when nothing is listed" '[[ ! -e "$BASE/fresh/.agent-work-skill-prune-backup" ]]'

export HOME="$BASE/prune"
mkdir -p "$HOME"
"$REPO/scripts/update-install.sh" --skip-upstream >/dev/null 2>&1
seed() { mkdir -p "$HOME/$1" && echo "---" > "$HOME/$1/SKILL.md"; }
seed .claude/skills/expo-ui
seed .agents/skills/expo-ui
seed .agents/skills/expo-native-ui
mkdir -p "$HOME/elsewhere/expo-native-ui" && ln -s "$HOME/elsewhere/expo-native-ui" "$HOME/.claude/skills/expo-native-ui"
seed .codex/skills/react-native-nitro-fetch
seed .claude/skills/my-own-skill
seed .codex/skills/orchestrate-agents
seed .codex/skills/api-design
seed .codex/skills/my-codex-skill
seed .codex/skills/.system/imagegen
cat > "$HOME/.agents/.skill-lock.json" <<'JSON'
{"version": 3, "skills": {"expo-ui": {"source": "expo/skills"}, "expo-native-ui": {"source": "expo/skills"}, "expo-dev-client": {"source": "expo/skills"}, "mine": {"source": "me/skills"}}}
JSON
BACKUP="$HOME/.agent-work-skill-prune-backup/$(date +%F)"
check "prune: --pending lists the strays" '[[ "$("$REPO/scripts/prune-skills.sh" --pending | wc -l | tr -d " ")" == 9 ]]'
check "prune: --pending moves nothing" '[[ -d "$HOME/.claude/skills/expo-ui" && ! -e "$BASE/prune/.agent-work-skill-prune-backup" ]]'
check "prune: ensure prints updated when a prune is pending" '[[ "$(ensure)" == "amillez plugin: updated" ]]'
for p in .claude/skills/expo-ui .agents/skills/expo-ui .agents/skills/expo-native-ui .claude/skills/expo-native-ui .codex/skills/react-native-nitro-fetch .codex/skills/orchestrate-agents .codex/skills/api-design; do
  check "prune: $p moved out" '[[ ! -e "$HOME/$p" && ! -L "$HOME/$p" ]]'
  check "prune: $p in the dated backup" '[[ -e "$BACKUP/$p" || -L "$BACKUP/$p" ]]'
  check "prune: $p logged" 'grep -qF "$HOME/$p -> $BACKUP/$p" "$HOME/.agent-work-skill-prune-backup/prune.log"'
done
check "prune: symlinked stray moved as a link, target kept" '[[ -L "$BACKUP/.claude/skills/expo-native-ui" && -d "$HOME/elsewhere/expo-native-ui" ]]'
for p in .claude/skills/my-own-skill .codex/skills/my-codex-skill .codex/skills/.system/imagegen; do
  check "prune: unlisted $p left alone" '[[ -f "$HOME/$p/SKILL.md" ]]'
done
check "prune: current orchestrate-agents in ~/.claude and ~/.agents kept" 'has_skill orchestrate-agents'
check "prune: lock drops expo-ui and expo-native-ui only" '[[ "$(python3 -c "import json,sys; print(\" \".join(sorted(json.load(open(sys.argv[1]))[\"skills\"])))" "$HOME/.agents/.skill-lock.json")" == "expo-dev-client mine" ]]'
check "prune: lock backed up first" 'grep -q expo-native-ui "$BACKUP/skill-lock.json"'
check "prune: ensure prints already present once pruned" '[[ "$(ensure)" == "amillez plugin: already present" ]]'
lock_expo_ui() { python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["skills"]["expo-ui"]={"source":"expo/skills"}; json.dump(d,open(p,"w"))' "$HOME/.agents/.skill-lock.json"; }
seed .claude/skills/expo-ui && echo run2 > "$HOME/.claude/skills/expo-ui/SKILL.md" && lock_expo_ui
"$REPO/scripts/prune-skills.sh" >/dev/null
ln -s "$HOME/gone" "$HOME/.claude/skills/expo-ui" && lock_expo_ui
"$REPO/scripts/prune-skills.sh" >/dev/null
check "prune: three prunes the same day keep every folder backup" '[[ "$(cat "$BACKUP/.claude/skills/expo-ui/SKILL.md")" == "---" && "$(cat "$BACKUP/.claude/skills/expo-ui-1/SKILL.md")" == run2 && -L "$BACKUP/.claude/skills/expo-ui-2" ]]'
check "prune: three prunes the same day keep every lock backup" '[[ -f "$BACKUP/skill-lock.json" && -f "$BACKUP/skill-lock-1.json" && -f "$BACKUP/skill-lock-2.json" ]]'
check "prune: lock rewrite leaves no temp file" '[[ -z "$(ls -A "$HOME/.agents" | grep prune)" ]]'

python3 -c 'import json,sys; m=json.load(open(sys.argv[1])); m["prune"]=[{"id":"t","names":["orchestrate-agents","expo-dev-client"],"roots":["~/.claude/skills"]}]; json.dump(m,open(sys.argv[2],"w"))' "$REPO/manifest.json" "$HOME/guard-manifest.json"
seed .claude/skills/expo-dev-client
"$REPO/scripts/prune-skills.sh" --manifest "$HOME/guard-manifest.json" >/dev/null 2>&1
check "prune: a listed name akit still installs is kept" 'has_skill orchestrate-agents && [[ -f "$HOME/.claude/skills/expo-dev-client/SKILL.md" ]]'

python3 -c 'import json,sys; m=json.load(open(sys.argv[1])); m["prune"]=[{"id":"t","names":["synced",".system"],"roots":["~/.claude/skills","~/.codex/skills"]}]; json.dump(m,open(sys.argv[2],"w"))' "$REPO/manifest.json" "$HOME/protected-manifest.json"
seed .claude/skills/synced
"$REPO/scripts/prune-skills.sh" --manifest "$HOME/protected-manifest.json" >/dev/null 2>&1
check "prune: synced/ and .system/ never moved" '[[ -f "$HOME/.claude/skills/synced/SKILL.md" && -f "$HOME/.codex/skills/.system/imagegen/SKILL.md" ]]'

seed .claude/skills/expo-ui
python3 -c 'import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["skills"]["expo-ui"]={"source":"my/skills"}; json.dump(d,open(p,"w"))' "$HOME/.agents/.skill-lock.json"
check "prune: a folder locked to another source is not pending" '! "$REPO/scripts/prune-skills.sh" --pending >/dev/null 2>&1'
"$REPO/scripts/prune-skills.sh" >/dev/null 2>&1
check "prune: a folder locked to another source is kept with its lock entry" '[[ -f "$HOME/.claude/skills/expo-ui/SKILL.md" ]] && grep -q my/skills "$HOME/.agents/.skill-lock.json"'

echo '{' > "$HOME/.agents/.skill-lock.json"
seed .codex/skills/api-design
rc=0; "$REPO/scripts/prune-skills.sh" --pending >/dev/null 2>&1 || rc=$?
check "prune: malformed lock makes --pending exit 2" '[[ $rc == 2 ]]'
check "prune: malformed lock makes ensure fail, not report already present" '! "$REPO/scripts/ensure-install.sh" --skills-root "$REPO" >"$HOME/ensure.out" 2>&1 && ! grep -q "already present" "$HOME/ensure.out" && grep -q JSONDecodeError "$HOME/ensure.out"'
check "prune: malformed lock moves nothing" '[[ -f "$HOME/.codex/skills/api-design/SKILL.md" ]]'
mkdir -p "$BASE/nopy" && ln -sf "$(command -v bash)" "$(command -v dirname)" "$BASE/nopy/"
rc=0; PATH="$BASE/nopy" "$REPO/scripts/prune-skills.sh" --pending >/dev/null 2>&1 || rc=$?
check "prune: missing python3 makes --pending exit 2" '[[ $rc == 2 ]]'

export HOME="$BASE/prune-alias"
mkdir -p "$HOME/.codex"
"$REPO/scripts/update-install.sh" --skip-upstream >/dev/null 2>&1
seed .agents/skills/api-design
ln -s "$HOME/.agents/skills" "$HOME/.codex/skills"
check "alias: ~/.codex/skills -> ~/.agents/skills has nothing pending" '! "$REPO/scripts/prune-skills.sh" --pending >/dev/null 2>&1'
check "alias: ensure prints already present" '[[ "$(ensure)" == "amillez plugin: already present" ]]'
"$REPO/scripts/prune-skills.sh" >/dev/null 2>&1
check "alias: installed skills behind the alias kept" 'has_skill orchestrate-agents && [[ -f "$HOME/.agents/skills/api-design/SKILL.md" ]]'
check "alias: no backup made" '[[ ! -e "$HOME/.agent-work-skill-prune-backup" ]]'
rm "$HOME/.codex/skills"
mkdir -p "$BASE/outside/api-design" && ln -s "$BASE/outside" "$HOME/.codex/skills"
check "outside HOME: a root resolving outside HOME is not pending" '! "$REPO/scripts/prune-skills.sh" --pending >/dev/null 2>&1'
"$REPO/scripts/prune-skills.sh" >/dev/null 2>&1
check "outside HOME: nothing moved" '[[ -d "$BASE/outside/api-design" ]]'
rm "$HOME/.codex/skills" && seed .codex/skills/api-design
mkdir -p "$BASE/outside-backup" && ln -s "$BASE/outside-backup" "$HOME/.agent-work-skill-prune-backup"
rc=0; "$REPO/scripts/prune-skills.sh" --pending >/dev/null 2>&1 || rc=$?
check "backup outside HOME: --pending exits 2" '[[ $rc == 2 ]]'
check "backup outside HOME: ensure fails, not report updated or already present" '! "$REPO/scripts/ensure-install.sh" --skills-root "$REPO" >"$HOME/ensure.out" 2>&1 && ! grep -q "amillez plugin:" "$HOME/ensure.out" && grep -q "outside HOME" "$HOME/ensure.out"'
check "backup outside HOME: nothing moved" '[[ -f "$HOME/.codex/skills/api-design/SKILL.md" && -z "$(ls -A "$BASE/outside-backup")" ]]'

if [[ "$failures" -gt 0 ]]; then
  echo "$failures check(s) failed"
  exit 1
fi
echo "all checks passed"
