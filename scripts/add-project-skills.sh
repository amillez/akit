#!/usr/bin/env bash
# Optional helper: mirror selected device/stack skills into a project's
# .claude/skills + .agents/skills (real copies, ready to commit).
# Device primary home remains ~/.claude + ~/.agents (default core+mobile).
# Do not dump the whole mobile set into every project — pick stack-relevant names.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ./scripts/add-project-skills.sh <project> --skills a,b,c [--force] [--skills-root /path]
       ./scripts/add-project-skills.sh --list [--skills-root /path]

Optional teammate mirror: copy selected skills into BOTH:
  <project>/.claude/skills/<name>/
  <project>/.agents/skills/<name>/

Primary install is still device/host (./scripts/install.sh / ensure-install.sh,
default core+mobile at ~/.claude + ~/.agents). Use this only when a project
should also commit stack-relevant skills for teammates (e.g. uniwind).

Options:
  --skills a,b,c   Comma-separated skill names (mobile catalog; not Argent)
  --force          Replace existing skill dirs (otherwise refuse to clobber)
  --skills-root    agent-skills checkout (default: this repo / AMILLEZ_SKILLS_ROOT)
  --list           Print mirrorable skill names and exit

Example:
  ./scripts/add-project-skills.sh /path/to/app --skills uniwind
USAGE
}

PROJECT=""
SKILLS_CSV=""
FORCE=0
SKILLS_ROOT_OVERRIDE=""
LIST_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --skills)
      SKILLS_CSV="${2:-}"
      if [[ -z "$SKILLS_CSV" ]]; then
        echo "error: --skills requires a comma-separated list" >&2
        exit 1
      fi
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --skills-root)
      SKILLS_ROOT_OVERRIDE="${2:-}"
      if [[ -z "$SKILLS_ROOT_OVERRIDE" ]]; then
        echo "error: --skills-root requires a path" >&2
        exit 1
      fi
      shift 2
      ;;
    --list)
      LIST_ONLY=1
      shift
      ;;
    --*)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -n "$PROJECT" ]]; then
        echo "error: unexpected argument: $1" >&2
        usage >&2
        exit 1
      fi
      PROJECT="$1"
      shift
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

resolve_skills_root() {
  if [[ -n "$SKILLS_ROOT_OVERRIDE" ]]; then
    echo "$SKILLS_ROOT_OVERRIDE"
    return
  fi
  if [[ -n "${AMILLEZ_SKILLS_ROOT:-}" ]]; then
    echo "$AMILLEZ_SKILLS_ROOT"
    return
  fi
  if [[ -d "$REPO_ROOT/skills" ]]; then
    echo "$REPO_ROOT"
    return
  fi
  local home_clone="${HOME}/agent-work/agent-skills"
  if [[ -d "$home_clone/skills" ]]; then
    echo "$home_clone"
    return
  fi
  echo "$REPO_ROOT"
}

SKILLS_ROOT="$(resolve_skills_root)"
MANIFEST="$SKILLS_ROOT/manifest.json"
CACHE_DIR="$SKILLS_ROOT/.cache/upstream-skills"

if [[ ! -f "$MANIFEST" ]]; then
  echo "error: manifest.json not found under $SKILLS_ROOT" >&2
  exit 1
fi

# Mirrorable catalog = mobile-group skills excluding Argent (host UI drive).
catalog_json() {
  AMILLEZ_MANIFEST="$MANIFEST" python3 -c '
import json, os
m = json.load(open(os.environ["AMILLEZ_MANIFEST"]))
names = []
seen = set()
for e in (m.get("upstream") or []) + (m.get("vendor") or []):
    if (e.get("group") or "") != "mobile":
        continue
    path = e.get("path") or ""
    pkg = e.get("package") or ""
    # Argent stays device-only for project mirrors
    if "argent" in pkg.lower() or "argent" in path.lower():
        continue
    for s in e.get("skills") or []:
        if s == "*" or not s or s in seen:
            continue
        if s.startswith("argent"):
            continue
        seen.add(s)
        names.append(s)
print(json.dumps(names))
'
}

skill_meta() {
  # prints: source_kind\tpackage_or_path\tref_or_empty
  local name="$1"
  AMILLEZ_MANIFEST="$MANIFEST" AMILLEZ_SKILL="$name" python3 -c '
import json, os
m = json.load(open(os.environ["AMILLEZ_MANIFEST"]))
sid = os.environ["AMILLEZ_SKILL"]
for e in m.get("vendor") or []:
    path = e.get("path") or ""
    for s in e.get("skills") or []:
        if s == sid:
            print(f"vendor\t{path}/{s}\t")
            raise SystemExit
for e in m.get("upstream") or []:
    if (e.get("group") or "") != "mobile":
        continue
    pkg = e.get("package") or ""
    if "argent" in pkg.lower():
        continue
    ref = e.get("ref") or ""
    for s in e.get("skills") or []:
        if s == sid or s == "*":
            print(f"upstream\t{pkg}\t{ref}")
            raise SystemExit
print("unknown\t\t")
'
}

CATALOG="$(catalog_json)"

if [[ "$LIST_ONLY" -eq 1 ]]; then
  echo "Mirrorable skills (optional project copies; device still has core+mobile):"
  AMILLEZ_CATALOG="$CATALOG" python3 -c 'import json,os; [print(f"  - {s}") for s in json.loads(os.environ["AMILLEZ_CATALOG"])]'
  exit 0
fi

if [[ -z "$PROJECT" ]]; then
  echo "error: project path required" >&2
  usage >&2
  exit 1
fi
if [[ ! -d "$PROJECT" ]]; then
  echo "error: project path is not a directory: $PROJECT" >&2
  exit 1
fi
PROJECT="$(cd "$PROJECT" && pwd)"

