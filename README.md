# Concilium

**Cross-model adversarial review and idea generation for Claude Code, Codex, Kimi and Grok. All
models work with subscriptions. No API keys needed.**

Concilium puts more than one frontier-model lineage on the same problem. A frontier **Claude**
model — **Opus 5 or Fable 5** — orchestrates, and OpenAI's **gpt-5.6-sol**, **gpt-5.6-terra** and
**gpt-5.5** work the other side through the official `codex` CLI. Two further families can join as
opt-in seats: **Kimi** (Moonshot) and **Grok** (xAI), each on its own subscription CLI. In review,
the second model **proposes** a verdict and the orchestrator **ratifies** it by checking the probe
itself. That split is the method — it is what catches wrong-join-key "refutations", scope
mismatches, and stale-vs-wrong conflations that either model alone would confidently ship.

It exists for the tasks where a single model's confident answer isn't good enough: load-bearing
research claims, benchmark numbers, subtle schema/data questions, diffs you're about to trust — and
for the tasks where the problem is that nobody has had the good idea yet. Different lineage means
different blind spots, and that is the only lever here that has ever measured as real.

> **If this seems complicated — it isn't.** After install, fire **`/concilium`** and state your
> problem. It runs a review by default — and if your problem is one of the few shapes another mode
> handles better, it says so in a line and lets you pick. See [the commands](#the-commands) for
> extended use.

<!-- DEMO GIF GOES HERE — record one real round (claim in → PROBE → verdict flip), ~30s,
     asciinema or terminal GIF, and drop it directly under this comment. This is the highest-
     converting asset the page can carry; everything below is secondary to it. -->

## Examples

Typed into a normal Claude Code session. The slash commands take arguments; everything else is
plain English.

**Just describe the problem.** This is the one to reach for when you don't want to think about
which mode you need:

```
/concilium Our data dropped right after the cache change. Find the Cause.
```

**Or mention it mid-sentence.** It doesn't have to start the line:

```
We keep finding duplicate rows past the dedup pass. Use /concilium on this before I touch the matcher. Use all available models.
```

Either way it reviews by default, and tells you in a line if your problem is one of the shapes
another mode handles better. "All available models" means every family you have a CLI logged in
for — four *lineages* at most.

**Review a specific claim.**

```
/concilium-review "Our data dropped right after the cache change. The deploy was the only thing that shipped today. Find the Cause."
```

Comes back with the five blocks. Read the probe, not the summary.

**Review what you're about to commit.**

```
/concilium-review --diff
/concilium-review --diff main        # against a branch instead of the working tree
```

**Generate ideas instead of checking them.**

```
/concilium-forge "Our dedup pass misses ~30% of true duplicates and we're out of ideas."
```

Round 1 in parallel across seats, you curate the register, round 2 builds on it. Nothing is scored
or voted on.

**Continue a forge you already started.**

```
/concilium-forge --continue path/to/REGISTER.md
```

**Ask for a mode by name.** No flags, no script — say what you want:

```
Run an instrument audit on the design.

Fragment-verify this write-up — I want to know which parts survive.

Blind-replicate this spec on two seats and show me only the diff between the implementations.

Cross-examine this claim. I don't think it's wrong, maybe it's underdetermined.

Frame-translate the problem before we try anything else — three fields, methods attached.
```

**Ask which mode fits, before running anything.** Useful when the problem is awkwardly shaped and
you'd rather not guess:

```
Here's what I'm stuck on: <describe it>. Which concilium mode fits this best, and what would it
give me that a plain review wouldn't? Recommend, don't run.
```

You get a short recommendation with the reason, and a chance to say no. Worth doing when a round is
expensive or the framing is the thing you're unsure about — the wrong mode returns a competent
answer to a question you weren't asking.

**Run every mode that applies.** For a problem you want attacked from all sides:

```
Work out which concilium modes are genuinely applicable here, run each of them, and give me the
union of what they found — not one merged verdict.
```

Two things to know before asking for this. It is **N rounds, not one**, at 5–15 minutes each, so it
is an afternoon rather than a coffee break. And the modes answer *different questions* — an
instrument audit and a fragment verify disagreeing is not a split to resolve, it is two findings.
Ask for the union, never a merged verdict; a verdict welded out of answers to different questions
means nothing. Expect some to be ruled out as inapplicable: blind replication needs a spec,
instrument audit needs a measurement design, and a mode with nothing to bite on should be skipped
rather than run empty.

**Run the loop when a verdict is disputed.**

```
/concilium-review "The index rebuild is what fixed the query, not the new stats."
…round comes back REFUTED…

I disagree, and here's why: its probe measured the whole table, but the regression was only ever on
the partitioned range. Loop it — new evidence path, keep going until it converges or goes dry.
```

Each round starts a fresh session and must bring a new evidence path. It stops on its own —
converged, dry, or at the round cap — rather than arguing indefinitely.

**Add an opt-in seat.** Never in a default round; ask explicitly, and say which:

```
Run that again with the Grok seat as well.

Add the Kimi seat, isolated, and tell me where the two seats disagree.
```

Two seats disagreeing is a *result*, not a tie to break. Weigh it by family, and never by which
seat sounded more certain.

## Install

**As a plugin (recommended)** — in any Claude Code session:

```
/plugin marketplace add raichominev/concilium
/plugin install concilium@raicho-skills
```

No SSH key needed — the shorthand falls back to HTTPS on its own.

**Or by hand**

Linux / macOS:

```bash
git clone https://github.com/raichominev/concilium.git ~/.claude/skills/concilium
chmod +x ~/.claude/skills/concilium/scripts/*.sh
```

Windows (PowerShell):

```powershell
git clone https://github.com/raichominev/concilium.git "$env:USERPROFILE\.claude\skills\concilium"
```

You also need the [OpenAI codex CLI](https://github.com/openai/codex) logged in via a ChatGPT
subscription at minimum. Other families, if desired, need their own subscriptions — full
[requirements](#requirements) below. First time in a new environment, let it run the calibration
bootstrap ([`references/setup.md`](references/setup.md)) before trusting verdicts.

## The commands

```
/concilium-review "<claim>"           # is this true? one seat probes, you ratify
/concilium-review --diff [base]       # same, pointed at your working-tree diff
/concilium-forge   "<question>"       # what has nobody tried? seats generate, nothing is judged
/concilium                            # the skill itself, when you're not sure which you want
```

**Review** hands your claim to a different lineage under a binding contract. It comes back with five
blocks — `PROBE / ALT / CAVEAT / VERDICT-PROPOSAL / PHASE-LOG` — and the last word is yours: read
the actual probe, re-run its load-bearing step, assign the tag. 

**Forge** is the opposite discipline. Seats produce original ideas against an open question, read
each other's through a shared register and build on them, and **nothing is judged or voted on**.
Round 1 tends to converge; round 2 is where the reframings appear.

Reviews run long — **5–15 minutes at research tier is normal**, so run them in the background with
a full timeout from the first call.

### There are eight more modes

Instrument audit, fragment verify, blind replication, cross-examination, frame translation,
selective escalation, role rotation, calibration league. **You ask for one by name, in plain
words** — nothing fires automatically, and `/concilium` will suggest one only when your problem is
clearly a better fit for it than a review.

The one worth knowing up front is the **instrument audit**: point it at a measurement design
*before* you spend the runs, and it tells you whether the number that comes back can mean anything.
Cheapest high-value call in the set.

What each mode is for, what would kill it, and the approaches already measured **dead** (so nobody
rebuilds them): [`references/modes.md`](references/modes.md).

### The loop — deliberate until it converges

One pass is often enough; a *concilium* is a council, so when a verdict is disputed it runs
another round. Each round must bring a **new** evidence path (enforced on both sides), uses a
**fresh session** (not a fragile resume chain), and the loop **terminates explicitly** —
converged, dry (no new evidence → escalate), or a round cap. Full protocol in
[`SKILL.md`](SKILL.md). It's orchestrated by the Claude session, not a shell script — the
ratification step is judgment, not automation.

## Seats

Two seats are standard. Two more are **experimental and opt-in — neither is part of a default
round**, and an extra seat buys nothing unless it is genuinely independent, so weigh a panel by
*family*, never by headcount.

| Seat | Family | Transport | Status |
|---|---|---|---|
| Orchestrator | Anthropic | the Claude Code session itself | ratifies; never routed to |
| Reviewer | OpenAI | `codex` CLI, ChatGPT subscription | standard |
| Kimi | Moonshot | Kimi Code CLI, or Kimi Desktop on Windows | experimental, opt-in |
| Grok | xAI | Cursor Agent CLI, Cursor subscription | experimental, opt-in |

**Kimi** ([`references/kimi-seat.md`](references/kimi-seat.md)) is calibrated but flakier than the
codex seat and weaker on isolation: no sandbox, and an exit code of 0 on failure.

**Grok** ([`references/grok-seat.md`](references/grok-seat.md)) runs on Cursor-subscription auth —
no xAI API key, no per-token bill. Effort is baked into the model id rather than passed as a flag.
Isolation is better than the Kimi seat's but still not containment. It scored **below** the OpenAI
seat on the calibration packet: seat it for a fourth lineage, not for accuracy.

A fifth seat exists — the orchestrator's own family run in a throwaway guest, for rounds that must
be blind. It has no wrapper and a good reason to exist:
[`docs/in-depth.md`](docs/in-depth.md).

### Tiers — route work by weight

| Tier | OpenAI (codex) | Effort | For |
|---|---|---|---|
| Research | `gpt-5.6-sol` | max | open review rounds, adversarial verification |
| Mechanical | `gpt-5.5` | medium | verifying a known claim with one probe |
| Runner | `gpt-5.6-terra` | low | execute-and-report: run a script, babysit an import |

Anthropic's seat is not a tier: **Opus 5 or Fable 5** orchestrates and ratifies rather than being
routed to. On the experimental seats, always name the model — at least one CLI's default is an
older generation than its flagship and nothing in the output says so.

### Park-and-switch

A codex session can be parked and resumed under a *different* model with its context intact —
research on sol, mechanical follow-ups on a cheaper tier, one conversation. The full re-pin recipe
(and why bare `resume` is dangerous) is in [`SKILL.md`](SKILL.md).

## Requirements

- [Claude Code](https://claude.com/claude-code) — this skill is meant to be run from Claude
  Code with **Opus 5 or Fable 5 as the orchestrator** (any Claude model can drive it; those two
  are the measured ratification seats).
- The [OpenAI codex CLI](https://github.com/openai/codex), logged in via a ChatGPT subscription
  (`codex login status` → "Logged in using ChatGPT").
- *Optional, experimental:* the extra-family seats — **Kimi Desktop** on Windows or the
  cross-platform **Kimi Code CLI**, and the **Cursor Agent CLI** for the xAI seat. Neither is
  needed for a default round, and both want isolating:
  [`references/isolated-guest-vmware.md`](references/isolated-guest-vmware.md) builds a throwaway
  guest.

### What if I'd rather use API keys?

Fine — **the skill never touches authentication.** The wrappers shell out to each vendor's own CLI
and inherit whatever session that CLI already has, so a CLI logged in with a key behaves exactly
like one logged in with a subscription. `codex login --with-api-key` reads an OpenAI key from
stdin; `cursor-agent --api-key` (or `CURSOR_API_KEY`) covers the xAI seat, though note that is a
*Cursor* key rather than an xAI one. Check the Kimi CLI's own help for its equivalent.

The trade is the obvious one: keys bill per token, and a research-tier round is 5–15 minutes of a
frontier model reasoning at maximum effort, run across two or more families. Subscriptions are the
default here because that cost is what made a multi-seat panel routine enough to measure.

**The one direction that does not work** is the reverse — a subscription cannot be turned into an
API key. Proxy and router bridges that claim to do it are outside every provider's terms; don't
build one.

Two things worth knowing up front:

- **The reviewer reads `AGENTS.md`, not `CLAUDE.md`.** codex auto-loads `AGENTS.md`; if your
  project only has a `CLAUDE.md`, the reviewer would miss your ground rules — so the wrappers
  auto-bridge `CLAUDE.md` into the contract when no `AGENTS.md` is present (opt out with
  `-NoAutoRules`; override with a curated `-ProjectRules` file; best practice is to keep an
  `AGENTS.md`). See [`SKILL.md`](SKILL.md) → *Project adaptation*.
- **No inbound port.** The skill uses `codex exec`/`review` over stdio — a review opens no
  listening port. codex's *interactive* app-server may bind a loopback port, but this skill never
  uses it. Details in [`references/setup.md`](references/setup.md).

> **Note**: experimental — extracted from a working research-project loop, where every rule was
> earned by a real failure. Read the caveats in [`docs/in-depth.md`](docs/in-depth.md) before a
> round you intend to act on; they, the measurements behind them, and what this skill has proven
> *doesn't* work all live there. Feedback is warmly welcome: issues, PRs, or war stories of your
> own (see that page's maintenance rule before adding examples).

## Release notes

### v1.4 (2026-08-20)

- **Forge mode** — the generative half. Seats produce original ideas against an open question and
  build on each other through a shared register; nothing is judged or voted on.
- **Eight further modes, and one generic driver.** A mode is now a markdown contract file, so
  adding one is a doc change rather than a script: instrument audit, fragment verify, blind
  replication, cross-examination, frame translation, selective escalation, role rotation,
  calibration league. Catalogue: [`references/modes.md`](references/modes.md).
- **`/concilium-review` and `/concilium-forge`** ship as commands.
- **A fourth family: the xAI seat** on Cursor-subscription auth, plus a fifth seat that is the
  orchestrator's own family run in a throwaway guest for blind rounds.
- **A per-seat skepticism block**, on by default only where it measured positive — it *cost*
  accuracy on the seats that were already discriminating.
- **Measured: rank seats per task.** Blind originality and outcome prediction produce different,
  partly inverted orderings, and a chaining round inverted it again.
- **Several modes found their own defects on first use** — an escalation gate that read a label's
  line instead of its block, a saturated file-access tripwire, a spec whose declared character
  range excluded the mark it called decorative. Those write-ups are in
  [`references/modes.md`](references/modes.md) and [`references/pitfalls.md`](references/pitfalls.md),
  and they are the most useful pages here.

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

## License

[Apache License 2.0](LICENSE) © 2026 Raicho Minev. Contributions are accepted under the same
license (Apache-2.0 §5 — inbound=outbound), so a PR needs no separate CLA.
