#!/usr/bin/env bash
# concilium-review-kimi.sh — EXPERIMENTAL third-family seat via the Kimi Code CLI (Linux/macOS).
#
# Sibling of concilium-review-kimi.ps1, which drives the Windows *desktop* runner. This one drives
# the cross-platform CLI instead. Same review contract, same five blocks, same verdict discipline.
#
# Usage:
#   ./concilium-review-kimi.sh claim "<claim text>"
#   ./concilium-review-kimi.sh diff [base-branch]
#   ./concilium-review-kimi.sh raw   "<prompt>"      # no contract (calibration probes)
#
# Env:
#   MODEL          model alias to pass through (default: leave the CLI's own default alone)
#   EFFORT         reasoning effort if your build exposes one; unset = CLI default
#   REPO_DIR       tree under review (default: git toplevel, else cwd)
#   PROJECT_RULES  path to a curated ground-rules file appended to the contract
#   PRIOR_ROUNDS   path to a prior-rounds file (loop mode)
#   AUTO_RULES=1   opt in to bridging AGENTS.md/CLAUDE.md into the contract (OFF by default, #18)
#   SANDBOX_FROM   copy this tree to a throwaway dir and run there (see SECURITY)
#   KEEP_SANDBOX=1 keep the throwaway copy instead of deleting it
#   WATCH_PATHS    comma-separated paths that must stay unread; reported if accessed (see #21)
#
# ⛔ SECURITY — read before using this transport.
#   The CLI's print mode (`-p`) implies auto-approval of every tool call: it cannot be combined
#   with --yolo/--auto/--plan because it already runs unattended. That makes this seat MORE
#   permissive than the desktop wrapper's `manual` mode, not less. The seat also does not stay in
#   its working directory (pitfalls #20) — measured on every real round to date.
#   Run it in a container or a throwaway VM holding the payload and nothing else. SANDBOX_FROM
#   bounds the blast radius and proves what changed; it is not containment.
#
# STATUS: DRAFT — not yet exercised against a live CLI. Verify the flag names against
# `kimi --help` on your build before trusting it; the CLI is young and its surface moves.

set -euo pipefail

MODE="${1:-}"
[ -n "$MODE" ] || { echo "usage: $0 {claim|diff|raw} [...]" >&2; exit 2; }

REPO_DIR="${REPO_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
HERE="$(cd "$(dirname "$0")" && pwd)"
CONTRACT_PATH="$HERE/../references/contract.md"
[ -f "$CONTRACT_PATH" ] || { echo "contract not found: $CONTRACT_PATH" >&2; exit 3; }

command -v kimi >/dev/null 2>&1 || {
  echo "kimi CLI not found on PATH. Install: curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash" >&2
  echo "Then run 'kimi' once and '/login' (device-code OAuth) before using this wrapper." >&2
  exit 3; }

# --- disposable working copy -------------------------------------------------------------------
SANDBOX_DIR=""
cleanup() { [ -n "$SANDBOX_DIR" ] && [ -z "${KEEP_SANDBOX:-}" ] && rm -rf "$SANDBOX_DIR"; }
trap cleanup EXIT

if [ -n "${SANDBOX_FROM:-}" ]; then
  SANDBOX_DIR="$(mktemp -d "${TMPDIR:-/tmp}/concilium-kimi-XXXXXX")"
  # Secrets and VCS metadata never enter the copy.
  rsync -a \
    --exclude '.git' --exclude 'node_modules' --exclude '__pycache__' \
    --exclude '.venv' --exclude 'venv' --exclude '.mypy_cache' --exclude '.pytest_cache' \
    --exclude '*.env' --exclude '.env' --exclude '*.pem' --exclude '*.key' \
    --exclude 'id_rsa*' --exclude '*.pfx' --exclude '*.p12' --exclude 'credentials*' \
    "$SANDBOX_FROM"/ "$SANDBOX_DIR"/
  REPO_DIR="$SANDBOX_DIR"
  PRE_MANIFEST="$(cd "$REPO_DIR" && find . -type f -exec sha256sum {} + 2>/dev/null | sort)"
  echo ">> sandbox copy: $SANDBOX_FROM -> $SANDBOX_DIR" >&2
fi

# --- blind-integrity tripwire (see pitfalls #21 for what this does and does not prove) ----------
WATCH_PRE=""
if [ -n "${WATCH_PATHS:-}" ]; then
  WATCH_PRE="$(IFS=,; for p in $WATCH_PATHS; do
      [ -e "$p" ] && find "$p" -type f -printf '%p\t%A@\n' 2>/dev/null; done | sort)"
  echo ">> blind-integrity watch: $(printf '%s\n' "$WATCH_PRE" | grep -c . ) files" >&2
