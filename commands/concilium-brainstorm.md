---
description: Run a Concilium BRAINSTORMING campaign — open-book cross-model idea brainstorminging with a live read-only copy of the project's database per seat. Findings replayed, ideas flow to human-reviewed dossiers, never orchestrator-curated.
argument-hint: "<question about a system whose conventional methods are exhausted>  |  --round <c1|build|discovery> [campaign-path]"
---

Run a **brainstorming** campaign on: `$ARGUMENTS`

Brainstorming is forge's open-book inversion, for a question where the conventional methods are
exhausted and nobody knows where the door is. Seats get a LIVE READ-ONLY copy of the system under
discussion — its data and/or its source tree, whichever exist; volume is quotaed by boldness tier;
every idea carries re-executable evidence; ideas end in **human-reviewed dossiers, never an
orchestrator shortlist**. Read
`references/brainstorming-mode.md` FIRST and follow its evidence tiers — wire nothing marked [open] as
a rule. The governing pipeline rules live in `references/modes.md`: §"IDEAS are never synthesised",
§"A research session does NOT implement", §"Every multi-seat round ends in a SYNTHESIS" (findings
only).

## If `$ARGUMENTS` is a question (new campaign)

1. **Instrument before brief.** An isolated guest holds a throwaway READ-ONLY replica of whatever
   the system has: source tree as a private copy per seat; data as an immutable snapshot each seat
   can query but not damage. When the data lives in a database, the proven wiring is a rootless
   Postgres restore with ONE SELECT-only role per seat (`default_transaction_read_only = on`,
   statement timeout) and `log_statement='all'` so the server's own log is the per-seat dig log;
   for file-shaped data, read-only copies plus shell-history capture play the same roles. Fixture
   freshness is a validity condition — gate every round on a fixture-vs-live drift check; a stale
   snapshot has manufactured a confident three-vendor convergent falsehood.
2. **Write the brief** with, non-negotiably: the boldness quota (4 incremental / 4 aggressive / 4
   "laughed out of the room", tier-3s stating why_absurd + what_must_be_true — fewer than 4 tier-3
   is a failed run); the evidence contract (the query or command you RAN and what it RETURNED —
   both are replayed); the denominator rule (every rate names its population); THREE deliverables (ideas,
   FINDINGS — the fast payoff, resource REQUESTS); the known-intentional-absences list (or seats
   rediscover them every round); ground-truth boundaries (what in the data is the system's own
   output and therefore never a correctness signal).
3. **Run the seats** in parallel where transports are disjoint. Big packets go to the seat as a
   FILE in its cwd with a pointer prompt (Linux caps one argv string at 128 KiB). Checkpoint-as-
   you-go is mandatory in every prompt. Verify ARTIFACTS, never exit codes or markers; retry a
   failed seat once; salvage order is final-answer vs checkpoint, richer wins.
4. **Replay every evidence query/command** against the same fixture and score. Then write the FINDINGS
   synthesis (convergent / disagreements / single-seat / retracted — the disagreement section is
   mandatory and the payoff), verify the load-bearing findings fixture-side, and **spawn
   implementation sessions** for anything touching live — the brainstorming session never verifies
   against live "just this once".

## `--round c1` (peer comments) and `--round build` (C2/C3)

C1: every seat reads all other seats' ideas ([YOURS] excluded) and comments constructively — no
verdicts, no scores. Build rounds: seats get the COMPLETE dossiers as files and produce up to 8 new
ideas, each citing ≥2 parent entries, plus up to 10 targeted comments. Between rounds: fold
checkpoint-salvaged outputs, stamp LIVE VERDICTS from implementation sessions onto their dossier
entries, and tell the next round to argue WITH verdicts, not about them. Dossier mechanics
(conservative grouping, vetoable FILTERED list, mechanical INDEX) per `brainstorming-mode.md` §pipeline.

## `--round discovery` (after fixes land)

The capacity measurement: pre-register the protocol and the R-FIXED / R-KNOWN / NOVEL metric with
decision thresholds BEFORE the run, refresh the fixture from the repaired system, run ONE clean
generation round, replay, classify with receipts. This is what turns "the panel finds things" into
a property — it has been run once and passed (NOVEL 32.5%, 13/13 replay-surviving).

## Standing constraints

- The orchestrator NEVER ranks, shortlists or synthesises ideas. The human reviews dossiers.
- Seat behaviour is task-shaped: chunk bulk work for seats that collapse at scale; treat "pass" as
  an effort-budget signal; quota exhaustion arrives disguised as transport failure.
- Findings hand over to implementation sessions as verified measurements, never as seat quotes.
- Every analyzer-facing consequence stays owner-approved, measured, ledger-rowed.
