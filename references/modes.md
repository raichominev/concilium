# Modes of multi-model use — shipped, proposed, and refuted

The concilium is not one workflow. A seat panel can be pointed at very different jobs, and the
discipline that makes one work destroys another: review mode's duty to refute is exactly what kills
an idea in forge mode. This page is the catalogue.

Every entry names what would prove or kill it, because several plausible modes on this page have
already been measured and are dead (bottom section).

## Shipped

| mode | question it answers | discipline | script |
|---|---|---|---|
| **Review** | is this claim true? | one seat probes and PROPOSES, orchestrator ratifies | `concilium-review*.{sh,ps1}` |
| **Loop** | is this *disputed* claim true? | fresh session per round, new evidence path each time, dry-stop | same + `PRIOR_ROUNDS` |
| **Forge** | what has nobody pointed at yet? | nobody judges anybody; shared register; originality scored | `concilium-forge.{sh,ps1}` |
| **Instrument audit** | could this measurement produce a number that is not an answer? | attacks the fixture, never the claim | `concilium-mode.sh instrument-audit` |
| **Fragment verify** | which PARTS of this survive? | atomise, rule per fragment, salvage the supported core | `concilium-mode.sh fragment-verify` |
| **Blind replication** | is this spec unambiguous? | two seats implement blind; the DIFF is the deliverable | `concilium-mode.sh blind-replication` |
| **Cross-examination** | what must be answered before anyone rules? | questions with probes attached; no verdict | `concilium-mode.sh cross-examination` |
| **Frame translation** | what does another field call this? | restate structurally, import method not metaphor | `concilium-mode.sh frame-translation` |
| **Selective escalation** | is the cheap seat enough? | gate on what tier 1 SAYS, escalate cross-family | `concilium-escalate.sh` |
| **Role rotation** | calibrated labels from N seats | each generates once, others adjudicate; union by lineage | `concilium-mode.sh role-rotation` |
| **Calibration league** | whose forecasts deserve weight? | replay a frozen packet; score stable profiles, not totals | `calibration-league.md` (half killed — read it) |

## Proposed — worth building, in rough order of expected value

