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
# VERIFIED against Kimi Code CLI v0.34.0 on Ubuntu 24.04. The surface is young and moves — re-check
# `kimi --help` if your version differs. Notes from that verification:
#   * the prompt goes in via `-p` as an ARGV argument. Piping to stdin without `-p` HANGS (the CLI
#     waits on a TTY) — it is not an input path. A full contract is ~10 KB, far under ARG_MAX.
#   * there is no --final-message-only / --print / --quiet / -w / --effort on this build. Use
#     --output-format stream-json and take the last {"role":"assistant"} line; cd for the workdir.
#   * `-p` alone already auto-approves tool calls; --yolo/--auto are for interactive mode.

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

Runtime provenance (use in PHASE-LOG): model=${MODEL:-cli-default}, transport=kimi-code-cli (v0.34.0 surface)."

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
# -p takes the prompt as an argument and runs one-shot; stream-json gives a parseable transcript
# whose last assistant line is the answer. No -w on this build, so cd instead.
ARGS=(-p "$PROMPT" --output-format stream-json)
[ -n "${MODEL:-}" ] && ARGS+=(--model "$MODEL") || echo ">> WARNING: MODEL unset — the CLI default is an older generation than the flagship (setup.md)" >&2

echo ">> kimi -p <${#PROMPT} chars> --output-format stream-json ${MODEL:+--model $MODEL}  (cwd: $REPO_DIR)" >&2
set +e
STREAM="$(cd "$REPO_DIR" && kimi "${ARGS[@]}" 2>&1)"
CODE=$?
set -e

# last assistant message = the review; falls back to the raw stream if parsing finds nothing
RAW="$(printf '%s
' "$STREAM" | python3 -c '
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
    if d.get("role") == "assistant" and isinstance(d.get("content"), str):
        out.append(d["content"])
print(out[-1] if out else "")
')"
[ -n "$RAW" ] || RAW="$STREAM"
printf '%s
' "$RAW"

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
