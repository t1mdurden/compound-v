---
name: designing-agents
description: Pick the least-structure design that solves an AI/LLM feature, and design the tools it calls — climb from a single call up to autonomous agents and sub-agents only when complexity demonstrably earns its keep. Use when deciding "should this be an agent or a workflow?", "how many agents?", whether to add a loop or tools or sub-agents, when architecting any multi-step LLM pipeline, or when writing or fixing a tool or MCP definition — including an agent that keeps picking the wrong tool or passing wrong arguments — even when the ask is just "make this smarter."
---

# Designing Agents

Find the simplest thing that works, then add agentic complexity **only when it demonstrably improves outcomes**. Every step up the ladder trades latency and cost for capability, so each rung has to pay that tax. For many features a single LLM call with good retrieval and a few in-context examples is already enough.

Two definitions the whole decision turns on:
- **Workflow** — LLMs and tools orchestrated through *predefined code paths*. You wrote the control flow; the model fills in the steps.
- **Agent** — the LLM *dynamically directs its own process and tool use*. The model drives the loop and decides what to do next.

Workflows are predictable and debuggable; agents handle the unpredictable at the cost of predictability. Most "I need an agent" turns out to be "I need a workflow," and most "I need a workflow" turns out to be one good call.

## When to use

Deciding the *shape* of an AI feature — one call vs. a chain vs. a loop vs. multiple agents — or diagnosing an existing one that's flaky, slow, or expensive because it's over-built (or under-built). Skip it when the shape is obvious: a single, well-understood call needs no architecture decision; just write it.

This skill owns the **decision** — which shape, how much complexity — not execution: for token/context mechanics use compound-v:context-engineering; for fan-out details use compound-v:dispatching-parallel-agents; for the evaluator/review loop use compound-v:recheck.

## The escalation ladder — climb only as far as the task forces you

One gate sits before the ladder: **would the best person do this agentically, or as ordered steps?** A linear task gets a function with ordered steps — wrapping an agentic loop around it adds latency and unpredictability and makes the pipeline harder to evaluate. Past that gate, start at the bottom **and give every rung a measurable result** — without one you cannot tell whether the added complexity helped, which is the only thing that justifies it. Move up one rung only when you can name the specific thing the current rung *can't* do. A **latency budget** can force you *down* the ladder regardless of capability: if the feature must feel instant (compound-v:product-taste names the perceptual cliffs), a multi-round agent is off the table. Orthogonal to the rung: **build the first working version on the most capable model you have**, so a failure means the *approach* is wrong; downshift to cheaper models once it works and measure what you lose.

