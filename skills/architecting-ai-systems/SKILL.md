---
name: architecting-ai-systems
description: Design the architecture of a system around a frontier model — harness thickness, the one hard primitive to build, the retrieval shape, whether to build a reward-generating environment, what to delete on the next model release. Opt-in (manual): invoke when the user explicitly asks to design or architect an AI system or product — "help me design the AI architecture for my project", "wrapper or primitive?" — names this skill, or another Compound V skill hands off here. Do not auto-trigger on incidental "make it smarter" mentions; this is a deliberate deep-dive.
---

# Architecting AI Systems

Architect the compound system AROUND a frontier model so the harness — not the swappable model — is your durable edge, and resolve how-thick-a-harness by building where the model *barely* works today. The model is a component you rent and will swap; what you engineer around it — the retrieval, the validators, the environment, the one hard primitive — is what compounds across model generations. But the architecture diagram is not the asset, and neither is the code: when the answer to "what stops someone rebuilding this in a weekend" is "our architecture," there is no moat. What survives is integration depth, proprietary data access, distribution, and the accumulated edge cases — the parts that took calendar time rather than tokens (the moat test itself belongs to **compound-v:startup-taste**). Get the shape right and a better base model *helps* you; get it wrong and the next release deletes you.

## When to use

- You've decided to build (startup-taste said go) and now you're choosing the system shape: one thin call vs. a thick compound, wrapper vs. primitive.
- You're picking the one hard primitive to build — a sync engine, a retrieval+synthesis pipeline, a reward-generating environment — and letting the product fall out of it.
- You're choosing a retrieval architecture and someone reflexively said "vector RAG."
- You're deciding what plumbing to throw away on the next model release, or whether the harness you have is now the ceiling.
- The question is "what do we build around the model" or "will the next model help me or delete me" — that's this skill even when nobody says "architecture."

**Skip it when** the decision is the agent's *internal* shape (loop / tools / sub-agents → **REQUIRED:** use compound-v:designing-agents), its *token budget* (KV-cache, compaction, JIT-vs-preload → **REQUIRED:** use compound-v:context-engineering), or the *build/no-build verdict itself* (**REQUIRED:** use compound-v:startup-taste — it owns the wrapper test, primitive-in-one-sentence, own-your-ceiling, and verifier-first gates; come here for the buildable HOW once it says build). Once the architecture is committed and the running system starts drifting, double-firing, or racing, that's the sibling **REQUIRED:** use compound-v:ai-system-reliability.

## The default: a thick compound harness, sized to where the model barely works

The reflex split is wrong on both ends. A **thin wrapper** (paste context, call model, return) gives the model no edge a competitor can't clone in a weekend, and a base-model upgrade deletes you. **Training your own foundation model** burns your iteration speed and the next frontier release laps you anyway. The middle path wins: engineer a **composite architecture around a frontier model** — context injection, validators, error recovery, a fine-tuned fixer for the last mile — and let the model stay swappable underneath.

How thick is the live tension, and it has one resolver: **build where the model barely works today — the 10–30% success band.** Below that band you're writing science fiction; above it, the surface is already commoditized and you're late to it. What is measured here is METR's task horizon — the length of task a model finishes autonomously at >50% — doubling roughly every seven months. The band itself, and the ~18-month read on it, are this skill's inference from that figure and sit on a different axis: a doubling in task *length* is not the same as a rise in success *rate* on the task you already have. Treat the band as a bet to re-derive in your own domain, not a constant to look up. So the workflow that's *almost* working today is exactly the one to architect around now, because the infra, evals, and domain context can't be built overnight; waiting until it works means a competitor already built them. The corollary tells you what to make *thin*: any layer the next model will simply absorb is a layer you shouldn't pour concrete into. Build the durable scaffolding (verifiable environments, retrieval, state, conventions); skip the elaborate cognitive scaffolds and role-play planners scale will wash away. **The band has a named dissent, and the axis is where your edge comes from:** Jeff Dean (a YC talk) advises aiming where general models succeed 0–1% of the time and reading 20% as a warning that scale will close the gap for everyone — right when your edge is data the general model cannot see or a niche model you train, wrong when the product is built to ride the next model.

