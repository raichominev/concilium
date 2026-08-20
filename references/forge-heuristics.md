# Forge heuristics — a staged library, not one prose block

A forge round is only as good as the search instruction it carries, and **the right instruction
changes between rounds**. Round 1 finds the obvious, because the obvious is what a single strong
model reaches on its own. The value of a panel is what happens *after* that: consensus becomes a
signal to be read rather than a target to re-hit, and the weak, orphaned, single-seat ideas become
the raw material.

Each heuristic below states when it applies. The driver injects the round-appropriate set;
`forge-brief-template.md` carries H1 because it is the only one that belongs in the standing brief.

---

## H1 — Nearby, never touched  *(round 1)*

The highest-yield move in a mature project is rarely a new algorithm. It is material already in the
project, one join away from the question, that nobody has pointed at it: an artifact built for
another purpose, a by-product of a failed experiment, a document read for content but never for
structure, a constraint documented in prose but never enforced in code.

## H2 — Consensus is a signal, not a target  *(round 2+)*

When several models independently propose the same method, that convergence is **evidence the method
is real** — and simultaneously evidence that it is the obvious answer, reachable by one model alone.
So: record it, mark it CONFIRMED, and **stop mining it**. The round-2 instruction must say plainly
that re-proposing a convergent idea scores zero, and must instead ask what the convergence *implies*
— what must be true about the problem for four independent models to land there, and what that
constrains next.

## H3 — Unconventional mandate  *(round 2+)*

Explicitly ask for methods that a domain expert would flinch at on first hearing. Three productive
shapes, worth naming in the instruction because models default away from all of them:

- **inverted assumption** — take something the project treats as fixed (a floor, a quarantine, a
  data-flow rule, an evaluation-only policy) and propose the version where it is false;
- **wrong-direction use** — run an existing component backwards (a generator used as a critic, an
  index used for its ordering rather than its content, a repair used as evidence);
- **borrowed constraint** — a technique whose home field studies a different object entirely, imported
  with its method rather than as a metaphor (see `frame-translation.md`).

## H4 — Build up from weak signals  *(round 3+, the payoff round)*

The point of a shared register is not parallel brainstorming; it is **chaining**. Instruct seats to:

- take **two or more ORPHANS** — ideas proposed once, by one seat, that nobody built on — and
  compose them into a single method neither could support alone;
- prefer combinations where each part is individually too weak to fund, because those are precisely
  the ideas a single model discards and a panel can rescue;
- state the **chain explicitly**: A supplies X, B supplies Y, and the combination yields Z that
  neither has;
- treat a chain that fails as a finding — if two orphans cannot combine, say what blocks them.

## H5 — Orphan marking  *(orchestrator duty, every round)*

H4 only works if orphans are findable. When curating, tag every entry with its build-on count, and
give the register an explicit **ORPHANS** section listing the single-seat, never-reused ideas. Do not
prune them for tidiness: the register's job at this stage is to keep weak signals alive long enough
to be combined. Convergent ideas get a CONFIRMED tag and move out of the hunting ground.

## H6 — Adversarial self-application  *(any round, cheap)*

Ask the seat to name the strongest reason its own best idea is already known, then either kill it or
sharpen it into the part that survives. This is the only place in forge mode where a seat is asked to
judge anything — and it judges only its own output, which does not chill anyone else's.

---

## Staging summary

| round | instruction carries | scored on |
|---|---|---|
| 1 | H1 | ideas that miss the frozen known-methods list K |
| 2 | H2 + H3 + build-on-others | non-convergent ideas; reframes of others' entries |
| 3+ | H4 + H5-tagged register + H3 | chains of orphans; explicit A+B→C statements |

**Do not skip round 2's convergence read.** It is what makes round 3 possible: without a CONFIRMED
set and an ORPHANS list, the third round regresses to the first.
