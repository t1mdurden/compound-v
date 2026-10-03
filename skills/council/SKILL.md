---
name: council
description: Several independent fresh-context takes on one hard question, and a verdict that shows where they disagreed. Use when a judgment call has no checker to run and being wrong is expensive: an architecture or vendor choice, a diagnosis with competing explanations, a strategy, pricing or hiring call, a design nobody can objectively score, or a conclusion that feels obviously right that nobody has pushed back on. Also on "get a second opinion", "what would other models say", "poke holes in this", "am I missing something", or wanting the alternatives laid out rather than one confident answer. Skip it when a test, query or benchmark can settle the question — run that instead.
---

# Council

**Generation is cheap; selection is the bottleneck.** A council is a way to manufacture a selection signal for a question that has no checker — and its first job is to talk you out of needing one.

Start from the measured version, because the intuitive one is wrong. Sampling a single model repeatedly does *not* give you one answer N times: coverage against samples "follows an exponential power law," and the interpretation is that models "already know a whole lot more than what you get out of them when you just ask them once." Diversity is abundant and nearly free. What you cannot do is *pick* — majority voting "plateaus after 10 or 50 samples," because voting is a selector with no access to truth. That gap between producing a good answer and recognising it is the whole problem a council is trying to solve, and it is why the design below spends its budget on **examining** answers rather than on generating more of them.

## Before you convene — three cheaper rungs

Climb these in order. A council is the fourth rung, not the first.

1. **Is there a checker?** A test, compiler, type system, query, benchmark, or a person who already knows. Run it. Model self-critique on checkable claims measurably degrades results, and one sound external verifier beats any amount of self-examination.
2. **Can you *manufacture* one?** This is the rung people skip. Verifiability is not fixed — "it is possible to actually improve the asymmetry by front-loading some research about the task." An hour spent writing acceptance cases, an answer key, a scoring rubric with worked examples, or a spike that makes the question empirical is cheaper than a 15× council and leaves you with something reusable.
3. **Would one better pass do?** More thinking budget, a stronger model, or a rewritten prompt on a single attempt. Fan-out is a latency-and-coverage play; it is not the only way to spend more compute on a hard question.
4. **Then convene** — for a call that is expensive or hard to reverse, has genuinely separable angles, and still has no checker after rungs 1–3.

**Price it honestly, both halves.** Agents use about 4× the tokens of a chat and multi-agent runs about 15×. Anthropic's own analysis says multi-agent systems "work mainly because they help spend enough tokens to solve the problem," token spend alone explaining 80% of the variance — *and* the same essay reports a multi-agent research system beating its single-agent baseline by 90.2%. Both halves are real: you are buying compute, and buying compute works.

## Stage 1 — members, differentiated by mandate

Every member is the same model with the same tools. That is what a production harness already assumes: Codex tells its root agent that all agents "are equally intelligent and capable, and have access to the same set of tools," locating every difference in the assigned task and the propagated context.

- **Mandate over costume.** Role prompting is largely deprecated as a capability lever — "if they understand the thing, just ask them to do the thing that you want," and the shipped guidance is ~80% of effort on well-defined tasks, ~20% on personas. But do not over-learn that: a role *anchor* is load-bearing for **stability**, not capability — CAMEL opens every prompt with "Never forget you are X" because without it agents role-flip after ~5–10 turns. Anchor the role firmly; don't expect the costume to do the thinking.
- **Each mandate must stand alone.** This is the constraint that keeps a council from being **depth-first work wearing a fan-out costume** — the anti-pattern **compound-v:dispatching-parallel-agents** names explicitly, whose fix is to sequence. A member's brief is legitimate only if it can be answered from *the question plus its own assigned sources*, never from a sibling's output. "Argue the strongest case" and "steelman the minority view" pass. "Reconcile the two" does **not** — that needs the others' text, so it belongs to the chair in stage 3, not to a parallel member.
- **A narrowed surface.** When Codex spawns its reviewer it replaces the base instructions wholesale and disables the tool families that would let it wander back. A role that changes the harness is a real role.
- **Count: 3–5, and know what the number is.** It is a *parallelism and chair-attention* default, not a quality ceiling — the same Anthropic guidance scales to "more than 10 subagents" for complex work, and the 3–5 figure elsewhere is explicitly a human's working memory. Go wider when the question genuinely has more separable angles than you have members; the cost is your synthesis, not correctness.

Give each member an objective, an output format, guidance on tools and sources, and clear task boundaries — without those, agents duplicate work and leave gaps. Members never message each other; **compound-v:dispatching-parallel-agents** owns the dispatch mechanics.