## What the app layer is for, and why the lab will not do it for you

The division of labour worth designing against, from Andrej Karpathy:

> "Personally I suspect that LLM labs will trend to graduate the generally capable college student,
> but LLM apps will organize, finetune and actually animate teams of them into deployed
> professionals in specific verticals **by supplying private data, sensors and actuators and feedback
> loops**."

Read that list as the spec for what you are building. The lab ships general capability; the four
things it cannot ship are the ones only you have — **private data** nobody else holds, **sensors**
that observe your domain, **actuators** that act in it, and **feedback loops** that close over real
outcomes. A system that adds none of those is a wrapper, and the next model release deletes it.

Note also which word sits inside that list: *finetune*. Even here, the argument is not that context
alone does it. Where a behaviour must hold across every session and cannot be re-supplied each time,
weights are the mechanism and context is a workaround for not having them.

## Build the one hard primitive; the product is its consequence

Don't build "a product." Build the **one hard primitive** and let the product fall out of it — Linear built a sync engine, Perplexity a retrieval+synthesis pipeline, Cursor speculative editing, each before any UI. The disqualifying test: **if you can't state the primitive in one sentence, you don't have one yet** ("the search result, from links to a cited answer").

And once startup-taste's own-your-ceiling gate has named a ceiling-setting dependency, the architectural consequence is where your scarce novelty goes: spend your **innovation tokens** on that layer and nowhere else — you get roughly three novel-tech bets before operational complexity sinks you, so the owned primitive is the novel part and everything around it (queues, storage, deploys, the provider seam) is boring, well-understood tech.

## Which retrieval primitive — vector RAG is usually the wrong shape

When the system needs retrieval, the reflex "bolt on a vector DB" conflates document-filtering with passage-relevance and collapses multi-hop reasoning into one cosine score. Pick the shape from the task:

- **High-stakes / multi-hop:** run parallel model passes that decide what deserves attention, then synthesize and reverse-engineer citations — not one similarity score.
- **Web-scale search:** link-prediction-as-pretraining plus a custom vector store that filters at scale.
- **Enterprise search:** real-time, permission-aware per-person personalization over a people/role/doc knowledge graph.
- **Agentic search — a model writing the queries:** start lexical (BM25 beside grep) and add embeddings for what it provably misses. A model writes long queries dense with names, acronyms and identifiers — where embedding-only retrieval fails and exact match does not. Tune BM25 to your document length before judging it: on a long-document deep-research benchmark, re-tuning its defaults lifted an agent from 64% to 82%, and the tuned lexical agent beat released dense-retriever agents — so check how a benchmark's losing arm was configured before it picks your retriever. Embeddings earn their place where the same thing is said in different words; past what the shell can scan, retrieve into a local workspace and grep there.

**And what you admit into the index is an architecture decision, not an ingestion detail — it sits upstream of the shape choice.** Pointing the agent at the whole drive and letting retrieval sort it out is the named anti-pattern: an unfiltered organizational corpus mixes asserted opinion with validated outcome and the model weights them alike, so a researcher's strongly-held view comes back as fact and nothing ties a past spec to whether it actually worked. Curate by **validation status** rather than relevance — admit a document when its claim was checked, and attach the outcome. Budget for it: on one large platform's internal agents the corpus work outweighed the dedicated build work, and a first attempt that handed the agents everything on the drive "hallucinate[d] like crazy".

This is the architecture *choice*. The token mechanics underneath it — JIT-vs-preload, cache, compaction — are **REQUIRED:** use compound-v:context-engineering, and before you write the retrieval code, **REQUIRED:** use compound-v:searching-patterns to look up how it's actually built.

## When the primitive is a reward-generating environment

