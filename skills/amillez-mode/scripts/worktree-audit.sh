#!/usr/bin/env bash
# Read-only audit of git worktrees and leftover runtime state. Classifies each
# linked worktree by size, age, merge state, uncommitted work, remote and PR
# state, and last local activity, then suggests a bucket. Never deletes,
# never writes. Deletion stays a gated step in playbooks/worktree-cleanup.md.
set -u
# Keep git status from opportunistically rewriting the index (read-only, and
# the index mtime stays a real activity signal).
export GIT_OPTIONAL_LOCKS=0

usage() {
	cat <<'USAGE'
Usage: worktree-audit.sh [--root DIR] [--fetch] [--no-runtime] [REPO ...]

Audits every linked worktree of each REPO. With no REPO: the current repo when
run inside one, otherwise every git repo found one or two levels under the root.

  --root DIR     Root to scan when no REPO is given.
                 Default: $AGENT_WORK_ROOT, else ~/agent-work.
  --fetch        Run `git fetch origin` first so the MERGED column is fresh.
                 Off by default (fetch updates remote-tracking refs).
  --no-runtime   Skip the runtime section (Metro ports, booted simulators,
                 running emulators).
  -h, --help     Show this help.

Buckets: hold-wip, hold-open-pr, verify-recent, safe, review, prunable. A bucket is
advice, not permission.
USAGE
}

root="${AGENT_WORK_ROOT:-$HOME/agent-work}"
fetch=0
runtime=1
repos=()
while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help) usage; exit 0 ;;
		--root) root="${2:?--root needs a directory}"; shift 2 ;;
		--fetch) fetch=1; shift ;;
		--no-runtime) runtime=0; shift ;;
		-*) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
		*) repos+=("$1"); shift ;;
	esac
done

now=$(date +%s)

if stat --version >/dev/null 2>&1; then
	mtime() { stat -c '%Y' "$1" 2>/dev/null || echo 0; }
	ymd() { date -d "@$1" '+%Y-%m-%d' 2>/dev/null || echo "?"; }
else
	mtime() { stat -f '%m' "$1" 2>/dev/null || echo 0; }
	ymd() { date -r "$1" '+%Y-%m-%d' 2>/dev/null || echo "?"; }
fi

