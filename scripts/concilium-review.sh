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
# Env: MODEL, EFFORT, MECHANICAL=1 (mechanical tier), REPO_DIR, PROJECT_RULES (file path),
#      PRIOR_ROUNDS (file path — loop mode: prior probes + objection; reviewer takes a new path),
#      NO_AUTO_RULES=1 (skip auto-bridging CLAUDE.md when no AGENTS.md — codex reads AGENTS.md only).
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
elif [ -z "${NO_AUTO_RULES:-}" ]; then
  # codex loads AGENTS.md natively (cwd upward); it does NOT see CLAUDE.md. Bridge that gap so the
  # reviewer isn't blind to project rules Claude has. PROJECT_RULES (a curated extract) overrides.
  if [ -f "$REPO_DIR/AGENTS.md" ]; then
    printf '>> codex will load AGENTS.md natively from %s\n' "$REPO_DIR" >&2
  elif [ -f "$REPO_DIR/.claude/CLAUDE.md" ]; then
    CONTRACT="$CONTRACT

--- PROJECT INSTRUCTIONS (.claude/CLAUDE.md — codex does not load this natively) ---
$(cat "$REPO_DIR/.claude/CLAUDE.md")"
    printf '>> injected .claude/CLAUDE.md (no AGENTS.md present)\n' >&2
  elif [ -f "$REPO_DIR/CLAUDE.md" ]; then
    CONTRACT="$CONTRACT

--- PROJECT INSTRUCTIONS (CLAUDE.md — codex does not load this natively) ---
$(cat "$REPO_DIR/CLAUDE.md")"
    printf '>> injected CLAUDE.md (no AGENTS.md present)\n' >&2
  fi
fi

# Loop mode: prior rounds' probes + the orchestrator's objection, so this round takes a NEW path.
if [ -n "${PRIOR_ROUNDS:-}" ] && [ -f "$PRIOR_ROUNDS" ]; then
  CONTRACT="$CONTRACT

--- PRIOR ROUNDS (do NOT repeat these probes; take a new evidence path; address the objection) ---
$(cat "$PRIOR_ROUNDS")"
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
