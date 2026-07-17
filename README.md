# Concilium

> Cross-model adversarial review for Claude Code: a second AI model — GPT via the OpenAI
> `codex` CLI on ChatGPT-subscription auth, **no API key** — independently probes your claims
> with falsification attempts and *proposes* a verdict; the calling Claude session checks the
> probe and *ratifies* it. Different model lineage, different blind spots.

## ⚠️ Status: experimental

This skill was extracted from a working research project's cross-model review loop (its
"concilium") after one intense day of building, breaking, and calibrating it against a real
codebase. Every operational rule in it maps to a **measured failure** (see
[`references/pitfalls.md`](references/pitfalls.md) — resume silently resetting model *and*
sandbox, confident wrong verdicts on perfect-looking probes, context compaction corrupting long
sessions, and more). But it is young, opinionated, and shaped by one environment.

**Feedback is warmly welcome** — issues, PRs, war stories of your own, or just "this rule made
no sense on my setup." That's the point of publishing it.

## What's in the method

- **Five-block review contract**: `PROBE / ALT / CAVEAT / VERDICT-PROPOSAL / PHASE-LOG` —
  falsification probe required, alternative explanation required, hedges forced into the output
  (they don't survive terse formats otherwise).
- **Ratification protocol**: the reviewer proposes, the caller verifies the actual probe and
  assigns the final verdict. Extremal first-attempt results (0%/100%) are treated as tripwires,
  not discoveries.
- **Tier matrix**: research / mechanical / runner tiers pairing model choice with reasoning
  effort, so quota goes where judgment is needed.
- **Park-and-switch**: resume a parked codex session under a *different* model with context
  intact — with the full re-pin recipe, because bare resume silently resets everything.
- **Calibration bootstrap**: known-truth tests to run before trusting verdicts in a new
  environment, and a head-to-head method for picking tier models.

## Requirements

- [Claude Code](https://claude.com/claude-code) (any platform).
- The [OpenAI codex CLI](https://github.com/openai/codex) installed and logged in via a ChatGPT
  subscription (`codex login status` → "Logged in using ChatGPT"). No OpenAI API key is used —
  and a subscription cannot be turned into one; the CLI *is* the transport.

## Install

**Linux / macOS:**
```bash
git clone https://github.com/raichominev/concilium.git ~/.claude/skills/concilium
chmod +x ~/.claude/skills/concilium/scripts/concilium-review.sh
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/raichominev/concilium.git "$env:USERPROFILE\.claude\skills\concilium"
```

Then in any Claude Code session: ask for a cross-model review / second opinion, or invoke
`/concilium` directly. First time in a new environment, let it run the calibration bootstrap
(see [`references/setup.md`](references/setup.md)).

## Layout

| Path | What |
|---|---|
| `SKILL.md` | The method — tiers, invocation, ratification, resume recipe |
| `scripts/concilium-review.sh` | Reviewer wrapper, Linux/macOS (bash) |
| `scripts/concilium-review.ps1` | Reviewer wrapper, Windows (PowerShell 5.1+) |
| `references/pitfalls.md` | The measured failures behind every rule |
| `references/setup.md` | First-time setup, calibration, model head-to-head method |
| `evals/evals.json` | Draft test prompts for skill evaluation |

## Provenance

Distilled 2026-07-17 from a live research-codebase concilium (cross-model research/review
framework: two models alternating as researcher and reviewer, human owner as arbiter). Project
specifics stripped; the battle scars kept.
