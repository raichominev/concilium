# Benchmarks and measured results

This page contains Concilium's benchmark procedures and measured results. First-time installation,
authentication and the calibration bootstrap remain in [`setup.md`](setup.md).

## Choosing tier models: the head-to-head method

When unsure which model gets a tier (e.g. new mid-tier vs old flagship):

1. Pick 3 known-truth tasks: one pure-reasoning (use the known-truth trace in
   [`setup.md`](setup.md)), one real DB/code claim with
   a subtlety you've already resolved, one schema/namespace trap you've been bitten by.
2. Run both candidates on all three at the same effort, in parallel background batches, same
   prompts (use the wrapper so the contract is identical). Capture tokens + wall time.
3. **Ratify before grading**: when the candidates disagree on facts, run the deciding query
   yourself — both can be right at different scopes, and your own notes may be the wrong ones.
4. Grade on: correctness, completeness under ambiguity (did it answer the hard half or punt?),
   verdict framing, cost. 3 tasks detects gross differences only — say so in the writeup, and
   don't dress a tie up as a winner. Ties break toward cheaper/newer.

## Benchmarking orchestrator / panel chairs on your project

The head-to-head above picks GPT-side tier models; the same philosophy scales to choosing the
orchestrator seat — or a whole panel — with your own project as the benchmark:

1. Harvest your experiment log: every measured change with a recorded outcome becomes one item.
   Rewrite each as its pre-registration (change, fixture, metric, gate), outcome stripped;
   chairs predict WIN / NEUTRAL / FAIL + confidence, strict JSON. **The outcome must not be
   recoverable from the repo** — if a chair can grep its way to the answer the packet measures
   retrieval, which is saturated, and every seat scores 100% (measured three times; see the Kimi
   section below). Uncertain-outcome prediction is the whole point.
2. Run every candidate chair CLEAN-CONTEXT (pitfall #16 — structural isolation, headless, tools
   off) on the identical packet. **Three runs per chair, minimum.** One run is not a measurement:
   measured spreads reach 4 points on a 14-item packet *within a single seat at identical
   settings*, which is larger than most between-seat differences you will be tempted to act on.
3. Score on the STABLE profile — items a chair gets right in every replicate, wrong in every
   replicate, and the ones that flip — not on a single run's total. Then take PAIRWISE ERROR
   OVERLAP over the stable-wrong sets: two chairs that stably miss the same items add less than
   their solo accuracies suggest. Seat by PANEL COVERAGE, not by solo rank, and treat a seat's
   spread as a property in its own right — the highest single score measured came from one of the
   least stable seats.
4. Expect same-lineage chairs to correlate (pitfall #16's paired rerun also exposed a shared
   wrong inference produced independently); the cross-lineage seat usually rescues items the
   family jointly misses. That measured panel math — not model cards — is what seated Opus 5
   as the second orchestrator in v1.2.

## Measured: adding a third model family (Kimi, EXPERIMENTAL) — 2026-08-06/07

Environment: Kimi Desktop 3.1.5 / daimon-bundle 0.5.49, `k3-agent`, against `gpt-5.6-sol` and a
clean-context Claude Opus 5 seat. Every item's ground truth was established independently before
grading. Two instrument designs were tried; only the second measures anything.

