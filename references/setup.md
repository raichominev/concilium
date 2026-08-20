# First-time setup & calibration

## Install / auth
- `codex --version` — any reasonably current CLI; it self-updates. `codex update` to force.
- `codex login status` → "Logged in using ChatGPT". If not: `codex login` (user does this — it's
  an OAuth flow). No API key involved anywhere.
- Model inventory: `codex debug models` (or `~/.codex/models_cache.json`). A 400 "requires a
  newer version of Codex" on a listed model → `codex update`.
- Usage telemetry: session rollouts under `~/.codex/sessions/**.jsonl` embed `rate_limits`
  snapshots (`used_percent`, `window_minutes`, `resets_at`, `plan_type`) — useful when the user
  asks "how much of my quota did this eat?" (windows are typically weekly, so drains look small).

### Kimi seat (optional third family)
Two transports. Only the desktop one has a wrapper in this repo.

**Kimi Code CLI (Linux/macOS/Windows) — `scripts/concilium-review-kimi.sh`.** The engine is
cross-platform and MIT-licensed. Install via the official script (single binary, no Node needed) or
`npm i -g @moonshot-ai/kimi-code` with Node ≥22.19.0; state lives in `~/.kimi-code/`, relocatable
with `KIMI_CODE_HOME`. Auth is device-code OAuth (authorise on any device) or a platform API key,
so it works headless. Verified against v0.34.0:
- **Always pass `--model`.** The shipped `default_model` is an older generation than the flagship,
  and nothing in the output tells you which model answered. A seat you did not choose is not a seat.
- **Reasoning effort is config-only** — there is no `--effort` flag. It lives per model alias in
  `config.toml` as `default_effort`, alongside the `support_efforts` list for that alias.
- **Prompt goes in via `-p` as an argv argument.** Piping to stdin without `-p` hangs on a TTY wait;
  it is not an input path. There is no `--final-message-only`/`--print`/`--quiet`/`-w`: use
  `--output-format stream-json` and take the last `{"role":"assistant"}` line, and `cd` for workdir.
- ⚠ Print mode auto-approves every tool call by construction — *more* permissive than the desktop
  seat's `manual` mode — so run it in a container or throwaway VM.
- ⚠ Naming trap: the PyPI `kimi-code` is an empty meta-package for the legacy Python agent (state in
  `~/.kimi/`); the real one is the npm package.

**Kimi Desktop (Windows) — the shipped wrapper.** Requires the desktop app installed and signed in.
`scripts/concilium-review-kimi.ps1` drives the bundled `kimi-daimon` runner directly:
- Runtime: `%APPDATA%\kimi-desktop\daimon-bundle` — its `bin\` launcher wants Node 24 that the
  bundle does not ship, so the wrapper runs `dist/src/runner/cli.js` under the app's own Electron
  (`Kimi.exe` with `ELECTRON_RUN_AS_NODE=1`). Override paths with `CONCILIUM_KIMI_EXE`,
  `CONCILIUM_KIMI_BUNDLE`, `CONCILIUM_KIMI_SHARE`.
- Models come from the app config (`daimon-share\daimon\config.json`); the wrapper validates
  `-Model` against it and errors with the available list. `k3-agent` is the flagship.
- The wrapper writes its **own** agent home under `daimon-share\concilium\` and never edits the
  app's config. Sandbox: the hosted agent config accepts only `manual` or `yolo` — `manual` is
  the default and is an agent-config constraint, not an OS sandbox (weaker than codex's
  `-s read-only`; assume the reviewer can read anything under its workDir).
- CLAUDE.md auto-bridging is **off by default** for this seat (opt in with `-AutoRules`; prefer
  `-ProjectRules`) — see pitfalls #18. Pass multi-line prompts only through the wrapper (#19).

### Grok seat (optional fourth family)

Transport is the **Cursor Agent CLI** on Cursor-subscription auth — no xAI API key. Install:
`curl https://cursor.com/install -fsS | bash` (Windows: `irm 'https://cursor.com/install?win32=true' | iex`),
then `cursor-agent login` (browser/device OAuth — the user does this) and `cursor-agent status` to
confirm. `cursor-agent --list-models` prints the roster; **effort is baked into the model id**
(`cursor-grok-4.6-{low,medium,high,xhigh}`, each with a `-fast` sibling) and there is no effort flag.

- The installer writes PATH into `.bashrc`, which non-interactive SSH never sources — put it in
  `.profile` instead, exactly like the kimi CLI, and verify with `bash -lc 'command -v cursor-agent'`.
- A fresh working directory needs `--trust` in headless, or the run refuses with a trust prompt.
- On Linux the session also lives in `~/.local/share/cursor-agent`, which `CURSOR_CONFIG_DIR` does
  **not** cover — see pitfalls #22 before touching `HOME` for this seat.

Seat detail, measured limits and calibration numbers: [`grok-seat.md`](grok-seat.md).

## Calibration bootstrap (do this before trusting verdicts in a new environment)

1. **Known-truth reasoning test** (proves the connection + model sanity, no tools):
   ask the reviewer to hand-trace a program whose output you've captured by running it. A good
   probe is a Python mutable-default-argument trap — models that pattern-match instead of
   tracing get it wrong:
   ```python
   def f(x, acc=[]):
       acc.append(x)
       if len(acc) < 3:
           return f(x * 2, acc)
       return list(acc), sum(acc)
   results = []
   for i in range(3):
       results.append(f(i + 1))
   print(results)
   ```
   Forbid code execution in the prompt; require `ANSWER:` as the last line; compare exactly.
2. **One simple real task** from the target project (a claim you already know the full truth
   about, ideally including a written-when nuance). Grade both the numbers AND the verdict
   framing — overconfident "refuted" on stale-vs-wrong is the common miss.
3. Only then use it on load-bearing claims — with ratification always on.

## Choosing tier models: the head-to-head method

When unsure which model gets a tier (e.g. new mid-tier vs old flagship):

1. Pick 3 known-truth tasks: one pure-reasoning (the trace above), one real DB/code claim with
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

**Calibration (bootstrap steps 1–2).** Both reviewer seats passed the known-truth reasoning trace
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
generation behaves like reasoning effort (measured above): it resamples the same blind spots
rather than moving them. **Only a different lineage moves them** — that is now three independent
measurements pointing the same way (effort, repetition, generation).

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
The cause is the saturation rule below wearing a second costume: the items were classic language
gotchas, which are **memorized facts, not derivations** — self-contained is not the same property as
unsaturated. A packet that could measure this needs claims computed from invented data, plus
true-but-surprising claims to bait refutation.

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

## Wrapper defaults

`scripts/concilium-review.ps1` / `.sh` default to models current at authoring time. Check the
tier table in SKILL.md against `codex debug models` on first use and override via
`-Model`/`MODEL` or edit the defaults for your installation.

## Networking & architecture — no inbound port

The wrappers invoke `codex exec` / `codex review`, which talk to the model over **stdio** (the
prompt is piped to stdin, the result read from stdout) — a plain subprocess. Verified: a review
run opens **no listening TCP port** of its own; nothing inbound is exposed by using this skill.

codex *does* ship networked/daemon modes for its interactive and integration architecture —
`app-server`, `exec-server`, `--remote <ws://IP:PORT>`, and `mcp-server`. If you have ever seen
codex "on a port", that's one of these (typically the interactive app-server daemon), bound to
**loopback (127.0.0.1)** and gated behind auth for any non-loopback listener. **This skill uses
none of them** — only `codex exec`/`review` over stdio. So you can install and run it without
opening a firewall or exposing a service; the only outbound traffic is codex's normal,
authenticated call to the model provider.
