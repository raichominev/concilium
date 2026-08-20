#!/usr/bin/env bash
# concilium-review-cursor.sh — cross-model review seat via the Cursor Agent CLI.
#
# Runs an xAI model (default Grok 4.6 at extra-high effort) on Cursor-subscription auth — no xAI
# API key, no metered per-token billing. Sibling of concilium-review.sh (codex/GPT) and
# concilium-review-kimi.sh (Moonshot). Same contract, same five blocks, same verdict discipline.
#
# The review contract lives in references/contract.md (single source of truth shared with every
# wrapper) — edit it there, not here.
#
# Usage:
#   ./concilium-review-cursor.sh claim "<claim text>"
#   ./concilium-review-cursor.sh diff [base-branch]
#   ./concilium-review-cursor.sh raw   "<prompt>"      # no contract (calibration probes)
#
# Env:
#   MODEL           model id (default cursor-grok-4.6-xhigh). Effort is BAKED INTO the id here —
#                   there is no --effort flag: ...-low | -medium | -high | -xhigh, each with a
#                   `-fast` sibling. See `cursor-agent --list-models`.
#   MECHANICAL=1    mechanical tier (cursor-grok-4.6-medium)
#   ALLOW_FAST=1    permit a `-fast` model id (refused by default — the fast lane is a different
#                   serving path, so its calibration does not transfer)
#   REPO_DIR        tree under review (default: git toplevel, else cwd)
#   PROJECT_RULES   curated ground-rules file appended to the contract
#   PRIOR_ROUNDS    prior-rounds file (loop mode)
#   AUTO_RULES=1    also inject AGENTS.md/CLAUDE.md into the contract. OFF by default because this
#                   CLI already loads project CLAUDE.md/AGENTS.md natively from the workspace.
#   NO_HOME_ISOLATION=1  run under the real $HOME (see HOME ISOLATION — expect shell tools to break)
#   WATCH_PATHS     comma-separated paths that must stay unread; reported if accessed. Watch the
#                   EVIDENCE (real tree, results log, answer key) for blind rounds.
#   CURSOR_AGENT    explicit path to the CLI if it is not on PATH
#
# ⛔ SECURITY — what this seat does and does not contain (all measured 2026-08-19, CLI 2026.08.11):
#   * `--mode ask` DOES block writes. Two probes asked it to create a file; both were refused and
#     nothing landed on disk. That is a real read-only constraint, unlike the kimi seat.
#   * `--force` here only bypasses the interactive command allowlist, which headless cannot answer
#     (approvalMode=allowlist rejects every unlisted command with a bare "Rejected:"). Combined with
#     `--mode ask` it buys read commands, not writes. NEVER pair --force with agent mode.
#   * `--sandbox enabled` is macOS/Linux ONLY — "Sandbox requires macOS or Linux" on Windows.
#   * The workspace is NOT a boundary. A canary file outside it was read by absolute path and its
#     contents returned verbatim. Everything the user account can read is in scope, and what it
#     reads reaches Cursor's backend. Isolation, if you need it, is an OS-level job (VM or a
#     separate account with ACLs). WATCH_PATHS is a contamination tripwire, not containment.
#
# HOME ISOLATION (on by default, and load-bearing):
#   The Cursor CLI imports Claude Code's user-level hooks, skills and plugins (claudeUserHooks /
#   loadClaudePlugin in its bundle), and there is no flag to disable the import. On Windows it then
#   ALWAYS builds the hook payload wrapper in PowerShell syntax
#       Get-Content -LiteralPath '<payload>' -Raw | & { $input | <hook command> }
#   but runs that string with the shell it detects from MSYSTEM/SHELL. Launched from Git Bash it
#   detects bash, which cannot parse `& {`, so EVERY hook dies with
#       --: eval: line 1: syntax error near unexpected token `&'
#   and EVERY SHELL TOOL CALL IS REJECTED — the reviewer then "reviews" without being able to run a
#   single probe, and says so only if you read the transcript. The hook COMMAND is irrelevant: a
#   hook whose command is literally `exit 0` fails identically (measured 2026-08-19). Launch the CLI
#   from cmd/PowerShell, or from a shim that clears MSYSTEM/EXEPATH at the cmd level — MSYS
#   re-injects MSYSTEM into every Win32 child, so `env -u MSYSTEM` does not clear it — and the same
#   hooks run fine. This wrapper takes the other route: point HOME/USERPROFILE at an empty directory
#   and pass CURSOR_CONFIG_DIR at the real profile for auth, which works on any launch shell. Side
#   benefit: the reviewer cannot read ~/.claude, which matters for blind rounds. Project-level
#   .claude/ hooks in REPO_DIR are still loaded — if shell calls come back "Rejected: ... syntax
#   error", that is the cause.
#
# Run in BACKGROUND with a full ~10 min timeout from the first call: real reviews take 5-15 min.

set -euo pipefail

MODE="${1:-}"
[ -n "$MODE" ] || { echo "usage: $0 {claim|diff|raw} [...]" >&2; exit 2; }

