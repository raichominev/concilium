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
| ↳ *grounding* | does handing over the repo anchor the seats? | **measured 2026-08-23: null at panel level, reproducible PER SEAT** — see `forge-mode.md` §Blindness | |
| **Brainstorming** | crazy ideas against a system whose conventional methods are exhausted | OPEN-BOOK forge inversion: a live read-only copy of the system per seat (data and/or source, if applicable), volume quota, evidence replayed; ideas flow to human-reviewed dossiers through peer-comment/build rounds, never through orchestrator curation | [`brainstorming-mode.md`](brainstorming-mode.md) — formed 2026-08-24 from one full 8-seat campaign, every claim evidence-tiered |
| **Instrument audit** | could this measurement produce a number that is not an answer? | attacks the fixture, never the claim | `concilium-mode.sh instrument-audit` |
| **Fragment verify** | which PARTS of this survive? | atomise, rule per fragment, salvage the supported core | `concilium-mode.sh fragment-verify` |
| **Blind replication** | is this spec unambiguous? | two seats implement blind; the DIFF is the deliverable | `concilium-mode.sh blind-replication` |
| **Cross-examination** | what must be answered before anyone rules? | questions with probes attached; no verdict | `concilium-mode.sh cross-examination` |
| **Frame translation** | what does another field call this? | restate structurally, import method not metaphor | `concilium-mode.sh frame-translation` |
| **Selective escalation** | is the cheap seat enough? | gate on what tier 1 SAYS, escalate cross-family | `concilium-escalate.sh` |
| **Role rotation** | calibrated labels from N seats | each generates once, others adjudicate; union by lineage | `concilium-mode.sh role-rotation` |
| **Calibration league** | whose forecasts deserve weight? | replay a frozen packet; score stable profiles, not totals | `calibration-league.md` (half killed — read it) |

## A research session does NOT implement — plan the implementation sessions up front

**Added 2026-08-23, owner-directed. His words: *"the intermix of changes and the continuation of
research in one session is overwhelming."*** He is right, and the failure is structural rather than
a matter of discipline: a panel round produces findings *faster than one session can act on them*,
so the acting crowds out the research, and neither is done well.

**The rule.** The session that runs a panel round stays on research: it briefs the seats, runs them,
verifies the artifacts, writes the synthesis, and stops. **It does not fix what the round found.**

**Plan the implementation sessions as part of the round, not as an afterthought.** Before reporting,
partition the synthesis into work packages and spawn one session per package. Always plan at least
one; there is usually more than one, because findings cluster by subsystem and by who must approve
them. Good partition lines, in order of usefulness:

- **by subsystem**, so two sessions never edit the same files;
- **by approval class** — a data-integrity fix is a session's to make, an analyzer change (a floor,
  an arm default, a cap) needs the owner and a measured before/after ledger row, so those must not
  share a session;
- **by dependency**, when one fix changes what another can even measure.

**Tell each implementation session it may spawn further sessions itself.** A package that turns out
to be three packages should split rather than sprawl, and the session doing the work is better placed
to see that than the one that wrote the brief.

**What the research session hands each implementation session:** the verified measurement, not the
seat's phrasing; the cause where it is known; the hazards that apply (in this project: never run the
harvest+generate-paradigms pair as housekeeping, never change an analyzer default without owner
approval, only gold is ground truth); and what is explicitly out of scope. A finding handed over as a
quote rather than as a verified measurement will be re-investigated from scratch.

⚠ **Where verification lives (owner-directed, 2026-08-24).** Split it by what it touches:

- **Fixture-side sanity stays with the research session**: does the finding reproduce on the data
  the seats were actually given? This is cheap, read-only, and catches fixture artifacts — at least
  one convergent, three-vendor finding in this project was an artifact of a stale snapshot, and
  handing that downstream would have spent a whole session on a non-problem.
- **Verification AGAINST LIVE SYSTEMS is implementation-session work, always.** When a finding
  needs checking against the live database, the current source tree, or anything another session
  may be mutating, the research session spawns the implementation session and hands it the claim —
  it does not run the live check itself "just this once". The reasons are the same ones behind the
  no-implementing rule: the live side is where other sessions work (collision risk), a live check
  routinely grows into a diagnosis and then a fix (scope creep is the observed failure, not a
  hypothetical), and the research session's fixture-based framing is exactly the wrong lens for
  live state.

## IDEAS are never synthesised by the orchestrator — dossiers, peer comments, human review

**Added 2026-08-23, owner-directed, and it OVERRIDES the synthesis rule below for the idea half of
any generating round.** His words: *"By applying the current method (the orchestrator synthesizes)
you are destroying the possibility to build over the craziness. This implies that you have the best
view and you don't. Actually nobody does. This is a shot in the dark."*

