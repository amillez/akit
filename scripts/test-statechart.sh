#!/usr/bin/env bash
# Run skills/statechart/scripts/statechart on real TLC for the behavior our copy changes from upstream.
set -uo pipefail

usage() {
  cat <<'USAGE'
Usage: [TLA2TOOLS=/path/to/tla2tools.jar] ./scripts/test-statechart.sh [--keep]

Runs the statechart launcher with real TLC in a temporary folder. It checks that a
model with many regions finishes and falls back to parent states, and that relative
TLA2TOOLS and JAVA paths work. It needs java on PATH, and Node, Bun, or Deno.
Without TLA2TOOLS, it downloads the pinned TLC jar and checks its SHA-256.
Prints PASS or FAIL per check and exits 1 on any failure.

  --keep   Keep the temporary folder and print its path
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
CLI="$REPO/skills/statechart/scripts/statechart"
JAR_URL="https://github.com/tlaplus/tlaplus/releases/download/v1.7.4/tla2tools.jar"
JAR_SHA="936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88"
FALLBACK="So the chart draws parent states in place of regions."

command -v java >/dev/null || { echo "error: java is not on PATH" >&2; exit 1; }
# macOS /usr/bin/java dispatches on its own name, so a link to it under another name cannot run.
REAL_JAVA="$(java -XshowSettings:properties -version 2>&1 | sed -n 's/^ *java\.home = //p')/bin/java"
[[ -x "$REAL_JAVA" ]] || { echo "error: cannot find the JVM binary, got $REAL_JAVA" >&2; exit 1; }
BASE="$(cd "$(mktemp -d)" && pwd -P)"
if [[ "$KEEP" -eq 1 ]]; then
  echo "sandbox: $BASE"
else
  trap 'rm -rf "$BASE"' EXIT
fi

JAR="$BASE/tla2tools.jar"
if [[ -n "${TLA2TOOLS:-}" ]]; then
  cp "$TLA2TOOLS" "$JAR" || exit 1
else
  curl -fsSL -o "$JAR" "$JAR_URL" || { echo "error: cannot download $JAR_URL" >&2; exit 1; }
fi
if [[ "$(shasum -a 256 "$JAR" | cut -d' ' -f1)" != "$JAR_SHA" ]]; then
  echo "error: tla2tools.jar does not match SHA-256 $JAR_SHA" >&2
  exit 1
fi
unset TLA2TOOLS JAVA

failures=0
check() {
  if eval "$2"; then
    echo "PASS $1"
  else
    echo "FAIL $1"
    tail -n 5 "$BASE/last.log" | sed 's/^/  /' | cut -c1-200
    failures=$((failures + 1))
  fi
}

# Sets $code and $out. The launcher writes only to a new folder, so each run gets its own.
runs=0
run() {
  local dir="$1"
  shift
  runs=$((runs + 1))
  out="$BASE/out-$runs"
  (cd "$dir" && "$CLI" "$@" --out "$out") > "$BASE/last.log" 2>&1
  code=$?
}
fell_back() { grep -qsF "$FALLBACK" "$out/report.md" && [[ -f "$out/chart.mmd" ]] && ! grep -qE '^ *--$' "$out/chart.mmd"; }
kept_regions() { [[ -f "$out/report.md" ]] && ! grep -qF "$FALLBACK" "$out/report.md" && grep -qE '^ *--$' "$out/chart.mmd"; }
broke_safe() { [[ "$code" -eq 1 ]] && grep -qs 'Safe' "$out/report.md"; }

regions_view() {
  cat > "$1" <<VIEW
export const state = (v) =>
  Object.fromEntries(Array.from({ length: $2 }, (_, i) => [\`Region\${i}\`, $3]));
VIEW
}

MODELS="$BASE/models"
mkdir -p "$MODELS"
cat > "$MODELS/Correlated.tla" <<'TLA'
---- MODULE Correlated ----
VARIABLE x
Init == x \in {0, 1}
Next == UNCHANGED x
Safe == x \in {0, 1}
====
TLA
cat > "$MODELS/Fork.tla" <<'TLA'
---- MODULE Fork ----
VARIABLE x
Init == x = 0
Go == x = 0 /\ x' \in {1, 2}
Rest == x # 0 /\ UNCHANGED x
Next == Go \/ Rest
Safe == x \in {0, 1, 2}
====
TLA
cat > "$MODELS/Bits.tla" <<'TLA'
---- MODULE Bits ----
EXTENDS Naturals
VARIABLE bits
Init == bits \in [1..5 -> {0, 1}]
Next == \E i \in 1..5 : bits' = [bits EXCEPT ![i] = 1 - @]
Safe == DOMAIN bits = 1..5
====
TLA
cat > "$MODELS/Counter.tla" <<'TLA'
---- MODULE Counter ----
EXTENDS Naturals
VARIABLE x
Init == x = 0
Inc == x < 2 /\ x' = x + 1
Done == x = 2 /\ UNCHANGED x
Next == Inc \/ Done
Safe == x < 2
====
TLA
for m in Correlated Fork Bits Counter; do
  printf 'INIT Init\nNEXT Next\nINVARIANT Safe\n' > "$MODELS/$m.cfg"
done
regions_view "$MODELS/correlated-32.mjs" 32 'v.x === 0 ? "Offline" : "Online"'
regions_view "$MODELS/correlated-5.mjs" 5 'v.x === 0 ? "Offline" : "Online"'
regions_view "$MODELS/fork-32.mjs" 32 '["Idle", "Left", "Right"][v.x]'
regions_view "$MODELS/fork-5.mjs" 5 '["Idle", "Left", "Right"][v.x]'
regions_view "$MODELS/bits-5.mjs" 5 'v.bits[i + 1] ? "On" : "Off"'

# A low heap limit makes the exponential failure fast. It is not the cause.
export NODE_OPTIONS=--max-old-space-size=64
export JAVA=java TLA2TOOLS="$JAR"

run "$MODELS" Correlated.tla --view correlated-5.mjs
check "5 regions, correlated starts: exit 0" '[[ "$code" -eq 0 ]]'
check "5 regions, correlated starts: falls back to parent states" 'fell_back'
run "$MODELS" Correlated.tla --view correlated-32.mjs
check "32 regions, correlated starts: exit 0" '[[ "$code" -eq 0 ]]'
check "32 regions, correlated starts: falls back to parent states" 'fell_back'

run "$MODELS" Fork.tla --view fork-5.mjs
check "5 regions, one step with two targets: exit 0" '[[ "$code" -eq 0 ]]'
check "5 regions, one step with two targets: falls back to parent states" 'fell_back'
run "$MODELS" Fork.tla --view fork-32.mjs
check "32 regions, one step with two targets: exit 0" '[[ "$code" -eq 0 ]]'
check "32 regions, one step with two targets: falls back to parent states" 'fell_back'

run "$MODELS" Bits.tla --view bits-5.mjs
check "5 independent regions: exit 0" '[[ "$code" -eq 0 ]]'
check "5 independent regions: keeps regions" 'kept_regions'

unset NODE_OPTIONS

run "$MODELS" Counter.tla
check "absolute TLA2TOOLS: Safe breaks" 'broke_safe'

REL="$BASE/rel"
mkdir -p "$REL/lib"
cp "$MODELS"/Counter.* "$REL"
ln -s "$JAR" "$REL/tla2tools.jar"
ln -s "$REAL_JAVA" "$REL/java-local"
ln -s "$REAL_JAVA" "$REL/lib/java-local"

TLA2TOOLS=tla2tools.jar JAVA=java run "$REL" Counter.tla
check "TLA2TOOLS=tla2tools.jar JAVA=java: Safe breaks" 'broke_safe'
TLA2TOOLS="$JAR" JAVA=./java-local run "$REL" Counter.tla
check "JAVA=./java-local: Safe breaks" 'broke_safe'
TLA2TOOLS=../rel/tla2tools.jar JAVA=lib/java-local run "$REL" Counter.tla
check "TLA2TOOLS=../rel/tla2tools.jar JAVA=lib/java-local: Safe breaks" 'broke_safe'

unset TLA2TOOLS JAVA
mkdir -p "$BASE/mise-bin" "$BASE/mise-jar"
ln -s "$JAR" "$BASE/mise-jar/tla2tools.jar"
cat > "$BASE/mise-bin/mise" <<MISE
#!/bin/sh
case "\$1" in
  where) echo "$BASE/mise-jar" ;;
  which) echo "\$MISE_JAVA" ;;
esac
MISE
chmod +x "$BASE/mise-bin/mise"

PATH="$BASE/mise-bin:$PATH" MISE_JAVA="$REAL_JAVA" run "$REL" Counter.tla
check "mise with no JAVA: Safe breaks" 'broke_safe'
PATH="$BASE/mise-bin:$PATH" MISE_JAVA=/nonexistent/java JAVA=./java-local run "$REL" Counter.tla
check "mise with JAVA=./java-local: Safe breaks" 'broke_safe'
PATH="$BASE/mise-bin:$PATH" MISE_JAVA=/nonexistent/java JAVA=java run "$REL" Counter.tla
check "mise with JAVA=java: Safe breaks" 'broke_safe'

if [[ "$failures" -gt 0 ]]; then
  echo "$failures check(s) failed"
  exit 1
fi
echo "all checks passed"
