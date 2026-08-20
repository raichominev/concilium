#!/usr/bin/env bash
# concilium-forge.sh — run one FORGE round on one seat.
#
# The forge is the concilium's generative mode: seats produce ORIGINAL ideas against an open
# question, read each other's ideas from a shared register, and BUILD on them. Nobody judges
# anybody. There is no verdict, no five blocks and no ratification — that is review mode
# (concilium-review*.sh). See references/forge-mode.md before using this.
#
# Usage:
#   ./concilium-forge.sh <seat> <round> --brief <file> [--register <file>] [--out <dir>]
#
#   seat     codex | cursor | kimi        (add a seat by extending the case block below)
#   round    an integer; round 1 usually runs without a register, later rounds with one
#   --brief    the question + inventory + already-tried list (references/forge-brief-template.md)
#   --register the curated shared register; omitted on round 1
#   --out      output directory (default: ./forge-out)
#
# Env passthrough: MODEL, MECHANICAL, REPO_DIR and the seat wrappers' own variables.
#
# Cost: one model call per seat per round. A 4-seat 2-round forge is 8 calls — cheaper than one
# review loop, because nothing here re-runs probes.

set -euo pipefail

SEAT="${1:-}"; ROUND="${2:-}"; shift 2 2>/dev/null || true
[ -n "$SEAT" ] && [ -n "$ROUND" ] || {
  echo "usage: $0 <seat: codex|cursor|kimi> <round> --brief <file> [--register <file>] [--out <dir>]" >&2
  exit 2; }

BRIEF=""; REGISTER=""; OUT="./forge-out"
while [ $# -gt 0 ]; do
  case "$1" in
    --brief)    BRIEF="$2"; shift 2 ;;
    --register) REGISTER="$2"; shift 2 ;;
    --out)      OUT="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
[ -f "$BRIEF" ] || { echo "brief not found: $BRIEF" >&2; exit 3; }

HERE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$OUT"

PROMPT="$(cat "$BRIEF")"

if [ -n "$REGISTER" ] && [ -f "$REGISTER" ]; then
  # Round-staged heuristics (references/forge-heuristics.md). Round 2 reads the consensus and pushes
  # for the unconventional; round 3+ chains ORPHANS, which is where a panel beats a single model.
  if [ "$ROUND" -le 2 ]; then
    INSTR="1. BUILD ON ANOTHER SEAT'S IDEA. Pick at least two entries that are NOT yours and extend,
   combine, invert or generalise them into something neither seat proposed. Do not evaluate or rank
   them. Name the ids you built on.
2. CONSENSUS IS A SIGNAL, NOT A TARGET. Entries marked CONFIRMED were reached independently by
   several models: that makes them real AND obvious, so re-proposing one scores ZERO. Instead say
   what the convergence IMPLIES — what must be true about this problem for independent models to
   land there, and what that rules in or out next.
3. GO UNCONVENTIONAL. Prefer methods a domain expert would flinch at on first hearing: invert an
   assumption the project treats as fixed; run an existing component BACKWARDS (a generator as a
   critic, an index for its ordering rather than its content); or import a technique from a field
   that studies a different object entirely, with its method attached and not as a metaphor.
4. DESIGN ONE EXPERIMENT you would run first: the join or query, the fixture, what counts as
   informative, what would make you abandon it, and what a FAILURE would teach.
5. PROPOSE NEW ideas the register does not contain."
  else
    INSTR="1. CHAIN THE ORPHANS. The register marks ORPHANS — ideas proposed once, by one seat, that
   nobody built on. Take TWO OR MORE of them and compose a single method neither could support
   alone. State the chain explicitly: A supplies X, B supplies Y, the combination yields Z that
   neither has. Prefer combinations whose parts are individually too weak to fund — those are what a
   single model discards and a panel can rescue. If two orphans cannot combine, say what blocks it;
   that is a finding too.
2. DO NOT re-propose anything marked CONFIRMED. Convergence has already been recorded; mining it
   again scores ZERO.
3. GO UNCONVENTIONAL, as above: inverted assumption, wrong-direction use of an existing component,
   or a borrowed constraint from a distant field.
4. DESIGN ONE EXPERIMENT for your strongest chain, with informative_if, abandon_if, and what a
   FAILURE would teach.
5. NEW ideas only if they are not reachable from the register."
  fi

  PROMPT="$PROMPT

--- IDEA REGISTER (every seat's work so far, curated) ---
$(cat "$REGISTER")

--- ROUND $ROUND INSTRUCTION ---
$INSTR

Output strict JSON, nothing else:
{\"built_on\":[{\"id\":\"<seat>-r$ROUND-<n>\",\"builds_on\":[\"<id>\"],\"idea\":\"...\",\"what_neither_said\":\"...\"}],
 \"experiment\":{\"name\":\"...\",\"join_or_query\":\"...\",\"fixture\":\"...\",\"informative_if\":\"...\",\"abandon_if\":\"...\",\"failure_teaches\":\"...\"},
 \"new_ideas\":[{\"id\":\"<seat>-r$ROUND-n<n>\",\"idea\":\"...\",\"nearby_material\":\"...\",\"cheapest_test\":\"...\"}]}"
fi

DEST="$OUT/forge-$SEAT-r$ROUND.txt"
ERR="$OUT/forge-$SEAT-r$ROUND.err"

# Seat isolation. Measured 2026-08-19: with several seats run sequentially in ONE directory, a later
# seat read an earlier seat's output file and openly positioned against it ("grok spent X39/X50 and
# never touched X05"), which destroys round independence — a seat differentiates strategically
# instead of thinking. Give every seat a fresh empty cwd, and keep $OUT outside it.
SEAT_CWD="$(mktemp -d "${TMPDIR:-/tmp}/concilium-forge-$SEAT-XXXXXX")"
export REPO_DIR="$SEAT_CWD"
case "$(cd "$OUT" 2>/dev/null && pwd)" in
  "$SEAT_CWD"*) echo ">> WARNING: --out is inside the seat's working directory; seats can read each other" >&2 ;;
esac
trap 'rm -rf "$SEAT_CWD"' EXIT

echo ">> forge seat=$SEAT round=$ROUND prompt=${#PROMPT} chars cwd=$SEAT_CWD -> $DEST" >&2

case "$SEAT" in
  codex)
    # research tier, read-only, empty cwd is the caller's job if the round must be blind
    printf '%s' "$PROMPT" | codex exec -m "${MODEL:-gpt-5.6-sol}" -s read-only --skip-git-repo-check \
      -c model_reasoning_effort="${EFFORT:-max}" > "$DEST" 2> "$ERR" ;;
  cursor|grok)
    "$HERE/concilium-review-cursor.sh" raw "$PROMPT" > "$DEST" 2> "$ERR" ;;
  kimi)
    "$HERE/concilium-review-kimi.sh" raw "$PROMPT" > "$DEST" 2> "$ERR" ;;
  *)
    echo "unknown seat: $SEAT (codex|cursor|kimi)" >&2; exit 2 ;;
esac

if grep -q '"ideas"\|"built_on"' "$DEST" 2>/dev/null; then
  echo ">> ok: $DEST ($(wc -c < "$DEST") bytes)" >&2
else
  echo ">> WARNING: no ideas/built_on JSON in $DEST — check $ERR before counting this round" >&2
fi
