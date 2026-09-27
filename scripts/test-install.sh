#!/usr/bin/env bash
# Run install.sh, update-install.sh, and ensure-install.sh against a throwaway HOME with a stub npx.
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

AMILLEZ_SKILLS=()
for d in "$REPO"/skills/*/; do AMILLEZ_SKILLS+=("$(basename "$d")"); done
VENDOR=()
for d in "$REPO"/vendor/codex/*/; do VENDOR+=("$(basename "$d")"); done

export HOME="$BASE/fresh"
mkdir -p "$HOME"
check "fresh HOME: ensure prints installed" '[[ "$(ensure)" == "amillez plugin: installed" ]]'
for s in "${AMILLEZ_SKILLS[@]}" "${VENDOR[@]}"; do
  check "fresh HOME: $s installed" 'has_skill "$s"'
done
check "fresh HOME: rules installed" '[[ -f "$HOME/.claude/rules/amillez-models.md" && -f "$HOME/.agents/rules/amillez-models.md" ]]'
check "fresh HOME: stamp written" '[[ -f "$HOME/.amillez-plugin.json" && -f "$HOME/.agents/amillez-plugin.json" ]]'

: > "$HOME/npx.log"
check "installed HOME: ensure prints already present" '[[ "$(ensure)" == "amillez plugin: already present" ]]'
check "installed HOME: ensure runs no npx" '[[ ! -s "$HOME/npx.log" ]]'

for s in "${AMILLEZ_SKILLS[@]}"; do
  rm -rf "$HOME/.claude/skills/$s"
  check "missing $s: ensure prints updated" '[[ "$(ensure)" == "amillez plugin: updated" ]]'
  check "missing $s: reinstalled" 'has_skill "$s"'
done

export HOME="$BASE/core"
mkdir -p "$HOME"
"$REPO/scripts/install.sh" --groups core >/dev/null 2>&1
check "install --groups core: adds grill-me" 'grep -q "mattpocock/skills --skill grill-me" "$HOME/npx.log"'
check "install --groups core: skips Argent" '! grep -q argent "$HOME/npx.log"'
check "install --groups core: skips vendor" '[[ ! -e "$HOME/.claude/skills/${VENDOR[0]}" ]]'

export HOME="$BASE/skip-upstream"
mkdir -p "$HOME"
"$REPO/scripts/update-install.sh" --skip-upstream >/dev/null 2>&1
check "update-install --skip-upstream: runs no npx" '[[ ! -s "$HOME/npx.log" ]]'
for s in "${AMILLEZ_SKILLS[@]}" "${VENDOR[@]}"; do
  check "update-install --skip-upstream: $s installed" 'has_skill "$s"'
done
check "update-install --skip-upstream: stamp written" '[[ -f "$HOME/.amillez-plugin.json" ]]'

if [[ "$failures" -gt 0 ]]; then
  echo "$failures check(s) failed"
  exit 1
fi
echo "all checks passed"
