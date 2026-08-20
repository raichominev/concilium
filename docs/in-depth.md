# Concilium in depth

*What the ten modes are for, which seats are worth having, what was actually measured, and what
will bite you. The README is the short version; this is the argument behind it.*

## Two halves, and eight more modes

The skill started as one workflow and is now a catalogue. The two you will use most:

**Review** — *is this claim true?* One seat probes adversarially under a binding contract, proposes
a verdict, and you ratify by re-running its load-bearing step.

**Forge** — *what has nobody pointed at yet?* Seats generate original ideas against an open
question, read each other's work through a shared register and **build on it**, and **nothing is
judged or voted on**. Use forge when the bottleneck is that the good idea has not been had yet.

Judging is not a small variation on generating. The review contract's duty to refute kills a
half-formed idea before anyone can extend it — so the two are separate modes with opposite
discipline, and the forge tells seats explicitly not to evaluate each other. The same result shows
up in the published literature: a judge model reading a debate transcript can score *worse* than no
intervention at all, because a shared bias reappears in the judge.

The other eight are each a markdown contract dispatched by one generic driver, so adding a mode
means adding a file rather than a script:

| Mode | The question it answers | Discipline |
|---|---|---|
| **Instrument audit** | could this measurement produce a number that is not an answer? | attacks the fixture, never the claim |
| **Fragment verify** | which *parts* of this survive? | atomise, rule per fragment, salvage the supported core |
| **Blind replication** | is this spec unambiguous? | two seats implement blind; the **diff** is the deliverable |
| **Cross-examination** | what must be answered before anyone rules? | questions with probes attached; no verdict |
| **Frame translation** | what does another field call this? | restate structurally, import the method not the metaphor |
| **Selective escalation** | is the cheap seat enough? | gate on what tier 1 *says*, escalate cross-family |
| **Role rotation** | calibrated labels from N seats | each generates once, the others adjudicate |
| **Calibration league** | whose forecasts deserve weight? | replay a frozen packet; score stable profiles, not totals |

**Modes are run by name, not selected for you.** Ask for one — "audit that measurement design
before I run it" — or drive it yourself:
`scripts/concilium-mode.sh <mode> <seat> --input <file>`. Nothing fires automatically.

**If you only try one, try the instrument audit.** It is the highest value-per-call mode here.
Pointed at a planned experiment, both seats refused it outright and named the defect: the design
would have consumed a large batch of runs and returned a number that measured nothing. One call
before the batch, not a post-mortem after it.

Full catalogue with what would kill each mode — and the ones already measured **dead**, so nobody
rebuilds them — is [`references/modes.md`](../references/modes.md).

## The fifth seat: your own family, structurally isolated

Four of the five seats are four different lineages. The fifth is the odd one out — the
orchestrator's *own* family, run in a guest that holds the payload and nothing else.

It exists because *instructed* blindness does not work. A model carrying the project's own
instructions and told to answer "from the packet alone" measurably still uses them: on a
14-item packet, an in-session chair scored well above the same family in an isolated guest, and the
reason was simply that four of the answers were stated outright in the context it was told to
ignore. **A subagent of the project under study is not a blind seat, whatever the prompt says.**

Structural isolation is the only version that holds. The seat has no wrapper — you run Claude Code
in the guest ([`references/isolated-guest-vmware.md`](../references/isolated-guest-vmware.md), which
is written around a different seat but applies unchanged). Worth the trouble: on outcome prediction
the isolated seat topped the whole panel, and unlike its in-session sibling it earned the score.

## What it's tested to do

The skill ships a behavioural eval set ([`evals/evals.json`](../evals/evals.json)) — seven
scenarios, each written around a specific way this kind of tool goes wrong:

| # | Scenario | The failure it's testing for |
|---|---|---|
| 0 | Review a subtly overbroad claim | Rubber-stamping — the round must surface a caveat, not a flat confirm, and the orchestrator must ratify rather than relay |
| 1 | Set up codex as a reviewer, no API key | Trying to build a router/proxy or an API-key bridge instead of using subscription auth |
| 2 | Cheap mechanical follow-up in the same session | Bare `resume` or a fresh session, instead of the full re-pin recipe on a cheaper model |
| 3 | An ordinary review request | Adding an experimental seat unbidden, or presenting a default round as three-seat |
| 4 | Extra seat explicitly requested | Leaving the model unnamed (silently the wrong generation), burying the isolation position, or trusting an exit code that is 0 on failure |
| 5 | "Run it once on each seat and rank them" | Handing over a ranking built from single draws that sit inside the run-to-run noise |
| 6 | "Crank every seat to max effort for coverage" | Complying silently — effort is not a coverage lever |

⚠ The eval set covers the **review** half. Forge and the eight contract modes are not in it yet.

## What we measured

Findings from the origin project's own workload, not assumptions. Method in
[`references/setup.md`](../references/setup.md).

