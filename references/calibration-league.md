# Calibration league — score the project's forecasting, not the seats'

Every other mode measures models. This one measures **the project**: how much its own
pre-registrations deserve to be believed. The instrument already exists in most research repos and
is almost never used for this.

## The idea

An experiment ledger pairs a pre-registration (change, fixture, metric, gate) with a recorded
outcome. Strip the outcomes, re-issue the pre-registrations as a prediction packet, and you learn two
things at once:

- **the project's forecasting skill** — if a team's pre-registered gates are met 80% of the time, its
  gates are too easy; at 20%, its plans are systematically optimistic and its cost estimates are
  worthless;
- **which seat predicts this project's outcomes best**, which is the seat whose judgement to weight
  when deciding what to fund next.

## Why it is worth doing

The measured 2026-08-19 result on a 14-item packet from this project's own ledger: seats scored
6–9/14 blind, against 7/7 base rates — barely above chance, and the errors were **asymmetric**
(chairs were over-credulous in prediction mode, over-refuting in adjudication mode, and the direction
turned out to be lineage-dependent too). If frontier models predict a project's outcomes at close to
chance, then "does this arm sound promising?" is not evidence, and only the ledger is.

## Method

1. **Harvest.** Every ledger entry with a pre-registration AND a recorded outcome. Exclude any entry
   whose own author attributed the result to noise — grading a chair against an outlier measures
   variance, not judgement.
2. **Strip.** Remove the outcome and every downstream number. ⚠ The hard part: a ledger's figures are
   usually quoted across other documents and version-control objects, so stripping the repo is
   hopeless. Ship a purpose-built directory containing only the packet, and run the seats where they
   cannot reach the repo at all (`isolated-guest-vmware.md`). A seat that can grep its way to the
   answer measures retrieval, which is saturated.
3. **Balance.** Report the WIN/FAIL base rate; an unbalanced packet lets "always answer FAIL" score
   well and turns a criterion shift into an apparent skill gain.
4. **Replicate.** Three runs per seat minimum. Single-run spreads of up to 4 points on a 14-item
   packet have been measured *within one seat at identical settings*.
5. **Score on the stable profile** — items a seat gets right in every replicate, wrong in every
   replicate, and the ones that flip — not on a single run's total.

## RESULT OF THE FIRST RUN (2026-08-20): half of this mode is dead, half of it works

The harvest was attempted against a real 173-row research ledger. **The project-level half hit a
kill condition — a different one than the page predicted — and the seat-level half produced a
usable league.** Both outcomes are the mode's, and the split is the finding.

### Killed: you cannot score a project's forecasting against gates written after the outcome

The page's stated kill condition was "the ledger's entries cannot be stripped of their outcomes
without becoming unanswerable". The actual failure is upstream of that: **there was nothing to
strip.** Measured on the ledger:

- **0 of 173 rows** sit in a registered-but-unmeasured state. Every row was written after the
  result was known, so the ledger is an *outcome log*, not a pre-registration register.
- The `baseline` column records the **baseline**, not a gate: only **5 of 173** carry threshold
  language there. 56 rows mention a threshold *somewhere*, but 24 of those mentions are inside the
  `result` column and 20 inside `verdict` — i.e. written together with the answer.
- Checking the hand-built 14-item packet against the rows it was drawn from: **only 2 of the 14
  gates were readable from the ledger row.** The other 12 were composed by the packet's author,
  who already knew each outcome. Scoring anyone's forecasting against a threshold placed with
  hindsight measures the threshold-placer, not the forecaster.
- The verdict column is free prose — **55% of rows** resist any keyword classifier, and the 84%
  adoption rate over the classifiable remainder is a curation statistic on a keyword-selected
  subsample, not a hit rate. Do not quote it as one.

**Revival condition, and it is cheap:** add one `gate` column written *before* the run, and allow a
row to exist with `gate` filled and `result`/`verdict` empty. From the first N such rows the
project-level league becomes a two-line query. Retrofitting it to closed rows is not possible and
should not be attempted.

### Ran: the seat-level league, scored on stable profiles

The other half needs no pre-registration — only a packet with a key, which existed. Replaying 30
archived runs (5 seats x 2 instruction arms x 3 replicates) on the 10 context-free items of a
14-item packet, scoring each seat on its **stable profile** (right in every replicate / wrong in
every replicate / flipping) at the arm each seat runs by default:

| rank | seat | arm | stable-right | stable-wrong | flips | single-run acc |
|---:|---|---|---:|---:|---:|---:|
| 1 | Claude, structurally isolated | base | **7** | 1 | 2 | 76.7% |
| 2 | xAI seat | boost | 6 | 1 | 3 | 73.3% |
| 3 | Claude, in-session | base | 5 | 2 | 3 | 66.7% |
| 4 | OpenAI seat | base | 5 | **4** | 1 | 56.7% |
| 5 | Moonshot seat | boost | 4 | 3 | 3 | 53.3% |

Three things this bought that a single-run total could not:

- **The ordering is task-specific, and it inverts.** The OpenAI seat ranks 4th here on prediction
  while ranking **first by a factor of two** on blind originality (setup.md). Rank seats per task;
  a general "best seat" does not exist in this data.
- **The stable-wrong set is the seat's prior, not its noise** — and the sets barely overlap. Four
  items are stably wrong for the OpenAI seat, one for the top seat, and they are different items.
  That is what a lineage difference looks like when you stop averaging it away.
- **Panel floor zero, coverage 8/10.** No item is stably wrong for *every* default seat, and the
  union of the stable-right sets covers 8 of 10. Compare the effort sweep, where four items were
  missed by one seat at every effort level: the seats that rescue each other are in different
  families, which is the same result this skill keeps measuring from new directions.

⚠ Two caveats that bound the table. Five seats are only **four families** — the two Claude rows
share a lineage and differ by isolation, not by model — so weight by family, not by row. And the
packet was hand-**balanced** 7 WIN / 7 FAIL (5/5 on the clean subset); a balanced packet is the
right instrument for scoring seats and the wrong one for reading a project's base rate off, which
is the other reason the project-level half needs its own harvest.

## What to do with the result

- **Project-level:** a low hit rate is not embarrassing, it is a budget input. It says pre-registered
  optimism should be discounted by a known factor, and that cheap falsification beats careful
  planning at the margin.
- **Seat-level:** weight the best predictor's opinion when triaging a register — but only after
  checking it is not simply the seat with the best-matching prior, which the stable-wrong set reveals.
- **Never weight a vote by its own stated confidence.** Measured: seats differ by ~30 points in mean
  stated confidence on items they get right, so confidence is not comparable across families.

Machinery, if you are building this from scratch: a frozen packet file (pre-registrations only,
item order randomised), a key file, one raw answer file per seat per replicate, and a scorer that
reads the key and reports the stable profile rather than a total. That is the whole apparatus; the
seat-level half above was produced from exactly those four things.

## Cost, now that it has been run once

The seat-level half cost **zero model calls** — it is a replay of runs the panel had already
produced for another question, which is the argument for keeping a packet, a key and every raw
answer file rather than only the scored total. The project-level half costs one schema column and
then nothing.

⚠ **Keep the scorer's input path honest.** The re-score script for the archived runs pointed at a
directory that did not exist and died with a `ZeroDivisionError` on an empty run set — a scorer
that finds no runs must fail loudly with "0 runs parsed", never divide. Check that a replay script
still resolves its inputs before quoting anything it prints.
