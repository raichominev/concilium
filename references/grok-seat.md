# The Cursor/Grok seat — what it is, what it costs, what was measured

**Experimental and opt-in. Never part of a default round** — add it only when a fourth family is
asked for. This page is the single home for the seat: how it runs, how it fails, and what testing
it produced. Install and auth detail live in [`setup.md`](setup.md); the failure modes are in
[`pitfalls.md`](pitfalls.md) #22–26.

Wrappers: `scripts/concilium-review-cursor.sh` / `.ps1`. Default model `cursor-grok-4.6-xhigh`.

## Why this transport

The seat runs an xAI model through the **Cursor Agent CLI** on Cursor-subscription auth. That is
the point: xAI's own Grok Build CLI steers headless use toward `GROK_CODE_XAI_API_KEY`, which would
put a metered API key into a skill whose whole premise is subscription auth — and its long-context
band bills the *entire* request at the higher rate once a prompt reaches 200K tokens, which review
contracts plus diffs can reach. Through Cursor there is no key and no per-token bill.

The trade is a **harness in the middle**: Cursor's own system prompt and tools wrap the model
(measured: ~16K input tokens of scaffolding on a trivial call). Blind-spot independence comes from
the weights, so it still counts as a distinct lineage, but a calibration measured here does not
transfer to the same model run through a different harness. The wrapper stamps both the model and
the harness version into PHASE-LOG for that reason.

## Effort lives in the model id

There is no `--effort` flag. The roster is `cursor-grok-4.6-{low,medium,high,xhigh}`, each with a
`-fast` sibling; `cursor-agent --list-models` prints the current set. The wrappers **refuse a
`-fast` id** unless `ALLOW_FAST=1` / `-AllowFast`: the fast lane is a different serving path, so
this seat's calibration does not describe it.

The model does not reliably know its own id — asked directly, it answered with the *display name*.
Provenance comes from the wrapper's own `--model`, never the model's word.

## Isolation: better than kimi, still not containment

- **`--mode ask` genuinely blocks writes.** Two probes asked it to create a file; both were
  refused and nothing landed on disk. This is a real read-only constraint, which the kimi seat has
  no equivalent of.
- **`--force` is required and is not what it sounds like here.** Headless cannot answer the
  interactive command allowlist, so without it every unlisted command dies on a bare `Rejected:`.
  Paired with `--mode ask` it buys read commands, not writes. Never pair it with agent mode.
- **`--sandbox enabled` is macOS/Linux only** — on Windows it errors out with "Sandbox requires
  macOS or Linux", so the Windows seat has no OS sandbox at all.
- **The workspace is not a boundary.** A canary file outside it was read by absolute path and
  returned verbatim — same porousness as kimi. Everything the account can read is in scope, and
  what it reads reaches Cursor's backend.
- **Explicit `deny` rules DO survive `--force`** (the CLI documents force as "allow unless
  explicitly denied", and an outside-path read came back `TOOL-DENIED Permission denied`). They are
  not a blind harness, though: a guessed deny list left a search tool uncovered and a run walked
  straight through it (pitfalls #25).

For anything that must be blind, use a guest holding the payload and nothing else
([`isolated-guest-vmware.md`](isolated-guest-vmware.md)). That is how the number below was measured.

## Two Windows-only traps that cost real time

Both are in pitfalls #22–23 with the evidence:

1. **It imports Claude Code's user-level hooks** (`claudeUserHooks`, `loadClaudePlugin` in the
   bundle) and there is no flag to stop it — then wraps every hook payload in **PowerShell** syntax
   (`... -Raw | & { $input | <hook command> }`) while picking the shell that runs it from
   `MSYSTEM`/`SHELL`. Launched from Git Bash those disagree, bash cannot parse `& {`, and the syntax
   error **rejects every shell tool call** while the reviewer quietly reviews with no probes. The
   hook command is innocent: a hook whose command is `exit 0` fails the same way, and the plugin
   hooks blamed for this originally run fine when the CLI is launched from cmd/PowerShell. So there
   are two fixes — launch from a shell that matches the wrapper (clearing `MSYSTEM`/`EXEPATH` at the
   cmd level; MSYS re-injects `MSYSTEM`, so `env -u` will not do it), or isolate `HOME`. The
   wrappers isolate `HOME`/`USERPROFILE` when `~/.claude` exists, because that holds no matter which
   shell launched them and, as a bonus, hides `~/.claude` during blind rounds.
   ⚠ Isolate only when that directory exists: on Linux the session also lives in
   `~/.local/share/cursor-agent`, which `CURSOR_CONFIG_DIR` does not cover, so unconditional
   isolation breaks auth outright.
2. **The prompt must go via stdin.** Through the Windows `.cmd` shim a multi-line argv prompt
   arrives truncated at line one, and the model answers a question you never asked — it does not
   error, it confabulates a reply about an empty request.

## Reasoning boost: ON by default for this seat

The wrappers append `reasoning-boost.md` to the contract unless you pass `REASONING_BOOST=0` /
`-NoReasoningBoost`. Measured on the prediction packet, it was this seat's largest single
improvement: false alarms 33.3% → **6.7%**, d′ 0.51 → 1.58, accuracy +13.3 pp. The mechanism is a
criterion shift toward refutation, not better reasoning — see the mode caveat in SKILL.md, and
`setup.md` for the full five-seat table.

## What the calibration measured (2026-08-19)

Bootstrap steps 1 and 2 passed on the host: an exact hand-trace of the mutable-default-argument
program, and a real two-part claim correctly refuted `[X]` with file:line citations and an honest
CAVEAT about what it had stubbed rather than run.

The 14-item outcome-prediction packet, three replicates in the isolated guest:

| | r1 | r2 | r3 | spread | stable-correct | stable-wrong | flips |
|---|---|---|---|---|---|---|---|
| `cursor-grok-4.6-xhigh` | 8/14 | 7/14 | 6/14 | 2 | 5 | 4 | 5 |

**It does not out-score the existing seats** (codex 9, kimi 7, Claude 7 on single runs of the same
packet). The case for it is coverage: against codex it rescues two items codex missed, while both
stably miss three others. Seat it as a fourth lineage, not as an upgrade.

Two profile findings, both on clean data:

- **Lowest stated confidence of any seat measured** — mean 70.9 (61–86) on items it got right,
  against codex 99.7, kimi 95.1, Claude 93.9. It is the most willing to express doubt, which
  matters when weighing a lone dissenter (and is one more reason never to weight a vote by its own
  confidence).
- **It errs over-skeptical** — 14 FAIL-on-a-WIN against 7 WIN-on-a-FAIL. The 2026-08-07 panel found
  the opposite (chairs over-credulous in prediction mode) and called that the most transferable
  result. This lineage does not follow it, so "direction of error is mode-dependent" now needs a
  second qualifier: it is **lineage-dependent too**.

### What testing this seat produced for everyone else

- **A 100% score is a contamination alarm, not a discovery.** Two host-side runs returned 14/14 on
  a packet where the best prior seat got 11. Both had read the project's own docs, where the
  outcomes are recorded; the giveaway was in their preambles ("architecture notes already record
  later measurements", "the first grep didn't fully show") and in reasons quoting exact ledger
  values at confidence 95. The skill's own extremal-result tripwire caught what the file-access
  tripwire could not.
- **The blind-integrity tripwire can be structurally useless on a given machine** — and you can
  prove it with a control in 90 seconds (pitfalls #24). Run the control before trusting a clean
  verdict from it, not just after a suspicious one.
