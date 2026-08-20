#!/usr/bin/env bash
# concilium-escalate.sh — SELECTIVE ESCALATION: cheap seat first, cross-family seat only when the
# cheap one's own output says it is not settled.
#
#   ./concilium-escalate.sh "<claim>" [--out <dir>] [--cheap <seat>] [--expensive <seat>]
#
# Default ladder: cheap = codex mechanical tier; expensive = cursor (a DIFFERENT family, which is the
# point — escalating within one lineage resamples the same blind spots, measured three ways in
# setup.md).
#
# ESCALATION GATE. It fires on what the reviewer SAYS, never on how confident it sounds:
#   * VERDICT-PROPOSAL carries [C] (unverified) ......... not settled -> escalate
#   * CAVEAT is anything other than "none" ............... probe left gaps -> escalate
#   * fewer than 5 contract blocks ....................... run failed -> escalate
#   * an extremal 0%/100% appears in the probe ........... tripwire (SKILL.md) -> escalate
# Confidence wording is deliberately NOT a trigger: seats differ enormously in how much doubt they
# express (codex mean 99.7 vs grok 70.9 on items they got right), so it carries no comparable signal.
#
# Cost model: a settled claim costs one mechanical call; a disputed one costs mechanical + research
# in a second family. On a stream of mostly-settled claims that is far cheaper than always running
# the research tier, and it never silently downgrades a hard claim.

set -euo pipefail

CLAIM="${1:-}"; shift || true
[ -n "$CLAIM" ] || { echo "usage: $0 \"<claim>\" [--out <dir>] [--cheap <seat>] [--expensive <seat>]" >&2; exit 2; }

OUT="./escalate-out"; CHEAP="codex"; EXPENSIVE="cursor"
while [ $# -gt 0 ]; do
  case "$1" in
    --out) OUT="$2"; shift 2 ;;
    --cheap) CHEAP="$2"; shift 2 ;;
    --expensive) EXPENSIVE="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

HERE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$OUT"

run_seat() {   # $1 seat, $2 dest, $3 extra-env
  case "$1" in
    codex)       env $3 "$HERE/concilium-review.sh" claim "$CLAIM" > "$2" 2>"$2.err" ;;
    cursor|grok) env $3 "$HERE/concilium-review-cursor.sh" claim "$CLAIM" > "$2" 2>"$2.err" ;;
    kimi)        env $3 "$HERE/concilium-review-kimi.sh" claim "$CLAIM" > "$2" 2>"$2.err" ;;
    *) echo "unknown seat: $1" >&2; exit 2 ;;
  esac
}

CHEAP_OUT="$OUT/escalate-1-$CHEAP.txt"
echo ">> tier 1: $CHEAP (mechanical)" >&2
run_seat "$CHEAP" "$CHEAP_OUT" "MECHANICAL=1" || true

blocks=$(grep -oE '(^|[^A-Za-z-])(PROBE|ALT|CAVEAT|VERDICT-PROPOSAL|PHASE-LOG):' "$CHEAP_OUT" 2>/dev/null \
         | sed 's/[^A-Z-]//g' | sort -u | grep -c . || true)
reason=""
[ "$blocks" -lt 5 ] && reason="only $blocks/5 contract blocks"

# Read a labelled BLOCK, not the rest of the label's line. Measured 2026-08-19 on this script's
# first live run: the seat printed "CAVEAT:" alone on one line with the text beneath it, so a
# same-line extraction saw an empty string, scored it "none", and failed to escalate a run that
# plainly said it had not verified half the claim. The SAME transcript puts the verdict tag on the
# line after "VERDICT-PROPOSAL:", so the [C] test needs the block reader too — a same-line grep for
# [C] there is the identical bug wearing a different label.
read_block() {   # $1 = block name
  awk -v want="$1" '
    $0 ~ "^[^A-Za-z]*" want ":" {f=1; sub("^[^A-Za-z]*" want ":[[:space:]]*",""); print; next}
    f && /^[^A-Za-z]*(PROBE|ALT|CAVEAT|VERDICT-PROPOSAL|PHASE-LOG):/{f=0}
    f{print}' "$CHEAP_OUT" 2>/dev/null | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g;s/^ //;s/ $//'
}

verdict=$(read_block VERDICT-PROPOSAL)
case "$verdict" in
  *'[C]'*) reason="${reason:+$reason; }verdict is [C] (unverified)" ;;
esac

caveat=$(read_block CAVEAT)
case "$(printf '%s' "$caveat" | tr 'A-Z' 'a-z')" in
  ""|none|none.|"none — "*) ;;
  *) reason="${reason:+$reason; }CAVEAT is non-empty" ;;
esac
grep -qE '(^|[^0-9])(0|100)(\.0+)?%' "$CHEAP_OUT" 2>/dev/null && reason="${reason:+$reason; }extremal 0%/100% in the probe"

if [ -z "$reason" ]; then
  echo ">> SETTLED at tier 1 — no escalation. Cost: 1 mechanical call." >&2
  cat "$CHEAP_OUT"
  exit 0
fi

echo ">> ESCALATING to $EXPENSIVE (different family). Reason: $reason" >&2
EXP_OUT="$OUT/escalate-2-$EXPENSIVE.txt"
run_seat "$EXPENSIVE" "$EXP_OUT" "EFFORT=max" || true

echo "===== TIER 1 ($CHEAP, mechanical) ====="; cat "$CHEAP_OUT"
echo; echo "===== TIER 2 ($EXPENSIVE, research, escalated because: $reason) ====="; cat "$EXP_OUT"
echo
echo ">> Both are PROPOSALS. Ratify per SKILL.md: read the probes, check the load-bearing step" >&2
echo ">> yourself, and weigh disagreement by LINEAGE — never settle it by counting votes." >&2