1. **Single augmented-LLM call** — one model call with retrieval, tools, and in-context examples. The atomic building block; everything above is composed from it. Default here.
2. **A Skill** — a reusable prompt/procedure that runs *in the main context*: the cheapest reuse there is, no isolation tax, no extra round-trips. If the win is "I keep re-explaining the same thing," it's a Skill, not an agent.
3. **A workflow (predefined control flow)** — when the task cleanly decomposes into *fixed* steps you can write in code. Three canonical shapes:
   - **Prompt chaining** — sequential steps, each consuming the last's output; add a programmatic gate between steps to catch errors early. Use when the decomposition is fixed and clean (outline → validate → write).
   - **Routing** — classify the input, dispatch to a specialized handler. Use when inputs fall into distinct categories better handled separately; doubles as a cost lever (easy cases to a small model, hard ones to a big one). Routing isn't only a front-door classifier: an agent can run until it hits a hard subtask, **forward a fork of its full context to a second model** for that one step, then resume with the result. Two gaps bound it and only one has a fix: a worker **cannot reliably tell when it doesn't know** — so the trigger must be an *observable external signal* (a failing test, a reviewer's verdict, an attempt count: "always escalate on a merge conflict"), never self-assessed confidence — and it cannot reliably tell **what to ask**, which no external signal repairs. That second gap is why the cheap-primary form of this shipped and didn't pay: the quality ceiling is set by the *primary*, so a weak one caps the strong helper it calls. Run it **between two strong models as a capability router** (this one debugs better, that one writes tests better), not as a difficulty escalator up from a weak model — and fork the whole context rather than hand-picking a slice, since the asker is the one who doesn't know what's relevant. **That last rule inverts on ESCALATION and the axis is which model produced the context** — forwarding a *peer's* full context is right, forwarding a *failing weaker* model's is not: AWS measured recovery rising when the weak model's reasoning is dropped and only its working-tree edits are kept. See references/shapes.md, "Split the decider from the executor", which carries the numbers. A routing tactic, not a reason to build a model-router.
   - **Parallelization** — *sectioning* (independent subtasks at once) or *voting* (same task N times, aggregated under a stated rule). Use for speed or when multiple perspectives raise reliability — but price the vote honestly: runs sharing a prompt and tool set have *correlated* errors, so N tries buy far less than N independent tries, and the exit is the fixed N, never "they finally agreed."
4. **Orchestrator-workers** — a lead LLM decides the subtasks *at runtime* and delegates them; unlike parallelization, the subtasks **aren't known in advance**. Use only when you genuinely can't predict the decomposition (multi-file edits, open-ended search).
5. **Evaluator-optimizer** — a generator and an evaluator loop until a signal says "good enough." Use only when you have a *clear evaluation criterion* and iterative refinement measurably helps.
6. **Autonomous agent** — the model plans and operates the loop itself on environmental feedback, for as many steps as it takes. Use for open-ended problems where you *can't* hardcode a fixed path or predict the step count. Precondition: **ground truth from the environment each step** (test results, code execution, tool returns) — without it the agent drifts.
7. **Sub-agents (context isolation)** — split work into fresh, isolated context windows. **A sub-agent is context isolation, not org-chart role-play**, and there are exactly two legitimate reasons to spawn one. **(a) Isolation:** the subtask's intermediate output would pollute the parent's context, so the sub-agent absorbs the token-heavy reading/searching and returns only a distilled digest (the mechanism lives in compound-v:context-engineering). Same move as a **failure firewall**: it grinds through the failed attempts and returns the success plus a note on the dead ends. **(b) Independent judgment:** you do not want the same person writing and reviewing the code, and a fresh context is the only way to get a verdict that isn't anchored on the reasoning that produced the work. **Capability decomposition is not a reason** — a sub-agent is not smarter at a sub-domain; it is the same model with less context. The positive test is informational: split only when there is genuinely **no purpose in the first context being part of the second**. Split by *role* and you have drawn your org chart rather than the problem's structure, at a real price in mutual information — a triage agent forwards its verdict and everything else it learned dies. **Neither is tool count** — retrieve the ~5 tools a task needs over a list of 50 instead. The costs are real — a clean slate that sees none of your history, a latency tax to re-gather context, telephone-risk on what comes back — so don't reach for it when the task needs tight back-and-forth. **Cap the tree at one level — and check your harness's default, because it is probably not 1.** Claude Code lets a subagent spawn its own subagents **three layers deep by default** (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=1` turns nesting off), so depth-1 is a decision you make, not a floor you inherit. Enforce it structurally, the way the harness does: at its cap it withholds the `Agent` tool from the child, so a worker at the limit does the work itself and returns a summary.

## An agent is an LLM + a loop + tools — there is no secret

A working coding agent is **under ~400 lines, most of it boilerplate** (~190 after three tools). The loop is the whole heartbeat: read input → append to the conversation → call the model with the full conversation + tool defs → run any tool call and append its result → show text to the user → loop. The model server is *stateless*; it only sees what you put in the `conversation` — maintaining that history is your job, which is why context engineering is the substance of agent quality.

A tool is four parts: **name**, **description**, **input schema**, and the **function**. Give a model a tool and it *wants* to use it — it auto-triggers and chains without coaching, so the leverage is in the tool interface, not clever prompting: builders routinely spend more time optimizing tools than the prompt.

At ship time you wrap those four parts in **operational** concerns the primitive doesn't carry: a **timeout that returns a result** (a slow tool reports "timed out," it doesn't throw), an **approval gate** on irreversible actions, an **`is_enabled`** predicate to hide a tool the model shouldn't reach for in the current state, and an **error formatter** that turns a raw stack trace into a terse, model-readable message. The pattern tying these together: **a tool error is a tool *result*, not an exception** — feed the failure back into the conversation as the tool's output and let the model adapt, rather than crashing the loop. Hand results back as **structured objects**: a typed return the next step can read beats prose it has to re-parse.

**Skip the high-level agent SDKs.** Model differences are large enough that you'll build your own thin abstraction anyway, and the SDKs obscure the underlying prompts/responses and can mangle message history. Target the provider API directly so you control cache points and see real errors.

## Tool design is an interface (ACI)

Invest as much in the agent-computer interface as in a human UI. The agent is a non-deterministic caller that will call the wrong tool, with the wrong args, in the wrong order — unless the interface prevents it:

- **Poka-yoke the arguments** — make wrong calls hard to express. Requiring **absolute paths** instead of relative ones eliminated a whole error class on real benchmarks. Constrain types and enums so invalid states can't be passed.
- **Minimal overlap.** If a human engineer can't say which of two tools to use in a situation, neither can the agent. Curate a small set of distinct tools; consolidate into one `search_x` rather than exposing every low-level endpoint.
- **Describe it like a docstring for a junior.** State what it does, when to use it, when *not* to, and what it returns. Return high-signal semantic fields (names, types) over cryptic IDs (`uuid`, `mime_type`).
- **Add tool examples only where the schema cannot say it.** Newer models take the examples as their exploration space, and an enum or expressive parameter already conveys usage. Examples pay for nested input where valid JSON isn't correct use, optional parameters whose inclusion matters, conventions no schema captures — Anthropic measured 72% to 90%.
- **Fix the tool, not the prompt around it.** When the agent keeps misusing a tool, treat the tool as an eval target: run it many times, watch where the model trips, then rewrite the interface and description *in the agent's own voice*. A dedicated tool-testing pass that did exactly this cut downstream task-completion time ~40%.

**And when the shape is wrong, observe before you redesign — from traces, not a single run.** Re-drawing the topology (more agents, different roles) is guessing. Give the agent real data on a filesystem and plain tools, review its traces to saturation, and derive the shape from what recurs: *when the agent writes the same script repeatedly, that script wants to become a command; when it keeps re-loading the same guidance, that guidance belongs in the prompt.* Splitting is sometimes right: failure-to-follow-instructions and wrong-tool-selection are named triggers for it. Then pull the deterministic half out: statistics, thresholds and prioritisation are code, and **the agent's job is to investigate, not to identify.**

- **Make the tool dumb and deterministic, not agentic.** A tool that is itself an LLM or sub-agent chains two non-deterministic systems, compounding failure. Prefer a plain deterministic action (a literal web search, a direct lookup) over "ask a sub-agent to figure it out" — push the intelligence into the *calling* agent. The reverse backfires: a sub-LLM wrapped inside an output tool to fix tone increases latency *and* reduces quality.

## Per-step reliability is the real bottleneck

Multi-step agents fail on *compounding* error, not on any single hard step. At 90% per step, 100 steps gives 0.9^100 ≈ 0.003% — effectively zero. You need roughly **99.9% per step** before long chains work, and each added "nine" is roughly an order-of-magnitude harder.

- **Scope tasks small and verify each one.** Prefer subtasks with **automated verification** (tests, type-checks, a runnable result) — verifiability, not model IQ, limits how far an agent can reliably go. **A verifiable signal is the precondition for autonomy** — no signal → no autonomy → keep it a short, checked workflow.
- **Don't trust the model's own narration as a check.** "Show your reasoning" is not a correctness signal — the visible chain-of-thought can be edited to nonsense and the model still answers correctly, so it isn't a faithful trace of the computation.
- **On a retryable failure, change a variable — don't re-roll the same dice.** Retrying the same model often produces repeat failures. Fail *over* — a different model, or a substantively changed prompt/context — so the retry is a new experiment.

Measurement on a multi-agent research system found **three factors explain ~95% of the performance variance — token spend alone explains ~80%, the other two being tool-call count and model choice.** "Add another agent" is rarely the lever; "let the one agent spend more tokens on the hard part" usually is.

## Agency is a second axis — the ladder sets machinery, not authority

A rung says how much *structure* a feature gets and nothing about how much *decision authority* the agent holds; every unit of autonomy handed over is a unit of control given up. Stage it separately: hold the user-facing experience constant and remove the human one release at a time — the agent **drafts for an operator** who accepts, edits or rejects, then **answers the user directly**, then **gets the consequential tools** (issue the refund, open the PR, launch the campaign).

The reason is signal, not caution. At the draft rung the operator's edits on real traffic are a labelled record of exactly where the agent is wrong, harvested while being wrong still costs only a discarded draft — error analysis for free, and the eval set you didn't have (**REQUIRED:** use compound-v:evals to turn the override log into one). So where *no verifiable signal → no autonomy* dead-ends, the rung below autonomy is how you manufacture the signal: evals catch only the failures you already knew to look for, and the rest surface in production.

**Promote on information gain, not a calendar** — climb when a calibration pass turns up no failure mode you have already seen, concretely when operators stop editing the drafts. **Two events demote a rung:** a model swap (the new model's failure distribution isn't the old one's, so the calibration you earned is void) and adjacent-task drift (a policy-lookup tool users start feeding whole loan applications to, asking what previous underwriters decided on cases like this, is a different system wearing the same UI). This axis is orthogonal to *tool breadth* — a broad-tools, full-context start still routes its output through an operator. The named failure is starting at the top: the fully autonomous first release fails in a hundred uncatalogued ways at once, which reads as "the approach doesn't work."

## Bound the loop; reinforce the objective every turn

- **Cap the loop and force a finish.** An unbounded "keep going until done" loop is a bug — a stuck agent burns tokens forever. Set a hard turn ceiling (≈10 is a sane default) and, on the last allowed step, switch the prompt to **forced-done**: "summarize and stop, you are out of budget." Strip the tools from that last call so the only thing it can emit is the answer — and **still record the stop reason as the cap, never as success**. A run that exhausted its budget and then wrote a tidy summary did not succeed; logging it as success launders the cap into a win and destroys the one signal that tells you the budget is too small.
- **Gate irreversible actions behind a human (HITL).** Deleting data, sending a message, deploying, spending money — anything you can't undo gets an approval checkpoint before it runs, not a post-hoc apology. Reversible actions run free. Make the gate **checkpoint-backed** — the approval may land hours later, so persist state and resume rather than blocking a live process (compound-v:ai-system-reliability). **The autonomy posture belongs to the user, not the agent** — whether writes pause for review is a setting the person running the system owns, fixed out-of-band for the run. An agent may narrow its own permissions; it must never widen its own approval policy.
- **Durability is a separate axis from this ladder.** Climb the ladder for *capability*; add durability independently when the work must survive a crash. Any rung can run ephemeral by default and be promoted to durable with a flag — never a rewrite, never a forced graph (compound-v:ai-system-reliability owns the durable-state seams).
- **Reinforce the objective on every tool return**, not once up front. Each tool result is a chance to re-state the goal and current status, hint when a tool failed, and report state changes. A todo/echo tool that reflects the agent's own task list back is enough to keep it on track.
- **Manage cache points explicitly** (this is where agent cost lives — see compound-v:context-engineering). Keep the system prompt and tool list static so the prefix stays cached; feed dynamic data (current time, fresh state) in a *later* message, never in the cached prefix.

### The stop rule (write it down; the model won't infer it)

Any agentic loop needs an auditable four-clause stop condition; it halts when **any** fires:

1. **Hard cap** — turn/tool/token budget hit (the ceiling above).
2. **Coverage green** — the success signal is satisfied (tests pass, the criterion is met).
3. **Stuck** — the same action **and** an unchanged result, both conjuncts required. "The last few steps stopped changing the answer" is the wrong test: it kills legitimate polling, where repeating one call is the design and a *changing* result is progress. A period-2 A-B-A-B cycle counts as stuck too. Stuck is one of four degradation states, named here for the whole kit: **frozen** — no progress and no error, nothing running, so re-issue or change the action; **stuck** — as above, so change a variable (different input, layer, tool), never re-issue the identical call; **blocked** — a genuine external dependency the loop cannot satisfy, so halt and escalate with the exact condition named; **misdirected** — real progress toward the wrong goal, the most dangerous because every health signal reads green, so re-read the original objective. Only *stuck* is a halt clause here; the other three name a response, not an exit.
4. **Model-done** — the model declares the task complete *and* that survives a check.

Two riders: **reserve budget for synthesis** so the loop doesn't spend its last token mid-thought with nothing written up, and **tell the model how much budget it has left** each turn so it can pace itself. A strong RL'd model's internal stopping policy is not extractable from the weights, so you state the contract.

## Multi-agent is delegation, not a message bus

When you do split across agents, the working shape is **agent-as-tool**: a parent calls a sub-agent the way it calls any tool, gets a result back, and stays in control — not a swarm of peers gossiping on a shared channel and editing the same files. The rule that keeps this sane: **parallelize intelligence, keep writes single-threaded.** Fan out the *reading, searching, and analysis* (read-only, composes cleanly); funnel every *write* through one actor in a defined order. Two agents editing the same file is a merge conflict you chose to create; deeper, every action a peer takes carries an implicit decision the others can't see, and conflicting implicit decisions compound into incoherent output. (For fan-out mechanics, see compound-v:dispatching-parallel-agents.)

**State the kill-reason as loudly as the keep-reason.** Every sub-agent is a standing bet that the model can't hold the task in one context, and frontier models keep winning that bet back — teams are *collapsing* sub-agents into the main loop, keeping the one that isolates a genuinely separate judgment. So make removal routine: **on every model upgrade, take out a layer and re-measure; keep it only if the score drops.**

Be skeptical of "look, a swarm built a whole compiler" demos. The famous multi-agent successes **all had a cheap, verifiable success criterion** (it compiles, the browser renders, the suite is green) that let agents grind without a human in the loop. Most real software has no such oracle — correctness is "did this match the user's intent," which only a human can score — so the swarm has nothing to converge against and drifts. No verifiable criterion → no swarm.

### Counterweights (when the simple rule bends)

- **Maximal-then-restrict for a strong RL'd model.** For a heavily-RL'd frontier model, every hand-built abstraction is often a *liability* it has to work around — so hand it broad tools and full context, then claw back only what demonstrably hurts.
- **The Ralph loop beats the org chart.** A single deterministic loop running on *fresh* context, restarted each cycle, routinely outperforms an elaborate multi-agent graph running on *stale* accumulated context — the reason batching into clean-context units (compound-v:batched-implementation) beats a standing committee of agents.
## Worked example — "answer questions about our docs"

The reflex is "build a RAG agent with sub-agents." Walk the ladder instead — every rung you didn't need is latency and cost you didn't pay:

1. **Single call?** Paste the doc section + the question into one call with a grounding instruction ("answer only from the provided context"). If the docs fit, *you are done* — ship this.
2. **Retrieval too big to paste?** A two-call **chain** (retrieve → answer). Still a workflow, still debuggable. Most doc Q&A lives here.
3. **Questions span unrelated domains?** Add **routing** — a classifier in front, specialized handlers (billing docs, API docs) behind.
4. **Multi-hop research across sources you can't predict?** *Now* it's **orchestrator-workers**: a lead dispatches readers, each a **sub-agent** so raw page dumps never pollute the lead's context. If answers must clear a quality bar, wrap an **evaluator-optimizer** loop (compound-v:recheck) that checks groundedness and retries.

## Red flags

| Symptom | The actual problem |
| --- | --- |
| "Let's make it multi-agent" before a single call was tried | Skipping the ladder. Burden of proof is on complexity — prove the call fails first. |
| Sub-agents named after job titles ("PM agent", "QA agent"), or spawned because there are too many tools | Org chart, not context control — and the split deletes mutual information the second agent needed. Split only for context isolation or independent judgment; a sub-agent isn't a tool shelf, so retrieve the ~5 tools the task needs over the list of 50. |
| Sub-agent count unchanged across model upgrades | The layer is a bet the model already won back. Remove one, re-measure, keep it only if the score drops. |
| An agent that loosens its own approval gate | The autonomy posture is the user's setting, fixed out-of-band. Agents may narrow permissions, never widen them. |
| Long autonomous loop with no verification between steps | 0.9^n is killing you. Scope smaller, verify each step against ground truth. |
| A tool that is itself an LLM agent | Compounding non-determinism. Make the tool deterministic; lift the intelligence to the loop. |
| Reaching for a heavyweight agent framework on day one | It hides the prompts and mangles history. Drive the loop yourself. |
| Dynamic data (timestamps, state) in the system prompt | Busts the cache every turn. Static prefix; feed dynamics in a later message. |
| "Show your reasoning" used as the correctness check | CoT isn't a faithful trace. Verify with tools, not self-narration. |