if [ -n "${MECHANICAL:-}" ]; then
  MODEL="${MODEL:-cursor-grok-4.6-medium}"
else
  MODEL="${MODEL:-cursor-grok-4.6-xhigh}"
fi

# Case-insensitive, and ALLOW_FAST=0/false/no must mean OFF (a bare -n test would accept "0").
case "$(printf '%s' "$MODEL" | tr 'A-Z' 'a-z')" in
  *-fast)
    case "$(printf '%s' "${ALLOW_FAST:-}" | tr 'A-Z' 'a-z')" in 1|true|yes|on) ;; *)
      echo "refusing model '$MODEL': the -fast lane is a different serving path and does not inherit" >&2
      echo "this seat's calibration. Set ALLOW_FAST=1 to override deliberately." >&2
      exit 2 ;;
    esac
    ;;
esac

REPO_DIR="${REPO_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
HERE="$(cd "$(dirname "$0")" && pwd)"
CONTRACT_PATH="$HERE/../references/contract.md"
[ -f "$CONTRACT_PATH" ] || { echo "contract not found: $CONTRACT_PATH" >&2; exit 3; }

# --- locate the CLI -----------------------------------------------------------------------------
AGENT="${CURSOR_AGENT:-}"
if [ -z "$AGENT" ]; then
  if command -v cursor-agent >/dev/null 2>&1; then
    AGENT="cursor-agent"
  elif [ -n "${LOCALAPPDATA:-}" ] && [ -f "$(cygpath -u "$LOCALAPPDATA" 2>/dev/null)/cursor-agent/cursor-agent.cmd" ]; then
    AGENT="$(cygpath -u "$LOCALAPPDATA")/cursor-agent/cursor-agent.cmd"
  elif [ -f "$HOME/.local/bin/cursor-agent" ]; then
    AGENT="$HOME/.local/bin/cursor-agent"
  else
    echo "cursor-agent not found. Install: curl https://cursor.com/install -fsS | bash" >&2
    echo "  (Windows: powershell -c \"irm 'https://cursor.com/install?win32=true' | iex\")" >&2
    echo "Then run 'cursor-agent login' before using this wrapper." >&2
    exit 3
  fi
fi

# --- blind-integrity tripwire (contamination check; see pitfalls) --------------------------------
WATCH_PRE=""
if [ -n "${WATCH_PATHS:-}" ]; then
  WATCH_PRE="$(IFS=,; for p in $WATCH_PATHS; do
      [ -e "$p" ] && find "$p" -type f -printf '%p\t%A@\n' 2>/dev/null; done | sort)"
  echo ">> blind-integrity watch: $(printf '%s\n' "$WATCH_PRE" | grep -c .) files" >&2
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

# Reasoning boost — ON by default for THIS seat. Measured 2026-08-19 on the 14-item prediction
# packet: this seat over-called WIN, and the block cut its false-alarm rate 33.3% -> 6.7% (d' 0.51 ->
# 1.58, +13.3 pp accuracy) — the largest gain of any seat. Disable with REASONING_BOOST=0.
# ⚠ That measurement is PREDICTION mode; these wrappers run ADJUDICATION mode, where chairs already
# over-refute (setup.md). If reviews start reading as reflexively negative, turn it off and say so.
BOOST_PATH="$HERE/../references/reasoning-boost.md"
if [ "${REASONING_BOOST:-1}" != 0 ] && [ -f "$BOOST_PATH" ]; then
  CONTRACT="$CONTRACT

$(cat "$BOOST_PATH")"
  echo ">> reasoning boost ON (REASONING_BOOST=0 to disable)" >&2
fi

AGENT_VERSION="$("$AGENT" --version < /dev/null 2>/dev/null | tr -d '\r' | head -1)"
CONTRACT="$CONTRACT

Runtime provenance (use in PHASE-LOG): model=$MODEL, seat=cursor, harness=cursor-agent ${AGENT_VERSION:-unknown}."

case "$MODE" in
  claim) PROMPT="$CONTRACT

--- CLAIM UNDER REVIEW ---
${2:?claim text required}" ;;
  diff)
    BASE="${2:-}"
    D="$(cd "$REPO_DIR" && { [ -n "$BASE" ] && git diff "$BASE" || git diff HEAD; })"
    [ -n "$D" ] || { echo "No diff to review in $REPO_DIR" >&2; exit 2; }
    PROMPT="$CONTRACT

--- DIFF UNDER REVIEW (repo: $REPO_DIR) ---
$D" ;;
  raw)   PROMPT="${2:?prompt text required}" ;;
  *)     echo "unknown mode: $MODE" >&2; exit 2 ;;
esac

