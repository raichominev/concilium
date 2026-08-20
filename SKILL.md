---
name: concilium
description: >-
  Adversarial cross-model review for hard, load-bearing tasks — combining frontier models: the
  Claude session (Opus 5 or Fable 5 as the intended orchestrator) hands a claim, diff, or result to an
  OpenAI model (gpt-5.6-sol / gpt-5.6-terra / gpt-5.5, via the codex CLI on ChatGPT-subscription
  auth, no API key), which probes it with falsification attempts and PROPOSES a verdict; the
  orchestrator checks the probe and RATIFIES. Two EXPERIMENTAL, opt-in extra-family seats can be
  added when asked for — Kimi (Moonshot, via the Kimi Code CLI or the local Kimi Desktop runner)
  and Grok (xAI, via the Cursor Agent CLI on Cursor-subscription auth); neither is part of a
  default round. Use whenever the user wants a second opinion from a different model, a
  cross-model or concilium review, adversarial verification of a research claim, benchmark
  number, or diff, says "have GPT/codex check this", explicitly asks to add the kimi or grok seat,
  wants codex set up as a reviewer, needs to switch codex models mid-session (park-and-resume), is
  tiering work across codex models, or wants to LOOP/iterate rounds until a claim converges. Also
  covers FORGE mode — cross-model idea GENERATION against an open research question, where seats
  build on each other's ideas through a shared register and nothing is judged or voted on — so use
  it when the user wants original ideas, a research plan, brainstorming across models, or asks what
  nobody has tried yet; and it catalogues the other multi-model modes worth running.
---

# Concilium — cross-model adversarial review

