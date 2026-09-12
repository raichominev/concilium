# The Anthropic-compatible seats — Z.ai, DeepSeek, Qwen, and Google

Four more families, none of which needed a new transport. Three vendors expose an
**Anthropic-compatible `/v1/messages` endpoint**, so the Claude Code CLI drives them directly; the
fourth (Google) has its own CLI. This page is the single home for all four: how they run, what they
cost, and what the calibration measured.

Wrappers: `scripts/concilium-review-compat.sh <glm|deepseek|qwen>` and
`scripts/concilium-review-agy.sh`. Both take the same `{claim|diff|raw}` surface as every other
seat, load `references/contract.md`, honour `PRIOR_ROUNDS` for the loop, and count five blocks
before trusting a run.

## The seats

| seat | vendor | model | credential | plan |
|---|---|---|---|---|
| `glm` | Z.ai | `glm-5.3` | `ZAI_TOKEN` | GLM Coding Plan Lite — **quota-metered, not per-token** |
| `deepseek` | DeepSeek | `deepseek-v4-pro` | `DEEPSEEK_TOKEN` | pay-as-you-go API key |
| `qwen` | Alibaba | `qwen3.8-max` | `QWEN_TOKEN` | pay-as-you-go DashScope key |
| Google | Google | `gemini-3.1-pro-high` | Antigravity OAuth | Google AI Pro |

Base URLs live in the wrapper's vendor table; override with `COMPAT_BASE_URL` / `COMPAT_MODEL` /
`COMPAT_TOKEN` for a vendor not listed.

