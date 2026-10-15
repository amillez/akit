#!/usr/bin/env bash
# Merge the permissions.allow entries from templates/claude-settings.json into ~/.claude/settings.json.
# Adds missing entries and keeps every other key. --check exits 1 when an entry is missing.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

MODE=merge
case "${1:-}" in
  --check) MODE=check ;;
  "") ;;
  *) echo "usage: $0 [--check]" >&2; exit 2 ;;
esac

if ! command -v python3 >/dev/null 2>&1; then
  echo "warning: python3 missing, skipping Claude settings" >&2
  exit 0
fi

python3 - "$MODE" "$ROOT/templates/claude-settings.json" "$HOME/.claude/settings.json" <<'PY'
import json, os, sys, tempfile

mode, template, dest = sys.argv[1:]
want = json.load(open(template))["permissions"]["allow"]
try:
    with open(dest) as f:
        settings = json.load(f)
except FileNotFoundError:
    settings = {}
except json.JSONDecodeError as e:
    sys.exit(f"error: {dest} is not valid JSON ({e}), left unchanged")

allow = settings.setdefault("permissions", {}).setdefault("allow", [])
missing = [rule for rule in want if rule not in allow]
if mode == "check":
    sys.exit(1 if missing else 0)
if not missing:
    print(f"ok (unchanged): {dest}")
    sys.exit(0)

allow.extend(missing)
real = os.path.realpath(dest)
os.makedirs(os.path.dirname(real), exist_ok=True)
fd, tmp = tempfile.mkstemp(dir=os.path.dirname(real))
with os.fdopen(fd, "w") as f:
    json.dump(settings, f, indent=2, ensure_ascii=False)
    f.write("\n")
if os.path.exists(real):
    os.chmod(tmp, os.stat(real).st_mode & 0o777)
os.replace(tmp, real)
print(f"allowed in {dest}: {', '.join(missing)}")
PY
