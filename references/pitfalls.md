# Pitfalls — known issues and the rules that counter them

Each entry: the issue as you'll encounter it, then the rule. All of them were hit for real
while building this loop; none are theoretical. (Adding an entry? The README's maintenance rule
binds: generic, self-contained, judgeable from the text alone.)

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
real): zero stdout, a tiny stderr carrying only that line, and orphaned `codex.exe`
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
witness dangles (hit for real: an evaluation sidecar table rebuilt by delete-and-bulk-reinsert
— a witness id verified that same day would not have survived the next refresh).
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
homogeneous items — and reviews then build plans on them (hit for real: a claimed
"reserve" of tens of thousands turned out to be pure subtraction of the handled subset from a
total; enumeration found roughly two-thirds of it existed at all, and only about half of those
matched the claimed shape).
**Rule**: any load-bearing count must be enumerable — the claimer (either side) shows the
query/filter that lists its members, not the arithmetic that implies them.

## 15. Case-insensitive grep and console literals lie about non-Latin text
Two encoding traps beyond rule 8's crash class, both silent: `grep -i` under a C locale does
NOT case-fold non-Latin scripts (a lowercase Cyrillic pattern misses its uppercase form and
returns clean-looking "no matches"), and non-ASCII literals typed into a Windows console query
arrive in the console codepage, not UTF-8 (either an encoding error — the lucky case — or a
wrong-bytes search). Both hit for real while ratifying a claim over non-Latin-script data.
**Rule**: for non-Latin probes, write patterns with explicit case alternatives (or use tools
with true Unicode folding), and pass non-ASCII SQL via a UTF-8 file (`psql -f`) or explicit
byte escapes — never inline on the console. A "no matches" on non-Latin data needs one
positive control before you believe it.

