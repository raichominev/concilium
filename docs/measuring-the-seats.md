---
layout: article
title: "What happens when you actually measure the models"
description: "What repeated measurements reveal about model families, seats and research workflows."
---

# What happens when you actually measure the models

*Five families, four instruments, about 150 scored runs. Almost every intuition the orchestrator
started with turned out to be wrong, and the useful findings are the ones nobody was looking for.*

Every multi-model setup rests on beliefs about which model is good at what. Those beliefs are
usually vibes: a model felt sharp on Tuesday, a benchmark leaderboard said something, a vendor's
post claimed a reasoning gain. This page is what happened when the beliefs were replaced with
measurements on one project's own ground truth.

The headline is not a ranking. It is that **rankings do not transfer**, that **model family is a
real and measurable property**, and that several plausible ways to buy more coverage buy nothing at
all.

⚠ Two caveats before any number below. These are single-project measurements on packets of 14–39
items, and differences under about ten points are inside the noise. And they are snapshots of
specific model versions at a specific moment; treat the *shapes* as durable and the *ordering* as
perishable. The method is the transferable part.

## The instruments

Four campaigns, each measuring a different thing, because the first real finding was that one
instrument cannot rank a panel.

| Instrument | Task | Size | What it measures |
|---|---|---|---|
| **Ledger prediction** | given a pre-registered experiment with its outcome stripped, predict WIN / NEUTRAL / FAIL | 39 items, 6 chairs | forecasting on unseen, project-specific ground truth |
| **Adjudication replay** | given a claim as a researcher would pitch it, propose the falsification probe and rule | 18 claims, 5 chairs | the reviewer's actual job |
| **Outcome prediction** | a smaller binary packet, replicated | 14 items, 5 seats × 3 replicates | stability, calibration, and instruction effects |
| **Blind originality** | rank pooled ideas with author labels stripped | 51 ideas, 5 rankers | idea generation |

The first two were originally run against three model families. Two further families — a Moonshot
seat and an xAI seat — were adopted later and were **back-filled onto the same frozen packets and
the same keys**, three replicates each, in an isolated guest that held the packet and nothing else.
Those runs are what make the blind-spot arithmetic below possible, and they cost one afternoon.

All of them share three design rules that took a while to learn:

- **The answers must not exist anywhere the model can reach.** Claims answerable from a repo measure
  retrieval, and frontier models are saturated at retrieval — every seat comes back near-perfect and
  the instrument has zero measurement capacity. Built from a project's own unpublished experiment
  log, the items are genuinely unseen.
- **Balance the packet and randomise the order.** An unbalanced packet lets "always answer FAIL"
  score well, and a criterion shift then reads as a skill gain.
- **Blindness has to be structural.** More on that below; it is the rule that cost the most to
  learn.

## Finding 1 — the ranking does not transfer

The same models, measured four ways, produce four different orderings.

**Ledger prediction** (39 items, majority-class baseline 41%). The first four ran once each; the two
later seats ran three times, so their range is shown:

| chair | score | balanced | recall WIN / NEUTRAL / FAIL |
|---|---:|---:|---|
| opus | **84.6%** | 85.9% | 92 / 91 / 75 |
| fable | 82.1% | 82.8% | 92 / 82 / 75 |
| codex (sol) | 82.1% | 81.2% | 83 / 73 / **88** |
| grok | 69.2 – **84.6%** (mean 77.8) | — | — |
| kimi | 66.7 – 71.8% (mean 69.2) | — | — |
| sonnet | 64.1% | 62.8% | 83 / 36 / 69 |

The per-class recalls are where the interest is: the cross-family seat is the **best** of the panel
at recognising a failure (88%) and the **worst** at recognising a non-effect (73%), while the
same-family chairs are the mirror image. Two chairs with the same total were not doing the same
thing.

And note what the replicated seat does to the table. Grok's three runs span **69.2% to 84.6%** —
one seat, unchanged settings, covering almost the entire spread the original four-chair ranking was
built on. More on that in Finding 4.

**Adjudication replay** — the reviewer's real job — reorders them and drops everyone toward the
floor (18 claims, all-REFUTED baseline 56%):

