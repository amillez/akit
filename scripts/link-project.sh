#!/usr/bin/env bash
# OPTIONAL / OFF by default: symlink amillez first-party skills into a project.
# The amillez plugin installs at **user root** via install.sh / ensure-install.sh.
# Project trees should only hold project-specific skills (e.g. verify-*).
# Pass --project-local to enable this legacy convenience helper.
# Never touches .cursor/skills.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: ./scripts/link-project.sh --project-local [/path/to/project] [--force] [--skills-root /path/to/agent-skills] [--groups core|mobile|core,mobile]

**Default: OFF.** Amillez first-party skills install at user root
(~/.claude/skills, ~/.agents/skills) via ./scripts/install.sh.
Do **not** use this for normal ensure/coding gates.

Optional convenience only: creates per-skill symlinks so a project sees amillez skills in:
  .claude/skills/<name>  →  <skills-root>/skills/<name>
  .agents/skills/<name>  →  same

Requires explicit --project-local. Does NOT create .cursor/skills links.

Prefer: ./scripts/ensure-install.sh  (host install) or ./scripts/update-install.sh
USAGE
}

FORCE=0
PROJECT=""
SKILLS_ROOT_OVERRIDE=""
GROUPS_ARG=""
PROJECT_LOCAL=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --project-local)
      PROJECT_LOCAL=1
      shift
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

if [[ "$PROJECT_LOCAL" -ne 1 ]]; then
  echo "error: link-project.sh is OFF by default (user-root install model)." >&2
  echo "Amillez plugin → ~/.claude/skills + ~/.agents/skills via ./scripts/install.sh / ensure-install.sh." >&2
  echo "Project trees keep only in-repo skills (e.g. verify-*). Pass --project-local only for optional convenience." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

resolve_skills_root() {
  if [[ -n "$SKILLS_ROOT_OVERRIDE" ]]; then
    echo "$SKILLS_ROOT_OVERRIDE"
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
  echo "Clone amillez/agent-skills (e.g. ~/agent-work/agent-skills) or pass --skills-root." >&2
  exit 1
fi

PROJECT="${PROJECT:-$(pwd)}"
if [[ ! -d "$PROJECT" ]]; then
  echo "error: project path is not a directory: $PROJECT" >&2
  exit 1
fi
PROJECT="$(cd "$PROJECT" && pwd)"

# Resolve groups: core always; default core+mobile
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

# Map skill id → group from manifest.json (default core if missing)
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

link_one() {
  local dest="$1"
  local target="$2"
  local dest_dir
  dest_dir="$(dirname "$dest")"
  mkdir -p "$dest_dir"

  if [[ -L "$dest" ]]; then
    local current
    current="$(readlink "$dest")"
    if [[ "$current" == "$target" ]]; then
      echo "ok (exists): $dest"
      return 0
    fi
    if [[ "$FORCE" -eq 1 ]]; then
      rm -f "$dest"
    else
      echo "error: $dest is a symlink to $current (want $target); pass --force to replace" >&2
      return 1
    fi
  elif [[ -e "$dest" ]]; then
    if [[ "$FORCE" -eq 1 ]]; then
      rm -rf "$dest"
    else
      echo "error: $dest exists and is not a symlink to $target; pass --force to replace" >&2
      return 1
    fi
  fi

  ln -s "$target" "$dest"
  echo "linked: $dest -> $target"
}

echo "Project:     $PROJECT"
echo "Skills root: $SKILLS_ROOT"
echo "Groups:      core$([ "$WANT_MOBILE" -eq 1 ] && echo '+mobile' || true) (core always)"
echo "Skills:      ${SKILL_NAMES[*]}"
echo "warning: project-local amillez links are optional; prefer user-root install" >&2
echo

errors=0
for name in "${SKILL_NAMES[@]}"; do
  target="$SKILLS_DIR/$name"
  for rel in .claude/skills .agents/skills; do
    if ! link_one "$PROJECT/$rel/$name" "$target"; then
      errors=$((errors + 1))
    fi
  done
done

if [[ "$errors" -gt 0 ]]; then
  echo >&2
  echo "error: $errors link(s) failed (see above). Re-run with --force to replace conflicts." >&2
  exit 1
fi

echo
echo "Done. Optional project-local links created (amillez plugin itself remains user-root)."