## Stage 2 — cross-examination

**Fresh reviewers, not the authors.** "Having the agent that wrote the code review its own code is insufficient," and a model judging inside the context it generated in is the documented trigger for in-context reward hacking. Spawn new agents.

**But blind ≠ starved — this is the correction people get wrong.** The only controlled test in the corpus holds the model fixed and varies *only* the reviewer's context: diff-only versus context-aware, over 15 PRs, came out **+17.5% precision, +43.3% recall, +25.4% F1 in favour of the context-fed reviewer**. So withhold the author's *reasoning trace* — which is exactly what Codex strips when it forks history, keeping user and developer messages and dropping tool calls and reasoning — and *supply* the goal, the constraints and the source material. The mechanism is as much context rot as it is bias: the reviewer "re-discover[s] any context it needs as it reads the code from scratch," so keep its brief **short and relevant**, not empty.

**Ask for findings, not a leaderboard — and be precise about why.** Codex's shipped review rubric never ranks: its terminal judgment is binary (`"overall_correctness": "patch is correct" | "patch is incorrect"`), with the substance in a findings list carrying a P0–P3 integer and a `"confidence_score": <float 0.0-1.0>`. Copy that. **The honest caveat:** ranking peers *is* shipped and *is* validated — Google's co-scientist aggregates pairwise debates into Elo and reports its best results when ranking by highest Elo, and LangChain ships a tournament pattern where "a **judge subagent** compares them in pairs." That works because "the law of large numbers smooths out noise into a meaningful global ordering after enough matches." Three members and one round is nowhere near enough matches. Skip the leaderboard because you cannot afford the match volume that makes it mean anything — not because nobody has made it work.

Design the reviewer's brief around the known judge failures, in rough order of how likely each is to bite a council:

- **Length bias first.** Members write free-form answers of wildly different lengths, and judges "tend to bias toward longer responses." Equalise length in the comparison, or judge on named axes rather than holistically.
- **Order bias.** Do each pairwise comparison twice with the order swapped. Instruction does not fix it — the sentence telling the judge that presentation order "does not affect your judgment" was tested and the bias persisted.
- **Evidence before verdict.** Make the reviewer write its reasoning first, then the call. Derive the verdict from named axes rather than a gestalt, the way Codex's guardian derives its outcome "only after assigning `risk_level` and `user_authorization`."
- **Decompose instead of scaling.** Prefer several binary sub-checks to one graded score — "measuring specific sub-components with their own binary checks rather than using a scale." Note the LLM-specific failure is *over*-scoring, not middle-clustering: a judge rated a deliberately bad deck "between 2.8 and 4.0." Anchored examples fix a scale; a scale with no anchors is noise. **compound-v:evals** owns judge design in depth — go there rather than re-deriving it here.
- **Allow ties.** Sometimes two answers really are equally good, and forcing a winner manufactures a distinction.
- **Ban flattery**, as Codex's rubric does: the comment "should avoid excessive flattery" and phrasing like *Great job…* or *Thanks for…*.
- **Give the zero-finding exit and the keep-going push together:** "prefer outputting no findings" over weak ones, and "Do not stop at the first qualifying finding."

**Where aggregation *does* belong: over findings, not over answers.** Send each finding to independent verifiers and keep only what survives — a traced production run rejected 4 of 26 findings this way. That is a principled majority vote on a claim small enough to check, which is precisely what a vote over whole essays is not.

**One round by default — a budget choice, stated as one.** Iterated debate genuinely improves quality: co-scientist Elo trends monotonically upward across 203 research goals with "no saturation observed," and a production review loop keeps "finding new bugs each time." Those systems spend millions of tokens per question. Stop at one round because you chose a budget, and say so; add rounds when the answer is worth them.

**Agreement is weak evidence, not zero — when the members' contexts differed.** Resist the reflex that same-family agents are simply correlated — Cognition found that "putting the same model in two agents, even if the agent harness is exactly the same, does not quite make them self-biased/correlated in the same way you might imagine one human doing both tasks would be," because the agents "perform based on their context" and Cognition's reviewer shared none with the coder. Hold the context alike and the correlation returns: with context, scaffolding and model the same, Anthropic's red team found "different agents will take very similar actions, even when the action space is very large" — 18 of 30 agents started together on one task picked the same git branch name. So unanimity among members who shared a brief, sources and tools is one answer counted several times; among members whose mandates differed, treat it as a prompt to check whether anyone was positioned to disagree, not as proof of either truth or groupthink.