fi

# --- contract assembly (identical rules to the other wrappers) ----------------------------------
CONTRACT="$(cat "$CONTRACT_PATH")"

if [ -n "${PROJECT_RULES:-}" ] && [ -f "$PROJECT_RULES" ]; then
  CONTRACT="$CONTRACT

--- PROJECT GROUND RULES (binding) ---
$(cat "$PROJECT_RULES")"
elif [ -n "${AUTO_RULES:-}" ]; then
  for f in "$REPO_DIR/AGENTS.md" "$REPO_DIR/.claude/CLAUDE.md" "$REPO_DIR/CLAUDE.md"; do
    if [ -f "$f" ]; then
      CONTRACT="$CONTRACT

--- PROJECT INSTRUCTIONS ($(basename "$f")) ---
$(cat "$f")"
      echo ">> injected $(basename "$f")" >&2
      break
    fi
  done
fi

if [ -n "${PRIOR_ROUNDS:-}" ] && [ -f "$PRIOR_ROUNDS" ]; then
  CONTRACT="$CONTRACT

--- PRIOR ROUNDS (do NOT repeat these probes; take a new evidence path; address the objection) ---
$(cat "$PRIOR_ROUNDS")"
fi

CONTRACT="$CONTRACT

Runtime provenance (use in PHASE-LOG): model=${MODEL:-cli-default}, effort=${EFFORT:-cli-default}, transport=kimi-code-cli."

# --- build the prompt ---------------------------------------------------------------------------
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

# --- run ----------------------------------------------------------------------------------------
# -p is one-shot and exits; --final-message-only drops intermediate tool chatter so the five
# blocks arrive clean. Prompt goes on stdin: no argv length limit, no quoting hazard (the Win32
# argv mangling of pitfalls #19 is a Windows artifact and does not apply here).
ARGS=(-p --final-message-only -w "$REPO_DIR")
[ -n "${MODEL:-}" ]  && ARGS+=(--model "$MODEL")
[ -n "${EFFORT:-}" ] && ARGS+=(--effort "$EFFORT")

echo ">> kimi ${ARGS[*]}" >&2
set +e
RAW="$(printf '%s' "$PROMPT" | kimi "${ARGS[@]}")"
CODE=$?
set -e
printf '%s\n' "$RAW"

# --- never trust the exit code (#18) -------------------------------------------------------------
BLOCKS=$(printf '%s' "$RAW" | grep -cE '^(PROBE|ALT|CAVEAT|VERDICT-PROPOSAL|PHASE-LOG):' || true)
if [ "$MODE" != raw ] && [ "$BLOCKS" -lt 5 ]; then
  echo ">> WARNING: only $BLOCKS/5 contract blocks present — treat this run as FAILED regardless of exit code $CODE" >&2
fi

# --- report what the run touched ----------------------------------------------------------------
if [ -n "$WATCH_PRE" ]; then
  WATCH_POST="$(IFS=,; for p in $WATCH_PATHS; do
      [ -e "$p" ] && find "$p" -type f -printf '%p\t%A@\n' 2>/dev/null; done | sort)"
  TOUCHED="$(comm -13 <(printf '%s\n' "$WATCH_PRE") <(printf '%s\n' "$WATCH_POST") | cut -f1)"
  if [ -n "$TOUCHED" ]; then
    echo ">> BLIND-INTEGRITY TRIPPED: $(printf '%s\n' "$TOUCHED" | grep -c .) watched file(s) read" >&2
    printf '%s\n' "$TOUCHED" | head -20 | sed 's/^/   ! /' >&2
    echo "   Treat this round as CONTAMINATED unless you can attribute the reads to another process." >&2
  else
    echo ">> blind integrity OK" >&2
  fi
fi

if [ -n "$SANDBOX_DIR" ]; then
  POST_MANIFEST="$(cd "$SANDBOX_DIR" && find . -type f -exec sha256sum {} + 2>/dev/null | sort)"
  if [ "$PRE_MANIFEST" != "$POST_MANIFEST" ]; then
    echo ">> sandbox CHANGED:" >&2
    diff <(printf '%s\n' "$PRE_MANIFEST") <(printf '%s\n' "$POST_MANIFEST") | head -20 >&2
  else
    echo ">> sandbox unchanged" >&2
  fi
  [ -n "${KEEP_SANDBOX:-}" ] && echo ">> sandbox kept: $SANDBOX_DIR" >&2
fi

exit "$CODE"
