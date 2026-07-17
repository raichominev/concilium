---
name: concilium
description: >-
  Adversarial cross-model review for hard, load-bearing tasks — combining frontier models: the
  Claude session (Fable as the intended orchestrator) hands a claim, diff, or result to an
  OpenAI model (gpt-5.6-sol / gpt-5.6-terra / gpt-5.5, via the codex CLI on ChatGPT-subscription
  auth, no API key), which probes it with falsification attempts and PROPOSES a verdict; the
  orchestrator checks the probe and RATIFIES. Use whenever the user wants a second opinion from
  a different model, a cross-model or concilium review, adversarial verification of a research
  claim, benchmark number, or diff, says "have GPT/codex check this", wants codex set up as a
  reviewer, needs to switch codex models mid-session (park-and-resume), is tiering work across
  codex models, or wants to LOOP/iterate review rounds until a disputed claim converges.
---

# Concilium — cross-model adversarial review

A second, *different* model reviews your (or the user's) claims adversarially. Different model
lineage means different blind spots — that's the value. The reviewer PROPOSES; the calling
session RATIFIES. Never let either side's confidence substitute for evidence.

Designed to be orchestrated from Claude Code — Fable is the intended ratification seat; the
GPT side (sol/terra/5.5 via codex) does the independent probing and mechanical execution.

## Prerequisites (check once per environment)

1. `codex login status` → must say "Logged in using ChatGPT" (subscription OAuth — an API key is
   NOT needed and a subscription can NOT be used as one; don't attempt proxy/router bridges).
2. Discover available models: `codex debug models` or `~/.codex/models_cache.json`. If a model
   errors "requires a newer version of Codex", run `codex update` and retry.
3. First time in a new environment, run the calibration bootstrap (references/setup.md) before
   trusting verdicts: a known-truth reasoning test, then one simple real task, then (optionally)
   a head-to-head to pick tier models.

## Tier matrix (defaults are current-day models — override per installation)

| Tier | Default | Effort | Use for |
|---|---|---|---|
| Research | flagship (e.g. `gpt-5.6-sol`) | high | open review rounds, adversarial verification |
| Mechanical | prev flagship (e.g. `gpt-5.5`) | medium | verify a known claim with one probe |
| Runner | cheap tier (e.g. `gpt-5.6-terra`) | low | execute-and-report: run a script, babysit an import |

Runner tasks are NOT reviews — skip the wrapper and call codex directly:
`codex exec -m <cheap-model> -c model_reasoning_effort=low [-s read-only unless it writes] "<task>"`

## Running a review

Use the bundled wrappers. They load the shared review contract from
`references/contract.md` (single source of truth — falsification probe, alternative explanation,
caveat, verdict-proposal, schema/encoding rules; **edit the contract there**, never in the
scripts) and add provenance stamping. Both wrappers are functionally identical; pick by platform:

**Linux / macOS (bash):**
- Claim: `scripts/concilium-review.sh claim "<claim>"`
- Diff:  `scripts/concilium-review.sh diff [base-branch]`
- Config via env: `MODEL`, `EFFORT`, `MECHANICAL=1` (mechanical tier), `REPO_DIR`, `PROJECT_RULES` (rules file path).
- First use after clone: `chmod +x scripts/concilium-review.sh`.

**Windows (PowerShell 5.1+):**
- Claim: `powershell -ExecutionPolicy Bypass -File scripts/concilium-review.ps1 -Claim "<claim>" [-Mechanical] [-RepoDir <path>] [-ProjectRules <file>]`
- Diff:  `... -Diff [-Base <branch>]` — reviews the working-tree diff of `-RepoDir`.

Operational rules (each one is a measured failure — the why is in references/pitfalls.md):

- **Run in background with a full ~10 min timeout from the FIRST call.** Real reviews take
  5–15+ min at high effort; a foreground timeout kills them mid-probe.
- **Prefer a fresh session over resuming a timed-out one.** Long resumed chains hit context
  compaction — the reviewer's early careful reading gets lossy-summarized before the final,
  consequential step.
- **Never bare-resume.** `codex exec resume` silently resets model AND sandbox to the user's
  config.toml defaults. If you must resume (or want to switch models mid-session), re-pin
  everything:
  `codex exec resume -m <model> -c sandbox_mode="read-only" -c model_reasoning_effort=<tier> <session-id> -`
  Flags go BEFORE the positional session id. The key is `sandbox_mode` — `-c sandbox=...` is
  silently ignored, and there is no `-s` flag on resume. Cross-model resume retains context.
- **The reviewer is a full agent, not a chatbot** — read-only sandbox blocks file writes, not
  read commands or DB SELECTs. Everything it reviews goes to the second model's provider.

## Ratification protocol (the calling session's job)

The reviewer returns five blocks: `PROBE / ALT / CAVEAT / VERDICT-PROPOSAL / PHASE-LOG`.
Before relaying or acting:

1. **Read the actual probe** (the query/commands), not just the prose summary.
2. **Extremal results are a tripwire**: 0% or 100% on a first attempt usually means a wrong
   join key, wrong scope, or wrong table — not a discovery. Verify the probe's load-bearing
   step yourself before accepting it.
3. **Scope-check disagreements**: two probes can both be factually right at different scopes
   (one table vs DB-wide, one source vs all sources). Name the scope before comparing numbers.
4. **Distinguish refuted / stale / incomplete.** "The numbers differ today" does not mean the
   claim was wrong when written — check history/timestamps before saying "refuted".
5. Assign the final verdict tag yourself: `[V-code]` (verified vs source, cite file:line) /
   `[V-db]` (read-only query, cite it) / `[V-probe]` (re-runnable script) / `[C]` (unverified) /
   `[X]` (refuted — name what supersedes it). The proposal is input, not the answer.

## The concilium loop (iterative rounds)

A single review pass is often enough. But when the reviewer's probe has a gap, or you (the
orchestrator) disagree with the proposal on defensible grounds, one exchange isn't a *concilium*
— a council deliberates. The loop runs review rounds until the verdict converges or the dispute
is proven genuine. **This loop is orchestrated by you, the calling Claude session — it is a
protocol, not a script** (the ratification step is your judgment; nothing can automate it).

Each round:
1. Run a review (the wrapper) → get the five blocks → **ratify** per the protocol above.
2. Decide the round's outcome and act:

| Outcome | Condition | Action |
|---|---|---|
| **Converged** | You verified the probe's load-bearing step and it holds | STOP — emit the final tag. |
| **Dispute** | The probe has a gap, wrong scope, or you have a specific, *evidence-backed* objection | Write this round's PROBE + your objection to a rounds file; run the next round with `-PriorRounds`/`PRIOR_ROUNDS` pointing at it. |
| **Dry** | A round adds no new checkable evidence — the reviewer re-asserts, or says (in CAVEAT) it has no new path | STOP — escalate to the owner as `[C]`/`[POLICY]` with the open question. This is the anti-oscillation guard. |
| **Cap** | Round limit reached (default **3**) without converging | STOP — present the state and escalate; a real dispute is a finding, not a failure. |

Design rules (they follow directly from the pitfalls):

- **Fresh session per round — never a resume chain.** The loop is exactly the "long chain"
  that pitfall #3 warns about; carry context forward via the `-PriorRounds` file, not
  `codex exec resume`. Each round starts clean and sees only a compact summary of what was
  already tried.
- **Every round must add a NEW evidence path.** The contract (rule 8) enforces this on the
  reviewer side; you enforce it on yours — an objection is only worth a round if it's backed by
  evidence or points at a concrete, checkable gap. "I'm not convinced" is not a round.
- **Ratifier stays fixed (you / Fable); the reviewer can drop tiers as the dispute narrows.**
  Round 1 on the research tier; once it's down to a mechanical check, run later rounds
  `-Mechanical`. Each round is a real 5–15 min codex call — the cap and the dry-stop are cost
  controls, not just correctness ones.
- **Keep the rounds file in durable project storage** (not a session temp dir), so the whole
  deliberation is auditable and the final PHASE-LOG can cite it.

Trigger it when the user asks to "loop", "iterate", "keep going until it's resolved", "have them
hash it out", or when a first pass comes back disputed and the stakes justify another round.

## Project adaptation

- Project-specific ground rules (safety invariants, schema quirks, "never touch X") go in a
  rules file passed via `-ProjectRules` / `PROJECT_RULES` — the wrapper appends it to the
  contract. Keep it short; the reviewer reads the repo itself.
- If the project keeps a claims ledger, the PHASE-LOG block is a ready-to-paste line
  (`Phase N — <reviewer>(<model>) — <date> — <found> [proposed]`); append it only via the
  project's own hygiene rules (typically: owner or main session, append-only). No ledger → drop
  the block.
- Storage: keep probe outputs and frozen samples in a durable project location, never in
  session-scoped temp dirs (they die with the session).

## References

- `references/contract.md` — the review contract the wrappers send (edit it there; both scripts
  load it at runtime).
- `references/pitfalls.md` — known issues and the rules that counter them (read when a rule
  seems overcautious, or when debugging reviewer misbehavior).
- `references/setup.md` — first-time setup, calibration bootstrap, and the head-to-head method
  for picking tier models.