The synthesis rule below applies to **findings and claims** — checkable statements about data, where
convergence and contradiction are the signal. It does **not** apply to ideas. On a
shot-in-the-dark research question, curation is destruction: every ranking the orchestrator imposes
encodes the orchestrator's priors over a space where nobody's priors are informative, and the tail
it cuts is the part the round existed to produce.

**The idea pipeline instead:**

1. **Raw first.** Every idea, verbatim, in the authors' own words. This document is the deliverable,
   not an appendix.
2. **Mechanical curation only, and it is conservative by construction:**
   - *Dedup that GROUPS but never merges.* Near-identical ideas are clustered; every member's own
     wording is preserved (a sentence or two each). Whether two ideas are "really duplicates or
     still keep a variation" is treated as a hard question — when in doubt, do not group.
   - *Filter only ideas premised on issues already resolved or ruled out*, each with its id and a
     one-line reason, in a visible FILTERED list the human can veto.
3. **Peer-comment rounds.** Each seat receives ALL other seats' ideas (its own marked and excluded
   from commenting) and comments on each — constructively: what would make it work, what it
   combines with, the sharpest risk, a better cheapest-test. **No verdicts, no scores, no votes.**
   Comments are appended to each idea's dossier.
4. **The human reviews the dossiers.** Not a shortlist. Not a top-N.
5. **Iterate 2–3×**, each round feeding every seat everything said so far — the point of giving all
   ideas at once is to trigger inter-idea signals inside each model, and that only happens if
   nothing was cut on the way.

**Why craziness is the point, in the owner's framing:** when a system has hit the same wall many
times, conventional methods are exhausted by definition — every "reasonable" idea has been had. The
human experts succeed at scale because the data is systematic, not because of magic; their
irreplaceable expertise covers only the hardest few percent. So the automation headroom is real,
nobody knows where the door is, and a panel's value is the width of its search, which curation
narrows at exactly the wrong moment.

## Every multi-seat round ends in a SYNTHESIS — this is not optional

**Added 2026-08-23, owner-directed, after it was identified as the process's weak point.**

A multi-seat round produces a pile of per-seat outputs. The pile is not the deliverable. Whoever ran
the round must write **one synthesis document** before reporting, structured by *how many independent
seats reached each claim*:

1. **CONVERGENT** — reached by ≥2 seats independently, with the seat names and each one's own
   measurement. Convergence raises priority; it does not establish truth (see the warning below).
2. **DISAGREEMENTS** — where seats contradict each other, stated as a contradiction and left open
   if unresolved. **This section is the most valuable one and the one that gets skipped.**
3. **SINGLE-SEAT** — unreplicated leads, marked as such.
4. **RETRACTED / RESOLVED** — claims that died, and why.

⚠ **Why the disagreement section is mandatory.** On the round that produced this rule, four seats
made incompatible statements about where a system's error actually lived — one reporting a metric at
96.7% and another reporting the opposite conclusion from a different denominator. **Nothing in the
round surfaced it.** It was found only when a synthesis was written by hand afterwards, and it turned
out to be the single most important open question the panel had produced. A panel that is never asked
to disagree with itself reports its agreements and buries its contradictions.

⚠ **Convergence measures shared INPUT as readily as shared insight.** In the same round, three seats
across three vendors independently reached the same confident headline, which was an artifact of all
of them reading a fixture two days older than a schema change. Always record what the seats had in
common. Cross-model agreement on a shared corpus is evidence about the corpus.

**Practical note:** the cheapest way to surface a disagreement is to look for two seats quoting
different denominators for the same quantity — that is what D1 turned out to be. Ask of every
convergent-looking pair: *are these two numbers over the same population?*

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

## Measured — the ALT amendment (proposed 2026-08-20, run 2026-08-22)

**Outcome first: the pre-registered primary metric was vacuous by construction, and the
pre-registered confabulation watch-item fired.** The amendment stayed in the contract, but for a
different reason than it was proposed for, and with a quote requirement bolted on. What follows is
the original design, kept because the way it failed is the finding. Jump to **What it actually
measured** at the end for the result.

Review mode's `ALT` block was changed from "one alternative causal explanation you considered" to
**the strongest rival you rejected, plus the single observation that separated it from your
conclusion** — with an explicit "nothing separated them" answer that caps the verdict at `[C]`.
Ratification gained a matching step. Prompted by external feedback that the round preserves the
ingredients of a disagreement but never elevates the strongest rejected reading into the final
artifact; the feedback was right, and the defect is sharper than stated: ALT was **unranked and
unlinked**, so a reviewer optimising for a clean verdict was quietly rewarded for picking a weak
rival, and nothing obliged the verdict to reference it.