**Calibration ([bootstrap steps 1–2](setup.md#calibration-bootstrap-do-this-before-trusting-verdicts-in-a-new-environment)).** Both reviewer seats passed the known-truth reasoning trace
and two real review claims, reaching identical verdict tags with line citations that survived
spot-checking; the Kimi seat ran ~1.5–2× slower at comparable quality. The cross-family value
appeared in the CAVEAT rather than the verdict: on one review the third seat flagged stale
documentation that both the other reviewer and the orchestrator had missed. One instance is not
a rate, but it is the failure mode a third seat exists for.

**What does NOT work: fact-retrieval packets.** Three packets (8, 16 and 12 items) asking chairs
to judge TRUE/FALSE claims about a codebase they could read produced **108 answers, zero errors,
100% valid citations** across all three seats. Every pairwise both-miss set was empty, so measured
coverage was 100% for every pair *and every single seat* — the marginal value of a second or third
chair came out at exactly zero. That is a statement about the instrument, not the seats.
Harder-in-kind did not help: a packet requiring counting, ordering, and spotting an argument
present in one code branch but absent from its identically-named twin was also answered perfectly.
Nor did traps where an always-loaded summary file contradicts the detail doc (pitfall #17's
failure mode) — every seat went to the detail doc. **Any claim whose truth is written down
somewhere in the tree is a retrieval task, and frontier models are saturated at retrieval.** Do
not re-run this genre hoping for separation; it was tried three times.

**What works: outcome prediction.** Harvest a real experiment log, re-issue each entry as its
pre-registration (change + metric + baseline), strip the recorded outcome, and have chairs predict
WIN/FAIL. A log's numbers are usually quoted across many other documents and version-control
objects, so stripping the repo is hopeless — instead give chairs a purpose-built directory holding
only what they need, grep-verified to contain no result tokens, and watch the log for reads
(pitfall #21). Two packets were built this way, of 12 and 14 sound items.

**⚠ One run per seat cannot rank seats — measure the noise floor first.** Repeating the 14-item
packet three times per seat, at identical settings, gave a **spread of up to 4 points inside a
single seat**: one scored 8/4/6 across its three runs. Any single-run comparison of two seats a
point or two apart is reading sampling noise. Earlier versions of this section quoted exactly such
numbers, and pairwise-coverage claims built on them did not survive replication.

The durable unit is the **stable profile**: which items a seat gets right in *every* replicate,
wrong in *every* replicate, and which flip. Twelve runs, four seats, three replicates each:

| seat | scores | spread | stable-correct | stable-wrong | flips |
|---|---|---|---|---|---|
| A (family 1, older gen) | 8, 4, 6 | 4 | 3 | 5 | 6 |
| B (family 1, newer gen) | 7, 7, 5 | 2 | 5 | 6 | 3 |
| C (family 2) | 11, 8, 7 | 4 | 7 | 3 | 4 |
| D (family 3) | 9, 8, 8 | **1** | **8** | 5 | **1** |

Stability is itself a seat property worth knowing, and it does not track accuracy: the highest
single score (11) came from a seat with a 4-point spread, while the most consistent seat never
moved more than a point. A seat that swings 4 points needs replicates before you believe any
number from it.

**A model generation is not a second seat.** Seats A and B are the same family, one generation
apart. Their stable blind spots overlap on four items and **neither rescues a single item the
other stably misses** — in either direction. Cross-*family* seats do rescue items from both. So
generation behaves like reasoning effort: it resamples the same blind spots
rather than moving them. **Only a different lineage moves them** — that is now three independent
measurements pointing the same way (effort, repetition, generation). ⚠ **Measured once, so not a
law**: a later generation pair in the same family (Fable 5 → Fable 5.1, 2026-09-07, adjudication
packet) *did* move the blind spots — the two overlap less with each other (0.40) than Fable 5
overlaps its own runs a month apart (0.63). Read the section for 2026-09-07 below before quoting
this paragraph as "a generation is never a second seat".

Scored on stable profiles rather than single runs, the four-seat panel leaves exactly **one item
stably wrong for every seat**. That item is the one where a mechanism is obviously sound and every
model assumes the metric must therefore move; it does not. Worth knowing that such items exist:
they are invisible to a panel, however many lineages you add.

Three things worth stealing from the failures:

- **Exclude any item whose recorded outcome the log itself attributes to noise.** Grading a chair
  against an outlier the author already called unrepeatable measures variance, not judgement.
- **Ship every file a chair needs to answer.** One item was unanswerable because the relevant
  module was left out of the sandbox; all three "failed" it while reasoning correctly from the
  evidence they had. Both of run A's apparent shared blind spots turned out to be defective items
  — check your instrument before you report a blind spot.
- **Randomise item order.** A first draft had every true-WIN item first; position must carry no
  signal.

Direction of error is **mode-dependent**: in adversarial *adjudication* chairs over-refute (they
reject true claims), while in outcome *prediction* the same models were over-credulous — 61%
correct on changes that worked versus 46% on changes that failed. Never carry a bias correction
from one mode into the other.

⚠ **It is lineage-dependent too** (2026-08-19). The xAI seat, measured on the same packet in an
isolated guest, errs the *other* way in prediction mode — 14 FAIL-on-a-WIN against 7
WIN-on-a-FAIL. So the mode rule above describes the three families measured in 2026-08-07, not
models in general: re-measure the direction per seat before correcting for it.

**Calibration**: on items every seat got right, mean stated confidence was codex 99.7 (96–100,
effectively flat), Kimi 95.1 (80–99), Claude 93.9 (90–97). Codex is least willing to express
doubt, Kimi most — relevant when weighing a lone dissenter, and one more reason never to weight a
vote by its own stated confidence.

**Reliability**: 0/2 Kimi wrapper runs completed with rule auto-bridging on, which is why that
wrapper defaults bridging OFF. With bridging off it is better but not reliable (pitfalls #18).
Never trust its exit code.

## Measured: a "be inventive / take a strong position" instruction is a criterion knob (2026-08-19)

Five seats (Claude in-session, Claude blind, codex, grok, kimi) × 2 arms × 3 replicates = 30 runs on
the same 14-item packet, differing by one inserted "HOW TO REASON" paragraph telling the chair to
hunt non-obvious connections, be inventive and specific, and take the strong position because a
hedge scores the same as a miss.

Pooled on the 10 items no project note answers: accuracy 60.7% → 65.3% (**95% CI over items
[−3.3, +14.7] — includes zero, so not proven**), but hit rate fell only 70.7% → 66.7% while **false
alarms fell 49.3% → 36.0%**, moving d′ 0.56 → 0.79 and the criterion toward FAIL in 4 of 5 seats.

**Read it as a skepticism knob, not a reasoning upgrade**, and apply it per seat rather than
panel-wide: it gained +10 to +13 points for the seats that over-called WIN (kimi FA 93%→67%, grok
FA 33%→7%) and *cost* points for the two that were already discriminating (blind Claude −3.4 with d′
1.54→1.25; codex −6.7 with d′ 0.34→0.00). The origin project keeps the per-seat table and the 30
raw run files in its own docs.

⚠ That experiment also measured what a Claude subagent's own system prompt costs a blind round: an
in-session chair inherits the project's CLAUDE.md and memory, which stated 4 of the 14 answers
outright, and scored 76.2% against the same family's 57.1% in an isolated guest. **A subagent of the
project under study is not a blind seat**, no matter what the prompt says (pitfall #16/#17).

⚠ **The matching ADJUDICATION A/B is a null result on a saturated packet — do not quote it as
"the boost is safe for reviews".** 14 self-contained claims (7 true / 7 false, ground truth
established by executing each one), 19 runs across codex, kimi and blind Claude: **266 decisions,
zero errors in either arm**. It rules out over-refutation on *unambiguous* claims and nothing more.
The cause is the fact-retrieval saturation result above wearing a second costume: the items were classic language
gotchas, which are **memorized facts, not derivations** — self-contained is not the same property as
unsaturated. A packet that could measure this needs claims computed from invented data, plus
true-but-surprising claims to bait refutation.

## Measured: back-filling two later seats onto the frozen chair packets (2026-08-20)

The Moonshot and xAI seats were adopted after the original chair benchmarks, so they were re-run on
the **same frozen packets and keys**, three replicates each, in an isolated guest holding the packet
and nothing else. Two results matter more than the scores.

**Replication dissolved both published rankings.** On the 39-item prediction packet the xAI seat
scored 31 / 27 / 33 at identical settings — a **6-item, 15.4 pp spread**, covering three quarters of
the range the original four-chair ranking (64.1–84.6%) was reporting as differences *between*
models, where the top three sat inside a 1–2 item gap measured once each. On the 18-item
adjudication packet the Moonshot seat scored 12 / 13 / 10 against an original between-chair result
of 66.7 / 66.7 / 61.1 — a one-item gap inside a three-item noise band. Neither ranking was wrong; both
were **unresolvable**, and a single-run table cannot show you that. Replicate before you rank.

**Panel width buys real but partial coverage.** Of the items every original chair got wrong:
adjudication CLAIM-14 was **rescued** by both new families (kimi 3/3, grok 2/3) while CLAIM-16
stayed wrong for **all five** (and for eight vendors by 2026-08-23 — then a new-generation seat
answered it 6/6 on 2026-09-07; see that section); on prediction, ITEM-04 and ITEM-05 — already characterised as generic
evidence-breadth priors — stayed wrong for all five. Some joint failures are lineage artifacts a new
family fixes for free; others are shared priors that panel width will never touch.

⚠ **Error overlap tracks skill as well as lineage.** With six chairs on one packet the highest
overlap is still the same-family pair (0.62) and the lowest a cross-family one (0.18), but two
*cross*-family pairs land at 0.50–0.57 — all involving the weakest chairs, which fail together on
merely-hard items. Restricted to the four chairs scoring 31–33/39, same-family 0.62 vs cross-family
mean 0.29: the effect survives at ~2x, not the ~3x an uncontrolled reading gives. **Different vendor
does not imply decorrelated** — the two newest seats overlap each other (0.50) more than either
overlaps the codex seat.

**Operational note:** 3 of the 12 runs failed and none reported it — two truncated the 39-item JSON
mid-object (at items 36 and 38), and one returned `"subtype":"success","is_error":false` with an
**empty** result after 30k generated output tokens. Check the artifact — parse it and count the
items against what the packet asked for. A packet whose answer nears the output ceiling is also
*biased*, because truncation always eats the last items.

## Measured: blind originality ranking of the seats (2026-08-19)

51 ideas pooled from a 2-round forge across four seats, seat labels stripped, ids neutralised and
shuffled by content hash, then ranked by five rankers. **Self-ratings AND same-family ratings were
dropped**, so no seat scored its own or its sibling's ideas. Score = weighted top-12 placements per
idea contributed.

| seat | items | pts/item |
|---|---:|---:|
| codex (gpt-5.6-sol) | 12 | **11.17** |
| claude-opus (guest) | 12 | 5.83 |
| kimi (k3) | 13 | 5.00 |
| grok (cursor-grok-4.6-xhigh) | 14 | **1.43** |

Three things this measured that the orchestrator's own qualitative read got WRONG:
- **grok ranked last on originality**, and four of five rankers flagged three of its ideas as plain
  restatements of the frozen known-methods list. The orchestrator had rated it mid-pack, conflating
  *executability* (grok writes by far the most runnable tests) with *originality*.
- codex's lead is larger than any impression suggested — roughly 2x the next seat.
- claude-opus vs kimi is a coin flip; do not rank them from a single round.

**But the ranking does not predict chaining.** In the following round, where seats were told to
combine ORPHANED ideas rather than generate new ones, **grok — last on solo originality — produced
the best chains**, fusing two ideas that were each only a critique into a single instrument. Rank
seats per task, not once.

Reproducing this needs four things and nothing else: the pooled ideas with seat labels stripped and
ids shuffled by content hash, an author key held back, one ranking prompt per ranker, and a scorer
that drops self- **and** same-family ratings before counting.

## Measured: effort is not a substitute for a second family (2026-08-07)

The tempting cheap move is to run one seat at several reasoning efforts and treat the spread as a
panel. Measured, with the control that idea needs: six runs of `gpt-5.6-sol` over one 14-item
prediction packet — low, medium, high, xhigh, max, **plus a second run at high as the noise
floor**.

| | low | medium | high | high (replicate) | xhigh | max |
|---|---|---|---|---|---|---|
| correct | 7/14 | 7/14 | 9/14 | 8/14 | 7/14 | 9/14 |
| wall | 21s | 27s | 99s | 99s | 124s | 166s |

- Two runs at the **same** effort covered 10/14. Cross-effort pairs averaged **8.9** and never beat
  that. The full six-run ensemble also reached only 10/14 — equal to the two-run noise floor, and
  equal to a single cross-family pair.
- Accuracy is **not monotonic** in effort: `xhigh` scored with the cheap tiers while wall time grew
  8× from low to max.
- Four items were missed by **every run at every effort**; the cross-family seat got two of them.

**Varying effort resamples the same blind spots; a different lineage moves them.** If you want
coverage, add a family, not compute. If you want a cheap variance estimate, just run the same seat
twice — that is what an effort spread is actually measuring.

## Measured: a new-generation seat broke the panel's ceiling, and how the score was checked (2026-09-07)

Two models released in the first week of September 2026 were run on the frozen 18-claim
adjudication packet behind the eight-seat calibration table, under the same protocol: fresh empty
working directory outside every instruction-file ancestry, packet on stdin, closed book, tools off
for the Claude seat and a read-only sandbox for the codex seat, three runs on the base packet and
three on the treat packet. Two same-day controls ran beside them: the previous codex flagship at
max effort and Fable 5 at default effort, three base runs each. Base refute rate 55.6%.

| seat | runs | accuracy | refute rate | recognises TRUE claims | the four universal blind spots |
|---|---:|---:|---:|---:|---:|
| gpt-6-astra, max | 6 | **88.9%** | **57.4%** | **85.4%** | **22/24** |
| gpt-5.6-sol, max (control) | 3 | 70.4% | 48.1% | 75.0% | 3/12 |
| Fable 5, default (control) | 3 | 68.5% | 50.0% | 70.8% | 4/12 |
| Fable 5, archived August runs | 6 | 69.4% | 56.5% | 64.6% | 7/24 |
| Fable 5.1, default | 6 | 64.8% | 74.1% | 39.6% | 6/24 |

**A new ceiling.** The previous seven-seat band was 68.5–73.5%. Astra's six runs scored 17, 17,
16, 15, 14, 17 (spread 3), it has no stable-wrong item, and its error sets overlap every other
seat's at 0.13 or less. Its one recurring miss is a structural claim phrased as an absolute
("cannot change the output"), which it refutes on the ground that another mechanism could in
principle do the job — right in 2 of 6 runs. The controls landed inside the old band, so the
harness did not inflate anything.

**The "universal blind spots" were a property of the models, not of the claims.** Four items were
failed by every vendor measured (≥60% error across eight vendors), and the earlier reading was that
panel width cannot fix them because they are item properties. Astra answers them 22 of 24 times,
closed-book, with moderate confidence (0.60–0.68 on the hardest). "Adding another vendor from that
set cannot fix them" stays true; "no seat can" is refuted. The remedy for a blind spot is still
ground truth — but the ceiling was the panel's, not the packet's.

**How the score was checked before it was believed** (pitfall #26 fires on a 17/18, and the packet
key is public on the web): (1) every transcript shows the prompt, then the answer, and no tool call
between them; (2) an NTFS access-time tripwire over the origin project's document tree was clean
during the runs — the only accesses were the scorer's own reads, and a copy made by hand during the
window registered, which proves the tripwire was live; (3) a recognition probe (name the project
and repository, quote the recorded figures behind three claims, list the claims later upheld)
returned UNKNOWN five times, which is weak evidence on its own; (4) a **perturbation test**: the
supporting evidence of five claims was edited so that the correct verdict flips, and astra followed
the text on 5 of 5 at confidence 0.90–0.99, quoting the edited evidence, with 10 of 13 unperturbed
verdicts identical to its base runs. The control seat on the same perturbed packet also followed
the text 5 of 5 (11 of 13 unchanged), so the perturbation was readable. A memoriser answers the
original key. This is closed-book reasoning.

**Reasons, not scores.** On the blind-spot items astra judges the claim as stated and upholds it
with a scope caveat. Both Claude seats refute the same items by inferring that withheld evidence
"must have" contradicted the claim ("the supporting note conspicuously cites that the count was
run without stating its result, which suggests it contradicted the grammar") and by inventing a
mechanism that the packet does not describe — the manufactured-discriminator pattern this skill
already measured on refutations.

**Fable 5.1 is a harsher refuter than Fable 5, and a worse reviewer seat.** Refute rate up 18
points against the archived Fable 5 runs and 24 against the same-day control; true-claim
recognition down 25 and 31 points. It gains two REFUTED items (now 6/6) and loses two UPHELD ones
(now 0/6). Its error sets overlap Fable 5's at 0.40, less than Fable 5 overlaps its own runs a
month apart (0.63): this generation moved the blind spots, which makes it a counterexample to the
"a generation is not a second seat" paragraph above. Three runs per control, so the direction is
established and the size is not.

**Do not run Fable 5.1 headless at max effort on a closed-book packet.** One run of three answered
(12/18, 657 s, 50k output tokens, 2.2× the default-effort cost). The other two thought for 128,000
output tokens each, returned an error with no answer, and cost 5× a default run each. The CLI's
dollar budget guard is checked between turns and did not bound the single turn.

**Cost and runtime.** Astra at max: 545–854 s per run, 16k–34k tokens, about half a percent of a
weekly Plus window per run. Fable 5.1 at default effort: about four minutes and about 1.2 dollars
per run at list price, 8k cached input tokens and 12k thinking tokens. The origin project keeps the
runs, transcripts, scorer, perturbed packet and key in its own record.

## Measured: the ledger bridge on held-out review outputs (2026-09-17)

`scripts/concilium-ledger.py` was built against 3 review outputs from one project. Then its code
was frozen by hash. After the freeze, it was run on 12 review outputs that nobody had read while it
was built. They came from two projects, two seat families and four reviewer models. The pass criteria
were written before the run.

- **Parse.** 11 of 12 outputs parsed. For each of the 11, the tag, the model and the date matched
  the text when checked by hand, so there were no silent wrong extractions. The twelfth output gave a
  different tag for each part of the claim. The script refused it. It did not guess one tag.
- **Layouts that were not seen while the script was built:** block names in bold (`**PHASE-LOG:**`),
  a tag in bold (`**[X]**`), and extra seat annotations inside `reviewer(...)`. The script handled
  all three.
- **Contract echo.** When the output ends with the contract's template text, the parser refuses it
  (5 distinct tags). It does not record `[V-code]`.
- **Append.** The script made 33 attempts to append, into copies of three kit ledgers that were not
  read while it was built. Two of the ledgers use `L-` ids and one uses `A-` ids. 27 rows were
  written, and each one used the ledger's own id prefix. The 6 refusals were the final `[C]` cases,
  which is the designed result. After the appends, the kit's validator found no new error. The bytes
  before each new row were unchanged.
- **Not measured:** a ratifier's final tag that differs from the proposed tag. The test used the
  proposed tag as the final tag.