NAMES=()
if [[ -n "$SKILLS_CSV" ]]; then
  IFS=',' read -ra RAW <<< "$SKILLS_CSV"
  for s in "${RAW[@]}"; do
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    [[ -z "$s" ]] && continue
    NAMES+=("$s")
  done
fi

if [[ ${#NAMES[@]} -eq 0 ]]; then
  echo "error: pass --skills a,b,c (or --list)" >&2
  usage >&2
  exit 1
fi

in_catalog() {
  local want="$1"
  AMILLEZ_CATALOG="$CATALOG" AMILLEZ_WANT="$want" python3 -c '
import json, os, sys
cat = json.loads(os.environ["AMILLEZ_CATALOG"])
sys.exit(0 if os.environ["AMILLEZ_WANT"] in cat else 1)
'
}

resolve_source_dir() {
  local name="$1"
  local meta kind pkg_or_path ref
  meta="$(skill_meta "$name")"
  kind="$(printf '%s' "$meta" | cut -f1)"
  pkg_or_path="$(printf '%s' "$meta" | cut -f2)"
  ref="$(printf '%s' "$meta" | cut -f3)"

  if [[ "$kind" == "vendor" && -n "$pkg_or_path" ]]; then
    local v="$SKILLS_ROOT/$pkg_or_path"
    if [[ -f "$v/SKILL.md" ]]; then
      echo "$v"
      return 0
    fi
  fi

  if [[ -f "$CACHE_DIR/$name/SKILL.md" ]]; then
    echo "$CACHE_DIR/$name"
    return 0
  fi

  for base in "$HOME/.agents/skills/$name" "$HOME/.claude/skills/$name"; do
    if [[ -f "$base/SKILL.md" ]]; then
      echo "$base"
      return 0
    fi
  done

  if [[ "$kind" == "upstream" && -n "$pkg_or_path" ]]; then
    if ! command -v npx >/dev/null 2>&1; then
      echo "error: npx required to fetch upstream skill '$name' (or install device core+mobile first)" >&2
      return 1
    fi
    local spec="$pkg_or_path"
    if [[ -n "$ref" ]]; then
      spec="${pkg_or_path}#${ref}"
    fi
    echo "fetching upstream skill '$name' from $spec → cache…" >&2
    local tmp
    tmp="$(mktemp -d)"
    if ! HOME="$tmp" npx -y skills add "$spec" --skill "$name" --agent '*' -g -y --copy >/dev/null 2>&1; then
      HOME="$tmp" npx -y skills add "$spec" --skill "$name" -g -y --copy >/dev/null 2>&1 || true
    fi
    local found=""
    for cand in \
      "$tmp/.agents/skills/$name" \
      "$tmp/.claude/skills/$name"; do
      if [[ -f "$cand/SKILL.md" ]]; then
        found="$cand"
        break
      fi
    done
    if [[ -z "$found" ]]; then
      found="$(find "$tmp" -type f -name SKILL.md 2>/dev/null | while read -r f; do
        d="$(dirname "$f")"
        [[ "$(basename "$d")" == "$name" ]] && echo "$d" && break
      done | head -1)"
    fi
    if [[ -n "$found" && -f "$found/SKILL.md" ]]; then
      mkdir -p "$CACHE_DIR"
      rm -rf "$CACHE_DIR/$name"
      cp -R "$found" "$CACHE_DIR/$name"
      rm -rf "$tmp"
      echo "$CACHE_DIR/$name"
      return 0
    fi
    rm -rf "$tmp"
    echo "error: could not fetch upstream skill '$name' from $spec" >&2
    return 1
  fi

  echo "error: no source found for skill '$name' (install device core+mobile, or vendor/cache missing)" >&2
  return 1
}

copy_one() {
  local name="$1"
  local src="$2"
  local dest="$3"
  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ "$FORCE" -eq 1 ]]; then
      rm -rf "$dest"
    else
      if [[ -d "$dest" ]] && diff -rq "$src" "$dest" >/dev/null 2>&1; then
        echo "ok (unchanged): $dest"
        return 0
      fi
      echo "error: refuses to clobber $dest (pass --force to replace)" >&2
      return 1
    fi
  fi
  mkdir -p "$(dirname "$dest")"
  cp -R "$src" "$dest"
  if [[ -L "$dest" ]]; then
    echo "error: destination unexpectedly a symlink: $dest" >&2
    return 1
  fi
  echo "copied: $dest"
}

errors=0
echo "Project:     $PROJECT"
echo "Skills root: $SKILLS_ROOT"
echo "Skills:      ${NAMES[*]}"
echo

for name in "${NAMES[@]}"; do
  if [[ "$name" == argent || "$name" == argent-* ]]; then
    echo "error: Argent stays on device (part of mobile host install) — not a project mirror" >&2
    errors=$((errors + 1))
    continue
  fi
  if ! in_catalog "$name"; then
    echo "error: '$name' is not in the mirrorable catalog (see --list)" >&2
    errors=$((errors + 1))
    continue
  fi
  src=""
  if ! src="$(resolve_source_dir "$name")"; then
    errors=$((errors + 1))
    continue
  fi
  for rel in .claude/skills .agents/skills; do
    if ! copy_one "$name" "$src" "$PROJECT/$rel/$name"; then
      errors=$((errors + 1))
    fi
  done
done

if [[ "$errors" -gt 0 ]]; then
  echo >&2
  echo "error: $errors failure(s). Fix above; re-run with --force to replace conflicts." >&2
  exit 1
fi

echo
echo "Done. Optionally commit <project>/.claude/skills and .agents/skills so teammates share the copies."
echo "Device default remains core+mobile at ~/.claude + ~/.agents (ensure-install.sh)."
