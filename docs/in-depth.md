---
layout: article
title: "Concilium in depth"
description: "The modes, seats, measurements and practical limits behind Concilium."
---

# Concilium in depth

*What the ten modes are for, which seats are worth having, what was measured, and what will cause
you problems. The README is the short version. This page is the argument behind it.*

## Two halves, and eight more modes

The skill started as one workflow and is now a catalogue. The two modes you will use most:

**Review** — *is this claim true?* One seat probes adversarially under a binding contract and
proposes a verdict. You ratify the verdict when you re-run its load-bearing step.

**Forge** — *what has nobody examined yet?* Seats generate original ideas against an open question.
They read each other's work through a shared register and **build on it**. **No seat judges another,
and no seat votes.** Use forge when the bottleneck is that nobody has yet had the good idea.

Judging is not a small variation on generating. The review contract has a duty to refute, and that
duty kills a half-formed idea before anyone can extend it. The two are therefore separate modes with
opposite discipline, and the forge tells seats explicitly not to evaluate each other. The same
result appears in the published literature. A judge model that reads a debate transcript can score
*worse* than no intervention at all, because a shared bias reappears in the judge.

Each of the other eight modes is a markdown contract, and one generic driver dispatches all of them.
To add a mode, add a file rather than a script:

| Mode | The question it answers | Discipline |
|---|---|---|
| **Instrument audit** | could this measurement produce a number that is not an answer? | attacks the fixture, never the claim |
| **Fragment verify** | which *parts* of this survive? | atomise, rule per fragment, salvage the supported core |
| **Blind replication** | is this spec unambiguous? | two seats implement blind, and the **diff** is the deliverable |
| **Cross-examination** | what must be answered before anyone rules? | questions with probes attached, no verdict |
| **Frame translation** | what does another field call this? | restate structurally, import the method not the metaphor |
| **Selective escalation** | is the cheap seat enough? | gate on what tier 1 *says*, escalate cross-family |
| **Role rotation** | calibrated labels from N seats | each generates once, the others adjudicate |
| **Calibration league** | whose forecasts deserve weight? | replay a frozen packet, score stable profiles rather than totals |

**You run a mode by name. Nothing selects a mode for you.** Ask for one — "audit that measurement
design before I run it" — or run it yourself:
`scripts/concilium-mode.sh <mode> <seat> --input <file>`. No mode starts automatically.

**If you try only one mode, try the instrument audit.** It gives the most value per call. Both seats
read a planned experiment, refused it outright, and named the defect: the design would have consumed
a large batch of runs and returned a number that measured nothing. That is one call before the
batch, not a post-mortem after it.

[`references/modes.md`](../references/modes.md) holds the full catalogue. It gives what would kill
each mode, and it lists the modes already measured **dead** so that nobody rebuilds them.

## The fifth seat: your own family, structurally isolated

Four of the five seats are four different lineages. The fifth is different: it is the orchestrator's
*own* family, and it runs in a guest that holds the payload and nothing else.

It exists because *instructed* blindness does not work. A model carries the project's own
instructions. Tell it to answer "from the packet alone" and it measurably still uses them. On a
14-item packet, an in-session chair scored well above the same family in an isolated guest. The
reason was that the context it was told to ignore stated four of the answers outright. **A subagent
of the project under study is not a blind seat, whatever the prompt says.**

Structural isolation is the only version that holds. The seat has no wrapper — you run Claude Code
in the guest. [`references/isolated-guest-vmware.md`](../references/isolated-guest-vmware.md)
describes a different seat, but it applies unchanged. The trouble is worth it. On outcome prediction
the isolated seat led the whole panel, and it earned the score that its in-session sibling did not.

## What it is tested to do

The skill includes a behavioural eval set ([`evals/evals.json`](../evals/evals.json)). It has seven
scenarios, and each one is written around a specific way that this kind of tool fails:

| # | Scenario | The failure it tests for |
|---|---|---|
| 0 | Review a subtly overbroad claim | Rubber-stamping — the round must report a caveat, not a flat confirm, and the orchestrator must ratify rather than relay |
| 1 | Set up codex as a reviewer, no API key | Trying to build a router/proxy or an API-key bridge instead of using subscription auth |
| 2 | Cheap mechanical follow-up in the same session | Bare `resume` or a fresh session, instead of the full re-pin recipe on a cheaper model |
| 3 | An ordinary review request | Adding an experimental seat unbidden, or presenting a default round as three-seat |
| 4 | Extra seat explicitly requested | Leaving the model unnamed (silently the wrong generation), hiding the isolation position, or trusting an exit code that is 0 on failure |
| 5 | "Run it once on each seat and rank them" | Delivering a ranking built from single draws that sit inside the run-to-run noise |
| 6 | "Crank every seat to max effort for coverage" | Complying silently — effort is not a coverage lever |

⚠ The eval set covers the **review** half. Forge and the eight contract modes are not in it yet.

## What we measured

