#!/usr/bin/env bash
# Idempotently upsert a marked amillez-plugin block into <project>/.gitignore
# so stamps, rules, and per-skill symlinks stay machine-local (not committed).
# Never ignores all of .claude/ or teammate-owned files outside the block.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ./scripts/ensure-gitignore.sh <project-path> [--skills-root /path/to/agent-skills] [--groups core|mobile|core,mobile]

Upserts (replaces) a marked block in <project>/.gitignore:

  # >>> amillez-plugin (local only — do not commit)
  .amillez-plugin
  .amillez-plugin.json
  .claude/rules/amillez-models.md
  .agents/rules/amillez-models.md
  # per-skill links (both trees):
  .claude/skills/<each linked skill>
  .agents/skills/<each linked skill>
  # <<< amillez-plugin

Skill list follows --groups (same as link-project.sh; default core,mobile; core always).
Creates .gitignore if missing. Warns (does not git rm) if a path is already tracked.
USAGE
}

PROJECT=""
SKILLS_ROOT_OVERRIDE=""
GROUPS_ARG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --skills-root)
      SKILLS_ROOT_OVERRIDE="${2:-}"
      if [[ -z "$SKILLS_ROOT_OVERRIDE" ]]; then
        echo "error: --skills-root requires a path" >&2
        exit 1
      fi
      shift 2
      ;;
    --groups)
      GROUPS_ARG="${2:-}"
      if [[ -z "$GROUPS_ARG" ]]; then
        echo "error: --groups requires a value (e.g. core, core,mobile, mobile)" >&2
        exit 1
      fi
      shift 2
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

if [[ -z "$PROJECT" ]]; then
  echo "error: project path is required" >&2
  usage >&2
  exit 1
fi

if [[ ! -d "$PROJECT" ]]; then
  echo "error: project path is not a directory: $PROJECT" >&2
  exit 1
fi
PROJECT="$(cd "$PROJECT" && pwd)"

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
SKILLS_DIR="$SKILLS_ROOT/skills"

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "error: skills directory not found at $SKILLS_DIR" >&2
  exit 1
fi

# Resolve groups: core always; default core+mobile (same as link-project.sh)
WANT_MOBILE=0
if [[ -z "$GROUPS_ARG" ]]; then
  WANT_MOBILE=1
else
  IFS=',' read -ra RAW_GROUPS <<< "$GROUPS_ARG"
  saw_any=0
  for g in "${RAW_GROUPS[@]}"; do
    g="${g#"${g%%[![:space:]]*}"}"
    g="${g%"${g##*[![:space:]]}"}"
    g="$(printf '%s' "$g" | tr '[:upper:]' '[:lower:]')"
    case "$g" in
      core) saw_any=1 ;;
      mobile) WANT_MOBILE=1; saw_any=1 ;;
      "") ;;
      *)
        echo "error: unknown group '$g' (valid: core, mobile)" >&2
        exit 1
        ;;
    esac
  done
  if [[ "$saw_any" -eq 0 ]]; then
    echo "error: --groups produced no valid groups" >&2
    exit 1
  fi
fi

skill_group() {
  local id="$1"
  local manifest="$SKILLS_ROOT/manifest.json"
  if [[ -f "$manifest" ]] && command -v python3 >/dev/null 2>&1; then
    AMILLEZ_MANIFEST="$manifest" AMILLEZ_SKILL_ID="$id" python3 -c '
import json, os
m = json.load(open(os.environ["AMILLEZ_MANIFEST"]))
sid = os.environ["AMILLEZ_SKILL_ID"]
for section in ("firstParty", "upstream", "vendor"):
    for e in m.get(section, []):
        if e.get("id") == sid:
            print(e.get("group", "core"))
            raise SystemExit
        for s in e.get("skills") or []:
            if s == sid:
                print(e.get("group", "core"))
                raise SystemExit
print("core")
'
    return
  fi
  echo "core"
}

