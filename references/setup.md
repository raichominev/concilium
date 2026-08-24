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
- ⚠ **The alias is namespaced, and the bare name fails.** `-m k3` errors with `Model "k3" is not
  configured in config.toml`; the working form is the provider-qualified alias, `-m kimi-code/k3`.
  Read the aliases out of the `[models."…"]` table headers in `config.toml` rather than guessing —
  and note the file is not necessarily under `~`: `kimi doctor` prints the path it actually loaded
  (on one install, `/var/lib/…`, where a `find ~ -name config.toml` finds nothing at all).
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

### Z.ai seat (optional, a fifth family) — reuses the Claude Code CLI

The GLM Coding Plan exposes an **Anthropic-compatible endpoint**, so this seat needs no new
transport: point Claude Code at it.

```
export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
export ANTHROPIC_AUTH_TOKEN="<coding-plan key>"
claude -p "<prompt>" --model glm-5.3
```

- Usage meters against the **subscription quota**, not per token (`credits = (in x mult + cached x
  mult + out x mult) / 10000`). Take the **Coding Plan** key, not a general API-platform key — the
  latter is pay-per-token and bills separately.
- Give it its own `CLAUDE_CONFIG_DIR` so it cannot share transcripts with a real Anthropic seat.
- Claude Code warns `"glm-5.3" is not a model this version recognizes` and assumes a 200k window.
  Harmless for short packets; append `[1m]` to the model id or set `CLAUDE_CODE_MAX_CONTEXT_TOKENS`
  for long ones.
- ⚠ A third-party CLI roster may lag the vendor's own: one editor CLI's list topped out at 5.2 with
  no path to 5.3. **Check the vendor's plan, not the reseller's model list**, before concluding a
  generation is unavailable.

### Google seat (optional, a sixth family) — Antigravity, NOT the Gemini CLI

⚠ **Google's own Gemini CLI stopped serving individual accounts on 2026-06-18**, including paid AI
Pro and Ultra. Browser login still appears to succeed and the token exchange is refused server-side,
so reinstalling never helps. The supported successor is the **Antigravity CLI**, which the same AI
Pro plan covers:

```
curl -fsSL https://antigravity.google/cli/install.sh | bash     # installs ~/.local/bin/agy
agy                                                            # device-code login, SSH-aware
agy -p "<prompt>" --model gemini-3.1-pro-high
```

- The device-code paste prompt closes after **~30 seconds** — far too short to relay a code through
  a chat or ticket. Authenticate in a shell where you can paste it yourself.
- `agy models` lists what your tier actually exposes. **`gemini-3.1-pro-high` is the strongest
  CLI-reachable reasoning tier**; Deep Think is Ultra-gated and API access is early-access only, so
  it is not reachable from any CLI you can buy today. Describe the seat precisely rather than
  calling it "frontier".
- Antigravity shares the IDE's credit pool, so CLI volume eats the desktop allowance.

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

## Benchmarking and model selection

After the calibration bootstrap, the AI setup process should read
[`benchmarks.md`](benchmarks.md) whenever it must choose tier models, compare panel chairs,
or reproduce a measured default. Apply the head-to-head procedure there to the current project;
the historical measurements explain the shipped defaults and their limits.

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
