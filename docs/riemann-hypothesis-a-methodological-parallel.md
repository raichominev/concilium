---
layout: article
title: "Believe in yourself: a multi-agent research parallel"
description: "A methodological parallel about multi-agent research and the value of sustained exploration."
---

# “Believe in yourself”: a multi-agent research parallel

There is a recent story about Claude and the
[Riemann hypothesis](https://en.wikipedia.org/wiki/Riemann_hypothesis) that reminds me of
Concilium—not because the systems are the same, but because they share a view of how difficult
research can be organized.

Anthropic asked an unreleased research version of Claude to take a serious run at the hypothesis.
It did not solve it. After exploring many failed paths, however, it reported an advance on a
related longstanding mathematical bound. That result still needs proper review by the mathematical
community. Whether it survives that process is important, but outside the scope of this story.

What interests me here is the method.

Claude began cautiously. The human operator did not supply the missing mathematics. Instead, the
messages were mostly encouragement, including a simple phrase: “believe in yourself.” Claude then
pushed beyond its initial estimate of what was likely to work. It coordinated many agents from the
same model family, retained failed paths, searched the existing literature, ran checks and kept
going long enough to reach what the team reported as a breakthrough.

“Believe in yourself” is a memorable detail, but it should not be read as a magic prompt. The
useful intervention was permission to continue searching after a cautious model had concluded that
success was unlikely. Encouragement changed the search budget; it did not remove the need for
evidence.

The episode shows what can happen when one model becomes a temporary research organization. Work
can be divided, failed approaches can become shared knowledge, and one agent can criticize or
extend the route taken by another. Persistence becomes part of the system rather than a quality
expected from a single conversation.

It also shows the limit of the comparison. The mathematical problem sits inside a field with
decades of definitions, papers, partial results and formal tools already available. The agents
could search through a large, mature body of work. Concilium is meant to carry the same organized
persistence into questions where that map may not exist—where the evidence is local, the categories
are unsettled, and progress depends on heuristics for deciding what to try next.

There is another difference. The Claude experiment multiplied one model family. Concilium tries to
combine several. Same-family agents can search widely and share context efficiently, but they may
also share the same instincts and blind spots. Models trained differently are more likely to notice
different openings, question different assumptions and fail in different ways.

The original Concilium loop adds one more protection: the orchestrator presents the problem without
revealing its own conclusion. Each model gets a chance to form an independent view before the
deliberation begins. That makes the later exchange more valuable because the first round contains
genuinely different readings rather than variations on the chair's answer.

The common lesson is simple: a difficult problem may need more than a good answer. It may need an
organization that preserves failed paths, distributes attention, encourages another attempt and
keeps every claimed breakthrough provisional until it survives review.

Anthropic's account of the experiment is available in
[`Learning more about Claude's mathematical capabilities`](https://www.anthropic.com/research/riemann-zeta).