A second, *different* model reviews your (or the user's) claims adversarially. Different model
lineage means different blind spots — that's the value. The reviewer PROPOSES; the calling
session RATIFIES. Never let either side's confidence substitute for evidence.

Designed to be orchestrated from Claude Code — **Opus 5 and Fable 5 are both first-class
ratification seats** (measured at chair parity on a blind outcome-prediction benchmark; any
Claude model can drive the loop, but the ratifier should be one of the two). The GPT side
(sol/terra/5.5 via codex) does the independent probing and mechanical execution — and that
cross-family seat is load-bearing: it measurably catches what same-family chairs jointly miss.

## Prerequisites (check once per environment)

1. `codex login status` → must say "Logged in using ChatGPT" (subscription OAuth). An API key is
   NOT needed. It is not forbidden either — the wrappers inherit whatever session the CLI already
   has, so `codex login --with-api-key` works identically and simply bills per token. What does NOT
   work is the reverse: a subscription can NOT be used as an API key, so don't attempt proxy/router
   bridges.
2. Discover available models: `codex debug models` or `~/.codex/models_cache.json`. If a model
   errors "requires a newer version of Codex", run `codex update` and retry.
3. First time in a new environment, run the calibration bootstrap (references/setup.md) before
   trusting verdicts: a known-truth reasoning test, then one simple real task, then (optionally)
   a head-to-head to pick tier models.
4. Kimi seat — **EXPERIMENTAL and opt-in; never part of a default round.** Add it only when the
   user explicitly asks for a third family. Two transports, each with its own wrapper here:
   - **Kimi Desktop (Windows).** `scripts/concilium-review-kimi.ps1` drives the app's bundled
     daimon runner under its own Electron. Requires the desktop app installed and signed in.
   - **Kimi Code CLI (Linux/macOS/Windows).** `scripts/concilium-review-kimi.sh` drives the
     cross-platform, MIT-licensed CLI — headless `kimi -p` plus device-code OAuth, so it suits a
     container or a throwaway VM (worked example: references/isolated-guest-vmware.md). ⚠ Print
     mode auto-approves every tool call by construction, so isolation there is a precondition, not
     a precaution. ⚠ Always pass `--model`: the CLI's built-in default is an older generation than
     the flagship and nothing in the output names it.

   Calibrated but flakier than codex, and weaker on isolation: paths, models, sandboxing and the
   caveats are in references/setup.md and pitfalls #18–21.
5. Grok seat (xAI, fourth family) — **EXPERIMENTAL and opt-in; never part of a default round.**
   `scripts/concilium-review-cursor.{sh,ps1}` drive the **Cursor Agent CLI** on Cursor-subscription
   auth (no xAI API key, no per-token bill), default model `cursor-grok-4.6-xhigh`. Effort is baked
   into the model id, not a flag, and the wrappers refuse `-fast` ids unless you override.
   Isolation is better than kimi's (`--mode ask` provably blocks writes) but still not containment
   (the workspace is not a boundary; `--sandbox` is macOS/Linux only). It scored BELOW codex on the
   calibration packet — seat it for fourth-lineage coverage, not accuracy. Full detail, numbers and
   two Windows-only traps that silently break it: references/grok-seat.md, pitfalls #22–26.

## Tier matrix (defaults are current-day models — override per installation)

| Tier | Default | Effort | Use for |
|---|---|---|---|
| Research | flagship (e.g. `gpt-5.6-sol`) | **max** | open review rounds, adversarial verification |
| Mechanical | prev flagship (e.g. `gpt-5.5`) | medium | verify a known claim with one probe |
| Runner | cheap tier (e.g. `gpt-5.6-terra`) | low | execute-and-report: run a script, babysit an import |

Research-tier wrappers default to **max** on every seat. Effort vocabularies differ and are worth
knowing exactly: codex accepts `none · minimal · low · medium · high · xhigh · max` (measured —
the API rejects anything else and names the enum), the kimi seat accepts `low · high · max`.

**Effort is not a substitute for a second family — measured, with the control.** Six runs of one
seat (gpt-5.6-sol) over the same 14-item prediction packet, at low/medium/high/xhigh/max plus a
same-effort replicate: two runs at the SAME effort covered 10/14, while cross-effort pairs
averaged 8.9 and never beat that; the full six-run ensemble also reached only 10/14, equal to the
two-run noise floor and equal to one codex+kimi pair. Accuracy was not monotonic in effort
(high 9, max 9, xhigh 7, medium 7, low 7) while wall time grew 8× (21s → 166s). Four items were
missed by every run at every effort — and the cross-family seat got two of them. **Varying effort
resamples the same blind spots; a different lineage is what moves them.** If you want coverage,
add a family, not compute. `-Mechanical` is the deliberate opt-down and stays at `medium`.

Runner tasks are NOT reviews — skip the wrapper and call codex directly:
`codex exec -m <cheap-model> -c model_reasoning_effort=low [-s read-only unless it writes] "<task>" < /dev/null`
**Always close stdin on direct non-interactive calls** (bash `< /dev/null`; PowerShell `$null | codex …`) —
an open non-TTY stdin blocks codex forever on "Reading additional input from stdin...", and the orphaned
process survives the parent shell's timeout (pitfall #10; the wrappers are immune — they pipe via stdin).

## Modes

This skill has two halves. **Review mode** (the rest of this file) asks *is this claim true?* —
one seat probes, proposes, and the orchestrator ratifies. **Forge mode** asks *what has nobody
pointed at yet?* — seats generate original ideas against an open question, read each other's work
from a shared register and BUILD on it, and **nothing is judged or voted on**. Use forge when the
bottleneck is that the good idea has not been had yet; use review when a claim already exists and
might be wrong.

- Forge: `scripts/concilium-forge.{sh,ps1}`, method in `references/forge-mode.md`, brief template in
  `references/forge-brief-template.md`.
- The wider catalogue of multi-model modes — fragment verification, selective escalation, role
  rotation, blind replication, instrument audit, and the ones measured DEAD (effort sweeps,
  generation sweeps, instructed blindness, judge-over-transcripts, same-lineage majority votes) —
  is in `references/modes.md`.

### Offering a mode (what to do when the skill is invoked without one named)

The user will usually just describe a problem. **Default to review.** But first check the task
against the table below, and if a non-review mode clearly fits, **offer it in one or two lines
before running anything** — name the mode, say in a clause what it would return, and let the user
choose. Do not offer more than two, do not explain the catalogue, and do not offer at all when the
task is an ordinary "is this true?" — an unwanted menu is worse than no menu.

| If the user is about to / is asking… | offer | because |
|---|---|---|
| spend a batch of runs on a measurement, benchmark, eval or A/B | **instrument audit** | one call before the batch; it catches a fixture that cannot answer its own question |
| hand over a long write-up or a multi-claim result | **fragment verify** | a single verdict discards the parts that were right and hides the one load-bearing part that is wrong |
| act on a spec, schema or protocol others will implement | **blind replication** | two independent implementations; the divergences are the spec's ambiguities |
| settle something that looks underdetermined rather than wrong | **cross-examination** | returns the question list that has to be answered before a verdict means anything |
| stuck on framing, or the same approach keeps failing | **frame translation** | restates the problem in other fields' terms and imports their method |
| generate options, plans or research directions | **forge** | review's duty to refute kills a half-formed idea; forge is the opposite discipline |

Everything else — including all of `references/modes.md`'s remaining entries — is run only when the
user asks for it by name. Nothing here fires automatically.

Two requests about modes rather than for one, both common:

- **"Which mode fits this?"** — recommend, do **not** run. Name one mode (two at most), say what it
  would return that a review would not, and stop. The point of the question is the choice, so
  handing back a finished round instead of a recommendation answers a question they did not ask.
- **"Run every mode that applies."** — first rule modes OUT and say which and why: blind
  replication needs a specification, instrument audit needs a measurement design, fragment verify
  needs a multi-claim artifact. A mode with nothing to bite on returns a competent-looking void and
  costs a full round. Then run the survivors and report **the union of their findings, never a
  merged verdict** — they answer different questions, so two modes "disagreeing" is two findings,
  not a split to resolve. Warn about the cost before starting: N rounds at 5–15 minutes each.

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

**Grok fourth-family seat — EXPERIMENTAL, opt-in.** `concilium-review-cursor.sh` (env-configured:
`MODEL`, `MECHANICAL=1`, `ALLOW_FAST=1`, `REPO_DIR`, `PROJECT_RULES`, `PRIOR_ROUNDS`, `AUTO_RULES=1`,
`WATCH_PATHS`, `NO_HOME_ISOLATION=1`) and `concilium-review-cursor.ps1` (same surface as flags).
Both send the prompt on **stdin** (argv is mangled by the Windows shim), run `--mode ask --force`
(read commands, no writes), parse the CLI's `.result`, and count **distinct** contract blocks
instead of trusting the exit code. Auto-rules bridging is OFF: this CLI loads project
CLAUDE.md/AGENTS.md natively. See references/grok-seat.md before using it for anything blind.

**Kimi third-family seat — EXPERIMENTAL, opt-in.** Not part of a default round; add it only when
the user asks for a third family. Two wrappers, same contract and same five blocks:
`concilium-review-kimi.sh` (cross-platform CLI, env-configured — `MODEL` is mandatory there) and
`concilium-review-kimi.ps1` (Windows desktop runner).

The desktop wrapper takes the same `-Claim`/`-Diff`/`-RepoDir`/`-ProjectRules`/`-PriorRounds` surface, plus
`-Model` (default `k3-agent`), `-Effort` (`low|high|max`) and `-RawPrompt` (no contract, for
calibration probes). Two seat-specific differences, both measured: **CLAUDE.md auto-bridging is
OFF by default here** — the injection reliably kills the run with a bare `Connection error.`, so
it is opt-in via `-AutoRules`; use `-ProjectRules <file>` to give the reviewer context instead.
And **never trust its exit code** — it exits 0 on that failure, so check for the five blocks.
Multi-line prompts must go through this wrapper; a direct `kimi-daimon --prompt` from bash gets
its argv mangled (pitfalls #18–19).

**This seat has no sandbox — give it a disposable copy.** `-SandboxFrom <dir>` copies the tree
to a throwaway directory (excluding `.git`, virtualenvs and secret-shaped files), runs the agent
there, prints exactly what it created/modified/deleted, and deletes the copy unless
`-KeepSandbox`. Use it by default. Be clear about what it buys: workDir is **not** a boundary —
a canary outside it was read by absolute path and returned verbatim (pitfalls #20) — so this is
blast-radius control and an audit trail, not containment. If material on the machine must not
reach the provider, isolate at the OS level (separate account with ACLs, or a VM).

For a **blind round**, the risk from that same porousness is contamination rather than damage:
an agent that wanders into the real tree can find the answer, and the round silently stops being
blind. Add `-WatchPaths <a,b,c>` — it snapshots NTFS last-access times for whatever must stay
unread (the real repo, the results log, the answer key) and reports anything read during the
run. Validated against a known escape in both directions; read pitfalls #21 before trusting it,
including why an enumeration-based version of the same check reported "clean" on a run that had
demonstrably escaped.

**Reasoning boost — per-seat, measured, not a global switch.** `references/reasoning-boost.md` is a
short "hunt the non-obvious, take the strong position" block the wrappers can append to the contract.
It is **ON by default for the grok and kimi seats** and **OFF for codex**, because that is what was
measured: on a 14-item prediction packet it cut false alarms 33%→7% for grok (+13.3 pp) and 93%→67%
for kimi (+10.0 pp), while making codex *worse* (−6.7 pp, d′ 0.34→0.00). Override per round with
`REASONING_BOOST=0|1` / `-NoReasoningBoost` / `-ReasoningBoost`. It moves the decision criterion
toward refutation rather than improving reasoning, so ⚠ **it was measured in prediction mode while
these wrappers run adjudication mode, where chairs already over-refute** — if reviews start reading
as reflexively negative, turn it off. Detail and the per-seat table: `references/setup.md`.

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
- **Watch progress live, don't wait blind — and monitor the right stream.** The contract (rule 9)
  makes the reviewer emit `STATUS:` one-liners as it works, and codex writes progressively — but
  the streams split (verified live): with `1> out 2> err`, the **final five blocks land on
  stdout** while the **streaming transcript (banner, STATUS lines, tool calls) goes to stderr**.
  Point a tail/monitor at stderr for progress + failure signatures; read stdout for the verdict.
  Caveat: PowerShell `1>`/`2>` redirects write UTF-16 — decode accordingly (or redirect through a
  UTF-8-forcing step) before grepping.
- **A blind round needs structural isolation, not an instruction.** When the round must be
  unprimed (a blind eval, a framing-critical blind-first pass per request-template), run the
  reviewer in a clean directory with auto-rules bridging OFF (`-NoAutoRules` / `NO_AUTO_RULES=1`):
  a model carrying project context and told to "answer from the packet alone" measurably still
  uses that context (pitfalls #16–17).

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
6. **Weigh agreement by lineage.** Same-family confirmation (a Claude chair agreeing with a
   Claude orchestrator) is weak evidence — same-lineage chairs measurably share wrong answers,
   down to independently producing the identical wrong inference. A cross-family confirmation
   or refutation outweighs any count of same-lineage votes; never settle a dispute by majority
   across chairs that share a lineage. Two further families are available as experimental opt-in
   seats — Moonshot (kimi) and xAI (grok) — and an extra seat buys nothing unless it is
   *independent*, so weigh by family, not by headcount; note that a unanimous panel may simply mean
   the item was easy (setup.md). **Weigh a dissent by lineage, never by stated confidence** —
   measured, seats differ enormously in how much doubt they express (codex 99.7 mean vs grok 70.9
   on items they got right), so a confident vote and a hedged one are not comparable quantities.

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

### The reviewer sees AGENTS.md, not CLAUDE.md — mind the gap

codex auto-loads **`AGENTS.md`** (from the working directory upward), the same way Claude Code
auto-loads **`CLAUDE.md`**. They are different files: a project with only a `CLAUDE.md` gives the
reviewer *none* of the ground rules Claude has — it reviews half-blind. Three ways to close it,
in order of durability:

1. **Best (project-level): make `AGENTS.md` exist.** Mirror your `CLAUDE.md` into an `AGENTS.md`
   (or make `AGENTS.md` a short pointer to it), and keep them synced. This helps *all* codex
   usage, not just this skill, and is codex's own supported convention.
2. **Automatic (built into the codex wrappers): CLAUDE.md bridging.** When no `AGENTS.md` is
   present, the wrapper auto-injects the project's `CLAUDE.md` (root or `.claude/CLAUDE.md`) into
   the contract and prints a notice, so the reviewer isn't missing rules. Disable with
   `-NoAutoRules` / `NO_AUTO_RULES=1` (e.g. a huge, mostly-workflow CLAUDE.md you don't want in
   every review). **The kimi wrapper inverts this** — bridging is off unless you pass
   `-AutoRules`, because the injection breaks that seat (pitfalls #18); use option 3 there.
3. **Curated (explicit): `-ProjectRules <file>`.** Point at a short, hand-picked extract of the
   safety-critical rules — this *overrides* auto-bridging. Best for large instruction files where
   only a slice is relevant to review (invariants, "never touch X", schema quirks).

If you keep both files but let them drift, the reviewer sees the `AGENTS.md` version — sync them.

### Other adaptation
- If the project keeps a claims ledger, the PHASE-LOG block is a ready-to-paste line
  (`Phase N — <reviewer>(<model>) — <date> — <found> [proposed]`); append it only via the
  project's own hygiene rules (typically: owner or main session, append-only). No ledger → drop
  the block.
- Storage: keep probe outputs and frozen samples in a durable project location, never in
  session-scoped temp dirs (they die with the session).

## References

- `references/request-template.md` — how to construct the REQUEST you hand in (your side, not the
  reviewer's): confidence-tag facts (never "do not re-derive" over a conclusion), always mount the
  repo/DB, license rejecting the frame, and run a blind-first pass for framing-critical rounds. Read
  before writing any non-trivial request.
- `references/contract.md` — the review contract the wrappers send (edit it there; both scripts
  load it at runtime).
- `references/pitfalls.md` — known issues and the rules that counter them (read when a rule
  seems overcautious, or when debugging reviewer misbehavior).
- `references/setup.md` — first-time setup, calibration bootstrap, and the head-to-head method
  for picking tier models.
- `references/kimi-seat.md` / `references/grok-seat.md` — the two experimental extra-family seats:
  transports, measured limits, and what each one's testing produced for the skill as a whole.
