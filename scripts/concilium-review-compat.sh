#!/usr/bin/env bash
# concilium-review-compat.sh — review seat for ANY vendor exposing an Anthropic-compatible
# /v1/messages endpoint, driven through the Claude Code CLI. One script, many vendors: the only
# things that differ are the base URL, the model id and the token variable.
#
#   ./concilium-review-compat.sh <vendor> {claim|diff|raw} [...]
#
#   vendor   glm | deepseek | qwen   (or set COMPAT_BASE_URL/COMPAT_MODEL/COMPAT_TOKEN yourself)
#
# Config via env: MODEL (override the model id), REPO_DIR, PROJECT_RULES, PRIOR_ROUNDS,
#                 REASONING_BOOST=1 (OFF by default — see below), NO_AUTO_RULES=1.
#
# ⚠ Everything this seat reads goes to THAT vendor's provider, not Anthropic's. A Claude-Code
# transport does not mean a Claude model or Anthropic data handling. Check the vendor's retention
# terms before pointing it at anything sensitive.
#
# ⚠ Each vendor gets its OWN CLAUDE_CONFIG_DIR so it can never share session state or transcripts
# with a real Anthropic seat, or with another vendor. Same-family cross-reading is exactly what
# corrupts a lineage measurement.
#
# ⚠ Claude Code will warn that the model id is unrecognised and assume a 200k context window.
# Harmless for ordinary reviews; for very long material set CLAUDE_CODE_MAX_CONTEXT_TOKENS or use
# the vendor's own long-context model id.

set -euo pipefail

VENDOR="${1:-}"; shift || true
MODE="${1:-}"
[ -n "$VENDOR" ] && [ -n "$MODE" ] || {
  echo "usage: $0 <glm|deepseek|qwen> {claim|diff|raw} [...]" >&2; exit 2; }

case "$VENDOR" in
  glm)      DEF_URL="https://api.z.ai/api/anthropic";                  DEF_MODEL="glm-5.3";        TOKVAR="ZAI_TOKEN" ;;
  deepseek) DEF_URL="https://api.deepseek.com/anthropic";              DEF_MODEL="deepseek-v4-pro"; TOKVAR="DEEPSEEK_TOKEN" ;;
  qwen)     DEF_URL="https://dashscope-intl.aliyuncs.com/apps/anthropic"; DEF_MODEL="qwen3.8-max"; TOKVAR="QWEN_TOKEN" ;;
  *) echo "unknown vendor: $VENDOR (expected glm|deepseek|qwen)" >&2; exit 2 ;;
esac

BASE_URL="${COMPAT_BASE_URL:-$DEF_URL}"
MODEL="${MODEL:-${COMPAT_MODEL:-$DEF_MODEL}}"
TOKEN="${COMPAT_TOKEN:-${!TOKVAR:-}}"
[ -n "$TOKEN" ] || {
  echo "$TOKVAR is not set. Store it yourself — never paste a key into a command line:" >&2
  echo "  read -rsp 'key: ' k && printf '\\nexport $TOKVAR=%s\\n' \"\$k\" >> ~/.profile && unset k" >&2
  exit 4; }

command -v claude >/dev/null 2>&1 || {
  echo "claude CLI not found on PATH. This seat is driven through Claude Code." >&2
  echo "⚠ PATH often lives in ~/.profile, which non-interactive ssh does not source — try 'bash -lc'." >&2
  exit 3; }

REPO_DIR="${REPO_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
HERE="$(cd "$(dirname "$0")" && pwd)"
CONTRACT_PATH="$HERE/../references/contract.md"
[ -f "$CONTRACT_PATH" ] || { echo "contract not found: $CONTRACT_PATH" >&2; exit 3; }
CONTRACT="$(cat "$CONTRACT_PATH")"

# --- project rules: curated file wins; otherwise bridge CLAUDE.md when no AGENTS.md exists -------
if [ -n "${PROJECT_RULES:-}" ] && [ -f "$PROJECT_RULES" ]; then
  CONTRACT="$CONTRACT

--- PROJECT RULES (curated) ---
$(cat "$PROJECT_RULES")"
  printf '>> injected curated project rules\n' >&2