Sometimes the right thing to build around the model is not a pipeline but an **environment that generates a verifiable reward**. Where a solution can be auto-checked — code compiles, math checks, "did the reply book the meeting" — RL goes vertical, and quality of the signal beats quantity of data (a few thousand verifiable examples beat millions of low-quality RLHF ones). The engineering order is **build the verifier first**, because the system's ceiling is set by whether reward can be auto-checked at all.

Two disciplines make this hold. **Incentivize, don't teach** — design the reward surface and let scale surface the capability rather than scripting the procedure step by step; this is the mental model behind o1 and R1. And the real unlock for long autonomous runs is the **realistic environment that harvests real-world signal as reward**, not better prompts: serve checkpoints to production and harvest accept/reject. The named failure mode is **reward-hacking** — the model games the proxy (emitting broken tool calls to dodge a negative signal). Design against it before you ship the loop. To build and align the verifier/judge itself, **REQUIRED:** use compound-v:evals — say "then build the verifier" and point there; don't re-teach judge construction.

## Worked example — v0: four composite layers, no model swap

The reflex for "build a great code-generation product" is either a thin wrapper on the best model or "we'll train our own." Vercel's v0 did neither. Starting from a Claude Sonnet baseline, they engineered a composite architecture around the *same* model and drove error-free generation up by a ~30-point jump with zero model training, no model swap. The four layers, each one the harness doing work the model couldn't:

1. **RAG context injection** — pull the right framework/API context in at generation time so the model isn't guessing.
2. **Stream-time fixing** — repair errors as the output streams, before they reach the user.
3. **Deterministic AST / icon validation** — a non-model check that catches structural mistakes a model won't reliably self-catch.
4. **A fine-tuned AutoFixer** — a small specialized model for the last-mile failures the frontier model leaves behind.

The lesson is the whole skill in one case: the **harness, not the model, was the moat**. Every layer survives a frontier model upgrade — a better Sonnet makes all four *better*, not obsolete — which is exactly the test for whether you built a primitive or a wrapper (same model plus a better harness moved Opus 4.5 from 50.2% to 55.4% on SWE-bench Pro via context management and tool orchestration alone).

## Which layer next — size it by its share of the loop

Before engineering a layer, name the share of end-to-end time the step it automates holds: driving that step to near-zero removes at most that share, so a layer that halves a step holding 15% of the loop is capped at ~8% however good it is. One agentic-IDE team ran this as Amdahl's Law against the "AI writes 90% of the code" inference — engineers also review, test, debug, design, deploy and navigate, so cutting the 30-of-100 units spent writing down to 3 lands at 73: a 27% win, not 10×; their measured gain was 30–40%. Measure the shares in *your* loop rather than inheriting those, but expect generation to stop being the big one once the model writes the output — the time moves onto the human's review-and-accept surface. That surface is not compensating scaffolding and does not expire on the next release: a better model produces *more* output to review. It can also be the cap itself — that team's inline-refactor UI was limited by the host editor's extension API, not by model quality, and rebuilding it **tripled acceptance rate on unchanged models**. When the limiting surface is someone else's, that's the own-your-ceiling gate: **REQUIRED:** use compound-v:startup-taste.

## What to make thin, and what to delete each release

Hold the counterweight, because the same thesis that says "build the harness" says "don't over-build it." A too-thick harness becomes the *ceiling* — over-built plumbing caps a smarter model's overhang, and hand-crafted abstractions get erased the moment a better model lands (the Bitter Lesson: don't build the edge more compute will delete; in agent frameworks, ~99% of the value lives in the RL'd model). So:

