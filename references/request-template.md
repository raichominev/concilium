# Constructing the request (the calling session's side)

The wrappers add the review *contract* (how the reviewer behaves). This file governs the *request* you
hand in — the brief that presents the problem. A bad request anchors the reviewer to your framing and,
worse, can propagate your own errors into the review. The reviewer's independence is your safety net
only if the request licenses and enables it to check you.

## The core rule: front-load facts, not conclusions

Front-loading is good for **facts, code/file pointers, constraints, and already-rejected approaches** —
it spends the reviewer's budget on the frontier instead of re-deriving your setup (which, on a complex
topic, it may not finish before context compaction). Front-loading your **diagnosis/conclusion as
settled fact** is the hazard: the reviewer may reason inside your box, and if the "fact" is wrong, the
whole review inherits the error.

Measured failure (2026-07-20): a request asserted "all 3,331 verb entries have zero Ae forms" under a
heading "cite, do not re-derive." It was wrong (wrong table). The reviewer caught it ONLY because the
contract's falsification probe beat the "do not re-derive" instruction — luck, not design. Never write
"do not re-derive" over a load-bearing conclusion.

## Tag every input by confidence

Split the brief's facts into two explicitly-labelled buckets:

- **[VERIFIED]** — cite the query/probe/file:line that established it. The reviewer may still check;
  never forbid it.
- **[HYPOTHESIS — probe before relying]** — your current read, which the reviewer should independently
  verify before designing around it. Your load-bearing diagnosis goes HERE, not in VERIFIED.

If you're unsure which bucket a claim belongs in, it's a hypothesis.

## Always mount the repo / DB

Evidence access — not a blank prompt — is what actually keeps a reviewer independent. A text-only review
inherits whatever you assert. Pass `-RepoDir` (and note any read-only DB creds / how to run the app's
tooling) so the reviewer can re-derive your load-bearing numbers itself.

## Explicitly license rejecting the frame

Add to the asks: "Before accepting our facts, name any you'd verify first, and any framing or
categorization you'd throw out." This makes stepping outside your box a first-class instruction, not
something the reviewer has to risk.

## Blind-first for framing-critical rounds

When the decision is load-bearing AND your own framing might be the error (open diagnosis, not narrow
verification), run **two passes**:

1. **Blind pass** — minimal framing: the raw problem + data/repo access + "diagnose independently;
   reject our categorization if it's wrong." Capture the reviewer's OWN path before showing it yours.
2. **Context pass** — full brief (facts/constraints/rejected approaches), to reconcile and deepen.

Two rounds cost more, but you get genuine independence before anchoring. Skip it for narrow "verify this
specific claim" checks, where heavy front-loading is correct and cheaper.

Rule of thumb: **narrow verification → front-load heavily; open diagnosis where the framing itself might
be wrong → blind-first or hypothesis-labelled.** If in doubt on a high-stakes round, blind-first.

## Delegating reasoning to Fable — Fable SHOULD use concilium itself

When you delegate a substantial or load-bearing DIAGNOSIS/DESIGN to a Fable subagent, the anti-anchoring
rules above apply to how YOU prompt Fable (don't gate it with a probable outcome). Additionally —
**tell Fable to USE concilium itself on its own load-bearing or uncertain conclusions, not merely flag
them.** Earlier default guidance said "prefer flagging over spawning"; that under-used the tool and let
Fable's uncertain calls go unverified. Corrected standing rule:

- In the Fable delegation prompt, include the concilium invocation recipe and instruct: *"For any
  conclusion that is load-bearing AND you are not confident of — or any engine-change design you
  propose — run a concilium cross-model check yourself before finalizing it; don't just flag it."*
- Recipe to give Fable (verified reachable from a subagent's shell — codex is user-auth, on PATH,
  exit 0): write a short request `.md`, then run **synchronously** (blocking; the subagent waits):
  `powershell -ExecutionPolicy Bypass -File C:\Users\raicho\.claude\skills\concilium\scripts\concilium-review.ps1 -Claim (Get-Content <file> -Raw) -RepoDir <repo> [-Mechanical]`
  — CLOSE stdin on any direct `codex` call (`$null | codex …`) or it hangs. Use `-Mechanical` (prev-flagship, medium) for a quick verify; research tier only for open rounds.
- Fable still returns its final structured result to you; you RATIFY (the ratification seat never moves).
- Flagging (return `concilium_recommended` for the orchestrator to run) remains correct only when the
  check is NOT needed to finish Fable's own task — e.g. independent per-item verdicts in an interactive
  run where you're present to orchestrate. Autonomous / multi-phase / unattended Fable → Fable spawns.

## Request skeleton

```
Round type: [verification | open solution/diagnosis]. [If solution: propose+rank, don't just verdict.]
System / target file(s): …
[VERIFIED] facts (query/file:line cited): …
[HYPOTHESIS — probe before relying]: our current diagnosis is … ; we may be wrong because …
Representative variations: … (concrete, verbatim; enough to re-derive)
Constraints (hard): … (what must not change; what's additive/gated; measure-first recipe)
Already measured & REJECTED (don't re-propose): …
Asks: 1) … 2) …  N) Before accepting our facts, name any you'd verify first and any framing you'd reject.
```