**Why it should work, from measured data rather than intuition.** Chairs over-refute: on the
18-claim adjudication packet, refuted-recall runs 7/10 while upheld-recall is 4–6 of 8, and some
true claims are refuted by every chair independently. So on an `[X]` proposal the rejected
alternative is disproportionately likely to be the correct one. One claim on that packet was
refuted by all three original chairs and recovered only when two further families were added —
three near-miss records would have flagged it **without** buying two more lineages, which is the
expensive remedy this is meant to substitute for.

**The falsification design**, using the harness that already exists:

- Instrument: the 18-claim adjudication packet (ground truth established by executing each claim).
  ⚠ Do not confuse it with the saturated language-gotcha packet whose A/B was a null result — this
  one produces real errors (upheld-recall 4–6 of 8), so it has measurement capacity.
- Arms: current contract vs amended contract, one paragraph different. 3 seats x 3 replicates x
  2 arms = 18 runs.
- **Primary metric — recoverable-by-ALT rate:** on items the chair *wrongly refutes*, does ALT
  contain the true reading? Compare against the same rate on items it *correctly* refutes.
- **Kill it if:** those two rates are equal. Then ALT carries no signal about which refutations are
  wrong, and the block is overhead on every future round.
- **Watch for confabulation:** asking for "the strongest rival" invites inventing an impressive
  one. The discriminator requirement is the detector — an invented rival has no observation behind
  it, so count the rounds whose separation is argued rather than observed. If that share is large,
  the amendment is manufacturing prose, not preserving disagreement.
- Secondary: verdict accuracy should move *little*. This is a disclosure change, not a reasoning
  change; a large accuracy swing would mean the paragraph is acting as a criterion knob (see
  `reasoning-boost.md`) and would need separating from the disclosure effect.

### What it actually measured

**The primary metric could never have discriminated.** On a `REFUTED` verdict the strongest rejected
rival *is definitionally the claim under review*, so "does ALT contain the true reading on wrongly
refuted items?" is true almost by construction — and the control set confirms it: correctly-refuted
ALTs say the same kind of thing as wrongly-refuted ones ("the payoff could be real", "would yield
some local gains"). The kill condition was met and the metric is reported as a negative result. The
lesson generalises past this mode: **a metric can be pre-registered and still be untestable, and the
only way to find out is to build the control set.**

**The confabulation watch-item fired, in the opposite direction from the one assumed.** The
amendment was designed on the premise that a discriminator would be *missing* when the reviewer had
merely preferred. It is not missing — it is confidently present and sometimes invented:

- **The honest escape hatch was never taken.** `NOTHING-SEPARATED-THEM` was made cheap and
  explicitly non-penalised, and across the full corpus it was used **1 time in 315 refutations**
  (0.3%), against 6.1% on upholds. Asking "what separated them?" reliably produces an answer whether
  or not one exists. Quote it as 1/315, never as zero.
- **Some manufactured discriminators are fabricated experimental results.** Two chairs cited
  post-hoc measurements that appear nowhere in their closed-book input — "after enabling, zero X
  were written" — and used them to refute claims that were **true**. A third, subtler pattern is
  more common still: a true system fact aimed at the wrong object.

**The fix that followed, and what is still open.** `contract.md` now requires the separating
observation to be **quoted** — a file:line, a line of output, a query result — precisely so an
invented one has nowhere to hide. That requirement is itself unmeasured. Two ALT rewordings have now
failed to recover wrongly-refuted claims, which points at a design-level answer rather than another
rewording: a **first-class abstain verdict**, structured the way role rotation's `CANNOT-TELL` is.
Treat the amendment as retained-and-narrowed, not vindicated.

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

- **Giving a review seat the repository of the project whose claims it is reviewing** (measured
  2026-08-23, and the reason generalises). The intuition is that access converts deduction into
  checking. What it actually converts it into is *retrieval*: a project's repository is its
  experiment ledger's downstream artifact, so "is the proposed mechanism shipped and enabled?" and
  "did the claim hold?" are the same question asked twice. On an 18-claim packet whose ground truth
  was established by execution, that one-grep heuristic scores **83.3%** against seats measured at
  **70.8%** on the identical packet — and **3/4** on the four items every seat gets wrong, where the
  seats manage 19%. The answers sit in identifiers, defaults and **test function names**
  (`test_jotated_iti_past_active_doublet` settles one of them outright).
  **Sanitisation does not rescue it, on either horn.** Stripping comments and docstrings leaves
  prose inside string literals that are part of live data structures, and no strip touches an
  identifier without destroying the artifact under review. Checking out the tree from *before* the
  experiments removes the leak completely — and removes the substrate with it: the config module
  the claims are about does not exist yet, and 13 of 18 claims become unanswerable. **Clean or
  checkable, never both.**
  **What to do instead:** use a codebase the project has never published claims about, so the repo
  is evidence rather than ledger. **And before spending a batch, run the heuristic yourself** — if
  "is it in the code?" predicts your key, the arm is measuring retrieval and the runs are wasted.

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