### 1. Fragment verification — ✅ BUILT AND RUN
Verify *parts* of an answer rather than the whole. Published cross-model work reports that this
enables recovery of valid fragments from globally incorrect responses, which whole-answer selection
cannot do — and that cross-family generator/verifier pairs have measurably lower error correlation
(ρ ≈ 0.54) than within-family pairs (ρ ≈ 0.77). That is the same lineage effect this skill measured
three independent ways (effort, generation, repetition all resample one family's blind spots).
**Wiring:** split the reviewed claim into checkable atoms; route each to a cross-family seat; keep
per-fragment verdicts instead of one verdict. **Kill it if:** fragment verdicts never disagree with
the whole-answer verdict on a corpus of past reviews — then it is overhead.

### 2. Selective escalation — ✅ BUILT AND RUN (`concilium-escalate.sh`)

⚠ **Defect found on its first live run, now fixed — the lesson generalises.** The gate read only the
rest of the `CAVEAT:` line, but the seat printed `CAVEAT:` alone on one line with the text beneath
it. The gate saw an empty string, scored it "none", and **failed to escalate a run that plainly said
it had not verified half the claim**. Any gate that parses a seat's block output must read the
BLOCK, not the label's line. Verified against the real transcript after the fix.
Run the cheap seat first; escalate to a second family only where the margin is narrow or the seats
disagree. The tier machinery already exists (`-Mechanical`); what is missing is the *gate*.
**Wiring:** mechanical tier → if verdict confidence is high and nothing contradicts, stop; else
research tier, different family. **Kill it if:** the cheap seat's "confident" cases contain as many
errors as its uncertain ones — i.e. its confidence carries no signal, which is exactly what this
skill measured for one seat (codex mean stated confidence 99.7, effectively flat).

### 3. Role rotation for calibrated labels — ✅ CONTRACT BUILT (`role-rotation.md`)
N seats, N rounds; each round one seat generates and the other N−1 adjudicate, so every seat is the
generator exactly once. Published as a hallucination-detection design and reusable wherever you need
*labels* rather than a verdict. **Adopt with one modification:** that design aggregates by majority,
and the concilium's standing rule forbids settling anything by majority across chairs that share a
lineage. Rotate for coverage; aggregate by lineage-weighted union, not by count.

### 4. Blind replication — ✅ BUILT AND RUN
Two seats implement the same specification independently; the **diff is the deliverable**. Nothing
is voted on — where the implementations agree, the spec was unambiguous; where they diverge, the
spec was underspecified and that is the finding. **Cheap and underused:** it needs no gold, no
fixture, and no judge. **Kill it if:** divergences are dominated by style rather than semantics.

### 5. Instrument audit — ✅ BUILT AND RUN
A seat whose only job is to attack the *measurement*, never the claim: is this fixture saturated, is
this metric measuring the axis it names, is this packet answerable from the repo? This skill has now
lost three instruments in a row to exactly these failures (a retrieval-saturated packet, a
memorised-gotcha packet, a lemma-blind coverage metric), each caught only after the runs were spent.
An instrument audit costs one call before a 30-run batch. **Highest ratio of value to effort on this
page.**

### 6. Calibration league — ✅ RUN; HALF OF IT KILLED (`calibration-league.md`)
Score the *project's own forecasting*, not the seats'. **Run 2026-08-20 against a real 173-row
ledger, and it split.** The project-level half is **dead on that ledger**: 0 of 173 rows existed in
a registered-but-unmeasured state, only 5 carried threshold language in the pre-run column, and
only 2 of a 14-item packet's gates were readable from their ledger rows — the other 12 were
composed by an author who already knew the outcome. The predicted kill condition ("entries become
unanswerable once stripped") was the wrong hazard: **there was nothing to strip.** The seat-level
half *does* work with no pre-registration at all and cost zero calls, replaying 30 archived runs
into a stable-profile league whose ordering **inverts** the originality ranking below. Revival for
the dead half is one `gate` column written before the run; it cannot be retrofitted.

### 7. Cross-examination — ✅ BUILT AND RUN
Seat A must answer seat B's questions *before* either proposes a verdict. Distinct from debate: the
artifact is the question list, not the winner. Useful where the orchestrator suspects a claim is
underdetermined rather than wrong. **Watch for:** it degenerates into debate unless questions are
required to be answerable by a probe.

### 8. Frame translation — ✅ BUILT AND RUN
Ask a seat to restate the problem in another discipline's vocabulary before proposing anything.
Motivated by the forge's own result: round 1 (independent generation) produced convergence, while
round 2 (each seat reading the others) produced the *reframings* — a hidden confound, an ordering
constraint, an inversion of a whole approach. Reframing is where the value was; this mode targets it
directly instead of hoping for it.

### 9. (model, prompt) pair diversity
When a second vendor is unavailable, published practice builds the ensemble from (model, prompt)
pairs chosen for architectural spread. **Treat as a fallback, not an equal:** everything this skill
has measured says prompt variation within one family resamples that family's blind spots. Use it
when a cross-family seat is genuinely unavailable, and say so in the write-up.

## Refuted — do not rebuild these

- **Effort sweep as a pseudo-panel.** Six runs of one seat across five effort levels covered no more
  than two runs at the *same* effort; accuracy was not monotonic in effort while wall time grew 8×.
- **Generation sweep.** Two generations of one family, three replicates each, rescued nothing from
  each other; their stable blind spots were shared.
- **Instructed blindness.** A model carrying project context and told to answer "from the packet
  alone" measurably still uses that context. Blindness must be structural.
- **A judge LLM reading debate transcripts.** Published result: net gain can be *negative*, because
  when the majority errs from a shared bias the judge reproduces it. This is why the concilium
  ratifies by **re-running the load-bearing step**, never by reading the reviewer's prose.
- **Majority voting across same-lineage chairs.** Independent of the above: a published study of
  three heterogeneous agents found 2:1 divergences on 39% of questions, and in 25% of those the
  *minority* was right. Keep dissent with its evidence attached.

## Sources for the published claims above

Cross-model fragment verification and the ρ correlation gap: [Beyond Self-Checking: Fragment-Level
Verification Across Diverse LLMs](https://openreview.net/forum?id=U19s6I8Q0u). Role rotation:
[MSA at SemEval-2025 Task 3](https://arxiv.org/pdf/2505.20880). Debate ≈ voting, and diversity as the
dominant driver: [Debate or Vote](https://arxiv.org/html/2508.17536v1) and [Can LLM Agents Really
Debate?](https://arxiv.org/abs/2511.07784). Minority-correct rates and the negative-gain judge:
[Minority Sentinel](https://arxiv.org/pdf/2606.29270). Selective escalation to a formal checker:
[FregeLogic at SemEval 2026 Task 11](https://arxiv.org/pdf/2604.18328).

⚠ Several are workshop papers or system descriptions rather than replicated results, and the ρ
figures come from a single study. Treat them as design leads to validate locally — the same standard
this skill applies to its own measurements.


## Measured outcomes of the modes built on 2026-08-19

- **Instrument audit** paid for itself on first use: pointed at a forge brief, both seats refused it
  (`DO-NOT-RUN` / `FIX-FIRST`) and named the defect — the brief was a fill-in task whose cells are
  textbook method, with an undefined originality metric. One call prevented a 20-call batch of
  restatements. **Highest value-per-call mode in the set.**
- **Fragment verify** found three real defects in an already-published internal write-up: a
  population mismatch between two headline figures, an over-generalised "at any floor", and a
  refutation that did not follow from its own statistic. The SALVAGE block reconstructed the claim
  that the supported fragments actually sustain.
- **Blind replication** on a normalisation spec: 0/12 disagreements on equality judgements, but the
  two implementations produced *different canonical strings* (fine for comparison, fatal if the value
  is ever a database key), and both failed the same real-world pairs the spec did not cover. It also
  surfaced a genuine spec defect — a character range that excluded the very mark the spec called
  decorative, so a literal implementation keeps the mark the spec calls ignorable.
  ⚠ **The 0/12 undersells it, and re-running the two implementations shows why** (2026-08-20). The
  agreement holds on the twelve pairs that were tried and across 20,000 fuzzed pairs from the spec's
  own alphabet — but one seat's implementation **violates a numbered spec requirement**: it is not
  idempotent, because it strips the bracketed suffix *before* removing combining marks, so
  `lemma[encl]` followed by an accent needs two passes to converge. That same input is a real
  equality disagreement between the two seats. The other seat had **predicted the divergence in its
  EDGE-CASES block** without ever seeing its rival's code, which is the mode working exactly as
  designed. Lesson for the mode: **diff the implementations mechanically, do not stop at a pass
  count** — and keep the comparison harness, because this one was never saved and had to be rebuilt
  from the two extracted functions.
- **Frame translation** produced the single most useful sentence of its session by restating the
  problem as a sampling-design constraint, which an independent seat then reached from survey
  statistics — cross-mode convergence.
- **Cross-examination**, **selective escalation** and **role rotation** are built; escalation's gate
  deliberately ignores stated confidence, because measured confidence is not comparable across seats.
- **The escalation gate's block-vs-line defect had a second instance, found by replay** (2026-08-20).
  The `CAVEAT` read was fixed after the first live run; the `[C]` verdict test was left as a
  same-line grep — and in the very transcript that produced the original fix, the verdict tag also
  sits on the line *after* its label, so a `[C]` verdict would have been invisible. Both now go
  through one `read_block` helper. **When you fix a parser defect, grep for every other place that
  parses the same shape**; a lesson written into a doc is not a fix applied to the code.
- **Mode runs are not block-checked at all.** The review wrappers count five contract blocks before
  returning; the generic mode driver counts nothing, so a mode can return prose and look successful.
  Any checker added there must match blocks **unanchored**: one seat's transport concatenates its
  streaming preamble onto the first block with no newline (`…summary alone.LABELS:`), so a
  line-anchored `^BLOCK:` test reports the first block missing on output that is in fact complete.
