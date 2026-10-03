# Fan-out — when parallel agents earn their place, and when they multiply the bottleneck

`compound-v:get-shit-done-3-build` states the operative rule; this file carries the reasoning, the evidence
and the traps. Read once, not per run.

## The rule, in one line

**Dispatch the check, never the build — and take the cap off only where every lane is verifiable
without reading its trace.**

## Why the build is not dispatchable

The measured payoff for a fresh context is in *judging* work, not producing it. Every measured
result on dispatching the build runs the other way, and the skimping is the ledger's job rather than
dispatch's: an agent identified **20 call sites**, changed **5**, and stopped, and what fixed it was
an in-context checklist, not more workers.

The most-quoted counter-example does not say what it is usually quoted as saying. A three-arm run on
one ~2k-LOC service (three Node backends plus a Telegram mini-app), each arm scored out of 10 by a
frontier model: **codex solo 9 min, 8/10** · **agent team under an orchestrator 9 min, 5/10, with
diverged contracts** · **the same model solo, no agents, 7 min, 5/10.** The third arm is the control
the retellings drop. Teaming scored *identically to its own single-agent baseline* — it cost two
extra minutes and bought nothing, and the three-point gap belongs to the model, not the topology.
Carry the caveats with it: n=1, one run per arm, judged by an LLM against no published rubric.

So the honest rule is weaker and more useful than "agent teams fail": **on a small coupled service,
orchestration is score-neutral and latency-negative — pay for it only when you can name what it
buys.**

## The three boundaries, and which one binds

Fan-out looks like a code question and is not. Three boundaries stack:

| Boundary | What it decides |
|---|---|
| **File** | the *mechanism* — bare parallel runs when tasks touch different parts of the tree, `git worktree` when they touch the same files |
| **Context window** | the *size* of one unit of work |
| **The supervisor's head** | **whether you fan out at all** |

The third is binding and it is the one nobody prices. A contract boundary never appears as a licence
to split; contracts appear only as the thing that *breaks* when you do.

**The evidence is a practitioner arguing against his own tooling.** The operator in this corpus with
the most parallel machinery reports doing it least — twice, ten months apart, unprompted — because
it demands switching context, checking the coder's work and proof-reading plans, and by the end of a
day in that mode his head is "swollen". Against him sit two louder sources: one relaying 3–5 git
worktrees at once with single-keystroke aliases, and a product team running 3–8 agent instances per
engineer. The reconciliation is a **staffing** rule, not a tooling one: some people are inclined to
management and many simultaneous tasks, others do one task for ten hours; work with each as they
are. Which means the ceiling belongs to the operator, and no skill can set it as a number.

## Why coverage is the exception

Parallelism converts one review queue into N, and review is already the stage the pipeline names as
its constraint. **Fan-out is a human-bottleneck multiplier unless each lane is independently
verifiable without you** — and that is precisely what coverage work has and build work lacks. You
can re-run a sweep's claim yourself; you cannot re-derive a coder's judgment without redoing the
work. So sweeping the ask for undeclared rows, verifying closed rows independently of whoever closed
them, checking every call site rather than the five that were easy, and reading the source nobody
opened are all uncapped — and splitting the build is not.

## The trap: fan-out reads like diligence

Agents launched and tokens burned are evidence of nothing — not effort, not progress, not
thoroughness. A large fan-out *feels* rigorous and summarises even better, which is exactly why the
ledger grades the run and the agent count grades nothing. A run that dispatched thirty agents and
closed no rows did nothing, expensively.

## What a harness actually buys, priced honestly

A vendor's own long-running coding harness — planner, generator and evaluator run **strictly in
series**, with files as the only channel and **no parallel execution anywhere in the design** —
reports one build at **20 minutes and $9 solo versus 6 hours and $200 through the harness**:
*"over 20x more expensive."* The trade is not tokens saved. **A harness buys unattended autonomy
with money**, and the same source states the law that follows: *"every component in a harness
encodes an assumption about what the model can't do on its own, and those assumptions are worth
stress testing."* Remove one component at a time, or you cannot tell which were load-bearing.