- **Only a different lineage buys coverage.** Not more reasoning effort, and not a newer generation
  of the same family — both resample the same blind spots. A spread of effort levels on one seat
  covered no more than two runs at the *same* effort; accuracy was not monotonic in effort, and
  some items stayed unreachable at every level while wall time grew eightfold. Add a family, not
  compute.
- **One run is not a measurement.** Replicates at identical settings moved a seat's score by
  several points and flipped a large share of items. Single-run rankings were retracted in favour
  of stable profiles — the items a seat gets right in *every* replicate.
- **Rank seats per task, not once.** On blind idea-originality one seat led the panel by roughly
  2×; on outcome prediction the same seat placed fourth of five with the largest stable-wrong set
  in the panel. In a round where seats had to *chain* other seats' orphaned ideas rather than
  generate new ones, the seat that came **last** on solo originality produced the best chains.
  There is no general best seat in this data.
- **The stable-wrong set is a seat's prior, not its noise** — and the sets barely overlap between
  families. That is what a lineage difference looks like once you stop averaging it away. It is
  also the check to run before weighting a seat's opinion: a good scorer may simply be the seat
  whose prior happens to match this project.
- **Blind means structurally blind.** Ratings must drop self-scores *and* same-family scores, and a
  blind round must run where the answer is unreachable. Telling a model to ignore what it knows
  does not work.
- **A "be inventive, take the strong position" instruction is a skepticism knob, not a reasoning
  upgrade.** It cut false alarms sharply for the two seats that over-called success and *cost*
  accuracy for the two that were already discriminating. It is therefore **per-seat, not global**,
  and it is on by default only where it measured positive.
- **Opus 5 and Fable 5 are at parity as ratification chairs** — blind chair benchmark, not assumed.
- **Chairs over-refute; predictors over-believe** — and the direction is **lineage-dependent**, so
  re-measure it per seat before correcting for it. Never carry a bias correction across modes.
- **Confidence is not a weight.** Seats differ by ~30 points in mean stated confidence on items
  they get *right*. A confident vote and a hedged one are not comparable quantities.
- **A perfect score is a contamination alarm.** Two runs returned full marks on a packet where the
  best previously measured seat fell well short; both had reached material that answered it, and
  both said so in their own preambles. Grade the reasons, not the score.
- **Don't benchmark on fact-retrieval.** Claims answerable from somewhere in the repo measure
  retrieval, and frontier models are saturated there — every seat comes back near-perfect, which
  says nothing about any of them. Use outcome prediction against a real experiment log.

And the negative results, which are the more useful half — **effort sweeps, generation sweeps,
instructed blindness, a judge reading debate transcripts, and majority votes across same-lineage
chairs are all measured dead.** They are listed with their evidence in
[`references/modes.md`](../references/modes.md) so nobody rebuilds them.

## Caveats — read before trusting a round

**Everything a reviewer reads goes to that reviewer's provider.** True of every seat. Don't point
a review at a tree holding credentials or material that must not leave the machine. The reviewer is
a full agent, not a chatbot: a read-only sandbox blocks writes, not reads.

**A reviewer's verdict is a hypothesis, not a result.** Never flip a claim on a reviewer's
say-so; reproduce the probe's load-bearing step. Treat an extremal 0% or 100% on a first attempt as
a wrong join key until proven otherwise. And never weight a vote by its own stated confidence.

**Give every seat its own empty working directory.** Run seats in a shared directory and a later
one will read an earlier one's output and position against it — measured, with the seat saying so
in its own words. A panel that can see itself is not a panel, and any claim that its members
converged independently is void.

**Check that a seat's output is what it says it is.** One seat reported writing a structured file,
named it, called it valid, and had written nothing of the kind. A seat's report about its own
output is not evidence.

**Detection is a poor substitute for isolation, and it can saturate.** A file-access tripwire on
one machine flagged every watched file on every run — including a control with no agent running at
all, because the filesystem updated access times on its own. Run the tripwire's control *before*
the round, not after; a saturated tripwire is indistinguishable from a broken one.

**The experimental seats are the weakest links.** Opt-in, never in a default round. One has no
sandbox, does not stay where you put it, and exits 0 on failure; the other imports your Claude Code
hooks and, if one of them breaks, will review without running a single probe and mention it only in
prose you have to read. Run them isolated. The handling rules — and the case for keeping them — are
in [`references/kimi-seat.md`](../references/kimi-seat.md) and
[`references/grok-seat.md`](../references/grok-seat.md).

**Reviews run long** — 5–15 minutes at research tier is normal. Run them in the background with a
full timeout from the first call; a foreground timeout kills the probe mid-flight.

## Maintenance rule (docs & examples)

War stories stay, project specifics go. Every example in this repo must be self-contained and
judgeable from the text alone — no figures, table names, or artifacts that can only be verified
inside the origin project's private repo. The origin project keeps the full-detail originals in
its own docs and syncs the generic form here. Contributor PRs adding examples are bound by the
same rule — genericize your war story the same way. Release notes follow the same spirit:
summarized and reader-relevant; details live in SKILL.md and references — the README points,
it doesn't instruct.
