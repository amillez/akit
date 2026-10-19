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
(<name>-1, <name>-2, ... if that exists) and logged to stdout and
~/.agent-work-skill-prune-backup/prune.log.
When an entry sets lockSource, its names are also dropped from
~/.agents/.skill-lock.json (backed up first) if their source matches, so
`npx skills update -g` does not bring them back. A folder whose lock entry
names another source is left alone.

Skipped: a name this akit checkout still installs into a root that resolves
to ~/.claude/skills or ~/.agents/skills (so a ~/.codex/skills symlink to
~/.agents/skills is guarded too), anything that resolves outside HOME, and
anything under synced/ or .system/.

To undo, move the folder back from the backup dir.

  --pending   Print the paths that would be moved, change nothing. Exits 0
              if any are pending, 1 if none.

Exits 2 on any error (bad argument, missing python3, malformed manifest or
lock, or a backup dir that resolves outside HOME or can't be created), in
--pending too.
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
      [[ -n "$MANIFEST" ]] || { echo "error: --manifest requires a path" >&2; exit 2; }
      shift 2
      ;;
    *) echo "error: unexpected argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

command -v python3 >/dev/null || { echo "error: python3 not found" >&2; exit 2; }
exec python3 - "$MANIFEST" "$ROOT" "$PENDING" <<'PY'
import datetime, json, os, shutil, sys

def fail(kind, err, tb):
    sys.stdout.flush()
    print(f"error: {kind.__name__}: {err}", file=sys.stderr)
    os._exit(2)
# Any error exits 2, so --pending's exit 1 always means nothing is pending.
sys.excepthook = fail

manifest_path, root, pending = sys.argv[1], sys.argv[2], sys.argv[3] == "1"
home = os.environ["HOME"]
real_home = os.path.realpath(home)
manifest = json.load(open(manifest_path))
PROTECTED = {"synced", ".system"}

def expand(p):
    return os.path.join(home, p[2:]) if p.startswith("~/") else p

def inside(path, base):
    return path == base or path.startswith(base.rstrip(os.sep) + os.sep)

# Names this checkout installs into ~/.claude/skills and ~/.agents/skills.
installed = {s for u in manifest.get("upstream", []) for s in u.get("skills", [])}
skills_dir = os.path.join(root, "skills")
if os.path.isdir(skills_dir):
    installed |= set(os.listdir(skills_dir))
install_roots = [os.path.realpath(expand(r)) for r in ("~/.claude/skills", "~/.agents/skills")]

lock_path = os.path.join(home, ".agents", ".skill-lock.json")

def read_lock():
    if not os.path.isfile(lock_path):
        return None, None
    with open(lock_path, "rb") as f:
        raw = f.read()
    return raw, json.loads(raw)

def lock_source(lock, name):
    return (lock or {}).get("skills", {}).get(name, {}).get("source")

_, lock = read_lock()

moves, lock_drops, seen = [], [], set()
for entry in manifest.get("prune", []):
    want = entry.get("lockSource")
    for r in entry["roots"]:
        real_root = os.path.realpath(expand(r))
        for name in entry["names"]:
            src = os.path.join(expand(r), name)
            # The folder itself may be a symlink; it moves as a link, so resolve only its parent.
            real_src = os.path.join(real_root, name)
            if not os.path.lexists(src) or real_src in seen:
                continue
            if not inside(real_src, real_home) or PROTECTED & set(os.path.relpath(real_src, real_home).split(os.sep)):
                print(f"skip: {src} resolves to {real_src}, outside HOME or protected", file=sys.stderr)
                continue
            if name in installed and any(inside(real_root, i) for i in install_roots):
                print(f"skip: {src} is still installed by akit", file=sys.stderr)
                continue
            found = lock_source(lock, name)
            if want and found not in (None, want):
                print(f"skip: {src} is locked to {found}, not {want}", file=sys.stderr)
                continue
            seen.add(real_src)
            moves.append((entry["id"], r, src))
    if want:
        lock_drops += [(want, n) for n in entry["names"]]

lock_keys = [n for src, n in lock_drops if lock_source(lock, n) == src]

now = datetime.datetime.now()
backup_root = os.path.join(home, ".agent-work-skill-prune-backup")
day_dir = os.path.join(backup_root, now.strftime("%Y-%m-%d"))

def backup_problem(d):
    real = os.path.realpath(d)
    if not inside(real, real_home):
        return f"resolves to {real}, outside HOME"
    while not os.path.lexists(real):
        real = os.path.dirname(real)
    if not os.path.isdir(real) or not os.access(real, os.W_OK | os.X_OK):
        return f"can't be created: {real} is not a writable directory"

# Checked before --pending answers, so it never reports work the real run can't do.
if moves or lock_keys:
    for d in dict.fromkeys([backup_root, day_dir] + [os.path.join(day_dir, os.path.relpath(expand(r), home)) for _, r, _ in moves]):
        problem = backup_problem(d)
        if problem:
            print(f"error: backup dir {d} {problem}", file=sys.stderr)
            sys.exit(2)

if pending:
    for _, _, src in moves:
        print(src)
    for n in lock_keys:
        print(f"{lock_path}#{n}")
    sys.exit(0 if (moves or lock_keys) else 1)

if not moves and not lock_keys:
    print("prune: nothing to move")
    sys.exit(0)

os.makedirs(backup_root, exist_ok=True)
log = open(os.path.join(backup_root, "prune.log"), "a", buffering=1)

def record(line):
    print(line)
    log.write(f"{now.isoformat(timespec='seconds')} {line}\n")

def free_path(base, ext=""):
    path, n = base + ext, 0
    while os.path.lexists(path):
        n += 1
        path = f"{base}-{n}{ext}"
    return path

for entry_id, r, src in moves:
    rel = os.path.relpath(expand(r), home)
    dest = free_path(os.path.join(day_dir, rel, os.path.basename(src)))
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    shutil.move(src, dest)
    record(f"pruned ({entry_id}): {src} -> {dest}")

if lock_keys:
    # Re-read so entries npx skills wrote during the moves survive. Not a mutex: a write between this read and os.replace is lost.
    raw, lock = read_lock()
    drop = list(dict.fromkeys(n for src, n in lock_drops if lock_source(lock, n) == src))
    if drop:
        os.makedirs(day_dir, exist_ok=True)
        lock_backup = free_path(os.path.join(day_dir, "skill-lock"), ".json")
        with open(lock_backup, "xb") as f:
            f.write(raw)
        for n in drop:
            del lock["skills"][n]
        tmp = f"{lock_path}.prune-{os.getpid()}"
        try:
            with open(tmp, "w") as f:
                json.dump(lock, f, indent=2)
                f.write("\n")
                f.flush()
                os.fsync(f.fileno())
            os.replace(tmp, lock_path)
        finally:
            if os.path.lexists(tmp):
                os.unlink(tmp)
        record(f"pruned lock entries {', '.join(drop)} from {lock_path} (backup {lock_backup})")
log.close()
PY
