#!/usr/bin/env bash
# Copy curated project skills into a repo's .claude/skills and .agents/skills (committed, shared).
# Prefer real file copies (not symlinks to a personal checkout) so teammates get the skill bodies.
# Idempotent; refuses to clobber existing dirs/files without --force.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ./scripts/add-project-skills.sh <project> --skills a,b,c [--force] [--skills-root /path/to/agent-skills]
       ./scripts/add-project-skills.sh <project> --from-group project [--force]
       ./scripts/add-project-skills.sh <project> --list

Copy selected **project** skills into BOTH:
  <project>/.claude/skills/<name>/
  <project>/.agents/skills/<name>/

Ready to commit. Prefer copies from this repo's vendor/ + upstream cache (not
symlinks to a personal agent-skills checkout).

Options:
  --skills a,b,c     Comma-separated skill names from the project catalog
  --from-group project
                     Add the full projectSkillCatalog (usually too broad —
                     prefer --skills or suggest-project-skills.sh)
  --force            Replace existing skill dirs (otherwise refuse to clobber)
  --skills-root      agent-skills checkout (default: this repo / AMILLEZ_SKILLS_ROOT)
  --list             Print the project skill catalog and exit

Device core/argent stay at ~/.claude + ~/.agents via install.sh / ensure-install.sh.
Argent is NOT a project skill — use --groups core,argent on the host.
USAGE
}

PROJECT=""
SKILLS_CSV=""
FROM_GROUP=""
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
    --from-group)
      FROM_GROUP="${2:-}"
      if [[ -z "$FROM_GROUP" ]]; then
        echo "error: --from-group requires a name (project)" >&2
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

catalog_json() {
  AMILLEZ_MANIFEST="$MANIFEST" python3 -c '
import json, os
m = json.load(open(os.environ["AMILLEZ_MANIFEST"]))
cat = m.get("projectSkillCatalog") or []
print(json.dumps(cat))
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
    if e.get("target") != "project" and e.get("group") != "project":
        continue
    pkg = e.get("package") or ""
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
  echo "Project skill catalog (curate — do not dump unused):"
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
if [[ -n "$FROM_GROUP" ]]; then
  g="$(printf '%s' "$FROM_GROUP" | tr '[:upper:]' '[:lower:]')"
  if [[ "$g" != "project" ]]; then
    echo "error: --from-group only supports 'project' (got '$FROM_GROUP')" >&2
    echo "hint: Argent is device-only — ./scripts/install.sh --groups core,argent" >&2
    exit 1
  fi
  echo "warning: --from-group project copies the full catalog; prefer curated --skills" >&2
  while IFS= read -r line; do
    [[ -n "$line" ]] && NAMES+=("$line")
  done < <(AMILLEZ_CATALOG="$CATALOG" python3 -c 'import json,os; print("\n".join(json.loads(os.environ["AMILLEZ_CATALOG"])))')
fi
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
  echo "error: pass --skills a,b,c or --from-group project (or --list)" >&2
  usage >&2
  exit 1
fi

# Validate against catalog
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

  # 1) vendor path inside agent-skills
  if [[ "$kind" == "vendor" && -n "$pkg_or_path" ]]; then
    local v="$SKILLS_ROOT/$pkg_or_path"
    if [[ -f "$v/SKILL.md" ]]; then
      echo "$v"
      return 0
    fi
  fi

  # 2) upstream cache in agent-skills
  if [[ -f "$CACHE_DIR/$name/SKILL.md" ]]; then
    echo "$CACHE_DIR/$name"
    return 0
  fi

  # 3) already on device (copy, do not symlink)
  for base in "$HOME/.agents/skills/$name" "$HOME/.claude/skills/$name"; do
    if [[ -f "$base/SKILL.md" ]]; then
      echo "$base"
      return 0
    fi
  done

  # 4) fetch upstream into cache via isolated HOME + npx skills
  if [[ "$kind" == "upstream" && -n "$pkg_or_path" ]]; then
    if ! command -v npx >/dev/null 2>&1; then
      echo "error: npx required to fetch upstream skill '$name'" >&2
      return 1
    fi
    local spec="$pkg_or_path"
    if [[ -n "$ref" ]]; then
      spec="${pkg_or_path}#${ref}"
    fi
    echo "fetching upstream skill '$name' from $spec → cache…" >&2
    local tmp
    tmp="$(mktemp -d)"
    # Isolate install into tmp home so we can copy real files into cache
    if ! HOME="$tmp" npx -y skills add "$spec" --skill "$name" --agent '*' -g -y --copy >/dev/null 2>&1; then
      # Some CLIs ignore --agent '*'; try without
      HOME="$tmp" npx -y skills add "$spec" --skill "$name" -g -y --copy >/dev/null 2>&1 || true
    fi
    local found=""
    for cand in \
      "$tmp/.agents/skills/$name" \
      "$tmp/.claude/skills/$name" \
      "$tmp/.codex/skills/$name"; do
      if [[ -f "$cand/SKILL.md" ]]; then
        found="$cand"
        break
      fi
    done
    # deepest search
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

  echo "error: no source found for skill '$name' (not in vendor/cache/device)" >&2
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
      # Idempotent: identical tree → ok; else refuse
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
  # Ensure we did not leave a symlink
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
    echo "error: Argent stays device/host — ./scripts/install.sh --groups core,argent" >&2
    errors=$((errors + 1))
    continue
  fi
  if ! in_catalog "$name"; then
    echo "error: '$name' is not in the project skill catalog (see --list)" >&2
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
echo "Done. Commit <project>/.claude/skills and .agents/skills so teammates share the copies."
echo "Tip: ./scripts/suggest-project-skills.sh $PROJECT"
