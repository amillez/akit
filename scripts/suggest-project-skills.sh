#!/usr/bin/env bash
# Scan a project's package.json / lockfile-ish deps and suggest curated project skills.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ./scripts/suggest-project-skills.sh <project>

Reads package.json (and workspace package.json files one level deep) and prints
suggested skills from the agent-skills project catalog. Does not modify the tree.

Then add with:
  ./scripts/add-project-skills.sh <project> --skills a,b,c
USAGE
}

PROJECT="${1:-}"
if [[ "$PROJECT" == "-h" || "$PROJECT" == "--help" ]]; then
  usage
  exit 0
fi
if [[ -z "$PROJECT" || ! -d "$PROJECT" ]]; then
  echo "error: project directory required" >&2
  usage >&2
  exit 1
fi
PROJECT="$(cd "$PROJECT" && pwd)"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_ROOT="${AMILLEZ_SKILLS_ROOT:-$REPO_ROOT}"
MANIFEST="$SKILLS_ROOT/manifest.json"

# Collect dependency names from package.json files
DEPS_FILE="$(mktemp)"
trap 'rm -f "$DEPS_FILE"' EXIT

collect_pkg() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  python3 - "$f" >>"$DEPS_FILE" <<'PY'
import json, sys
path = sys.argv[1]
try:
    d = json.load(open(path))
except Exception:
    raise SystemExit(0)
for key in ("dependencies", "devDependencies", "peerDependencies", "optionalDependencies"):
    for name in (d.get(key) or {}):
        print(name.lower())
PY
}

collect_pkg "$PROJECT/package.json"
# one-level workspace packages
shopt -s nullglob
for f in "$PROJECT"/*/package.json "$PROJECT"/apps/*/package.json "$PROJECT"/packages/*/package.json; do
  collect_pkg "$f"
done
shopt -u nullglob

if [[ ! -s "$DEPS_FILE" ]]; then
  echo "No package.json deps found under $PROJECT"
  echo "Catalog (manual pick):"
  "$SCRIPT_DIR/add-project-skills.sh" --list
  exit 0
fi

SUGGESTED="$(python3 - "$DEPS_FILE" <<'PY'
import sys
deps = set(l.strip() for l in open(sys.argv[1]) if l.strip())

# Map dependency needles → skill names
rules = [
    (("react-native-vision-camera", "vision-camera"), ["react-native-vision-camera"]),
    (("react-native-mmkv", "react-native-mmkv"), ["react-native-mmkv"]),
    (("react-native-nitro-fetch", "nitro-fetch"), ["react-native-nitro-fetch"]),
    (("react-native-nitro-modules", "nitrogen", "nitro-modules"), ["build-nitro-modules", "api-design"]),
    (("uniwind",), ["uniwind"]),
    (("expo", "expo-dev-client", "eas-cli"), ["expo-dev-client", "expo-upgrade"]),
    (("react-native-reanimated", "react-native-gesture-handler"), ["animate-expo", "review-animations"]),
    (("react-native", "expo"), ["react-native-best-practices", "apple-design"]),
    (("swift",), ["swift"]),
    (("kotlin",), ["kotlin"]),
]

seen = []
for needles, skills in rules:
    if any(any(n in d or d == n for d in deps) for n in needles):
        for s in skills:
            if s not in seen:
                seen.append(s)

# Broader: any expo-* package
if any(d == "expo" or d.startswith("expo-") for d in deps):
    for s in ("expo-dev-client", "expo-upgrade", "react-native-best-practices"):
        if s not in seen:
            seen.append(s)

print("\n".join(seen))
PY
)"

if [[ -z "$SUGGESTED" ]]; then
  echo "No matching project skills for detected deps."
  echo "Run: $SCRIPT_DIR/add-project-skills.sh --list"
  exit 0
fi

echo "Suggested project skills for $PROJECT:"
echo "$SUGGESTED" | sed 's/^/  - /'
CSV="$(echo "$SUGGESTED" | paste -sd, -)"
echo
echo "Add with:"
echo "  $SCRIPT_DIR/add-project-skills.sh \"$PROJECT\" --skills $CSV"
