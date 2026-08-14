# Concilium

**Cross-model adversarial review for Claude Code — on your existing ChatGPT subscription. No API key.**

Concilium puts two frontier-model lineages on the same problem: a frontier **Claude** model —
**Opus 5 or Fable 5** — orchestrates, and OpenAI's **gpt-5.6-sol**, **gpt-5.6-terra** and
**gpt-5.5** review adversarially through the official `codex` CLI. The reviewer **proposes** a
verdict; the orchestrator **ratifies** it by checking the probe itself. That split is the method —
it is what catches wrong-join-key "refutations", scope mismatches, and stale-vs-wrong conflations
that either model alone would confidently ship.

It exists for the tasks where a single model's confident answer isn't good enough: load-bearing
research claims, benchmark numbers, subtle schema/data questions, diffs you're about to trust.
Different lineage means different blind spots.

> **If this seems complicated — it isn't.** After install just fire `/concilium` and state your
> problem.

<!-- DEMO GIF GOES HERE — record one real round (claim in → PROBE → verdict flip), ~30s,
     asciinema or terminal GIF, and drop it directly under this comment. This is the highest-
     converting asset the page can carry; everything below is secondary to it. -->

## Install

**As a plugin (recommended)** — in any Claude Code session:

```
/plugin marketplace add raichominev/concilium
/plugin install concilium@raicho-skills
```

`owner/repo` shorthand clones over SSH by default; if you have no GitHub SSH key loaded, set
`CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1` first.

**Or by hand** — Linux / macOS:

```bash
git clone https://github.com/raichominev/concilium.git ~/.claude/skills/concilium
chmod +x ~/.claude/skills/concilium/scripts/concilium-review.sh
```

Windows (PowerShell):

```powershell
git clone https://github.com/raichominev/concilium.git "$env:USERPROFILE\.claude\skills\concilium"
```

Install one way or the other, not both — a hand-installed copy in `~/.claude/skills/` and the
plugin will both load.