SKILL_NAMES=()
for d in "$SKILLS_DIR"/*/; do
  [[ -d "$d" ]] || continue
  name="$(basename "$d")"
  if [[ -f "$d/SKILL.md" ]]; then
    grp="$(skill_group "$name")"
    if [[ "$grp" == "core" ]]; then
      SKILL_NAMES+=("$name")
    elif [[ "$grp" == "mobile" && "$WANT_MOBILE" -eq 1 ]]; then
      SKILL_NAMES+=("$name")
    fi
  fi
done

if [[ ${#SKILL_NAMES[@]} -eq 0 ]]; then
  echo "error: no skills with SKILL.md under $SKILLS_DIR" >&2
  exit 1
fi

# Stable order for readable diffs
IFS=$'\n' SKILL_NAMES=($(printf '%s\n' "${SKILL_NAMES[@]}" | sort -u))
unset IFS

START_PREFIX='# >>> amillez-plugin'
END_MARK='# <<< amillez-plugin'

build_block() {
  printf '%s\n' '# >>> amillez-plugin (local only — do not commit)'
  printf '%s\n' '.amillez-plugin'
  printf '%s\n' '.amillez-plugin.json'
  printf '%s\n' '.claude/rules/amillez-models.md'
  printf '%s\n' '.agents/rules/amillez-models.md'
  printf '%s\n' '# per-skill links (both trees):'
  local name
  for name in "${SKILL_NAMES[@]}"; do
    printf '%s\n' ".claude/skills/$name"
    printf '%s\n' ".agents/skills/$name"
  done
  printf '%s\n' '# <<< amillez-plugin'
}

IGNORE_PATHS=(
  .amillez-plugin
  .amillez-plugin.json
  .claude/rules/amillez-models.md
  .agents/rules/amillez-models.md
)
for name in "${SKILL_NAMES[@]}"; do
  IGNORE_PATHS+=(".claude/skills/$name" ".agents/skills/$name")
done

warn_tracked() {
  local path="$1"
  if [[ ! -d "$PROJECT/.git" ]] && ! git -C "$PROJECT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return 0
  fi
  if git -C "$PROJECT" ls-files --error-unmatch -- "$path" >/dev/null 2>&1; then
    echo "warning: $path is tracked — run git rm -r --cached $path once" >&2
  fi
}

BLOCK="$(build_block)"
GITIGNORE="$PROJECT/.gitignore"

if [[ ! -f "$GITIGNORE" ]]; then
  printf '%s\n' "$BLOCK" > "$GITIGNORE"
  echo "created: $GITIGNORE (amillez-plugin block)"
else
  # Replace entire marked block, or append if markers missing.
  if grep -qF "$START_PREFIX" "$GITIGNORE" && grep -qF "$END_MARK" "$GITIGNORE"; then
    TMP="$(mktemp)"
    AMILLEZ_BLOCK="$BLOCK" AMILLEZ_START="$START_PREFIX" AMILLEZ_END="$END_MARK" \
      python3 - "$GITIGNORE" "$TMP" <<'PY'
import os, sys
src, dst = sys.argv[1], sys.argv[2]
block = os.environ["AMILLEZ_BLOCK"]
start = os.environ["AMILLEZ_START"]
end = os.environ["AMILLEZ_END"]
# Ensure block ends with single newline for clean join
if not block.endswith("\n"):
    block += "\n"
lines = open(src, encoding="utf-8").read().splitlines(keepends=True)
out = []
i = 0
replaced = False
while i < len(lines):
    line = lines[i]
    if line.startswith(start) or line.rstrip("\n") == start:
        out.append(block)
        replaced = True
        i += 1
        while i < len(lines):
            if lines[i].startswith(end) or lines[i].rstrip("\n") == end:
                i += 1
                break
            i += 1
        continue
    out.append(line)
    i += 1
if not replaced:
    if out and not out[-1].endswith("\n"):
        out[-1] = out[-1] + "\n"
    if out and out[-1].strip() != "":
        out.append("\n")
    out.append(block)
open(dst, "w", encoding="utf-8").writelines(out)
PY
    mv "$TMP" "$GITIGNORE"
    echo "updated: $GITIGNORE (amillez-plugin block)"
  else
    # Append with a blank line separator when file is non-empty
    if [[ -s "$GITIGNORE" ]]; then
      # Ensure trailing newline before blank line + block
      if [[ -n "$(tail -c 1 "$GITIGNORE" 2>/dev/null || true)" ]]; then
        printf '\n' >> "$GITIGNORE"
      fi
      printf '\n%s\n' "$BLOCK" >> "$GITIGNORE"
    else
      printf '%s\n' "$BLOCK" > "$GITIGNORE"
    fi
    echo "appended: $GITIGNORE (amillez-plugin block)"
  fi
fi

for p in "${IGNORE_PATHS[@]}"; do
  warn_tracked "$p"
done

echo "amillez-plugin gitignore: ${#SKILL_NAMES[@]} skill(s) ignored (groups: core$([ "$WANT_MOBILE" -eq 1 ] && echo '+mobile' || true))"
