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

## 10. Non-interactive `codex exec` blocks forever on open stdin
When launched from an automation harness (background shell, CI step) with the prompt as an
*argument*, codex sees a non-TTY stdin, prints `Reading additional input from stdin...`, and
blocks until EOF — which never comes if the parent holds the pipe open. Signature (hit for
real, 2026-07-18): zero stdout, a 39-byte stderr with only that line, and orphaned `codex.exe`
processes that *survive the parent shell's timeout kill* — the session looks "running" forever.
The wrappers are immune (they pipe the contract via stdin, which EOFs); **direct calls** — the
runner-tier pattern — are the trap.
**Rule**: every non-interactive direct call must close or terminate stdin: bash/CI
`codex exec … "<task>" < /dev/null`; PowerShell (no `<` operator) `$null | codex exec … "<task>"`;
or pass the prompt *via* stdin with `-` as the wrappers do. If a run shows the signature, kill
the orphaned codex processes before relaunching — they hold the session lock on nothing.

## 11. A subscription is not an API key
ChatGPT/Codex subscription auth is OAuth for the codex CLI only. It cannot authenticate a
proxy/router against the provider's API, and replaying the OAuth token outside the sanctioned
client is fragile and against ToS.
**Rule**: if auth is a subscription, the CLI *is* the transport. Don't build bridges.

## 12. "Stable" occurrence keys on rebuilt tables aren't
A witness key built on a table's auto-id is worthless if any pipeline step does
delete-and-reinsert — the ids silently renumber on the next rebuild, and every registered
witness dangles (hit for real 2026-07-24: a gold sidecar rebuilt via `.delete()` +
`bulk_create`; a ratifier-verified witness id would not have survived the next refresh).
**Rule**: before accepting any probe or artifact keyed on row ids, check the id column's
lifecycle (who deletes/reinserts?). Durable witnesses = fixture-scoped CONTENT keys plus an
immutable snapshot of the rows, registered as an artifact.

## 13. Iterated gating turns an oracle into a training signal
A held-out oracle (gold set, answer key) that gates candidates REPEATEDLY — with failures fed
back into the next proposal round — stops being held out: selection pressure optimizes against
it, and "gated" quietly becomes "trained on".
**Rule**: oracle gates are locked one-shot holdouts. No error feedback from the gate to the
proposer; a failed gate ends the candidate, not tunes it. If iteration is needed, split the
oracle and burn one slice per round.

## 14. A count derived by subtraction is not an inventory
"Remainder" numbers (total minus the handled subset) get presented as if they name real,
homogeneous items — and reviews then build plans on them (hit for real 2026-07-24: a claimed
"~30k lexical reserve" was `68,046 − 38,115`; actual verified members were 21,379, of which
only 15,720 matched the claimed shape).
**Rule**: any load-bearing count must be enumerable — the claimer (either side) shows the
query/filter that lists its members, not the arithmetic that implies them.

## 15. Case-insensitive grep and console literals lie about non-Latin text
Two encoding traps beyond rule 8's crash class, both silent: `grep -i` under a C locale does
NOT case-fold non-Latin scripts (a lowercase Cyrillic pattern misses its uppercase form and
returns clean-looking "no matches"), and non-ASCII literals typed into a Windows console query
arrive in the console codepage, not UTF-8 (either an encoding error — the lucky case — or a
wrong-bytes search). Both hit for real 2026-07-24 while ratifying a Cyrillic-concentration
claim.
**Rule**: for non-Latin probes, write patterns with explicit case alternatives (or use tools
with true Unicode folding), and pass non-ASCII SQL via a UTF-8 file (`psql -f`) or explicit
byte escapes — never inline on the console. A "no matches" on non-Latin data needs one
positive control before you believe it.