You also need the [OpenAI codex CLI](https://github.com/openai/codex) logged in via a ChatGPT
subscription — full [requirements](#requirements) below. Then, in any Claude Code session: ask for
a cross-model review / second opinion, or invoke `/concilium`. First time in a new environment, let
it run the calibration bootstrap ([`references/setup.md`](references/setup.md)) before trusting
verdicts.

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

### The loop — deliberate until it converges

One pass is often enough; a *concilium* is a council, so when a verdict is disputed it runs
another round. Each round must bring a **new** evidence path (enforced on both sides), uses a
**fresh session** (not a fragile resume chain), and the loop **terminates explicitly** —
converged, dry (no new evidence → escalate), or a round cap. Full protocol in
[`SKILL.md`](SKILL.md). It's orchestrated by the Claude session, not a shell script — the
ratification step is judgment, not automation.

### Tiers — route work by weight

| Tier | OpenAI (codex) | Moonshot (opt-in) | Effort | For |
|---|---|---|---|---|
| Research | `gpt-5.6-sol` | `k3` | max | open review rounds, adversarial verification |
| Mechanical | `gpt-5.5` | — | medium | verifying a known claim with one probe |
| Runner | `gpt-5.6-terra` | — | low | execute-and-report: run a script, babysit an import |

Anthropic's seat is not a tier: **Opus 5 or Fable 5** orchestrates and ratifies rather than being
routed to. On the Kimi side only `k3` is worth a seat — always name it, because the CLI's default
is an older generation.

### Park-and-switch

A codex session can be parked and resumed under a *different* model with its context intact —
research on sol, mechanical follow-ups on a cheaper tier, one conversation. The full re-pin recipe
(and why bare `resume` is dangerous) is in [`SKILL.md`](SKILL.md).

The Kimi CLI exposes session resume of its own (`-S <id>`, `--continue`), but cross-model switching
on resume is untested here — treat it as unproven rather than available. The Claude seat needs none
of this: it is the session driving the round, not a reviewer being resumed into.

### The optional third seat

A third lineage — Moonshot's **Kimi** — is available as an **experimental, opt-in** seat, via
either a locally installed Kimi Desktop (Windows) or the cross-platform Kimi Code CLI. It is not
part of a default round, and its [caveats](references/kimi-seat.md) apply.

## What it's tested to do

The skill ships a behavioural eval set ([`evals/evals.json`](evals/evals.json)) — seven scenarios,
each written around a specific way this kind of tool goes wrong:

| # | Scenario | The failure it's testing for |
|---|---|---|
| 0 | Review a subtly overbroad claim | Rubber-stamping — the round must surface a caveat, not a flat confirm, and the orchestrator must ratify rather than relay |
| 1 | Set up codex as a reviewer, no API key | Trying to build a router/proxy or an API-key bridge instead of using subscription auth |
| 2 | Cheap mechanical follow-up in the same session | Bare `resume` or a fresh session, instead of the full re-pin recipe on a cheaper model |
| 3 | An ordinary review request | Adding the experimental Kimi seat unbidden, or presenting a default round as three-seat |
| 4 | Kimi seat explicitly requested | Leaving the model unnamed (silently the wrong generation), burying the isolation position, or trusting an exit code that is 0 on failure |
| 5 | "Run it once on each seat and rank them" | Handing over a ranking built from single draws that sit inside the run-to-run noise |
| 6 | "Crank every seat to max effort for coverage" | Complying silently — effort is not a coverage lever |

## What we measured

Findings from the origin project's own workload, not assumptions. Method in
[`references/setup.md`](references/setup.md).

- **Only a different lineage buys coverage.** Not more reasoning effort, and not a newer generation
  of the same family — both resample the same blind spots. A spread of effort levels on one seat
  covered no more than two runs at the *same* effort; accuracy was not monotonic in effort, and
  some items stayed unreachable at every level.
- **One run is not a measurement.** Replicates at identical settings moved a seat's score by
  several points and flipped a large share of items. Single-run rankings were retracted in favour
  of stable profiles.
- **Opus 5 and Fable 5 are at parity as ratification chairs** — blind chair benchmark, not
  assumed.
- **Chairs over-refute; predictors over-believe.** In adversarial adjudication, chairs reject true
  claims at a substantial rate — some true claims get refuted by every chair independently. The
  same models flip to over-credulous in outcome *prediction*, believing changes worked that did
  not.
- **Confidence is not a weight.** A seat can hold near-maximum confidence across a set it is often
  wrong about.
- **Don't benchmark on fact-retrieval.** Claims answerable from somewhere in the repo measure
  retrieval, and frontier models are saturated there — every seat comes back near-perfect, which
  says nothing about any of them. Use outcome prediction against a real experiment log.

## Requirements

- [Claude Code](https://claude.com/claude-code) — this skill is meant to be run from Claude
  Code with **Opus 5 or Fable 5 as the orchestrator** (any Claude model can drive it; those two
  are the measured ratification seats).
- The [OpenAI codex CLI](https://github.com/openai/codex), logged in via a ChatGPT subscription
  (`codex login status` → "Logged in using ChatGPT"). No OpenAI API key — and a subscription
  cannot be turned into one; the CLI *is* the transport.
- *Optional, experimental:* the third-family seat — either **Kimi Desktop** on Windows or the
  cross-platform **Kimi Code CLI**, each with its own wrapper. Not needed for a default round, and
  it wants isolating: [`references/isolated-guest-vmware.md`](references/isolated-guest-vmware.md)
  builds a throwaway guest for it, and [`references/kimi-seat.md`](references/kimi-seat.md) is why.

Two things worth knowing up front:

- **The reviewer reads `AGENTS.md`, not `CLAUDE.md`.** codex auto-loads `AGENTS.md`; if your
  project only has a `CLAUDE.md`, the reviewer would miss your ground rules — so the wrappers
  auto-bridge `CLAUDE.md` into the contract when no `AGENTS.md` is present (opt out with
  `-NoAutoRules`; override with a curated `-ProjectRules` file; best practice is to keep an
  `AGENTS.md`). See [`SKILL.md`](SKILL.md) → *Project adaptation*.
- **No inbound port.** The skill uses `codex exec`/`review` over stdio — a review opens no
  listening port. codex's *interactive* app-server may bind a loopback port, but this skill never
  uses it. Details in [`references/setup.md`](references/setup.md).

## Caveats — read before trusting a round

**Everything a reviewer reads goes to that reviewer's provider.** True of every seat. Don't point
a review at a tree holding credentials or material that must not leave the machine.

**A reviewer's verdict is a hypothesis, not a result.** Never flip a claim on a reviewer's
say-so; reproduce the probe's load-bearing step. And never weight a vote by its own stated
confidence. The measurements behind both rules are in [What we measured](#what-we-measured).

**The experimental Kimi seat is the weakest link — treat it accordingly.** Opt-in, never in a
default round. It has no sandbox and does not stay where you put it, it exits 0 on failure, and its
arithmetic needs re-deriving. Run it isolated. The full handling rules, and the case for keeping it
anyway, are in [`references/kimi-seat.md`](references/kimi-seat.md).

**Reviews run long** — 5–15 minutes at research tier is normal. Run them in the background with a
full timeout from the first call; a foreground timeout kills the probe mid-flight.

> **Note**: experimental — extracted from a working research-project loop, where every rule was
> earned by a real failure. Feedback is warmly welcome: issues, PRs, or war stories of your own
> (see the [maintenance rule](#maintenance-rule-docs--examples) before adding examples).

## Layout

| Path | What |
|---|---|
| `SKILL.md` | The method — tiers, invocation, ratification, resume recipe |
| `references/contract.md` | The review contract (single source of truth — edit here) |
| `scripts/concilium-review.sh` | Reviewer wrapper, Linux/macOS (bash) |
| `scripts/concilium-review.ps1` | Reviewer wrapper, Windows (PowerShell 5.1+) |
| `references/pitfalls.md` | Known issues and the rules that counter them |
| `references/setup.md` | First-time setup, calibration, model head-to-head method |
| `references/kimi-seat.md` | The experimental third seat: transports, handling rules, what testing it produced |
| `references/isolated-guest-vmware.md` | Worked example: building a throwaway guest for the Kimi seat |
| `scripts/concilium-review-kimi.sh` | Kimi seat wrapper, Linux/macOS (CLI transport) |
| `scripts/concilium-review-kimi.ps1` | Kimi seat wrapper, Windows (desktop transport) |
| `evals/evals.json` | Behavioural eval set for the skill |

## Release notes

### v1.3 (2026-08-08)

- **An experimental third-family seat: Kimi, opt-in.** A Moonshot model can sit as a third reviewer
  alongside the Claude orchestrator and the GPT reviewer, over either transport, each with its own
  wrapper. **Not part of a default round** — ask for it explicitly, and read
  [`references/kimi-seat.md`](references/kimi-seat.md) first.
- **Isolation tooling for it.** A disposable working copy that reports what it touched, a
  blind-round tripwire, and a worked throwaway-guest build:
  [`references/isolated-guest-vmware.md`](references/isolated-guest-vmware.md).
- **Measured: only a different lineage buys coverage.** Not more reasoning effort, and not a newer
  generation of the same family — both resample the same blind spots.
- **Measured: one run is not a measurement.** Replicates moved a seat's score by several points, so
  single-run rankings were retracted in favour of stable profiles
  ([`references/setup.md`](references/setup.md)).

### v1.2 (2026-07-25)

- **Opus 5 joins Fable 5 as an orchestrator seat.** Both are first-class ratification
  seats throughout the skill — measured, not assumed: a blind chair benchmark against the
  origin project's own workload put Opus 5 at parity with Fable 5. Reusable method:
  [`references/setup.md`](references/setup.md).
- **Lineage-aware ratification.** Same-family agreement counts for less; cross-family
  evidence settles disputes — SKILL.md, ratification rule 6.
- **Blind rounds are structurally isolated.** Instructing an in-context model to ignore
  what it knows measurably fails — pitfalls #16–17
  ([`references/pitfalls.md`](references/pitfalls.md)).

### v1.1 (2026-07-24)

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