| chair | verdict accuracy | refuted recall | upheld recall |
|---|---:|---:|---:|
| grok | 66.7 – 77.8% (mean **72.2**) | 9/10 every run | 5, 3, 4 of 8 |
| fable | 66.7% | 7/10 | 5/8 |
| opus | 66.7% | 7/10 | 5/8 |
| kimi | 55.6 – 72.2% (mean 64.8) | 7, 7, 4 of 10 | 5, 6, **6** of 8 |
| codex (sol) | 61.1% | 7/10 | 4/8 |

Grok tops that table, and the top line is misleading — which is the point of keeping the recalls
next to it. It refutes almost everything (9/10 in every run) on a packet that is 56% REFUTED, so
scepticism pays: its **upheld**-recall, 3–5 of 8, is the worst measured, while kimi's 5–6 of 8 is
the best. On balanced accuracy the 7.4-point gap between them shrinks to 4.6 and sits inside both
seats' own run-to-run spread. **A headline accuracy on an unbalanced packet is a criterion
measurement wearing a skill costume.**

**Blind originality**, with self-ratings and same-family ratings dropped so nobody scored their own
lineage, inverts it again:

| seat | points per idea |
|---|---:|
| codex | **11.17** |
| claude (isolated) | 5.83 |
| kimi | 5.00 |
| grok | **1.43** |

And **outcome prediction**, scored on stable profiles rather than single runs, produces yet another
order — with codex, which led originality by a factor of two, placing fourth:

| seat | stable-right | stable-wrong | flips |
|---|---:|---:|---:|
| claude (isolated) | **7** | 1 | 2 |
| grok | 6 | 1 | 3 |
| claude (in-session) | 5 | 2 | 3 |
| codex | 5 | **4** | 1 |
| kimi | 4 | 3 | 3 |

Then a fifth twist. In a round where seats had to *chain* other seats' orphaned ideas rather than
generate new ones, **grok — dead last on solo originality, with three of its ideas flagged by four
of five rankers as restatements of known methods — produced the best chains**, fusing two ideas
that were each only a critique into a single working instrument.

There is no "best seat" in this data. There are seats that are good at specific things, and the
only way to know which is to measure the thing you actually want.

## Finding 2 — lineage is real, and you can put a number on it

The core bet of a multi-model panel is that different families fail differently. That is testable:
take each chair's set of wrong answers and compare the sets.

With all six chairs on the same 39 items, one run each so the sets are comparable:

| pair | error-set Jaccard | both wrong | |
|---|---:|---:|---|
| fable ~ opus | **0.62** | 5 | same family |
| grok ~ sonnet | 0.57 | 8 | |
| kimi ~ sonnet | 0.50 | 9 | |
| grok ~ kimi | 0.50 | 7 | |
| fable ~ kimi | 0.43 | 6 | |
| fable ~ sonnet | 0.40 | 6 | same family |
| grok ~ codex | 0.36 | 4 | |
| opus ~ sonnet | 0.33 | 5 | same family |
| grok ~ opus | 0.27 | 3 | |
| fable ~ codex | 0.27 | 3 | |
| opus ~ codex | **0.18** | 2 | |

The top of that table is a same-family pair and the bottom is a cross-family pair, which is the
result the panel is built on. On one item the two same-family chairs independently produced the
*identical* wrong inference, chaining the same two packet items in the same wrong direction.

⚠ **But adding two families exposed a confound the original three-chair reading could not see:
error overlap tracks skill as well as lineage.** The second and third rows are cross-family pairs
with high overlap — and all three involve the weakest chairs, which fail together on the same
merely-difficult items regardless of who made them. Controlling for it, by restricting to the four
chairs that scored 31–33 of 39:

- same family: fable ~ opus = **0.62**
- cross family: mean **0.29** across the five remaining pairs (0.18 to 0.36)

The lineage effect survives the control at a bit over 2×, rather than the 3× an uncontrolled
reading gives. **Two seats from different vendors are not automatically decorrelated** — grok and
kimi overlap at 0.50, higher than either overlaps with codex. Diversity is what you measure, not
what the vendor list implies.

The panel arithmetic follows directly. Pairing the best same-family chair with the cross-family seat
covered 37 of 39 items. Adding a *third same-family* chair on top added **zero**. The cross-family
seat's marginal contribution over the entire Claude family was three items.

