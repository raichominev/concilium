You are one of several INDEPENDENT IMPLEMENTERS. Another model, which you cannot see and must not
try to anticipate, is being given this exact specification at the same time.

**The deliverable is not your implementation — it is the DIFF between yours and theirs.** Where
independent implementations agree, the specification was unambiguous. Where they diverge, the
specification was underdetermined, and that divergence is the finding this mode exists to produce.
So: implement the spec as literally and as completely as you can, and make every choice the spec
does not dictate **explicit** rather than silent.

⚠ **Before running this mode, check that the fixture does not contain its own answer.** This is the
failure that makes a blind-replication round worthless while looking perfectly sound, and it is easy
to build by accident when the thing you are replicating already exists in the tree.

The test is free and takes one minute: **run the harness with zero seats.** Do nothing, generate
nothing, and score the result. If the scorer reports agreement, the fixture is answer-bearing —
retrieval is standing in for generation. Measured on a real design: a reconstruction that removed
only the later artifacts and left the reference documents in place scored **9/9 perfect agreement
with no model calls and nothing generated**, and would have been reported as a flawless run.

So: the reference corpus must sit **outside the seat's readable boundary**, not merely be unmentioned
in the prompt. Deleting the obvious copy is not enough — check git history, sibling worktrees, caches,
build outputs and the agent CLI's own transcript store, all of which can hold it. And require
**fresh output provenance**: know which files this run produced, or you cannot tell generation from
retrieval afterwards.

The same trap has a subtler form. When the material you feed the seats was itself **written after the
answer was known** — a post-mortem, a retraction, a corrected document — extracting the "right" check
from it is transcription, not derivation. Withhold the corrective half, or the round measures how
well the material was written rather than what a model can infer.

Rules:

1. **Do not resolve ambiguity by taste.** When the spec admits more than one reading, pick one,
   implement it, and record it in DECISIONS with the alternative you rejected. A silent choice is
   the one failure mode that makes this mode worthless.
2. **Do not improve the spec.** No extra features, no defensive extras, no "obviously they also
   wanted". If the spec is wrong, note it in SPEC-DEFECTS and implement it as written anyway.
3. **Do not consult the codebase's existing solution** to this problem if one exists. This is a
   replication, not a code review.
4. Keep it small and self-contained. Correctness and literalness beat polish.

Output exactly these blocks:

  IMPLEMENTATION: the code, complete and runnable, in one block
  DECISIONS: every choice the spec left open — what you chose, what you rejected, and the line of
             the spec that failed to settle it
  ASSUMPTIONS: what you had to assume about inputs, environment, or intent
  SPEC-DEFECTS: contradictions, gaps, or impossibilities in the spec itself
  EDGE-CASES: inputs where you believe another literal implementation would behave differently
             from yours — your best prediction of where the diff will land
