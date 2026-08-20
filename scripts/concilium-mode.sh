#!/usr/bin/env bash
# concilium-mode.sh — run any CONTRACT-STYLE concilium mode on any seat.
#
# A mode is a contract file in references/: the driver prepends it to your material and sends the
# whole thing through a seat's raw transport (so the review contract does NOT interfere). Adding a
# mode means adding a markdown file, not a script.
#
#   ./concilium-mode.sh <mode> <seat> --input <file> [--extra <file>] [--out <dir>]
#
#   mode   basename of references/<mode>.md — e.g. instrument-audit, cross-examination,
#          fragment-verify, frame-translation, blind-replication
#   seat   codex | cursor | kimi
#   --input the material under the mode's scrutiny (instrument description, claim, spec, transcript)
#   --extra optional second file appended after the input (a prior seat's output, a spec, a register)
#   --out   output directory (default ./mode-out)
#
# Env: MODEL / EFFORT / MECHANICAL and the seat wrappers' own variables pass through.
#
# Modes that are NOT run this way: review (concilium-review*.sh — it has its own contract, diff
# handling and five-block check) and forge (concilium-forge.sh — it has register semantics).

set -euo pipefail

MODE="${1:-}"; SEAT="${2:-}"; shift 2 2>/dev/null || true
[ -n "$MODE" ] && [ -n "$SEAT" ] || {
  echo "usage: $0 <mode> <seat: codex|cursor|kimi> --input <file> [--extra <file>] [--out <dir>]" >&2
  exit 2; }

INPUT=""; EXTRA=""; OUT="./mode-out"
while [ $# -gt 0 ]; do
  case "$1" in
    --input) INPUT="$2"; shift 2 ;;
    --extra) EXTRA="$2"; shift 2 ;;
    --out)   OUT="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

HERE="$(cd "$(dirname "$0")" && pwd)"
REFS="$HERE/../references"

# A mode CONTRACT addresses the seat directly ("You are the INSTRUMENT AUDITOR..."); every other
# file in references/ is prose for the human and starts with a markdown heading. Listing the whole
# directory invited `concilium-mode.sh setup codex`, which would ship the setup guide to a seat as
# if it were a contract. contract.md is a contract but belongs to the review wrapper, not here.
list_modes() {
  for f in "$REFS"/*.md; do
    b="$(basename "$f" .md)"
    [ "$b" = contract ] && continue
    case "$(head -1 "$f")" in "You are"*) echo "  $b" ;; esac
  done
}

CONTRACT="$REFS/$MODE.md"
if [ ! -f "$CONTRACT" ] || [ "$MODE" = contract ] || ! head -1 "$CONTRACT" | grep -q '^You are'; then
  echo "no such mode: $MODE" >&2
  if [ "$MODE" = contract ]; then
    echo "(contract.md is the REVIEW contract - run it with concilium-review*.sh, not this driver)" >&2
  elif [ -f "$CONTRACT" ]; then
    echo "($MODE.md exists but is documentation, not a seat contract)" >&2
  fi
  echo "available:" >&2
  list_modes >&2
  exit 3
fi
[ -f "$INPUT" ] || { echo "input not found: $INPUT" >&2; exit 3; }

mkdir -p "$OUT"

PROMPT="$(cat "$CONTRACT")

--- MATERIAL UNDER $(printf '%s' "$MODE" | tr '[:lower:]-' '[:upper:] ') ---
$(cat "$INPUT")"

if [ -n "$EXTRA" ] && [ -f "$EXTRA" ]; then
  PROMPT="$PROMPT

--- ADDITIONAL MATERIAL ---
$(cat "$EXTRA")"
fi

DEST="$OUT/$MODE-$SEAT.txt"
ERR="$OUT/$MODE-$SEAT.err"
echo ">> mode=$MODE seat=$SEAT prompt=${#PROMPT} chars -> $DEST" >&2

case "$SEAT" in
  codex)
    printf '%s' "$PROMPT" | codex exec -m "${MODEL:-gpt-5.6-sol}" -s read-only --skip-git-repo-check \
      -c model_reasoning_effort="${EFFORT:-max}" > "$DEST" 2> "$ERR" ;;
  cursor|grok)
    "$HERE/concilium-review-cursor.sh" raw "$PROMPT" > "$DEST" 2> "$ERR" ;;
  kimi)
    "$HERE/concilium-review-kimi.sh" raw "$PROMPT" > "$DEST" 2> "$ERR" ;;
  *) echo "unknown seat: $SEAT" >&2; exit 2 ;;
esac

echo ">> $DEST ($(wc -c < "$DEST") bytes)" >&2
