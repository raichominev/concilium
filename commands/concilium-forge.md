---
description: Run a Concilium FORGE round — cross-model idea generation against an open question, with a shared register. Nothing is judged or voted on.
argument-hint: "<open question>  |  --continue [register-path]"
---

Run a **forge** round on: `$ARGUMENTS`

Forge is the generative mode and the opposite discipline to `/concilium-review`. Seats produce
ORIGINAL ideas, read each other's from a shared register, and BUILD on them. No verdicts, no five
blocks, no ratification, **and no seat judges another seat** — the duty to refute kills a
half-formed idea before anyone can extend it. Read `references/forge-mode.md` before the first
round.

## If `$ARGUMENTS` is a question (new forge)

1. Write a brief from `references/forge-brief-template.md`. Three blocks carry it: the QUESTION, the
   **nearby inventory** (what the project already has to hand), and **ALREADY TRIED** — the last is
   worth more than any instruction, because it stops seats scoring on dead arms and pushes them into
   the empty cells.
2. Round 1, no register, seats in parallel — background, ~10 min timeout each:
   `scripts/concilium-forge.sh <seat> 1 --brief BRIEF.md --out <dir>`
   **Give every seat a fresh empty working directory.** Measured: seats sharing a directory read
   each other's output and position against it instead of thinking, which voids any claim that they
   converged independently.
3. **Curate** into a register: OPEN IDEAS (clustered, ranked by consequence) → HISTORY (with reuse
   counts) → EXPERIMENT LOG. Merge duplicates, credit every contributing id, and add your own ideas
   — the orchestrator is a seat too, including for the uncomfortable meta-ones.
4. Round 2 with `--register <file>`. Seats must name the ids they built on. This is where the value
   appears: round 1 tends to converge, round 2 produces the reframings.
5. Re-curate, then **name the gate** — the one experiment whose result orders all the others — and
   run it. A forge that never executes an experiment is a brainstorm.

## If `$ARGUMENTS` starts with `--continue`

Read the existing register, run the next round with `--register`, re-curate. Move anything acted
upon into HISTORY; keep OPEN IDEAS on top.

## Two rules that cost a round each to learn

- **Verify a seat's output actually parses.** One seat reported writing a valid structured file,
  named it, and had written nothing of the kind. Its report about its own output is not evidence.
- **An experiment lands in the log when it was worth RUNNING** — informativeness, not success.
  Record `informative_if`, `abandon_if`, and what a failure would teach. A null result on a
  saturated instrument is a finding about the instrument and belongs there too.

Keep the register, brief, raw seat outputs and any experiment scripts together in durable project
storage, never a session temp dir.
