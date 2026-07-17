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