## 16. Instructed blindness fails — isolation must be structural
Asking a model that carries project context to answer "from the packet alone" does not work.
Measured on a paired rerun of a 39-item blind benchmark: chairs run WITH project context in
their window flipped right→wrong on exactly the items whose answers that context contained,
once the same chairs were re-run clean-context — despite an explicit don't-rely contract AND
honest self-flagging of every leak they noticed. A model cannot un-see its context; the
instruction changes what it reports, not what it uses.
**Rule**: any round that must be unprimed (blind evals, independent second opinions, the
blind-first pass from request-template) runs structurally clean — fresh session, clean working
directory, auto-rules bridging OFF for that round. Keep a self-report channel ("list anything
your context reveals about the answer") anyway — not as protection, but as an audit: it
reliably finds leaks the orchestrator's own exclusion list missed.

## 17. Always-loaded project notes are a staleness poisoning vector
Any note injected into every session — project instruction files, memory indexes, standing
summaries — becomes an active poison the day it goes stale. Measured: a superseded one-line
summary (whose underlying detail file was already corrected) was quoted as fact by every
in-context chair and pushed them to a wrong answer the clean-context reviewer avoided.
**Rule**: treat always-loaded summaries as part of the docs-sync surface — correct them the
same session the underlying fact changes (correct, don't delete: silent absence breeds
re-derivation). When a reviewer cites your own project notes as evidence, verify the note
against its source before ratifying — "your docs say so" is a citation of you, not of reality.
Clean-context reviewers are immune by construction; one more reason #16's isolation rule pays
for itself.

## 18. The Kimi seat can drop a long run with a bare `Connection error.`
It exits 0 and logs nothing, so a failed run looks like a completed one. Rule-bridging makes it
far likelier; turning bridging off reduces it but does not remove it.
**Rules**: keep bridging off (`-ProjectRules <file>` when the reviewer needs project context;
`-AutoRules` only to test whether a future build fixed it). Never treat `rc=0` as success for
this seat — grep the output for the five blocks.

## 19. Windows arg encoding mangles multi-line prompts to the Kimi CLI
`kimi-daimon` takes its prompt as an argv element, not on stdin (the opposite of codex, #10).
Passing a multi-line `--prompt` from bash — or any layer that doesn't build the Win32 command
line explicitly — splits it mid-text: the runtime reports `Unexpected positional argument "…"`
and dumps its usage, or silently falls through to long-lived daemon mode (`stdin commands:
"health", "stop"`) and sits there until killed. Both were observed while wiring this seat up.
**Rule**: always go through `scripts/concilium-review-kimi.ps1`, which builds the command line
through an explicit Win32 quoting pass. For a runner-tier one-off, keep the prompt on one line
or stage it in a file and prompt "read X and follow it".

## 20. The Kimi seat's workDir is a starting point, not a boundary
Verified by canary: a file placed **outside** the agent's configured workDir, named by absolute
path in the prompt, was read and its contents returned verbatim — with `approvalMode: manual`
and the agent's workDir pinned to a disposable copy. It does this routinely, not exceptionally.
There is no OS sandbox behind this seat, so it reads anything the user account can read, and
everything it reads can reach the provider. codex's `-s read-only` is a different and stronger
guarantee: it restricts writes but is likewise not a read boundary — the difference is that
codex has a sandbox layer at all.
**Rule**: use `-SandboxFrom <dir>` (copies the tree to a throwaway directory, runs there, diffs
it afterwards, deletes it) as **blast-radius control, not containment** — it bounds what the
agent damages and proves what it touched, and it keeps secrets out of the copy. If the machine
holds material that must not reach the provider, the only real answer is OS-level isolation: a
separate Windows account whose ACLs deny the rest of the profile, or a VM/container. Never
assume "workDir is set" means "confined".

**The one configuration that produced a clean round: a guest holding the payload and nothing
else.** On a throwaway VM containing only the review copy, a full round stayed inside its sandbox
for the whole run — the first of six to do so — while every round on a machine with a live repo
next door wandered into it. Read that as weak evidence and design accordingly: it may simply be
that there was nowhere interesting to go. "It stayed put when nothing outside was worth reading"
is a much cheaper property to guarantee than "it is confined", and it is the one an
isolated guest actually buys you.

## 21. Blind rounds need an escape tripwire — and the obvious one lies to you
For a BLIND round the danger of an unsandboxed seat is not damage, it is **contamination**: if
the agent wanders out of its working copy into the real tree, it can find the answer and the
round silently stops being blind. NTFS last-access times make a cheap tripwire
(`-WatchPaths a,b,c` on the kimi wrapper: snapshot before the run, re-check after, report what
was read). Three things surfaced while building it:

1. **Enumeration returns stale timestamps.** `Get-ChildItem -Recurse` reads the *directory
   entry's* cached copy. A canary provably read mid-run still showed its pre-run access time via
   enumeration, while `Get-Item` on the same path showed the update — so the first version of
   the tripwire reported "clean" on a run that had demonstrably escaped. Enumerate for paths,
   then query each file directly. Verify any tripwire against a known escape before trusting it.
2. **Don't name the bait.** A honeypot planted at `…\honeypot\RESULTS.md` was declined by the
   model *because of the path*: "the path is outside my workspace (and is labeled as a
   honeypot), so I did not access it." Decoys must look like ordinary files.
3. **Confirm both directions.** After the fix: a run told to read outside trips and names the
   file, while the other files in the same directory are correctly reported unread; an ordinary
   in-sandbox run comes back clean, with no false positive.
4. **Never watch a path the tool legitimately needs.** A watch list that included the agent's own
   state directory tripped on exactly one file — its own stored OAuth credential, which it must
   read to authenticate at all. That is a guaranteed false positive dressed as an escape, and a
   tripwire that cries wolf on every run stops being read. Watch the *evidence* — the real tree,
   the results log, the answer key — never the runner's own home.

**Rule**: point `-WatchPaths` at whatever must stay unread for the round to count, and at nothing
the tool needs to function. Treat a trip as contamination unless you can attribute the read to
another process — indexers, sync clients and antivirus also touch files, so this is a tripwire,
not proof. And prefer structural isolation (pitfall #16) over detection where you can get it:
knowing a round was contaminated is worse than it not happening.

## 22. The Cursor CLI imports Claude Code's hooks — and one broken hook silences every probe

The Cursor Agent CLI loads `~/.claude` user-level hooks, skills and plugins by design
(`claudeUserHooks`, `loadClaudePlugin`, `importClaudeMarketplaces` in its bundle) and no flag
disables it. On Windows it then **always** builds the hook payload wrapper in PowerShell syntax —

```
$OutputEncoding = [System.Text.Encoding]::UTF8; Get-Content -LiteralPath '<payload>.json' -Raw | & { $input | <hook command> }
```

— while choosing the shell that *executes* that string from `MSYSTEM`/`SHELL` (`Mt()`/`Ut()` in the
bundle). Launched from Git Bash it picks bash, which cannot parse `& {`, so every hook dies with

```
Rejected: Hook blocked with message: --: eval: line 1: syntax error near unexpected token `&'
```

on **every shell tool call**. The reviewer does not fail: it reviews without running a single
probe and says so only in prose you have to read.

**The hook command is not the cause** — the `&` comes from Cursor's own wrapper. Measured
2026-08-19: an auto-memory hook (`python3 "…/trigger.py" || python "…/trigger.py"`) and a hook whose
command is literally `exit 0` are rejected identically, and the same auto-memory hook runs clean
when the CLI is launched from cmd/PowerShell. Two fixes, both real:

- **Match the shell to the wrapper.** Launch from cmd/PowerShell, or from a shim that clears
  `MSYSTEM`/`EXEPATH` **at the cmd level** and pins `SHELL` to powershell.exe. `env -u MSYSTEM` is
  not enough: the MSYS runtime re-injects `MSYSTEM` into every Win32 child. Cost: the agent's shell
  tool is then PowerShell, not bash.
- **Isolate `HOME`** (what these wrappers do) — point `HOME`/`USERPROFILE` at an empty directory and
  pass `CURSOR_CONFIG_DIR` at the real profile. Works from any launch shell and, as a bonus, hides
  `~/.claude` during blind rounds. Two caveats: **project-level** `.claude/` hooks under the repo
  are still loaded, and the isolation must be conditional — on Linux the session also lives in
  `~/.local/share/cursor-agent`, which `CURSOR_CONFIG_DIR` does not cover, so isolating
  unconditionally kills auth ("Authentication required" on every run in a headless guest). Trigger
  on `~/.claude` existing.

Second, independent trap once the shell does match: the wrapper runs under **Windows PowerShell
5.1** when no `pwsh` is installed, and there `||` is `The token '||' is not a valid statement
separator in this version`. A hook command written with a POSIX `A || B` fallback is a parse error
there even though the shell is now the right one.

**Rule**: watch the output for `Rejected: Hook blocked`, and never assume a silent review ran its
probes.

## 23. Two Windows-only ways a wrapper breaks before the model sees anything

Both measured while building the cursor wrappers, both silent:

1. **A multi-line prompt through the `.cmd` shim arrives truncated at line one.** The model then
   answers a question you never asked — the first packet probe came back "the query after the
   colon is empty" while the wrapper had passed 5 KB. Send prompts via **stdin**, never argv.
2. **A non-ASCII character inside a PowerShell string literal can break the whole script.** A
   BOM-less `.ps1` is decoded as Windows-1252 by PS 5.1, so an em dash (`E2 80 94`) contributes
   byte `0x94` = the smart quote `”`, which *terminates the literal*; the script then fails to
   parse with a misleading "Missing closing '}'" pointing dozens of lines away. Keep `.ps1` string
   literals pure ASCII (comments are safe, they end at EOL), and locate real errors with
   `[System.Management.Automation.Language.Parser]::ParseFile`, not by eye.

## 24. Run the tripwire's control before trusting it, not after

Pitfall #21 says a file-access tripwire is not proof because indexers and antivirus also touch
files. Measured 2026-08-19, that is not a corner case: `WATCH_PATHS` flagged **all 14** packet
files on **every** run, and a control with **no agent running at all** showed the same 14 access
times moving within 90 seconds (`fsutil behavior query disablelastaccess` = `2 (System Managed,
ENABLED)`). On that machine the tripwire could neither confirm nor deny an escape — it was pure
noise, and a saturated tripwire is indistinguishable from a broken one.

**Rule**: before a blind round, snapshot the watch list, wait, snapshot again with nothing running.
If files move at rest, the tripwire is useless there — get isolation instead of detection. What
actually caught the contamination in that round was the CLI's own transcript preamble.

## 25. Deny rules survive `--force`, but a guessed rule list is not a blind harness

The Cursor CLI documents `--force` as "force allow commands unless explicitly denied", and that
holds: with `permissions.deny` populated, an absolute-path read outside the workspace returned
`TOOL-DENIED Permission denied` even under `--force`. But a deny list assembled from *guessed* tool
names left a gap — one replicate scored 14/14 and its preamble read "the first **grep** didn't
fully show", i.e. a search tool no rule covered. Partial denial looks exactly like full denial
until you grade the output.

**Rule**: if you deny by rule, verify the vocabulary against the CLI's own tool names and probe
each one, or use a guest that holds nothing worth reading (#16, `isolated-guest-vmware.md`).

## 26. A perfect score is a contamination alarm

The ratification protocol already says 0% or 100% on a first attempt usually means a wrong scope,
not a discovery. It applies to *seat calibration* too: two runs returned 14/14 on a packet where
the best previously measured seat got 11. Both had read the project's own docs — the packet's
outcomes are quoted across the experiment ledger, session-close notes and architecture docs — and
both announced it in their preambles ("architecture notes already record later measurements") while
citing exact ledger values at confidence 95. The honest runs from the same seat scored 6–8 with
confidences in the 60s.

**Rule**: grade the *reasons*, not just the score. Retrieved numbers and unusually high confidence
are the tell, and a packet whose answers exist anywhere on the machine is not blind no matter how
empty the working directory is.