if [ ${#repos[@]} -eq 0 ]; then
	if top=$(git rev-parse --show-toplevel 2>/dev/null); then
		repos=("$top")
	elif [ -d "$root" ]; then
		while IFS= read -r d; do repos+=("$d"); done < <(
			find "$root" -mindepth 1 -maxdepth 2 -type d 2>/dev/null | sort | while read -r d; do
				[ -e "$d/.git" ] && echo "$d"
			done)
	fi
fi
if [ ${#repos[@]} -eq 0 ]; then
	echo "no git repos found (pass a repo path or --root DIR)" >&2
	exit 1
fi

seen=""
printf "SIZE\tAGE\tMERGED\tDIRTY\tREMOTE\tPR\tLAST_TOUCH\tBUCKET\tWORKTREE\n"
for repo in "${repos[@]}"; do
	common=$(git -C "$repo" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || {
		echo "skip (not a git repo): $repo" >&2; continue; }
	case " $seen " in *" $common "*) continue ;; esac
	seen="$seen $common"

	main_wt=$(git -C "$repo" worktree list --porcelain | awk '/^worktree /{print $2; exit}')

	if [ "$fetch" -eq 1 ]; then
		git -C "$main_wt" fetch origin --quiet 2>/dev/null || echo "warn: fetch failed for $main_wt" >&2
	fi
	base=$(git -C "$main_wt" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
	[ -z "$base" ] && base=origin/main

	prs=$(mktemp)
	(cd "$main_wt" && gh pr list --state all --limit 1000 \
		--json number,state,headRefName 2>/dev/null) > "$prs" || echo "[]" > "$prs"
	[ -s "$prs" ] || echo "[]" > "$prs"

	git -C "$repo" worktree list --porcelain | awk '/^worktree /{print $2}' | while read -r wt; do
		[ "$wt" = "$main_wt" ] && continue
		[ -d "$wt" ] || { printf -- "-\t-\t-\t-\t-\t-\t-\tprunable\t%s\n" "$wt"; continue; }

		size=$(du -sh "$wt" 2>/dev/null | awk '{print $1}')
		head=$(git -C "$wt" rev-parse HEAD 2>/dev/null)
		head_ts=$(git -C "$wt" log -1 --format='%ct' HEAD 2>/dev/null || echo 0)
		age=$([ "$head_ts" -gt 0 ] 2>/dev/null && echo "$(( (now - head_ts) / 86400 ))d" || echo "?")

		# Squash merges are not ancestors of the base, so PR state is the stronger signal.
		git -C "$wt" merge-base --is-ancestor "$head" "$base" 2>/dev/null && merged=YES || merged=no

		porcelain=$(git -C "$wt" status --porcelain 2>/dev/null)
		if [ -z "$porcelain" ]; then dirty=clean
		elif printf '%s\n' "$porcelain" | grep -qv '^??'; then
			dirty="wip:$(printf '%s\n' "$porcelain" | grep -cv '^??')"
		else dirty="scratch:$(printf '%s\n' "$porcelain" | grep -c '^??')"; fi

		branch=$(git -C "$wt" symbolic-ref --quiet --short HEAD 2>/dev/null || echo "")
		if [ -z "$branch" ]; then remote=detached
		elif git -C "$wt" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
			[ "$(git -C "$wt" rev-parse "origin/$branch" 2>/dev/null)" = "$head" ] \
				&& remote=pushed \
				|| remote="ahead$(git -C "$wt" rev-list --count "origin/$branch..HEAD" 2>/dev/null)"
		else remote=no-remote; fi

		pr="-"
		if [ -n "$branch" ] && command -v jq >/dev/null 2>&1; then
			pr=$(jq -r --arg b "$branch" \
				'.[] | select(.headRefName==$b) | "#\(.number)/\(.state)"' "$prs" 2>/dev/null | head -1)
			[ -z "$pr" ] && pr="-"
		fi

		# Last local activity: the newer of the worktree index and HEAD commit.
		gitdir=$(git -C "$wt" rev-parse --absolute-git-dir 2>/dev/null)
		touch_ts=$(mtime "$gitdir/index")
		[ "$head_ts" -gt "$touch_ts" ] 2>/dev/null && touch_ts=$head_ts
		last=$([ "$touch_ts" -gt 0 ] 2>/dev/null && ymd "$touch_ts" || echo "-")
		recent=$([ "$touch_ts" -gt 0 ] 2>/dev/null && [ $(( (now - touch_ts) / 86400 )) -le 4 ] && echo yes || echo no)

		case "$dirty" in wip:*) bucket=hold-wip ;; *)
			case "$pr" in *OPEN*) bucket=hold-open-pr ;; *)
				if [ "$recent" = yes ]; then bucket=verify-recent
				elif [ "$merged" = YES ] || [ "$pr" != "-" ]; then bucket=safe
				else bucket=review; fi ;;
			esac ;;
		esac

		printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
			"$size" "$age" "$merged" "$dirty" "$remote" "$pr" "$last" "$bucket" "$wt"
	done | sort -t$'\t' -k1,1 -rh

	rm -f "$prs"
done

[ "$runtime" -eq 1 ] || exit 0

echo
echo "RUNTIME"
if command -v lsof >/dev/null 2>&1; then
	for port in 8081 8090 19000 19001; do
		l=$(lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null | awk 'NR>1{print $1"/"$2}' | sort -u | tr '\n' ' ')
		echo "port $port: ${l:-free}"
	done
else
	echo "ports: lsof not found, skipped"
fi
pgrep -fl 'expo/bin/cli|expo (start|run)' 2>/dev/null | sed 's/^/expo: /' || true
if command -v xcrun >/dev/null 2>&1; then
	xcrun simctl list devices booted 2>/dev/null | grep -E '\(Booted\)' | sed 's/^ */booted simulator: /' || true
fi
if command -v adb >/dev/null 2>&1; then
	adb devices 2>/dev/null | awk 'NR>1 && $2=="device"{print "running emulator/device: "$1}'
fi
exit 0
