---
layout: article
title: "Where Multi-Model Review Grows into Deep Research"
description: "The boundary between reviewing a known artifact and discovering the evidence, framing and test for an unsettled problem."
---

# Where Multi-Model Review Grows into Deep Research

Multi-model workflows have found a practical shape in software development. One model prepares a plan or writes the change—for example, Claude—then a model from another family, say GPT, reviews it. To add weight to the process, some tools continue until the reviewer approves, while others run several reviewers in parallel.

The value is driven primarily by disagreement between model lineages. Both agents work on the same repository, plan, diff and test results. A reviewer can focus on a line, reproduce a failure or show that the implementation violates the agreed design. The pattern is possible with same-lineage models, though usually less effective. When guided by a skilled developer, the added value is immediately visible.

## Review has a useful boundary

Plan-first workflows such as [Claudex Loop](https://github.com/chaseai-yt/claudex-loop) move independent review before implementation. Review councils such as [Claude Code Review Council](https://github.com/yeameen/claude-code-review-council) widen the inspection across model families and specialist roles. Operational tools such as [Coding Review Agent Loop](https://github.com/wwind123/coding-review-agent-loop) preserve state and carry findings through implementation, tests and pull requests.

These methods solve real problems. They also share an important starting condition: the artifact under review already exists, or the workflow knows how to produce it.

| | Multi-model review | Deep research |
|---|---|---|
| Starting point | A plan, diff, repository or claim | A question whose framing may still be wrong |
| Evidence | Known artifacts and tests | Sources and probes that may need to be discovered |
| Iteration | Revise the artifact and review again | Try a genuinely different evidence path |
| Useful ending | Approval, defects or a bounded deadlock | A supported result, an unresolved alternative or a better question |

![Three distinct lenses reveal different structures in the same body of evidence.](assets/multi-model-research-landscape.png)

The distinction matters because a capable reviewer can rigorously inspect the wrong deliverable. If the original framing omitted the decisive documents, used the wrong population or divided the problem into misleading categories, repeated review deepens the gap.

## The artifact may be part of the question

Open research often begins without a stable specification: poor documentation, scattered terminology that hides viable paths or an available measurement that is only an assumption. Even the criteria for a useful result may become apparent only after some investigation.

In this situation, even the most capable workflows start to produce unsatisfactory results. The answer feels almost within arm's reach, yet the models somehow cannot reach it. A multi-lineage approach helps when the models are allowed enough independence to form different readings before a shared conclusion anchors them. One may question the category being measured. Another may find a source class that the first ignored. A third may accept the framing and discover that the apparent contradiction comes from two denominators.

Take voting as an example. It contributes little when the differences between votes are marginal. Three confident answers derived from one stale fixture remain three readings of the same picture. This is the point where slight disagreements begin to form a signal worth following, while voting—or another shallow aggregation method—buries it. Further loops on the same material are quickly exhausted. Models tend to settle after the first iteration, or the second at most.

## From review loop to research method

A research council therefore needs several disciplines that a normal review loop can leave implicit.

The first readings should form before the chair reveals its conclusion. Claims should travel with evidence that can be replayed. A disputed round should bring a new probe rather than another reformulation of the existing argument. The process should stop when the evidence converges, when no new path remains or when the unresolved choice belongs to the human owner.

Generation also needs its own treatment. Ideas created for an unmapped problem should not be collapsed immediately into a ranked shortlist. Their original wording, unexpected combinations, cheapest tests and failure conditions are part of the research record. Synthesis is valuable for findings; premature synthesis can erase the unusual idea that only becomes useful after another model extends it.

## Where Concilium fits

This is the boundary Concilium was built to handle. It combines cross-family review with blind-first diagnosis, bounded evidence-seeking loops, Forge for open questions and open-book Brainstorming against a read-only copy of the real system. Other modes audit an experimental instrument, verify a long result by fragments, expose ambiguity through blind replication, cross-examine an underdetermined claim or translate the frame into another field's methods.

Currently, Anthropic and OpenAI form the standard pair, selected through Concilium's own measurements. Adding more model families was initially disputed, but produced interesting and valuable results. The outcomes are evaluated by evidence and lineage—same-family models tend to converge too quickly—rather than headcount or stated confidence, and the orchestrator's conclusion remains subject to human ratification.

The method was extracted from ongoing scientific research and revised after real failures: misleading scopes, stale fixtures, shared blind spots, confident verdicts over sound calculations and experiments whose instruments could not answer the question being asked. That experience makes it field-tested in its originating research program. Independent use across other domains is the next evidence it needs—such feedback would be warmly welcome.

Multi-model review is already becoming ordinary engineering practice. Deep research begins when the workflow must discover what deserves review, which evidence can decide it and what should remain unresolved.

Concilium is available through the Claude Code plugin marketplace: add `raichominev/concilium`, then install `concilium@raicho-skills`. The source and full method are available in the [Concilium GitHub repository](https://github.com/raichominev/concilium).