These findings come from the origin project's own workload, not from assumptions.
[`references/benchmarks.md`](../references/benchmarks.md) gives the method.
[`measuring-the-seats.md`](measuring-the-seats.md) describes the campaigns behind these one-line
summaries: four instruments, five model families, the tables and the caveats.

- **Only a different lineage buys coverage.** More reasoning effort does not, and a newer generation
  of the same family does not — both resample the same blind spots. A spread of effort levels on one
  seat covered no more than two runs at the *same* effort. Accuracy was not monotonic in effort.
  Some items stayed unreachable at every level, and wall time grew eightfold. Add a family, not
  compute.
- **One run is not a measurement.** Replicates at identical settings moved a seat's score by several
  points and flipped a large share of items. We retracted the single-run rankings and use stable
  profiles instead — the items that a seat gets right in *every* replicate.
- **Rank seats per task, not once.** On blind idea-originality one seat led the panel by roughly 2×.
  On outcome prediction the same seat placed fourth of five, with the largest stable-wrong set in
  the panel. One round asked seats to *chain* other seats' orphaned ideas rather than generate new
  ones. In that round the seat that came **last** on solo originality produced the best chains. This
  data shows no general best seat.
- **The stable-wrong set is a seat's prior, not its noise** — and the sets barely overlap between
  families. That is the shape of a lineage difference, once you stop averaging it away. It is also
  the check to run before you weight a seat's opinion. A good scorer may be no more than the seat
  whose prior matches this project.
- **Blind means structurally blind.** Ratings must drop self-scores *and* same-family scores. A
  blind round must run where the answer is unreachable. An instruction to a model to ignore what it
  knows does not work.
- **A "be inventive, take the strong position" instruction is a skepticism control, not a reasoning
  upgrade.** It cut false alarms sharply for the two seats that over-called success. It *cost*
  accuracy for the two seats that were already discriminating. It is therefore **per-seat, not
  global**, and it is on by default only where it measured positive.
- **Opus 5 and Fable 5 are at parity as ratification chairs.** A blind chair benchmark shows this,
  and it is not an assumption.
- **Chairs over-refute, and predictors over-believe.** The direction is **lineage-dependent**, so
  measure it again per seat before you correct for it. Never carry a bias correction across modes.
- **Confidence is not a weight.** Seats differ by ~30 points in mean stated confidence on items they
  get *right*. A confident vote and a hedged one are not comparable quantities.
- **A perfect score is a contamination alarm.** Two runs returned full marks on a packet where the
  best seat measured before them scored much lower. Both runs reached material that answered the
  packet, and both said so in their own preambles. Grade the reasons, not the score.
- **Do not benchmark on fact retrieval.** A claim that the repo answers somewhere measures
  retrieval, and frontier models are saturated there. Every seat returns a near-perfect score, which
  says nothing about any of them. Use outcome prediction against a real experiment log.

The negative results are the more useful half. **Effort sweeps, generation sweeps, instructed
blindness, a judge that reads debate transcripts, and majority votes across same-lineage chairs are
all measured dead.** [`references/modes.md`](../references/modes.md) lists them with their evidence
so that nobody rebuilds them.

## Caveats — read these before you trust a round

**Everything a reviewer reads goes to that reviewer's provider.** This is true of every seat. Do not
point a review at a directory tree that holds credentials, or material that must not leave the
machine. The reviewer is a full agent, not a chatbot. A read-only sandbox blocks writes, not reads.

**A reviewer's verdict is a hypothesis, not a result.** Never flip a claim because a reviewer says
so. Reproduce the probe's load-bearing step. Treat an extreme 0% or 100% on a first attempt as a
wrong join key until you prove otherwise. Never weight a vote by its own stated confidence.

**Give every seat its own empty working directory.** If seats share a directory, a later seat will
read an earlier seat's output and position itself against it. This is measured, and the seat said so
in its own words. A panel that can see itself is not a panel, and any claim that its members
converged independently is void.

**Check that a seat's output is what the seat says it is.** One seat reported that it wrote a
structured file. It named the file and called it valid, and it had written nothing of the kind. A
seat's report about its own output is not evidence.

**Detection is a poor substitute for isolation, and it can saturate.** A file-access tripwire on one
machine flagged every watched file on every run. It also flagged a control run with no agent,
because the filesystem updated the access times on its own. Run the tripwire's control *before* the
round, not after. A saturated tripwire looks the same as a broken one.

**The experimental seats need stricter isolation.** They are opt-in, and they never join a default
round. One has no sandbox, does not stay where you put it, and exits 0 on failure. The other imports
your Claude Code hooks. If one of those hooks breaks, that seat will review without running a single
probe, and it will mention this only in prose that you have to read. Run both seats isolated.
[`references/kimi-seat.md`](../references/kimi-seat.md) and
[`references/grok-seat.md`](../references/grok-seat.md) hold the handling rules and the case for
keeping them.

**Reviews run long.** 5–15 minutes at research tier is normal. Run them in the background with a
full timeout from the first call. A foreground timeout kills the probe before it completes.
