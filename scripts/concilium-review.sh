#!/usr/bin/env bash
# concilium-review.sh — adversarial cross-model review via the OpenAI codex CLI
# (ChatGPT-subscription auth; no API key). See SKILL.md + references/pitfalls.md.
#
# The review contract lives in references/contract.md (single source of truth shared with the
# PowerShell wrapper) — edit it there, not here.
#
# Usage:
#   concilium-review.sh claim "<claim text>"
#   concilium-review.sh diff [base-branch]
# Env: MODEL, EFFORT, MECHANICAL=1 (mechanical tier), REPO_DIR, PROJECT_RULES (file path).
#
# Defaults are models current at authoring time (2026-07) — check `codex debug models`.
# Resume ONLY with the full re-pin:
#   codex exec resume -m <model> -c sandbox_mode="read-only" -c model_reasoning_effort=<tier> <id> -
set -euo pipefail

MODE="${1:-}"
if [ -n "${MECHANICAL:-}" ]; then
  MODEL="${MODEL:-gpt-5.5}"
  EFFORT="${EFFORT:-medium}"
else
  MODEL="${MODEL:-gpt-5.6-sol}"
  EFFORT="${EFFORT:-high}"
fi
REPO_DIR="${REPO_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

CONTRACT_PATH="$(cd "$(dirname "$0")" && pwd)/../references/contract.md"
if [ ! -f "$CONTRACT_PATH" ]; then
  echo "Contract file not found: $CONTRACT_PATH" >&2
  exit 3
fi
CONTRACT="$(cat "$CONTRACT_PATH")"

if [ -n "${PROJECT_RULES:-}" ] && [ -f "$PROJECT_RULES" ]; then
  CONTRACT="$CONTRACT

--- PROJECT GROUND RULES (binding) ---
$(cat "$PROJECT_RULES")"
fi

# Provenance stamp: the model does not reliably know its own id, so the wrapper injects it.
CONTRACT_FULL="$CONTRACT

Runtime provenance (use in PHASE-LOG): model=$MODEL, effort=$EFFORT."

case "$MODE" in
  claim)
    CLAIM="${2:?provide the claim text as arg 2}"
    printf '>> codex exec -m %s -s read-only (claim via stdin)\n' "$MODEL" >&2
    cd "$REPO_DIR"
    printf '%s\n\n--- CLAIM UNDER REVIEW ---\n%s' "$CONTRACT_FULL" "$CLAIM" \
      | codex exec -m "$MODEL" -s read-only --skip-git-repo-check \
          -c model_reasoning_effort="$EFFORT"
    ;;
  diff)
    BASE="${2:-}"
    cd "$REPO_DIR"
    if [ -n "$BASE" ]; then RANGE=(--base "$BASE"); else RANGE=(--uncommitted); fi
    printf '>> codex review %s (model=%s, contract via stdin)\n' "${RANGE[*]}" "$MODEL" >&2
    printf '%s' "$CONTRACT_FULL" \
      | codex review -c model="$MODEL" -c model_reasoning_effort="$EFFORT" "${RANGE[@]}" -
    ;;
  *)
    echo "usage: concilium-review.sh {claim \"<text>\"|diff [base-branch]}" >&2
    exit 2
    ;;
esac