# --- run ----------------------------------------------------------------------------------------
# The prompt goes via STDIN. As an argv argument it is silently mangled by the Windows .cmd shim:
# a multi-line prompt arrives truncated at line 1 and the model answers a question you never asked.
# Isolate HOME only when there is something to isolate FROM. The hazard is Claude Code's imported
# user-level hooks, so ~/.claude existing is the trigger. Isolating unconditionally breaks auth on
# Linux, where the session also lives in ~/.local/share/cursor-agent, which CURSOR_CONFIG_DIR does
# NOT cover: measured in a headless guest, every run died with "Authentication required".
# Isolate HOME only where the hazard exists AND isolation is safe:
#   * the hazard (imported ~/.claude hooks dying on a PowerShell-vs-bash wrapper mismatch) is
#     WINDOWS-only, so gate on the platform, not just on ~/.claude existing;
#   * on Linux the session lives in ~/.local/share/cursor-agent, which CURSOR_CONFIG_DIR does NOT
#     cover, so isolating there breaks auth outright. Measured 2026-08-19: installing Claude Code in
#     a Linux guest created ~/.claude, which flipped an earlier ~/.claude-only trigger ON and killed
#     six runs with "Authentication required" — a defence firing on the platform it cannot work on.
REAL_CURSOR_CFG="${CURSOR_CONFIG_DIR:-$HOME/.cursor}"
ISO_HOME=""
case "$(uname -s 2>/dev/null)" in
  MINGW*|MSYS*|CYGWIN*|Windows_NT)
    if [ -z "${NO_HOME_ISOLATION:-}" ] && [ -d "$HOME/.claude" ]; then
      ISO_HOME="$(mktemp -d "${TMPDIR:-/tmp}/concilium-cursor-home-XXXXXX")"
    fi ;;
esac

echo ">> $AGENT -p --trust --force --mode ask --model $MODEL (prompt ${#PROMPT} chars via stdin, cwd: $REPO_DIR)" >&2

set +e
if [ -n "$ISO_HOME" ]; then
  RAW_JSON="$(cd "$REPO_DIR" && printf '%s\n' "$PROMPT" | \
    HOME="$ISO_HOME" USERPROFILE="$(cygpath -w "$ISO_HOME" 2>/dev/null || echo "$ISO_HOME")" \
    CURSOR_CONFIG_DIR="$(cygpath -w "$REAL_CURSOR_CFG" 2>/dev/null || echo "$REAL_CURSOR_CFG")" \
    "$AGENT" -p --trust --force --mode ask --model "$MODEL" --output-format json 2>&1)"
else
  RAW_JSON="$(cd "$REPO_DIR" && printf '%s\n' "$PROMPT" | \
    "$AGENT" -p --trust --force --mode ask --model "$MODEL" --output-format json 2>&1)"
fi
CODE=$?
set -e
[ -n "$ISO_HOME" ] && rm -rf "$ISO_HOME"

# json mode emits one {"type":"result",...} object carrying the review in .result.
# The extractor goes in via -c, NOT a heredoc: a heredoc would take over stdin and the piped JSON
# would never reach the interpreter (measured — it silently yielded an empty result).
EXTRACT='
import sys, json
best = ""
for line in sys.stdin:
    line = line.strip()
    if not line.startswith("{"):
        continue
    try:
        d = json.loads(line)
    except Exception:
        continue
    if isinstance(d.get("result"), str):
        best = d["result"]
print(best)
'
PY_BIN=""
for c in python3 python py; do command -v "$c" >/dev/null 2>&1 && { PY_BIN="$c"; break; }; done
if [ -n "$PY_BIN" ]; then
  RAW="$(printf '%s\n' "$RAW_JSON" | "$PY_BIN" -c "$EXTRACT" 2>/dev/null)"
else
  echo ">> WARNING: no python on PATH — printing the raw JSON stream instead of the review" >&2
  RAW=""
fi
[ -n "$RAW" ] || RAW="$RAW_JSON"
printf '%s\n' "$RAW"

# --- never trust the exit code ------------------------------------------------------------------
# Count DISTINCT labels, not label-shaped lines: five "PROBE:" lines are not five blocks. (Caught
# by this seat reviewing this wrapper on its first round — the counting version passed that input.)
# The label may be glued to the previous sentence — this seat returns its STATUS chatter and the
# blocks as ONE line ("...the Windows profile.PROBE: Independent of..."), so anchor on a non-letter
# boundary rather than whitespace (a whitespace anchor scored that real 5-block review 4/5).
BLOCKS=$(printf '%s' "$RAW" | grep -oE '(^|[^A-Za-z-])(PROBE|ALT|CAVEAT|VERDICT-PROPOSAL|PHASE-LOG):' \
  | sed 's/[^A-Z-]//g' | sort -u | grep -c . || true)
if [ "$MODE" != raw ] && [ "$BLOCKS" -lt 5 ]; then
  echo ">> WARNING: only $BLOCKS/5 contract blocks present — treat this run as FAILED regardless of exit code $CODE" >&2
fi
# Match the hook signature, not a bare "Rejected:" — reviewers quote that string when discussing
# this very failure mode, which made the loose check cry wolf on a healthy run.
case "$RAW" in
  *"Rejected: Hook blocked"*) echo ">> WARNING: a tool call was REJECTED by an imported .claude hook — shell probes were blocked and the review ran without them (see HOME ISOLATION in this file's header; project-level .claude/ hooks are still loaded)." >&2 ;;
esac

# --- report what the run read -------------------------------------------------------------------
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

exit "$CODE"