⚠ **On this machine these tokens are not on the host.** They are exported from the isolated guest's
`~/.profile`, so a host-side check reports all three unset — which means *not on the host*, not
*not configured*. The guest also carries the `agy`, `cursor-agent` and `kimi` binaries and two
reference runners. Inventory, invocation and the login-shell trap:
[isolated-guest-vmware.md](isolated-guest-vmware.md#this-installation--inventoried-2026-09-12).

## Why routing a non-Anthropic model through Claude Code is safe to do — and what it is not

The transport is Anthropic's protocol; **the model, the provider and the data handling are the
vendor's.** A Claude-Code transport does not mean Claude-grade retention terms. Check the vendor's
policy before pointing a seat at anything sensitive, exactly as you would for any other seat.

Each seat gets its **own `CLAUDE_CONFIG_DIR`** (`~/.claude-<vendor>`), so it cannot share session
state or transcripts with a real Anthropic seat or with another vendor. That matters more than it
sounds: same-family cross-reading is precisely what corrupts a lineage measurement.

## Setup traps, all of them measured

- **Take the vendor's CODING-PLAN key where both exist.** Z.ai issues both a Coding Plan key
  (metered against your subscription quota) and a general API-platform key (pay-per-token, billed
  separately). The wrong one silently costs money.
- **Check the vendor's own plan, not a reseller's roster.** One editor CLI's model list topped out a
  full generation behind the vendor's current release, which nearly led to the conclusion that the
  newer model was unavailable. It was one subscription away.
- **Claude Code warns that the model id is unrecognised** and assumes a 200k context window. Harmless
  for ordinary reviews; for long material set `CLAUDE_CODE_MAX_CONTEXT_TOKENS` or use the vendor's
  long-context id.
- **Google's own Gemini CLI stopped serving individual accounts on 2026-06-18**, including paid AI
  Pro and Ultra. Login still *appears* to succeed and the token exchange is refused server-side, so
  reinstalling never helps. **Antigravity (`agy`) is the supported successor** and the same AI Pro
  plan covers it. Its device-code prompt closes after **~30 seconds** — authenticate where you can
  paste the code yourself.
- **`gemini-3.1-pro-high` is the strongest CLI-reachable reasoning tier**, not Google's maximum.
  Deep Think is Ultra-gated with early-access-only API, so it is unreachable from any CLI you can
  buy. Describe the seat precisely rather than calling it "frontier".
- Antigravity shares the IDE's credit pool, so CLI volume eats the desktop allowance.

## Seat calibration — PROVISIONAL, measurement still in progress

⚠ **These are working numbers from an unfinished measurement, not a published result.** They are
here because a seat's refusal behaviour is the thing you most need to know before trusting it, and
a provisional figure beats none. Expect them to move. Do not quote them outside this repo, and
re-read this section before relying on it.

Eight seats, seven vendors, an 18-claim adjudication packet with ground truth established by
execution, 6 runs per seat — **48 runs, 108 scored decisions per seat**. Packet base rate: 55.6%
REFUTED. (A ninth seat was run and is deliberately excluded: it reached an older generation of the
Z.ai model through a third-party CLI, so it is a reference set, not this vendor's seat.)

| seat | vendor | accuracy | refute rate | recognises TRUE claims |
|---|---|---:|---:|---:|
| astra (codex seat, for comparison; 2026-09-07) | OpenAI | **88.9%** | **57.4%** | **85.4%** |
| kimi | Moonshot | 70.4% | **53.7%** | 68.8% |
| **glm** | **Z.ai** | 70.4% | 59.3% | 62.5% |
| fable 5 | Anthropic | 69.4% | 56.5% | 64.6% |
| fable 5.1 (2026-09-07) | Anthropic | 64.8% | 74.1% | 39.6% |
| grok | xAI | 72.2% | 66.7% | 56.2% |
| opus | Anthropic | 69.4% | 68.5% | 50.0% |
| **deepseek** | **DeepSeek** | 66.7% | 68.5% | 47.9% |
| **Google** | **Google** | 69.4% | **76.9%** | **41.7%** |
| **qwen** | **Alibaba** | 63.0% | 67.6% | 37.5% |

**Read the refute rate, not the accuracy column.** Seven of the eight original seats sit within
6 points on accuracy while per-seat replicate spread runs 1–5 items, so the accuracy ordering is
inside the noise and should not be used to rank anything among them. The refute rate against the
55.6% base rate is the column that separates them. The one exception is `astra`, which sits
fifteen points above the band with a replicate spread of 3 — a difference no amount of replicate
noise produces on this packet.

- **`glm` is the best of the four for review work** — and fourth-best calibration in the whole
  panel, behind `fable 5` (56.5%), `astra` (57.4%) and `kimi` (53.7%). Since `fable 5` shares the
  orchestrator's lineage, `glm` is the third-best *cross-family* seat on this measure, after the
  codex seat `astra` and `kimi`.
- The two rows dated 2026-09-07 come from the same packet and protocol (three base + three treat
  runs, fresh empty cwd, closed book), scored with the same denominator. `astra` is the codex seat,
  not a compat seat; its row is here so the table reads as one panel. Detail, controls and the
  contamination checks behind the astra figure: `benchmarks.md`.
- **The Google seat refutes three-quarters of everything** and recognises 42% of true claims. It buys
  a high refuted-recall by rejecting nearly everything. Seat it for lineage diversity; do not treat
  its `[X]` as informative.
- **`qwen` has the weakest upheld-recall measured** (37.5%) and the widest replicate spread (5).
- ⚠ Under the reasoning boost the Google seat reached a **96.3% refute rate and 4.2% true-claim
  recognition** — the most extreme criterion shift in the set. The boost is OFF by default on every
  seat for this reason; do not enable it here. `deepseek` shifts the same way (+11.1 pp); `qwen`
  is the one measured counterexample (−8.5 pp), which is why the rule is stated for the population
  and not for every seat.

## Cost

`glm` bills against a subscription quota rather than per token. `deepseek` and `qwen` are
pay-as-you-go: at ~10 KB packets, a DeepSeek run costs roughly $0.13 at peak rates and about half
that off-peak, so a full 9-run seat workup is close to $1. Reasoning tokens dominate the bill on all
three — the visible answer is a small fraction of what is generated and charged.

## Runtime

Measured per run on the 18-claim packet: `glm` and Google around 150–200 s, `deepseek` ~700 s,
`qwen` ~1,240 s with a wide spread (533–1,671 s). Budget accordingly when running replicates; a
9-run seat is 20 minutes on Google and over three hours on Qwen.
