#!/usr/bin/env bash
# concilium-review-agy.sh — Google seat, via the Antigravity CLI (`agy`).
#
#   ./concilium-review-agy.sh {claim|diff|raw} [...]
#
# ⚠ Google's OWN Gemini CLI stopped serving individual accounts on 2026-06-18, including paid AI Pro
# and Ultra. Browser login still appears to succeed and the token exchange is refused server-side,
# so reinstalling it never helps. Antigravity is the supported successor and the AI Pro plan covers
# it. Install: curl -fsSL https://antigravity.google/cli/install.sh | bash   then run `agy` once.
# The device-code paste prompt closes after ~30 seconds — authenticate where you can paste it
# yourself; it is too short to relay through a chat.
#
# Model: `agy models` lists what your tier exposes. gemini-3.1-pro-high is the strongest
# CLI-reachable reasoning tier — Deep Think is Ultra-gated with early-access-only API, so it is not
# reachable from any CLI you can buy. Do not describe this seat as "frontier"; describe it as
# "Gemini 3.1 Pro, thinking_level high".
#
# ⚠ MEASURED CALIBRATION (2026-08-22, 18-claim adjudication packet, 6 runs = 108 decisions): this
# seat refutes 76.9% of everything against a 55.6% base rate — the HIGHEST refute rate of the eight
# seats measured — and recognises only 41.7% of TRUE claims, the second-worst upheld-recall (qwen is
# lower at 37.5%). It buys a high refuted-recall by rejecting nearly everything.
# Seat it for a distinct lineage, NOT as a trusted reviewer, and weigh its [X] verdicts accordingly.
#
# ⚠ Antigravity shares the IDE's credit pool, so CLI volume eats the desktop allowance.

set -euo pipefail

MODE="${1:-}"
[ -n "$MODE" ] || { echo "usage: $0 {claim|diff|raw} [...]" >&2; exit 2; }

command -v agy >/dev/null 2>&1 || {
  echo "agy not found on PATH. Install: curl -fsSL https://antigravity.google/cli/install.sh | bash" >&2
  echo "⚠ PATH often lives in ~/.profile, which non-interactive ssh does not source — try 'bash -lc'." >&2
  exit 3; }

MODEL="${MODEL:-gemini-3.1-pro-high}"
REPO_DIR="${REPO_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
HERE="$(cd "$(dirname "$0")" && pwd)"
CONTRACT_PATH="$HERE/../references/contract.md"
[ -f "$CONTRACT_PATH" ] || { echo "contract not found: $CONTRACT_PATH" >&2; exit 3; }
CONTRACT="$(cat "$CONTRACT_PATH")"

if [ -n "${PROJECT_RULES:-}" ] && [ -f "$PROJECT_RULES" ]; then
  CONTRACT="$CONTRACT

--- PROJECT RULES (curated) ---
$(cat "$PROJECT_RULES")"
  printf '>> injected curated project rules\n' >&2
fi

if [ -n "${PRIOR_ROUNDS:-}" ] && [ -f "$PRIOR_ROUNDS" ]; then
  CONTRACT="$CONTRACT

--- PRIOR ROUNDS (do NOT repeat these probes; take a new evidence path; address the objection) ---
$(cat "$PRIOR_ROUNDS")"
fi

# Reasoning boost — OFF by default on every seat since 2026-08-22 (see setup.md). This seat was the
# most extreme case measured: under the boost it reached a 96.3% refute rate and recognised 4.2% of
# true claims. Do not enable it here.
BOOST_PATH="$HERE/../references/reasoning-boost.md"
if [ "${REASONING_BOOST:-0}" != 0 ] && [ -f "$BOOST_PATH" ]; then
  CONTRACT="$CONTRACT

$(cat "$BOOST_PATH")"
  echo ">> reasoning boost ON — on THIS seat it measured a 96.3% refute rate. Reconsider." >&2
fi

CONTRACT="$CONTRACT

Runtime provenance (use in PHASE-LOG): model=$MODEL, vendor=google, transport=antigravity-cli."

case "$MODE" in
  claim) PROMPT="$CONTRACT

--- CLAIM UNDER REVIEW ---
${2:?claim text required}" ;;
  diff)
    BASE="${2:-}"
    D="$(cd "$REPO_DIR" && { [ -n "$BASE" ] && git diff "$BASE" || git diff; })"
    [ -n "$D" ] || { echo "No diff to review in $REPO_DIR" >&2; exit 2; }
    PROMPT="$CONTRACT

--- DIFF UNDER REVIEW (repo: $REPO_DIR) ---
$D" ;;
  raw)   PROMPT="${2:?prompt text required}" ;;
  *)     echo "unknown mode: $MODE" >&2; exit 2 ;;
esac

echo ">> agy -p --model $MODEL (prompt ${#PROMPT} chars, cwd: $REPO_DIR)" >&2
set +e
RAW="$(cd "$REPO_DIR" && timeout "${AGY_TIMEOUT:-900}" agy -p "$PROMPT" --model "$MODEL" 2>/dev/null)"
CODE=$?
set -e
printf '%s\n' "$RAW"

BLOCKS=$(printf '%s' "$RAW" | grep -oE '(^|[^A-Za-z-])(PROBE|ALT|CAVEAT|VERDICT-PROPOSAL|PHASE-LOG):' \
         | sed 's/[^A-Z-]//g' | sort -u | grep -c . || true)
if [ "$MODE" != raw ] && [ "$BLOCKS" -lt 5 ]; then
  echo ">> WARNING: only $BLOCKS/5 contract blocks present — treat this run as FAILED regardless of exit code $CODE" >&2
fi