### What two more families actually bought

The original write-up named the items its whole panel missed. Back-filling two new families onto the
same packets turns that into a measurement rather than an anecdote:

| instrument | missed by every original chair | after adding two families |
|---|---|---|
| adjudication | CLAIM-14, CLAIM-16 (both true, refuted by all) | **CLAIM-14 rescued** — kimi 3/3, grok 2/3. CLAIM-16 still **0 of 5 families** |
| ledger prediction | ITEM-04, ITEM-05 | **both still 0 of 5 families** |

Half the adjudication blind spot fell to a new lineage. None of the prediction blind spot did —
and the original write-up had already characterised those two items as generic evidence-breadth
priors that this corpus happens to refute. Two more vendors, three replicates each, and they
reproduce the error exactly.

That is the honest shape of what a wider panel buys: **real, item-level, and partial.** Some joint
failures are lineage artifacts that another family fixes for free. Others are shared priors that
every frontier model currently holds, and no amount of panel width will touch them — only ground
truth will.

This is why the standing rule is to weigh agreement by family and never settle a dispute by counting
votes across chairs that share a lineage.

## Finding 3 — effort is not a substitute for a family

The cheap move is to run one seat at several reasoning efforts and treat the spread as a panel. It
was tested properly, with a control: six runs of one seat over the same packet — five effort levels
plus a **same-effort replicate** to establish the noise floor.

| run | score |
|---|---:|
| high (a) | 9/14 |
| high (b) — same-effort replicate | 8/14 |
| max | 9/14 |
| low | 7/14 |
| medium | 7/14 |
| xhigh | 7/14 |

- Two runs at the **same** effort covered 10/14.
- Cross-effort pairs averaged 8.9 and **never beat** that. Best case tied it.
- The full six-run ensemble also reached 10/14 — equal to the two-run noise floor.
- Accuracy was **not monotonic** in effort, while wall time grew roughly eightfold.
- Four items were missed by every run at every effort. The cross-family seat got two of them.

Varying effort resamples one family's blind spots at increasing cost. If you want coverage, add a
family, not compute.

Two neighbouring shortcuts died the same way: a newer *generation* of the same family rescued
nothing its sibling missed, and prompt variation within one family is a fallback rather than an
equal.

## Finding 4 — one run is not a measurement

Replicates at identical settings, same packet, same effort. On the 14-item packet:

| seat | three runs | spread |
|---|---|---:|
| claude (in-session) | 10, 11, 11 | 1 |
| codex | 7, 7, 7 | 0 |
| grok | 8, 7, 6 | 2 |
| kimi | 7, 6, 5 | 2 |

A two-point spread on 14 items is fourteen percentage points — larger than most of the between-seat
gaps anyone would want to report. An early single-draw ranking was published, then retracted.

**On the 39-item ledger packet it is worse, and it retroactively dissolves a published ranking:**

| seat | three runs | spread | range |
|---|---|---:|---|
| kimi | 26, 27, 28 | 2 | 66.7 – 71.8% |
| grok | 31, 27, 33 | **6** | **69.2 – 84.6%** |

Grok's three runs, identical settings, span 15.4 percentage points. The original four-chair ranking
on this exact packet ran from 64.1% to 84.6% — so **one seat's noise band covers three quarters of
the spread that ranking was reporting as differences between models.** The published ordering there
(84.6 / 82.1 / 82.1) is three chairs inside a one-to-two item gap, measured once each.

The same happened on adjudication: kimi scored 12, 13, 10 out of 18 across three runs, while the
original campaign's entire between-chair result was fable 66.7 = opus 66.7 > codex 61.1 — a
one-item gap, one run each, inside a three-item noise band.

Neither ranking was wrong so much as **unresolvable**, and nothing in a single-run table shows you
that. This is the finding that costs the most to ignore, because a single run always produces a
confident-looking number.

What replaced it is the **stable profile**: the items a seat gets right in *every* replicate, wrong
in every replicate, and the ones that flip. The stable-wrong set is the more useful half — it is the
seat's *prior*, not its noise, and the sets barely overlap between families. Codex is stably wrong
on four of ten items where the top seat is stably wrong on one, and they are different items.

