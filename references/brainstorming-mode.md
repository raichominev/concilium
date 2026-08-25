# BRAINSTORMING mode — open-book idea brainstorminging with live data

Formed 2026-08-24 from one full campaign: 19 generation runs across 8 seats and 8 vendors, three
build rounds (C1 comments, C2/C3 combination), 341 register entries, ~1,700 peer comments, 5
implementation sessions spawned, and a dossier pipeline the project owner drove. Everything below
is tiered by evidence: **[proven]** fired ≥2 independent times, **[once]** observed once,
**[open]** designed or hypothesised, not measured. Wire nothing [open] as a rule.

## What it is, and when

BRAINSTORMING is forge's inversion for a question where **conventional methods are exhausted and nobody
knows where the door is**: high volume instead of a 6-idea cap, the known-methods list as a *label*
instead of a suppressor, and **open-book** — seats get a live read-only copy of the system under
discussion: its data and/or its source tree, whichever exist. Use it when the ask is "generate all
sorts of crazy ideas against this system" and the system can be safely replicated read-only into an
isolated environment. The campaign that formed the mode ran against a database; where the notes
below say Postgres or SQL, read them as that campaign's INSTANTIATION of the roles (immutable
snapshot, per-seat identity, server-side action log, replayable evidence) — the roles are the
method, the database is one way to fill them. Keep
forge for closed-book originality scoring; keep review for verdicts.

**The mode's real product surprised its design [proven].** It was built with ideas as deliverable 1
and findings as deliverable 2. Backwards: every result that changed what the project believed
arrived as a **finding** (a checkable claim about the data), while ideas needed the multi-round
dossier machinery before they compounded. Open-book generation audits far better than it invents —
say so in the brief, demand both, and treat the findings stream as the fast payoff and the idea
stream as the slow one.

## The instrument

- **Isolated guest, rootless everything [proven].** Postgres unpacked from distro .debs into the
  guest user's home (no sudo: `apt-get download` + `dpkg-deb -x`; point
  `unix_socket_directories` at the home tree; `jit=off` avoids the LLVM packages). Python tooling
  via the `virtualenv.pyz` zipapp when pip is absent.
- **One SELECT-only role per seat** with `default_transaction_read_only = on` and a statement
  timeout [proven — 19 runs with shell access, zero fixture damage, verified by tree checksum].
