# Concilium

**Cross-model adversarial review for hard tasks — combining the power of frontier models.**

Concilium is a [Claude Code](https://claude.com/claude-code) skill that puts two frontier-model
lineages on the same problem: a frontier **Claude** model — **Opus 5 or Fable 5** — orchestrates
the work, and OpenAI's **gpt-5.6-sol**, **gpt-5.6-terra**, and **gpt-5.5** serve as independent
reviewers and executors — reached through the official `codex` CLI on a plain **ChatGPT
subscription, no API key**.

It exists for the tasks where a single model's confident answer isn't good enough: load-bearing
research claims, benchmark numbers, subtle schema/data questions, diffs you're about to trust.
Different lineage means different blind spots — and the process below is built so that neither
side's confidence ever substitutes for evidence.

> **Note**: experimental — extracted from a working research-project loop, where every rule was
> earned by a real failure. Feedback is warmly welcome: issues, PRs, or war stories of your own
> (see the [maintenance rule](#maintenance-rule-docs--examples) before adding examples).

## v1.2 (2026-07-25)

- **Opus 5 joins Fable 5 as an orchestrator seat.** Both are first-class ratification
  seats throughout the skill — measured, not assumed: a blind chair benchmark against the
  origin project's own workload put Opus 5 at parity with Fable 5. Reusable method:
  [`references/setup.md`](references/setup.md).
- **Lineage-aware ratification.** Same-family agreement counts for less; cross-family
  evidence settles disputes — SKILL.md, ratification rule 6.
- **Blind rounds are structurally isolated.** Instructing an in-context model to ignore
  what it knows measurably fails — pitfalls #16–17
  ([`references/pitfalls.md`](references/pitfalls.md)).

## v1.1 (2026-07-24)

Lessons from a 5-round field deliberation (a methods-transfer review + two parallel design
reviews, all ratified):

- **Blind-first two-pass, validated in practice** (`references/request-template.md`): the blind
  round independently converged on the researcher's top transfers AND contributed two candidates
  the researcher missed — genuine independence, measured. Default to it for framing-critical
  rounds.
- **Ratify by verifying one load-bearing citation per round**: every round's decisive claim
  (a witness row, a delete-and-reinsert code path, an extremal concentration) was checkable in
  under a minute — and checking it is what makes the verdict yours, not the reviewer's.
- **Parallel reviews work**: two concurrent read-only reviewer sessions on sibling claims, no
  interference.
- **New pitfalls 12–15** (`references/pitfalls.md`): rebuilt-table id instability; iterated
  gating turning an oracle into training signal; derived-by-subtraction counts; non-Latin
  case-folding/console-literal traps.
- Also landed: the request-construction guide (`references/request-template.md`) — front-load
  facts not conclusions, confidence-tag every input, never write "do not re-derive" over a
  load-bearing conclusion.

## The process

```
you (in Claude Code — Opus 5 or Fable 5 orchestrating)
 │
 ├─ 1. hand a claim or diff to the reviewer wrapper
 │        scripts/concilium-review.{sh,ps1}
 │
 ├─ 2. a GPT-side model reviews it ADVERSARIALLY under a binding contract
 │        (references/contract.md): ≥1 falsification probe, ≥1 alternative
 │        explanation, forced caveats. It is a full agent — it reads the
 │        repo and runs read-only commands/queries itself.
 │
 ├─ 3. it returns five blocks:
 │        PROBE / ALT / CAVEAT / VERDICT-PROPOSAL / PHASE-LOG
 │
 ├─ 4. the orchestrator RATIFIES: reads the actual probe (not just the
 │        prose), treats extremal results (0%/100%) as tripwires, checks
 │        scope and staleness, and assigns the final verdict itself.
 │
 └─ 5. if the round is DISPUTED, loop: feed the probe + a specific
          objection into a fresh round (a new evidence path required),
          until it converges, goes dry, or hits the round cap.
```

The reviewer **proposes**; the orchestrator **ratifies**. That split is the core of the method
— it is what catches wrong-join-key "refutations", scope mismatches, and stale-vs-wrong
conflations that either model alone would confidently ship.

### The loop — deliberate until it converges

One pass is often enough; a *concilium* is a council, so when a verdict is disputed it runs
another round. Each round must bring a **new** evidence path (enforced on both sides), uses a
**fresh session** (not a fragile resume chain), and the loop **terminates explicitly** —
converged, dry (no new evidence → escalate), or a round cap. Full protocol in
[`SKILL.md`](SKILL.md). It's orchestrated by the Claude session, not a shell script — the
ratification step is judgment, not automation.

### Tiers — route work by weight

| Tier | Model | Effort | For |
|---|---|---|---|
| Research | `gpt-5.6-sol` | high | open review rounds, adversarial verification |
| Mechanical | `gpt-5.5` | medium | verifying a known claim with one probe |
| Runner | `gpt-5.6-terra` | low | execute-and-report: run a script, babysit an import |

### Park-and-switch

A codex session can be parked and resumed under a *different* model with its context intact —
research on sol, mechanical follow-ups on a cheaper tier, one conversation. The full re-pin
recipe (and why bare `resume` is dangerous) is in [`SKILL.md`](SKILL.md).

## Requirements

- [Claude Code](https://claude.com/claude-code) — this skill is meant to be run from Claude
  Code with **Opus 5 or Fable 5 as the orchestrator** (any Claude model can drive it; those two
  are the measured ratification seats — see the v1.2 notes above).
- The [OpenAI codex CLI](https://github.com/openai/codex), logged in via a ChatGPT subscription
  (`codex login status` → "Logged in using ChatGPT"). No OpenAI API key — and a subscription
  cannot be turned into one; the CLI *is* the transport.

Two things worth knowing up front:

- **The reviewer reads `AGENTS.md`, not `CLAUDE.md`.** codex auto-loads `AGENTS.md`; if your
  project only has a `CLAUDE.md`, the reviewer would miss your ground rules — so the wrappers
  auto-bridge `CLAUDE.md` into the contract when no `AGENTS.md` is present (opt out with
  `-NoAutoRules`; override with a curated `-ProjectRules` file; best practice is to keep an
  `AGENTS.md`). See [`SKILL.md`](SKILL.md) → *Project adaptation*.
- **No inbound port.** The skill uses `codex exec`/`review` over stdio — a review opens no
  listening port. codex's *interactive* app-server may bind a loopback port, but this skill never
  uses it. Details in [`references/setup.md`](references/setup.md).

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

Then, in any Claude Code session: ask for a cross-model review / second opinion, or invoke
`/concilium`. First time in a new environment, let it run the calibration bootstrap
([`references/setup.md`](references/setup.md)) before trusting verdicts.

## Layout

| Path | What |
|---|---|
| `SKILL.md` | The method — tiers, invocation, ratification, resume recipe |
| `references/contract.md` | The review contract (single source of truth — edit here) |
| `scripts/concilium-review.sh` | Reviewer wrapper, Linux/macOS (bash) |
| `scripts/concilium-review.ps1` | Reviewer wrapper, Windows (PowerShell 5.1+) |
| `references/pitfalls.md` | Known issues and the rules that counter them |
| `references/setup.md` | First-time setup, calibration, model head-to-head method |
| `evals/evals.json` | Draft test prompts for skill evaluation |

## Maintenance rule (docs & examples)

War stories stay, project specifics go. Every example in this repo must be self-contained and
judgeable from the text alone — no figures, table names, or artifacts that can only be verified
inside the origin project's private repo. The origin project keeps the full-detail originals in
its own docs and syncs the generic form here. Contributor PRs adding examples are bound by the
same rule — genericize your war story the same way. Release notes follow the same spirit:
summarized and reader-relevant; details live in SKILL.md and references — the README points,
it doesn't instruct.

## License

[Apache License 2.0](LICENSE) © 2026 Raicho Minev. Contributions are accepted under the same
license (Apache-2.0 §5 — inbound=outbound), so a PR needs no separate CLA.
