---
description: Route a claim, or the uncommitted diff, to the cross-model Concilium reviewer.
argument-hint: "<claim text>  |  --diff [base-branch]"
---

Run a **review** round on: `$ARGUMENTS`

A different model lineage probes the claim adversarially and **proposes** a verdict; you, the
calling session, **ratify** it. Read `references/contract.md` (what the reviewer is bound to) and
SKILL.md → *Ratification protocol* before the first round.

## Run it

- `--diff [base]` → review the working-tree diff:
  `scripts/concilium-review.sh diff [base]`
  (Windows: `powershell -ExecutionPolicy Bypass -File scripts/concilium-review.ps1 -Diff [-Base <branch>]`)
- otherwise treat `$ARGUMENTS` as the claim:
  `scripts/concilium-review.sh claim "$ARGUMENTS"`
  (Windows: `... concilium-review.ps1 -Claim "$ARGUMENTS"`)

Run it **in the background with a full ~10 min timeout from the first call** — research-tier rounds
take 5–15 minutes and a foreground timeout kills the probe mid-flight. On timeout prefer a FRESH
round over a resume; if you must resume, use the full re-pin recipe in SKILL.md (a bare
`codex exec resume` silently resets model AND sandbox to the user's config defaults).

Tier: `-Mechanical` / `MECHANICAL=1` for a mechanical check of a known claim; the default research
tier for open questions. Extra-family seats are **opt-in** — use `concilium-review-kimi.*` or
`concilium-review-cursor.*` only when the user asks for one.

## After it returns

1. Read the **actual probe** — the queries and commands, not the prose summary. An extremal 0% or
   100% on a first attempt is a tripwire for a wrong join key or wrong scope, not a discovery.
2. Show the five blocks (`PROBE / ALT / CAVEAT / VERDICT-PROPOSAL / PHASE-LOG`) verbatim.
3. Give **your** ratified tag and one sentence of reasoning. The proposal is input, not the answer,
   and same-family agreement is weak evidence — weigh a dissent by lineage, never by how confident
   it sounds.
4. If the round is disputed and you have an evidence-backed objection, loop: write this round's
   probe plus the objection to a rounds file and pass it as `-PriorRounds` / `PRIOR_ROUNDS`. Stop on
   convergence, on a dry round, or at the round cap.

If the project keeps a claims ledger, hand over the PHASE-LOG line for the user to append. Do not
append it, and do not commit anything, yourself.

## Other modes

Review is one of ten. An **instrument audit** before a large measurement batch is the cheapest
high-value call in the set; fragment verify, blind replication, cross-examination and frame
translation each answer a question review cannot. Catalogue: `references/modes.md`. They are run by
name — `scripts/concilium-mode.sh <mode> <seat> --input <file>` — not selected automatically.
