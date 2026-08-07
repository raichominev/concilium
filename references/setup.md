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

### Kimi seat (optional third family — Windows)
Requires **Kimi Desktop installed and signed in**; there is no standalone CLI and no API key.
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
   off) on the identical packet. One run per chair minimum; two catches run instability.
3. Score accuracy against recorded outcomes — but also PAIRWISE ERROR OVERLAP: two chairs that
   miss the same items add less than their solo accuracies suggest. Seat by PANEL COVERAGE
   (which pair/trio leaves fewest items missed by all), not by solo rank.
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
(pitfall #21). Two runs, 12 and 14 sound items:

| | codex | claude | kimi |
|---|---|---|---|
| run A (12 items) | 9/12 | 10/12 | 9/12 |
| run B (14 items) | 9/14 | 7/14 | 7/14 |

In run A every pair covered 11/12 and **the trio covered 12/12**, with each pair's both-miss a
*different single item* — so each seat was the sole correct answerer on exactly one item and
**removing any seat cost exactly one item**. In run B the best pair was codex+kimi at 10/14
against codex+claude at 9/14: on that packet the cross-family seat was a better second chair than
a same-lineage one, which is what the lineage rule predicts.

Three things worth stealing from the failures:

- **Exclude any item whose recorded outcome the log itself attributes to noise.** Grading a chair
  against an outlier the author already called unrepeatable measures variance, not judgement.
- **Ship every file a chair needs to answer.** One item was unanswerable because the relevant
  module was left out of the sandbox; all three "failed" it while reasoning correctly from the
  evidence they had. Both of run A's apparent shared blind spots turned out to be defective items
  — check your instrument before you report a blind spot.
- **Randomise item order.** A first draft had every true-WIN item first; position must carry no
  signal.

Direction of error is **mode-dependent**, and this is the most transferable result: in adversarial
*adjudication* chairs over-refute (they reject true claims), while in outcome *prediction* the
same models were over-credulous — 61% correct on changes that worked versus 46% on changes that
failed. Never carry a bias correction from one mode into the other.

**Calibration**: on items every seat got right, mean stated confidence was codex 99.7 (96–100,
effectively flat), Kimi 95.1 (80–99), Claude 93.9 (90–97). Codex is least willing to express
doubt, Kimi most — relevant when weighing a lone dissenter, and one more reason never to weight a
vote by its own stated confidence.

**Reliability**: 0/2 Kimi wrapper runs completed with rule auto-bridging on, which is why that
wrapper defaults bridging OFF. With bridging off it is better but not reliable (pitfalls #18).
Never trust its exit code.

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
