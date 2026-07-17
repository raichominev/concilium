# Pitfalls — the measured failures behind each rule

Every rule in SKILL.md was paid for. All incidents below were observed and verified in one
working day (2026-07-17) of building and calibrating this loop against a real research codebase;
identifying details generalized.

## 1. Bare resume silently resets model AND sandbox
A review session launched as `<flagship> -s read-only` timed out; it was resumed with
`codex exec resume -c model_reasoning_effort=high <id>`. The resumed banner showed the user's
config.toml defaults instead: a different model and `sandbox: workspace-write`. The "read-only
reviewer" had write access for two turns (audit showed only reads happened — luck, not design).
Worse: a verdict produced in those turns got attributed to the flagship model in notes.
**Rules**: re-pin `-m`, `-c sandbox_mode=`, `-c model_reasoning_effort=` on every resume; stamp
the model id into the output (the wrapper does this); flags before the positional session id.

## 2. `-c sandbox=read-only` is silently ignored
The config key is `sandbox_mode`. `-c sandbox=read-only` parses fine, does nothing, and the
banner keeps `workspace-write`. Silent-failure config keys are why the recipe is written out
verbatim rather than remembered.

## 3. Context compaction corrupts long resume chains
A session resumed three times (timeout → flag fix → table-name fix) hit a `compacted` event.
Its early full-text reads of the project docs and schema were lossy-summarized by the time it
wrote its final query — which contained the session's one serious bug (wrong join column).
**Rule**: fresh session per consequential review; if resuming, re-state critical facts (schema
semantics, invariants) in the resume prompt.

## 4. Confident wrong verdicts — ratification exists for a reason
Three incidents in one day, all with sound raw computation underneath:
- A probe joined two same-named id columns from different namespaces → clean-looking
  **0/40 → "[X] refuted"** that was 100% artifact. (The correct column existed on the same
  table; checking the model docstring + sampling values would have caught it.)
- A count mismatch (771 vs a claimed 538) was labeled "refuted" when the claim was actually
  *incomplete at write time* — a different failure with different consequences.
- A fallback proxy measurement was presented in the final blocks with flagship confidence, its
  "this is not the claim's actual protocol" hedge visible only in the reasoning trace.
**Rules**: the reviewer proposes, the caller ratifies; extremal first-attempt results (0%/100%)
mean *read the probe*; the CAVEAT block is mandatory so hedges survive into the final output.

## 5. Two probes can both be right — scope before comparing
Two models "disagreed" (0 overlap vs 3,547 overlapping ids). Ratification queries confirmed BOTH
exactly: one measured a single source's rows, the other the whole DB. The apparent contradiction
was a scope mismatch — and resolving it exposed an overgeneralized sentence in the human-side
notes. **Rule**: name the scope of every count before treating two numbers as comparable.

## 6. Refuted ≠ stale ≠ incomplete
A claim's numbers not matching today's DB has three different explanations: the claim was wrong
when written; the data drifted after; or the claim's scope was narrower than the checker assumed.
History tables/timestamps usually decide it — check before writing "[X]". (Measured case: a
"refuted" count was two-thirds under-count-at-write and one-third post-write drift.)

## 7. Reviews run long; foreground timeouts kill them mid-probe
A charter-compliant review (read rules → read target → grep code → form + run a real probe) took
5–15+ min at high effort. An 8-min foreground cap killed one mid-probe; its OS-level child work
died with the sandbox and nothing was salvageable. **Rules**: background from the first call,
full timeout; genuinely long replays (10+ min compute) belong in a detached OS process the
calling session monitors, not inside the reviewer.

## 8. Encoding: non-ASCII crashes default console pipes
Reviewer-spawned psql/PowerShell children crashed twice (`UnicodeEncodeError`, cp1251 codepage)
on Private-Use-Area and non-Latin glyphs in query output. **Rule**: force UTF-8 in any spawned
child (`[Console]::OutputEncoding`, `chcp 65001`, `PYTHONIOENCODING=utf-8`, or write query
output to a UTF-8 file instead of the console; on POSIX ensure a UTF-8 LANG/LC_ALL locale).

## 9. The reviewer is a full agent
Read-only sandbox blocks *file writes* — not shell reads, not DB SELECTs (it will happily use
credentials it finds in project docs), not network. Know what a probe can reach before pointing
it at a repo, and remember everything it reads is sent to the second model's provider.

## 10. Subscriptions are not API keys
A ChatGPT/Codex subscription authenticates the codex CLI via OAuth. It cannot authenticate a
proxy/router against the provider's API, and replaying the OAuth token outside the sanctioned
client is fragile and against ToS. If the user has a subscription, the CLI *is* the transport;
don't build bridges.