It also changes what a panel is worth. Across the five default seats, **no item is stably wrong for
everyone**, and the union of the stable-right sets covers 8 of 10. Compare the effort sweep, where
four items were unreachable at every level for one seat.

## Finding 5 — error direction is mode-dependent *and* lineage-dependent

In **adjudication**, every chair over-refuted. Refuted-recall was 7/10 for all three, but
upheld-recall was 5/8, 5/8 and 4/8 — and two true claims were refuted by **all three chairs
independently**. A reviewer's REFUTED verdict carries a substantial false-positive rate. That single
result is why the protocol splits propose from ratify: the split is the control for a measured bias,
not ceremony.

In **outcome prediction**, the same models flip to over-credulous, believing changes worked that did
not.

So far, so tidy — until a fourth family was measured on the same prediction packet and erred the
*other* way, 14 pessimistic errors against 7 optimistic ones. The mode rule describes the families
it was measured on, not models in general. Re-measure the direction per seat before correcting for
it.

## Finding 6 — an instruction can move the criterion without improving reasoning

One paragraph was inserted into the packet telling the chair to hunt non-obvious connections, be
specific rather than cautious, and take the strong position because a hedge scores the same as a
miss. Five seats, two arms, three replicates: 30 runs differing by that paragraph alone.

Pooled: accuracy 60.7% → 65.3%, **95% CI over items [−3.3, +14.7] — includes zero, so not proven.**

But the shape is consistent. Hit rate fell only 70.7% → 66.7% while **false alarms fell 49.3% →
36.0%**, moving d′ from 0.56 to 0.79 and the decision criterion toward FAIL in four of five seats.
It does not make chairs see more; it makes them **harder to talk into a yes by a plausible
mechanism**.

Which means it helps exactly the seats that were too credulous, and hurts the ones that were not:

| seat | false alarms, base → treat | accuracy |
|---|---|---:|
| grok | 33.3% → **6.7%** | +13.3 pp |
| kimi | 93.3% → 66.7% | +10.0 pp |
| claude (isolated) | 33.3% → 26.7% | −3.4 pp |
| codex | 46.7% → 53.3% | **−6.7 pp** (d′ 0.34 → 0.00) |

A "reasoning" instruction that improves two seats and degrades two others is not a reasoning
instruction. It is a knob, and it belongs per seat.

## Finding 7 — blindness has to be structural

The cheapest-sounding way to run a blind evaluation is to tell an in-context model to answer from
the packet alone. It does not work, and this was measured twice.

When context leaks were removed, chairs flipped from **right to wrong** on the leaked items — all
three of them — meaning the "answer from the packet alone" contract had measurably not been followed
even while the chairs were honestly self-reporting possible contamination. And an in-session chair
that inherited its project's own always-loaded instructions, which stated four of fourteen answers
outright, scored 76.2% against the same family's 57.1% in an isolated guest.

A subagent of the project under study is not a blind seat, whatever the prompt says.

Worse, contamination flatters the wrong conclusion. An early reading found the two same-family
chairs' errors *disjoint* — apparent evidence against the lineage effect. The clean rerun reversed
it: the disjointness was itself a contamination artifact, because the leaked context had handed the
family the answers on precisely the items where their shared priors fail.

Corollary: **a perfect score is a contamination alarm.** Two runs returned 14/14 on a packet where
the best previously measured seat reached 11. Both had reached material that answered it, and both
announced it in their own preambles while citing exact values at high confidence. The honest runs
from the same seat scored 6–8. Grade the reasons, not the score.

## Finding 8 — confidence is not a weight

Mean stated confidence on items the seat got **right**: codex 99.7 on one packet (range 96–100 —
effectively flat), kimi 95.1, claude 93.9, grok 70.9.

Those are not comparable quantities. A seat that says 99 and a seat that says 71 are not expressing
different degrees of belief; they are expressing different habits.

And it gets worse in the mode that matters. In adjudication, the cross-family seat's calibration was
**inverted** — mean confidence 0.91 when right, 0.93 when *wrong*. Its single most confident answer
on one subset was wrong. The Claude chairs were flat but honest, around 0.6 either way.

Weigh a dissent by lineage. Never by how certain it sounded.

## Finding 9 — cross-family independence does not protect against a plausible mechanism