- **The dig log is the server's statement log** (`log_statement='all'`,
  `log_line_prefix='%m|%u|%p|'`): per-seat, timestamped, and the one record a model cannot
  misreport [proven — it separated real exploration styles (640 vs 117 statements, 31 vs 8 tables)
  and exposed one seat's checkbox ritual of `count(*)` against nonexistent tables].
- **Fixture freshness is a validity condition [proven, the hard way].** A snapshot two days older
  than a schema change manufactured a confident THREE-VENDOR convergent finding. Convergence
  measures shared input as readily as shared truth. Gate every round on a fixture-vs-live diff, or
  state the fixture date in the brief and require structural claims to be re-checked against the
  source tree.
- **Deliberately withheld data must be named in the brief [proven].** Seats rediscovered an
  intentionally-empty table three times until the brief said it was intentional.

## The contracts

- **Boldness quota [proven, 18/19 runs held it exactly]:** 4 incremental / 4 aggressive / 4
  "would get you laughed out of the room", the tier-3s carrying `why_absurd` and
  `what_must_be_true`. A quota produces wild ideas; asking for "crazy" produces adjectives.
- **Evidence contract + replay [proven]:** every idea carries the SQL it ran and the result it got;
  the harness re-executes both. Across 311 replayed queries, fabrication was ≈0 — the live DB is
  the entailment oracle that closed-book receipt-checking could never be. Unplanned second use
  [once]: replaying an old round's SQL against refreshed data separates STALE findings from
  fabricated ones mechanically.
- **Checkpoint-as-you-go [proven — saved ≥5 runs on 4 transports]:** every finished object appended
  to a file the moment it exists. Transports have eaten completed answers via an output-side
  content filter, prose-wrapped finals, empty results and truncation; the checkpoint is what
  survives. The runner promotes a non-empty checkpoint when the final message is empty.
- **Denominator rule [proven, twice over]:** every rate must state its population. Measured 97%
  compliance in the first round that carried it as a brief invariant — and the reconciliation pass
  found that FOUR of the campaign's six recorded disagreements died of unnamed denominators or
  unnamed comparison keys. Naming the population is not hygiene; it is where the contradictions
  actually lived.

## The rounds

1. **Generation** (per seat, parallel where transports are disjoint).
2. **C1 — peer comments:** every seat reads all other seats' ideas ([YOURS] excluded), comments
   constructively — what would make it work, combinations by id, sharpest risk, better cheapest
   test. **No verdicts, no scores, no votes.** Allow an honest pass but see the gemini lesson below.
3. **C2/C3 — build rounds:** seats receive the COMPLETE dossiers as files and produce up to 8 new
   ideas, each REQUIRED to cite ≥2 parent entries, plus up to 10 targeted comments. Chains of
   chains and evidence-backed dissent both invited.
4. **Live verdicts feed back [once, worked well]:** when an implementation session settles a
   claim, stamp the verdict on the dossier entries before the next round and tell seats to argue
   WITH verdicts, not about them.

**Did the multi-round bet pay? [once — treat as promising, not proven.]** The owner's hypothesis
was that giving every seat everything said so far triggers inter-idea signals. Observed in one
campaign: the owner's own entry became the most-built-on idea of C2; two seats independently
converged on deriving its rule-set mechanically; C3 produced chains citing four C2 parents and a
three-seat convergence on an evaluator defect. No overlap metric between rounds was computed, and
the clean-round discovery-capacity experiment has since run — see the closing section. **Known limitation [once]: the panel
plus three rounds still missed a gap the owner found by asking one question** (a match-time
mechanism whose machinery existed generate-side); breadth of search does not substitute for the
domain expert's question.

## The dossier pipeline — the orchestrator NEVER curates ideas

Covered in `modes.md` §"IDEAS are never synthesised"; operationally [proven by owner acceptance
across three rounds]:

raw verbatim ideas → conservative mechanical grouping (same MECHANISM only, every member's wording
preserved, cosine-proposed pairs hand-adjudicated, when in doubt no group) → a visible vetoable
FILTERED list (only resolved/ruled-out premises) → per-entry dossiers accumulating peer comments,
test-run stamps and live verdicts → a mechanical INDEX (counts only; sort key = the seats' own
combine-with graph) → **the human reviews dossiers, never a shortlist**.

## Session architecture

Per `modes.md` §"A research session does NOT implement": the BRAINSTORMING session briefs, runs,
verifies fixture-side, folds, and spawns; **live verification and every fix goes to implementation
sessions** [proven — 5 spawned, zero collisions, one live verdict returned and folded]. Findings
hand over as verified measurements, never as seat quotes.

## Seat handling — behaviour is task-shaped, never global [proven]

- One seat wrote panel-quality comments at 15 entries and collapsed to passes, then to one
  boilerplate template, at 190 — while its GENERATION rounds were fine. Fix: chunk bulk tasks for
  that seat; and treat "pass" as an effort-budget signal, not an entry judgment. An honest-pass
  escape clause will be exploited by exactly the seat it wasn't designed for.
- Cursor-routed seats read stdin; claude/kimi/agy take argv — **Linux caps one argv string at 128
  KiB**, so big packets ship as FILES in the seat's cwd with a pointer prompt [proven — 7 seats
  died in 0 s teaching this].
- agy needs `--dangerously-skip-permissions` and a raised `--print-timeout` or returns 0 bytes;
  Alibaba content-inspects OUTPUT (medieval text can trip it); quota exhaustion arrives as
  transport failure (Z.ai 5-hour window, Moonshot billing cycle) — **retry once before recording a
  seat as failed, and check the artifact, never the marker** [proven repeatedly].
- Web access is a behaviour, not a capability tier [once]: the seat with the best web tooling used
  none of it; a compat-endpoint seat used it.

## What is deliberately NOT in this method

- No orchestrator ranking, shortlisting or synthesis of ideas — measured reasoning in `modes.md`.
- No majority voting anywhere.
- No self-training-shaped uses of the system's own output as a correctness signal; a project's own
  stored analyses are population data only.
- The reconciliation pass over disagreement lists (one cross-examination call per contradiction)
  remains **[open]** — designed, never run.
- A discovery-capacity measurement (clean repeat round after fixes land, scored by overlap with
  the previous round's findings) — **measured, 2026-08-24** [once]: pre-registered 8-seat round on
  a same-day repaired fixture; 40 findings classified against the prior campaign's 94 → R-FIXED 1
  · R-KNOWN 26 · NOVEL 13 (32.5%, all replay-surviving) → the frozen rule's capacity branch fired:
  the panel finds beyond fixture salience. The one R-FIXED was the fixture predating a fix — a
  row-count drift gate cannot see rows moved in place; add a content probe per fixed table next
  time. Result: the origin project's `brainstorming/discovery/DISCOVERY-CAPACITY-RESULT.md`.
