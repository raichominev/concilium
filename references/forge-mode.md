# Forge mode — the concilium's generative half

Review mode asks *is this claim true?* Forge mode asks *what has nobody pointed at yet?* Same seats,
same transports, opposite discipline: **nothing is judged, nothing is voted on, and no verdict is
produced.** Ideas are raw material for the next seat.

Scripts: `scripts/concilium-forge.{sh,ps1}`. Brief template: `forge-brief-template.md`.
For scale, the run these notes come from: 2 rounds, 4 seats, 46 raw ideas → 9 clusters → 4
experiment designs → 1 executed.

## Why it is a separate mode and not a prompt variation

Three measured reasons, not stylistic ones:

1. **Judging destroys the yield.** The review contract's job is to refute; applied to a half-formed
   idea it kills it before anyone can build on it. In the forge, seats are told explicitly not to
   evaluate each other. The published literature converges here too: a judge reading a debate
   transcript can score *worse* than no intervention, because a shared bias reappears in the judge.
2. **Aggregation by voting is the wrong operator for ideas.** A vote answers "which of these",
   whereas the forge wants the union plus the combinations. Every idea survives; the orchestrator
   curates rather than eliminates.
3. **Originality has to be scored, or seats regress to the safe answer.** The brief says so plainly:
   an idea that is wrong but new and testable scores; a correct and already-known one scores zero.

## The register is the mechanism

One markdown file, three sections, in that order:

- **OPEN IDEAS** — clustered, at the top, most consequential first.
- **HISTORY** — round-1 entries absorbed into clusters, with which seats reused them.
- **EXPERIMENT LOG** — designs worth running, each with `informative_if`, `abandon_if` and
  **what a failure would teach**. Informativeness is the logging criterion; success is not.

Seats read the whole register and must name the ids they built on. That is what turns four parallel
brainstorms into one conversation — and in the worked example it is where the value appeared: round
1 produced heavy convergence (four seats independently proposing the same join), while round 2
produced *reframings* — a confound nobody had seen, an ordering constraint that made another seat's
idea invalid until a third seat's ran first, and an inversion that turned fragile text extraction
into search-and-eliminate.

## Orchestrator duties (not automatable — this is the judgment step)

1. **Between rounds, curate.** Merge duplicates into clusters, keep the sharpest formulation, credit
   every contributing id, and rank by consequence rather than by novelty.
2. **Contribute.** The orchestrator is a seat too and should add ideas each round, including the
   uncomfortable meta-ones ("nine clusters and not one touches X").
3. **Promote what got built on** into HISTORY with its reuse count — that is the honest measure of
   which round-1 idea mattered.
4. **Name the gate.** Usually one experiment orders all the others; say which and why. In the worked
   example the recall-vs-ranking audit decided which half of the register was worth funding, so it
   ran first and its result retired a whole cluster.
5. **Run one.** A forge that never executes an experiment is a brainstorm. The register's own rule is
   that an experiment lands in the log when it was worth running, whatever it returned.

## Blindness

Forge rounds do **not** need the blind machinery review rounds need — you *want* the seats grounded
in project facts. What they must not see is the answer to any experiment the register proposes. In
practice: ship a self-contained brief, and if a seat runs on the project machine, remember that a
subagent of the project under study inherits its instructions and memory (pitfalls #16/#17) and is
therefore not a blind chair.

Do include an **already tried** section in the brief. It is worth more than any instruction: it
stops seats scoring on dead arms, and it is the cheapest way to push them toward empty cells.

## Cost

One model call per seat per round; no probes, no re-runs. A 4-seat 2-round forge is 8 calls, which
is less than a single disputed review loop. The expensive part is the orchestrator's curation and
whatever experiment the register earns.

## Seat isolation — measured, not theoretical

Run seats sequentially in one working directory and a later seat will read an earlier one's output.
Measured 2026-08-19: with four seats writing into a shared guest directory, the third opened a
rival's round-3 file and positioned against it explicitly — *"grok spent X39/X50/X31/X23 on
mint-and-quarantine chains and never touched X05, so all three of my chains are built on…"*. It is
not a hallucination and not harmless: a seat that can see a sibling's answer differentiates
strategically instead of thinking, and any claim that seats converged independently is void.

`concilium-forge.sh` now gives each seat a fresh empty cwd and warns if the output directory sits
inside it. When driving seats by hand, do the same — and remember that seats reading each other is
the *design* in a chaining round, but only through the **curated register**, never through raw
sibling output.

Second failure from the same run: a seat announced *"round 3 written to r3-kimi.txt (valid JSON)"*
while writing nothing — the captured artifact was a prose summary and the JSON never existed. Check
that the captured output actually parses; a seat's report about its own output is not evidence.