The one that should temper enthusiasm for the whole approach. On one claim, all three chairs — two
families — independently invented the **same incorrect mechanism**, a story that was plausible from
the system's architecture and wrong about what the measurement actually showed.

Different lineages fail differently on *knowledge*. They can still converge on a wrong explanation
when the wrong explanation is the architecturally obvious one. Panel agreement is evidence; it is
not proof, and it is weakest exactly where the answer sounds most reasonable.

## Building your own

The apparatus is small. Four things:

1. **A frozen packet** — items with outcomes stripped, balanced, order randomised, self-contained
   enough that nothing outside the file is needed to answer.
2. **A key**, never shown to a seat, held separately.
3. **One raw answer file per seat per replicate.** Three replicates minimum. Keep the raw files, not
   just the scores — every re-analysis on this page was possible only because they survived.
4. **A scorer** that reports the stable profile and the pairwise error overlap, not a total.

Then resist the two temptations: reporting a single run, and reporting an aggregate that hides which
items moved.

## Interlude: three of twelve runs came back broken, and none of them said so

Back-filling the two later seats meant twelve fresh runs. **Three failed**, in two ways, and neither
way announced itself:

- **Truncation.** The 39-item answer runs into an output ceiling and the JSON stops mid-object —
  once at item 36, once at item 38. Both CLIs emitted the partial answer as a normal result.
- **Empty success.** One seat returned `"subtype":"success","is_error":false` with an **empty**
  result string, after eight minutes and 30,000 generated output tokens. Its own error flag said
  fine. It happened twice on the same item, then succeeded on retry.

An exit code would have called all three a success. So would the CLI's own error field. The only
thing that caught them was a check on the **artifact**: parse the file, count the items, compare to
the number the packet asked for. That check costs four lines and it is the difference between a
retry and a silently corrupted row in a results table.

It also shapes instrument design. A packet whose answer approaches an output limit is not just
risky, it is **biased** — the truncation lands on the last items, so those get systematically fewer
answers than the first ones. Keep the required answer well clear of the ceiling, or split the
packet.

The salvage rule that follows: repair what parses, report what is missing, and never let a missing
answer be scored as a wrong one. The repaired run above contributed 37 of 39 items, and the stable
profile was computed only over items every replicate answered — a smaller denominator, stated, is
better than a silent zero.

**And a hole found afterwards, which is the more useful half.** The runs were isolated per-run — a
fresh empty working directory each time, every result pulled off the box and deleted before the next
one started. That cleanup missed the thing that mattered: **the agent CLIs keep their own transcript
stores outside any working directory you clean.** A later run of the same CLI could, in principle,
have read an earlier run's full conversation. The guest had also not been reverted to snapshot
first, so it still held an older campaign's material — different packets, other seats' predictions,
and at no point any answer key.

The empirical check settled it for one seat: every transcript was probed for tool-use blocks, and
all eight reported zero — closed-book, exactly as the packet demanded. The first version of that
probe reported zero for the **control** as well, which is how it was caught: an unvalidated null is
not evidence. For the other seat the equivalent log was not reachable, so that side rests on the
weaker argument that nothing approached ceiling.

Two rules, then. **Revert the guest between campaigns, not between runs** — per-run hygiene inside a
dirty box is theatre. And **validate a contamination detector against a known-positive before you
believe its null**, which is the same lesson a saturated tripwire taught earlier, arriving from the
opposite direction.

## Coda: the scorers rot faster than the data

Every campaign above was re-derived from its raw files while writing this page. **Five of six
archived scorers no longer ran.** Not one had a logic error; every failure was a stale path or a
renamed directory — a runs folder that had been called something else, a filename pattern from an
earlier convention.

Four of the five failed **silently**, printing a clean, well-formatted table with no rows in it. One
divided by zero on the empty set. And one had a filename pattern that quietly excluded a single
seat — the isolated seat that turned out to *top* that instrument — while reporting the other four
without complaint.

Two rules fell out of that, and they are as durable as anything else here:

- **A scorer that finds no inputs must fail loudly.** "0 runs parsed" is a valid output. An empty
  table is not.
- **Keep the raw answer files.** The scorers were all repairable in minutes because the data they
  read was still there. If the numbers had been kept and the runs discarded, this page could not
  have been written and none of its figures could be checked.
