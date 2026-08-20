# Forge brief — TEMPLATE

> Copy this file and replace the three filled blocks below — the QUESTION, the nearby INVENTORY,
> and ALREADY TRIED — keeping their headings. The last one matters most: it is what pushes seats
> into empty cells instead of rediscovering dead arms. The blocks are filled here with a worked
> example so you can see how specific each line has to be; **specificity is the whole point**, and
> a vague inventory returns vague ideas. Driver: `scripts/concilium-forge.{sh,ps1}`.
> Method: `forge-mode.md`.

## Round brief

## Your job

Produce ORIGINAL, ACTIONABLE ideas against the question below. You are scored on **originality
count**, not on caution and not on being right. An idea that is wrong but new and testable scores;
an idea that is safe and already known scores zero. Maximise your original-idea count.

**Governing heuristic — "the answer is nearby, never touched."** The highest-yield move in a mature
project is usually not a new algorithm. It is a piece of material already sitting in the project,
one join away from the question, that nobody has pointed at it yet: an artifact built for another
purpose, a by-product of a failed experiment, a document read for its content but never for its
structure, a constraint that is documented in prose but never enforced in code. Hunt those first.

**Do not judge other seats' ideas.** When you are given ideas from other models, treat them as raw
material: extend, combine, invert, or build an experiment on top of them. Criticism is not the
output here; construction is.

---

*Everything from here down is the worked example. Replace it.*

## THE QUESTION (prospective, open)

> The product deduplicates customer records arriving from many acquired systems. A matcher scores
> candidate pairs and merges above a threshold. Quality is capped by a hard fact: **there is no
> labelled set of true duplicates** — nobody has ever hand-adjudicated a sample at scale, and the
> only "labels" that exist are the matcher's own past merges, so ordinary supervised learning would
> train on its own output.
>
> **What is the highest-yield, least-explored move available to raise match quality using material
> the system ALREADY HAS but has never systematically exploited?**
>
> Answer with concrete moves, each cheap enough to test in days, not months.

## What the project already has (the "nearby" inventory)

- **A support ticket archive** where agents write free text like "this is the same person as
  account 4471" — thousands of human adjudications, recorded for a different purpose and never
  parsed as labels.
- **Merge-undo events**: 3,200 merges reversed by a human within 30 days. Every one is a
  hand-confirmed FALSE positive, and the table has never been joined to the matcher's scores.
- **Per-source schema documentation** written during each acquisition, stating in prose which
  fields were mandatory, which were free text, and which were auto-populated. Three known examples:
  one source defaulted missing birthdates to 1900-01-01; another truncated surnames at 20
  characters; a third stored two different phone formats depending on signup year.
- **A rule-based normaliser** whose coverage is uneven — of 226 known address abbreviations, only
  about 15 have a rewrite rule at all. Coverage, not rule quality, is the binding constraint there.
- **An experiment ledger** with many recorded failures, each with its pre-registration and outcome.
- **Search infrastructure** that folds spelling variation into normalised columns, plus trigram
  indexes over the whole record set.
- **Per-record structure**: creation timestamps, source system, edit history, and which fields a
  human has ever touched.

## Already tried — do NOT propose these again (they score zero)

- A sequence model over the edit history (wiring gate failed).
- Naive one-cluster-per-email assumptions.
- A full source × era × channel noisy-channel model (too big; prototype-only).
- Hierarchical multi-signal machinery (a flat version already beat it).
- Mining recurring templates inside the records themselves (yielded 0.25%).
- Confidence-threshold gating of the auto-merge step, and cluster-size gating of the same.
- A blanket normalisation that erases the variation it is supposed to model.
- Suppressing matches by field shape alone (the rule never fired).

---

## Output format

Strict JSON, nothing before or after:

{"ideas":[
  {"id":"<seat>-1",
   "idea":"one sentence, concrete",
   "nearby_material":"which existing artifact it exploits",
   "why_unexplored":"why nobody has pointed it here yet",
   "cheapest_test":"the smallest thing that would show it works or fails, runnable in days",
   "builds_on":"<id of another seat's idea, or 'new'>"}
]}

Aim for 6-10 ideas. Quality bar: each must name a specific existing artifact and a test.
