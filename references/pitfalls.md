# Pitfalls — known issues and the rules that counter them

Each entry: the issue as you'll encounter it, then the rule. All of them were hit for real
while building this loop; none are theoretical.

## 1. Bare `codex exec resume` resets model AND sandbox
`resume` re-resolves model and sandbox from `~/.codex/config.toml`, silently discarding the
`-m`/`-s` flags the session was originally launched with. A read-only flagship review can come
back as a default-model session with `workspace-write` — and its output gets misattributed.
**Rule**: resume only with the full re-pin, flags BEFORE the positional session id:
`codex exec resume -m <model> -c sandbox_mode="read-only" -c model_reasoning_effort=<tier> <session-id> -`
The wrappers stamp `model=`/`effort=` into every prompt so output is attributable regardless.

## 2. `-c sandbox=...` is silently ignored on resume
The config key is `sandbox_mode`. `-c sandbox=read-only` parses, does nothing, and leaves you
in `workspace-write`. There is no `-s` flag on resume at all. Verify the banner
(`sandbox: read-only`) rather than trusting the flag you passed.

## 3. Long resume chains hit context compaction
A session resumed several times can compact its context: the careful early reads (docs, schema,
invariants) get lossy-summarized before the final — usually most consequential — step. That's
when subtle bugs appear (e.g. a wrong join column in the closing query).
**Rule**: fresh session per consequential review. If you must resume, re-state the critical
facts in the resume prompt instead of trusting they survived.

## 4. Confident wrong verdicts on top of sound computation
The reviewer's arithmetic and SQL execution are reliable; its *verdict framing* is the weak
layer. Observed variants: a perfect-looking probe built on a wrong join key (two same-named
columns from different ID namespaces) yielding a clean 0% → "refuted"; a fallback/proxy
measurement presented with the confidence of the real protocol, its hedge visible only in the
reasoning trace.
**Rules**: the reviewer proposes, the caller ratifies by reading the actual probe; a 0% or 100%
first-attempt result is a tripwire, not a discovery; the CAVEAT block is mandatory so hedges
survive into the final output.

## 5. Two probes can both be right — at different scopes
Apparent contradictions between two reviews (or a review and your own notes) are often scope
mismatches: one measured a single source/table, the other the whole dataset. Both numbers can
ratify exactly.
**Rule**: name the scope of every count before comparing; resolve "disagreements" with a
deciding query, not by picking the more confident answer.

## 6. Refuted ≠ stale ≠ incomplete
"Today's numbers don't match the claim" has at least three explanations: the claim was wrong
when written, the data drifted afterwards, or the claim's scope was narrower than the checker
assumed. They have different consequences.
**Rule**: check history/timestamps before accepting an `[X]`; make the reviewer (and yourself)
say *which kind* of wrong it is.

## 7. Real reviews run long
A contract-compliant review (read rules → read target → explore code → form and run a probe)
takes 5–15+ minutes at high effort. A foreground call with a shorter timeout dies mid-probe,
and any OS-level work it spawned dies with the sandbox — unrecoverable.
**Rule**: run in background with a generous timeout from the FIRST call. Genuinely long compute
(10+ min replays) belongs in a detached OS process the calling session monitors, not inside the
reviewer.

## 8. Encoding crashes in spawned children
Child processes (psql, PowerShell) inherit the console's default codepage; non-ASCII output
(non-Latin scripts, Private-Use-Area glyphs) raises hard encoding errors mid-probe.
**Rule**: force UTF-8 in every spawned child — `chcp 65001` / `[Console]::OutputEncoding` /
`PYTHONIOENCODING=utf-8` on Windows, a UTF-8 `LANG`/`LC_ALL` on POSIX — or write output to a
UTF-8 file instead of the console. (Contract rule 7 tells the reviewer the same.)

## 9. The reviewer is a full agent, not a chatbot
`-s read-only` blocks file writes — not shell reads, not DB SELECTs, not network. It will read
whatever the repo exposes (including credentials in docs) and use them for read queries, and
everything it reads is sent to the second model's provider.
**Rule**: know what a probe can reach before pointing it at a repo; treat repo contents as
shared with the provider.

## 10. A subscription is not an API key
ChatGPT/Codex subscription auth is OAuth for the codex CLI only. It cannot authenticate a
proxy/router against the provider's API, and replaying the OAuth token outside the sanctioned
client is fragile and against ToS.
**Rule**: if auth is a subscription, the CLI *is* the transport. Don't build bridges.