**Validate the reviewer once.** Every judge source makes alignment to human judgment the load-bearing step, with a measured payoff — agreement went "from 68% to 94%" over three iterations of critique-and-revise. Read a handful of the reviewer's findings yourself and correct its brief before you trust the rest.

## Stage 3 — the chair

**Filter before you synthesize.** The chair's real job is checking returned findings against what the user actually asked — this is "key to preventing looping, disobeying the user, doing work that is out of scope." A finding that is true and irrelevant still costs the reader.

**And drop what nobody could have argued against.** Relevance is one filter; contestability is the other. A recommendation whose opposite no competent person would defend — *keep it simple*, *it depends on the use case* — carries no information about this question however true it is, and a council returning only those spent 15× to restate the prompt. The test comes from murder-boarding project plans, where new joiners kept writing principles like *move fast*: nobody can reasonably disagree with it, so picking it says nothing, and a real principle is one somebody reacts to as wrong. It tests the proposition, not the members — a concrete defect everyone would concede is a finding, not a truism. Hold your own verdict to it: if you could have written it before convening, report that the question turned out uncontested rather than dressing the restatement up as a synthesis.

**You own the final answer.** A shipped research orchestrator forbids delegating it outright: "NEVER create a subagent to generate the final report." With one caveat that matters at length — an orchestrator tens of thousands of tokens deep is badly placed to *type* a long report, and the fix is the one **compound-v:dispatching-parallel-agents** already specifies: write the plan and the per-section commitments yourself, then hand the typing to one fresh tool-locked worker that may not re-plan. Never delegate the *deciding*.

**Then:** lead with what the members disagreed on and how you called it; show the competing answers rather than blending them; name what stayed unresolved.

## Keep the stages from vanishing

A staged pipeline carried only in a prompt gets evicted by compaction mid-run — orchestrators have been observed to drop a whole critic stage and quietly downgrade a multi-draft ensemble to a single draft. Sessions are discrete, and compaction "isn't sufficient" on its own because it "doesn't always pass perfectly clear instructions to the next agent." Keep the stages on a visible checklist, and **tool-lock the reviewers read-only** rather than asking them not to write.

## What changed from llm-council, and why

| llm-council (Nov 2025) | Here | Why |
|---|---|---|
| 4 vendors via a paid API key | 3–5 fresh agents, one family, keyless | A shipped harness already assumes equally-capable agents on the same tools and differentiates by task and context. |
| Members differ by vendor | Members differ by mandate, sources, tool surface | Vendor diversity isn't available keyless; role prompting is a weak capability lever, though a real stability anchor. |
| Each member ranks all answers **including its own** | Fresh reviewers, given the goal but not the author's reasoning trace | Self-review is insufficient and shared evaluator/generator context invites reward hacking — but the measured win goes to the *context-fed* reviewer, not the starved one. |
| `FINAL RANKING:` + averaged rank positions | Findings with severity and confidence; verification aggregated over findings | Pairwise→Elo is real and measured, but it needs match volume a 3-member round cannot reach. The original's leaderboard is inert anyway — `calculate_aggregate_rankings` never reaches `stage3_synthesize_final`. |
| Regex over the ranking text | A stated output contract with a documented fallback | Production parsing is typed, then brace-sliced, then degraded non-fatally. |
| Fixed A/B/C/D order | Swap the order; equalise length; allow ties | Order bias cannot be instructed away, and length bias is the likelier failure when members write essays. |
| Chairman sees de-anonymized authors | No identities exist | The original anonymizes in stage 2, then hands the chair the real names — reopening the bias it just closed. |

## Red flags

| Symptom | What it means |
|---|---|
| Nobody tried to build a checker first | Rung 2 skipped. Verifiability can be manufactured, and it is cheaper than 15× and reusable. |
| A member's brief needs a sibling's answer | Depth-first work wearing a fan-out costume. Move it to the chair, or sequence it. |
| Reviewers are the stage-1 members | Self-review is insufficient; spawn fresh ones. |
| The reviewer got only the answers, no goal or constraints | Starved, not blind. The measured win is +17.5% precision / +43.3% recall for the context-fed reviewer. |
| The output is a winner or an averaged rank | Too few matches for an ordering to mean anything. Return findings; aggregate over findings instead. |
| A reviewer returned many small findings | No zero-finding exit in the brief, and no relevance filter at the chair. |
| Rounds run until the members agree | Convergence is not corroboration, and nobody set a budget. |
| A subagent decided the answer | Typing may be delegated; deciding may not. |
