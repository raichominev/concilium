#!/usr/bin/env bash
# concilium-review.sh — adversarial cross-model review via the OpenAI codex CLI
# (ChatGPT-subscription auth; no API key). Generic — see SKILL.md + references/pitfalls.md.
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

read -r -d '' CONTRACT <<'EOF' || true
You are the cross-model REVIEWER: an independent second opinion from a different model lineage.
Review adversarially — do not defer to the researcher/author. Binding contract:
1. Never build on a load-bearing unverified claim without verifying it first.
2. Run >=1 falsification probe. Review-by-reading is NOT review.
3. Attempt >=1 alternative causal explanation of the headline claim.
4. Prefer independent re-derivation (your own check, a different evidence path).
5. Credit refutations, not confirmations; claims travel WITH their evidence.
6. Schema caution: similar or identical column names across (or within) tables are NOT
   guaranteed to share an ID space or semantics. Check docstrings AND sample real values on
   both sides before joining. State the SCOPE of every count.
7. Encoding: force UTF-8 output in any child process you spawn (chcp 65001,
   [Console]::OutputEncoding, PYTHONIOENCODING; on POSIX a UTF-8 LANG/LC_ALL) — non-ASCII crashes default console codepages.

Output exactly these five blocks:
  PROBE:     the falsification probe you ran + its result (include the actual query/commands)
  ALT:       one alternative causal explanation you considered
  CAVEAT:    what this probe did NOT verify (coverage, proxy/fallback methodology, scope,
             protocol drift); "none" ONLY if the probe exercised the claim's literal protocol.
  VERDICT-PROPOSAL: one tag — [V-code] (file:line) / [V-db] (query) / [V-probe] (the probe) /
             [C] (unverified) / [X] (refuted; name what supersedes it) — plus one sentence.
             A PROPOSAL only: the receiving session/owner assigns the final tag.
  PHASE-LOG: one ledger-ready line: "Phase N — reviewer(<model-id>) — <date> — <found> [proposed]"
EOF

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
