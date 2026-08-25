# The dossier pipeline — ideas distillation after Forge/Brainstorming

A generation round leaves you with hundreds of raw ideas, comment threads across several
rounds, test stamps, and verdicts that landed while the campaign ran. The dossier pipeline
turns that pile into a reviewable dossier set **without the orchestrator ever ranking an
idea**. The human reviews; the pipeline only organizes.

This page records the practices that proved load-bearing when the pipeline first ran at
full scale. Each rule earned its place by a failure it prevents.

## The pipeline, in order

1. **Register** — every seat writes ideas into a shared register file, verbatim, with a
   stable id per idea (`seat-round-n`). The register is append-only during the campaign.
2. **Round digest** — after each round, one digest file summarizes what landed, with every
   claim carrying its source id. The digest quotes; it does not paraphrase numbers.
3. **Grouping** — ideas that independently converge on one mechanism become one dossier
   entry that preserves **every member's wording**. Convergence is recorded, never merged
   into a single rewritten text.
4. **Dossiers** — one file per tier. Each entry carries: the raw idea text, its mechanism,
   why-absurd/works-if where the contract asked for them, the evidence result, the seat's
   own `cheapest test` and `kill` condition, all peer comments, and any test-run or live
   verdict stamps.
5. **Index** — one table, one row per entry, **every column a mechanical count** (comment
   count, seat count, pass count, test-run flag). The sort key is the seats' own
   combine-with graph — how often other entries name this one as a partner — never an
   orchestrator preference.
6. **Filter file** — entries removed from review go into a separate file with the reason,
   full text kept, and **every removal is vetoable**: a veto returns the entry unchanged.
7. **Stamp store** — test runs and implementation verdicts append to one JSON store keyed
   by entry id. Dossier rebuilds render the stamps into the entries.
8. **Review ledger** — the human's rulings (pursue / park / kill / merge), append-only,
   reasons verbatim. The orchestrator records; it does not reinterpret.

## Best practices

### Neutrality is structural, not behavioral

- Do not rely on the orchestrator promising not to rank. Make ranking impossible to
  express: the index has no free-text column for opinion, the sort key is computed from
  the seats' own cross-references, and outcome labels are defined as comparisons against
  the seat's own stated bar.
- When the human asks "what do you think" about an entry they opened, analysis of THAT
  entry is in scope. A volunteered top-N is not.

### Preserve wording, always

- Group by convergence, but keep each member's full text. A merged paraphrase destroys
  the differences between variants, and the differences are frequently where the value is.
- Quotes keep their source wording verbatim, including numbers you believe are wrong.
  Corrections attach as stamps or verdict notes beside the original, never as edits to it.

### Make every idea carry its own test

- Require `cheapest test` and `kill` fields at generation time, with numeric thresholds.
  This is the highest-leverage rule in the pipeline: it converts a later testing campaign
  from judgment calls into mechanical comparisons ("measured X against the seat's own bar
  Y"), and it lets tests be sorted by cost instead of by appeal.
- A test result is stamped with its scope ("premise confirmed", "kill condition fired",
  "premise gone") — the ruling on the IDEA stays with the human.

### Inherit landed verdicts explicitly

- While a campaign runs, fixes land and premises die. Do not silently prune affected
  entries. Flag them: an entry whose premise leans on a since-repaired defect gets a
  named verdict flag and stays in the dossier. The reviewer sees the flag and the
  original claim together.
- Any number quoted from an earlier fixture epoch is suspect. Record the epoch with the
  number, and re-derive counts before any test that consumes them.

### Denominators and keys

- Every rate in a digest or dossier names its population. Most recorded "disagreements"
  between seats dissolve into two population definitions or two comparison keys once
  those are named — so name them at write time, not at reconciliation time.
- When two instruments measure "the same" quantity, record both readings and the
  definition each uses. Do not average them.

### Screen for circularity, report the screen's error rate

- Ideas that score the system against its own output need a circularity screen. Run the
  screen mechanically, then hand-adjudicate the hits, and report the screen as a screen
  ("N matched, ~M genuinely circular after adjudication") — never as a verdict count.

### Filters are cheap to reverse, so keep them honest

- Filter only on resolved premises or explicit human rulings, one reason per entry,
  full text preserved. If a filter needs an argument, it is not a filter — it is a
  ranking, and it belongs to the human.

### Rebuilds are mechanical

- The dossier set is a build artifact: register + comments + stamps in, dossiers +
  index out. Keep the builder rerunnable so a new stamp or a veto regenerates the set
  without hand-editing. Hand edits to build artifacts disappear on the next build —
  if something must be said, say it in the stamp store or the source files.

## Failure modes this design answers

| failure | rule that prevents it |
|---|---|
| Orchestrator taste quietly becomes the shortlist | mechanical index, seats'-graph sort, no opinion column |
| A paraphrase flattens three variants into one | verbatim grouping |
| A retracted number keeps circulating | stamps beside originals, epoch labels |
| Testing stalls on "which ideas deserve tests" | seat-authored bars + cost-sorted test plan |
| Disagreements consume rounds of argument | denominator-and-key discipline at write time |
| A removed idea is unrecoverable | vetoable filter file with full text |
| Self-confirming ideas read as measured wins | circularity screen with adjudicated error rate |
