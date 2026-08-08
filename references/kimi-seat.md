# The Kimi seat — what it is, what it costs, what was measured

**Experimental and opt-in. Never part of a default round** — add it only when a third family is
asked for. This page is the single home for the seat: how it runs, how it fails, and what testing
it produced. Setup and install detail live in [`setup.md`](setup.md); the failure modes it shares
with the rest of the skill are in [`pitfalls.md`](pitfalls.md) #18–21.

## Two transports

| | wrapper | notes |
|---|---|---|
| **Kimi Code CLI** (Linux/macOS/Windows) | `scripts/concilium-review-kimi.sh` | Cross-platform, MIT-licensed engine. Headless `-p` plus device-code OAuth, so it suits a container or a throwaway VM. |
| **Kimi Desktop** (Windows) | `scripts/concilium-review-kimi.ps1` | Drives the app's bundled runner under its own Electron. Requires the desktop app installed and signed in. |

Both load the same review contract and return the same five blocks. **Always name the model**: the
CLI's built-in default is an older generation than the flagship, and nothing in the output says so.

## Why it is the weakest seat

- **No sandbox, and it does not stay where you put it.** codex runs under `-s read-only`; this seat
  has no equivalent, and its working directory is *not* a boundary — a canary file outside it was
  read by absolute path and returned verbatim. Routine behaviour, not a corner case: expect it to
  read the live tree instead of the copy you gave it, and assume anything readable is in scope.
  `-SandboxFrom` gives blast-radius control and an audit trail of what changed, not containment.
  **If the machine holds anything sensitive, run this seat in a VM** — or at minimum a separate OS
  account whose ACLs deny the rest of your profile. On the CLI transport the case is stronger
  still: headless print mode auto-approves every tool call by construction, so isolation there is a
  precondition rather than a precaution. Worked example, with the gotchas that cost time:
  [`isolated-guest-vmware.md`](isolated-guest-vmware.md) — one deployment, not the only approach.
- **It fails silently.** It exits 0 on a connection failure, so check the output for the five
  contract blocks rather than the exit code. Auto-bridging your project rules into the contract
  reliably kills the run, so it ships off by default.
- **Do not trust its arithmetic.** It reports counts wrong by a small margin while the surrounding
  finding is correct — the failure mode most likely to be quoted onward unchecked. Counts are the
  cheapest thing to re-derive, so re-derive them.
- **Distinguish what it found from what it read.** A reviewer's most quotable claim is sometimes a
  restatement of something already in the material under review. That can still be valuable —
  separating a failure recorded as one mechanism into two is real work — but it is not discovery,
  and confident prose will not tell you which one you are getting.
- **`-WatchPaths` is a tripwire, not proof.** Indexers, sync clients and antivirus also touch
  files; an enumeration-based version of the same check reported "clean" on a run that had
  demonstrably escaped. Verify any such check against a known escape before relying on it, and
  never watch a path the tool itself needs — it reads its own stored credential every run.

## Why it earns a place anyway

A third lineage rescues items the other two miss together. Measured on prediction packets, the
Kimi seat was the sole correct answerer on individual items that codex and Claude both got wrong,
and a stable blind spot in one family was repeatedly rescued by another. That is the whole case for
it: not accuracy, coverage.

## What testing this seat produced

Three results, all of which generalise beyond Kimi:

- **Reasoning effort does not buy panel coverage.** Six runs of one seat across five effort levels
  covered no more than two runs at the *same* effort; accuracy was not monotonic in effort, some
  items were unreachable at every level, and wall time climbed steeply.
- **Neither does a model generation.** Two generations of one family, three replicates each,
  rescued *nothing* from each other — their stable blind spots were shared. A different family
  rescued items from both. Effort, generation and repetition all resample the same blind spots;
  only a different lineage moves them.
- **One run is not a measurement.** Three replicates per seat at identical settings moved scores by
  up to 4 points, with a large share of items flipping between runs. Single-run rankings and
  pair-coverage figures sit inside that noise; [`setup.md`](setup.md) now reports **stable
  profiles** instead — what a seat gets right, or wrong, in *every* replicate. Three runs is enough
  to see it and cheap to get.

The CLI wrapper was verified against a live install rather than written from documentation, which
corrected four flags that do not exist on the shipped CLI and found that piping a prompt to stdin
hangs — it has to go in as an argv argument.