- **Scaffolding has an expiry — delete it on every model release.** The "product overhang" is when the capability already existed and only your scaffolding didn't. Harness work built to compensate for one model's weakness turns into dead weight — sometimes actively harmful — the moment the next model doesn't have that weakness; mitigations built for one model's over-cautious behavior were obsolete on the following release. So record *why* each defensive layer exists, and on every model upgrade re-run the evals with the layer removed, keeping it only if removing it measurably hurts. Old defensive instructions don't get ignored — they get overfitted to. **Choose between architectures by what a stronger model does to them, not by one model's score:** swap a weaker model of one family for a stronger one and prefer the design that gains more — one that scores the same on both is capping the model (Manus's selection rule).
- **Only compensating layers expire.** A layer that *enforces* an invariant — write scope, permissions, an approval gate — is a guarantee, not a crutch, and a removal eval rarely reaches the long session where a prompted substitute fails: Cursor deleted ~15K lines of native worktree support and replaced the isolation with a markdown skill, then watched its weakest model start working in the primary checkout — on evals that cannot yet simulate the long sessions where any model forgets — and is rebuilding it natively (a talk). Last-mile specification — how *your* task differs from the model's default — does not expire either: it is *"irreducible to the extent that your task/context diverges from the mode, regardless of capability"* (Omar Khattab).
- **Keep the harness model-forward and mostly self-written.** The frontier framing is the shift from predefined scaffolds to reasoning-model-led workflows — the harness becomes the box and the model chooses how to proceed inside it. Prefer one universal interface (Bash) over dozens of bespoke tools, and **start from maximal capability and restrict, not the reverse**: a too-thick harness fails not because the model is weak but because the action space you handed it is incomplete, so it can't route around a broken path.
- **Code-over-tools:** give the agent a sandbox and let it call tools as code rather than exposing every tool as a direct call — measured ~98% token reduction on a realistic workflow.
- **Keep intelligence in a model-agnostic harness, not fine-tuned weights** — spend millions fine-tuning and the next base release erases the edge; compound systems are vaccinated against the Bitter Lesson. The clean expression of the seam: the provider is **one thin Protocol** (`complete(messages, tools, *, system) -> response`) and the app layer sits above it, so swapping the *provider call* is a one-line change (the LLM-OS / thin-provider-abstraction pattern). **The tool layer above that seam is per model, so a swap is a re-evaluation, not a one-liner:** OpenAI's models were trained on a patch-format edit tool and Anthropic's on string replacement, and handing either the other one *"costs extra reasoning tokens and produces more mistakes"* (Cursor) — provision each model the tool format it trained on, and re-run the evals on every swap (on Terminal-Bench 2.0 one model moved by as much as 14 points between a neutral harness and its vendor's own).
- **Build the non-composable core; compose proven engines; defer owned ones.** Build only the irreducible primitive (the loop, the context bundle, the one coercion engine you genuinely can't buy); *compose* solved problems (durability, memory, evals) behind interfaces you lock now; and *defer* owning an engine until dogfood proves the gap. Resolving the final form of eight engines on paper before anything runs is the over-engineering this skill exists to prevent — the tactical↔durable seam (same loop, one `durable=True` flag) lets the tactical parts stay simple and the durable parts get durable without a rewrite.

## Red flags

| Symptom | The actual problem |
| --- | --- |
| Swap the model in your head and the product is basically the same | You built a wrapper. A base-model upgrade deletes you, not helps you. Find the primitive. (You skipped the go/no-go gate: **REQUIRED:** use compound-v:startup-taste.) |
| Can't state the core primitive in one sentence | You don't have a primitive yet — you have a feature on top of someone's API. |
| "We'll fine-tune / train our own model" before the harness exists | Burns iteration speed; the next frontier release laps you. Build the composite around a frontier model. |
| Reflexively reaching for vector RAG | Conflates filtering with relevance, flattens multi-hop. Pick the retrieval shape from the task. |
| Building an RL loop before the verifier exists | The verifier sets the ceiling and catches reward-hacking. Build it first. |
| Architecting only for what the model already does *reliably* today | You'll have rebuilt it before launch, and that surface is already commoditized. Aim at the 10–30% band — roughly the capability ~18 months out (task horizon doubling ~7mo). |
| A thick hand-built scaffold the next model will absorb | That layer is now your ceiling. Keep the harness thin and model-forward; delete it each release — and any defensive layer nobody can say the reason for goes first. |
| Core primitive runs on a third-party service | That service caps your quality. Own the layer that sets your ceiling, or you don't control your destiny. |