elif [ -z "${NO_AUTO_RULES:-}" ] && [ ! -f "$REPO_DIR/AGENTS.md" ]; then
  for f in "$REPO_DIR/.claude/CLAUDE.md" "$REPO_DIR/CLAUDE.md"; do
    if [ -f "$f" ]; then
      CONTRACT="$CONTRACT

--- PROJECT RULES (auto-bridged from ${f##*/}) ---
$(cat "$f")"
      printf '>> injected %s (no AGENTS.md present)\n' "${f##*/}" >&2
      break
    fi
  done
fi

if [ -n "${PRIOR_ROUNDS:-}" ] && [ -f "$PRIOR_ROUNDS" ]; then
  CONTRACT="$CONTRACT

--- PRIOR ROUNDS (do NOT repeat these probes; take a new evidence path; address the objection) ---
$(cat "$PRIOR_ROUNDS")"
fi

# Reasoning boost — OFF by default on EVERY seat since 2026-08-22. Measured in ADJUDICATION mode on
# a non-saturated packet, 6 seats / 5 vendors / 36 runs: refute rate 61.0% -> 73.4% (+12.4 pp), true
# claims recognised 61.1% -> 43.5%, accuracy slightly DOWN. It is a pure criterion shift, and chairs
# already over-refute. Replicated on two further vendors: 7 of 8 seats (p = 0.035), with Qwen a
# counterexample -- the direction holds for the population, not for every seat.
# Enable per round with REASONING_BOOST=1; do not use it for review work.
BOOST_PATH="$HERE/../references/reasoning-boost.md"
if [ "${REASONING_BOOST:-0}" != 0 ] && [ -f "$BOOST_PATH" ]; then
  CONTRACT="$CONTRACT

$(cat "$BOOST_PATH")"
  echo ">> reasoning boost ON (measured to INCREASE false refutation in review mode)" >&2
fi

CONTRACT="$CONTRACT

Runtime provenance (use in PHASE-LOG): model=$MODEL, vendor=$VENDOR, transport=claude-code/anthropic-compat."

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

CFG="${CLAUDE_CONFIG_DIR:-$HOME/.claude-$VENDOR}"
echo ">> $VENDOR via claude -p --model $MODEL (prompt ${#PROMPT} chars, cwd: $REPO_DIR, cfg: $CFG)" >&2

set +e
STREAM="$(cd "$REPO_DIR" && \
  ANTHROPIC_BASE_URL="$BASE_URL" ANTHROPIC_AUTH_TOKEN="$TOKEN" CLAUDE_CONFIG_DIR="$CFG" \
  claude -p "$PROMPT" --model "$MODEL" --output-format stream-json --verbose 2>&1)"
CODE=$?
set -e

RAW="$(printf '%s\n' "$STREAM" | python3 -c '
import sys, json
out = []
for line in sys.stdin:
    line = line.strip()
    if not line.startswith("{"):
        continue
    try:
        d = json.loads(line)
    except Exception:
        continue
    if d.get("type") == "result" and isinstance(d.get("result"), str):
        out.append(d["result"])
    m = d.get("message")
    if isinstance(m, dict) and m.get("role") == "assistant":
        for c in (m.get("content") or []):
            if isinstance(c, dict) and c.get("type") == "text":
                out.append(c["text"])
print(out[-1] if out else "")
')"
[ -n "$RAW" ] || RAW="$STREAM"
printf '%s\n' "$RAW"

# --- never trust the exit code. Three transports have returned "success" with empty or truncated
# output; one reported is_error:false after 30k output tokens and an empty result. Count DISTINCT
# blocks, unanchored: a streaming preamble can be glued onto the first block with no newline.
BLOCKS=$(printf '%s' "$RAW" | grep -oE '(^|[^A-Za-z-])(PROBE|ALT|CAVEAT|VERDICT-PROPOSAL|PHASE-LOG):' \
         | sed 's/[^A-Z-]//g' | sort -u | grep -c . || true)
if [ "$MODE" != raw ] && [ "$BLOCKS" -lt 5 ]; then
  echo ">> WARNING: only $BLOCKS/5 contract blocks present — treat this run as FAILED regardless of exit code $CODE" >&2
fi
