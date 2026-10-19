#!/usr/bin/env bash
# Move skills that akit or its upstream packs once installed, and that are now excluded or renamed, out of the user skill dirs.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ./scripts/prune-skills.sh [--pending] [--manifest /path/to/manifest.json]

Reads the `prune` list in manifest.json. Each entry names skill folders and
the user skill dirs (~/.claude/skills, ~/.agents/skills, ~/.codex/skills) to
remove them from. Only listed names are touched; skills akit never installed
stay where they are.

Each match is moved, not deleted, to
  ~/.agent-work-skill-prune-backup/<YYYY-MM-DD>/<dir under HOME>/<name>
and logged to stdout and ~/.agent-work-skill-prune-backup/prune.log.
When an entry sets lockSource, its names are also dropped from
~/.agents/.skill-lock.json (backed up first) if their source matches, so
`npx skills update -g` does not bring them back.

To undo, move the folder back from the backup dir.

A name that this akit checkout still installs into that dir is never pruned.

  --pending   Print the paths that would be moved, change nothing. Exits 0
              if any are pending, 1 if none.
USAGE
}

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$ROOT/manifest.json"
PENDING=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --pending) PENDING=1; shift ;;
    --manifest)
      MANIFEST="${2:-}"
      [[ -n "$MANIFEST" ]] || { echo "error: --manifest requires a path" >&2; exit 1; }
      shift 2
      ;;
    *) echo "error: unexpected argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

exec python3 - "$MANIFEST" "$ROOT" "$PENDING" <<'PY'
import datetime, json, os, shutil, sys

manifest_path, root, pending = sys.argv[1], sys.argv[2], sys.argv[3] == "1"
home = os.environ["HOME"]
manifest = json.load(open(manifest_path))

# Names this checkout installs into ~/.claude/skills and ~/.agents/skills.
installed = {s for u in manifest.get("upstream", []) for s in u.get("skills", [])}
skills_dir = os.path.join(root, "skills")
if os.path.isdir(skills_dir):
    installed |= set(os.listdir(skills_dir))
install_roots = {"~/.claude/skills", "~/.agents/skills"}

def expand(p):
    return os.path.join(home, p[2:]) if p.startswith("~/") else p

moves, lock_drops = [], []
for entry in manifest.get("prune", []):
    for r in entry["roots"]:
        for name in entry["names"]:
            src = os.path.join(expand(r), name)
            if not os.path.lexists(src):
                continue
            if r in install_roots and name in installed:
                print(f"skip: {src} is still installed by akit", file=sys.stderr)
                continue
            moves.append((entry["id"], r, src))
    if entry.get("lockSource"):
        lock_drops += [(entry["lockSource"], n) for n in entry["names"]]

lock_path = os.path.join(home, ".agents", ".skill-lock.json")
lock = json.load(open(lock_path)) if os.path.isfile(lock_path) else None
lock_keys = []
if lock is not None:
    skills = lock.get("skills", {})
    lock_keys = [n for src, n in lock_drops if skills.get(n, {}).get("source") == src]

if pending:
    for _, _, src in moves:
        print(src)
    for n in lock_keys:
        print(f"{lock_path}#{n}")
    sys.exit(0 if (moves or lock_keys) else 1)

if not moves and not lock_keys:
    print("prune: nothing to move")
    sys.exit(0)

now = datetime.datetime.now()
backup_root = os.path.join(home, ".agent-work-skill-prune-backup")
day_dir = os.path.join(backup_root, now.strftime("%Y-%m-%d"))
os.makedirs(backup_root, exist_ok=True)
log = open(os.path.join(backup_root, "prune.log"), "a")

def record(line):
    print(line)
    log.write(f"{now.isoformat(timespec='seconds')} {line}\n")

for entry_id, r, src in moves:
    rel = os.path.relpath(expand(r), home)
    dest = os.path.join(day_dir, rel, os.path.basename(src))
    if os.path.lexists(dest):
        dest = f"{dest}-{now.strftime('%H%M%S')}"
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    shutil.move(src, dest)
    record(f"pruned ({entry_id}): {src} -> {dest}")

if lock_keys:
    lock_backup = os.path.join(day_dir, f"skill-lock.{now.strftime('%H%M%S')}.json")
    os.makedirs(day_dir, exist_ok=True)
    shutil.copy2(lock_path, lock_backup)
    for n in lock_keys:
        del lock["skills"][n]
    with open(lock_path, "w") as f:
        json.dump(lock, f, indent=2)
        f.write("\n")
    record(f"pruned lock entries {', '.join(lock_keys)} from {lock_path} (backup {lock_backup})")
log.close()
PY
