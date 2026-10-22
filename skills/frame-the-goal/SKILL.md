---
name: frame-the-goal
description: >-
  Opt-in: define a goal's success as a runnable check before any mechanism is chosen; use only when the user asks.
---

# Frame the Goal

You cannot build the simplest thing that "works" until "works" is a written, testable check — so before choosing any mechanism, turn the goal into a one-line success criterion plus its inputs, output contract, and hard constraints. Most builds fail not at the mechanism but at the frame: nobody ever stated what "done right" means, so the work optimizes a proxy and ships something that passes a demo and fails in the world. Neural nets and agents fail *silently* — they return a confident wrong answer with no exception — so an undefined goal has no tripwire. The frame is the tripwire.

**Resolving the ambiguity IS the task, not a precondition for it.** Real requests are far shorter and vaguer than the tasks systems get benchmarked on, and the change they actually ask for is far larger. Cursor built its internal eval out of real engineer queries for exactly this reason: public benchmarks are "incredibly well-specified" while real inputs look like *make better* or *fix bug* — much shorter problem statements, much longer diffs, hundreds of lines across multiple files. The gap between what the user typed and what they want is therefore the normal case, not a defect in the user: guessing intent well is part of the job, and guessing *silently* is the failure. Name the assumption you're proceeding under, in the frame, where it can be corrected cheaply. Infer what you can from the codebase and the surrounding context rather than demanding a complete spec up front; when the gap is too wide to infer across, the interview that closes it is **REQUIRED:** use compound-v:brainstorming — run its intake round, not a second, weaker copy of it here.

## When to use

- A goal just arrived and you're about to reach for a mechanism — "how do I do X", "build a thing that does Y", "make it smarter" — and "works" has not been written as a pass/fail or measurable check.
- The goal is vague ("handle support tickets") or heavy ("resolve billing disputes end-to-end") and you don't yet know what success would even look like.
- A plan opens with a tool, a model, or an agent before it states what output would count as correct.
- An AI feature is about to be built with no eval in sight — the success check IS the eval, and it has to exist first.

**Skip it when** "works" is already a crisp, agreed check (a known input → known correct output) and you're only choosing *how* — go straight to **REQUIRED:** use compound-v:simplest-thing-that-works. If the real question is *whether to build at all* (moat, scope, distribution), that's **REQUIRED:** use compound-v:startup-taste. If you need the durable, multi-section product source-of-truth rather than a quick frame, that's **REQUIRED:** use compound-v:writing-prd.

## The frame: four parts, then a check

The default is one pass over four parts, ending in a single sentence anyone can run against an output:

1. **Input distribution** — what actually arrives, including the messy tail, not the happy-path example. The frame has to cover the inputs that break it, or the check is theater.
2. **Transform** — what the system does to an input. State it as the *intent*, not a mechanism. "Mechanism" is the next skill's job; naming it here pre-commits you before you know the check. Type what you heard while you're at it: a **method** the user mentioned in passing ("use a queue") is not a **goal** (what must be true when you're done), and a method silently promoted to a goal is how the work ends up optimizing the wrong target.
3. **Output contract** — the exact shape and invariants of a correct output (schema, allowed values, what must never appear). This is what a verifier later asserts.
4. **Hard constraints** — latency, cost, and **stakes: reversible vs. irreversible**. A reversible action can run free; an irreversible one (charge, send, delete) needs a gate. Tag this now, because it decides how much stability the build later needs. Record every hard constraint **verbatim** — paraphrase is where "never do X" quietly decays into "prefer not to do X" by the time it reaches an implementer.

Then write the **success check**: one line that a human or a verifier can run against any output — a command with an expected result, or an observation someone could make and agree on. If it isn't machine-checkable, it isn't a check. "It should feel fast" is a wish; "p95 under 200ms measured by X" is a check, and so is "resolves the dispute as well as a human agent on N held-out cases." "Handles disputes well" is neither. That objectivity is what makes the downstream review evidence rather than opinion.

**Frame the full ambition, not the convenient proxy.** The check captures what the user actually wants, even when that's harder to measure — a proxy you can measure easily but that diverges from the goal is the classic way an eval silently rewards the wrong thing (*criteria drift*: the rubric must track what "good" really means, or the system games the gap). Never shrink the goal to fit an easy check. You cap the *machinery* later; you never cap the goal here.

**For an AI goal, the success check is the eval/verifier.** Define it before building, not after — for a domain where outputs can be auto-checked, that verifier is also what any later RL or self-improvement loop optimizes, so its quality sets the system's ceiling. Building it here doesn't mean *constructing* the judge — that's **REQUIRED:** use compound-v:evals (error analysis, a judge aligned to a human, decompose-by-mechanism). Frame the check; build the judge there.

## Heavy goals: decompose into a tree of checkable sub-goals

A genuinely hard goal does not get a weaker frame — it gets a *deeper* one. The frame never caps ambition; it makes a big ambition tractable by splitting it. Break the goal into sub-goals, each with its own one-line check, so the hard thing is assembled from small things that each provably work. A complex system that works is invariably grown from a simple system that worked; one designed complex from scratch never does (Gall's Law). The discipline is old and general: understand the goal, restate it in your own terms, split it into sub-problems you can each verify, then plan — understand → plan → execute → check.

Decomposing also tells you where the real risk is. Frame the riskiest, most load-bearing sub-goal's check first and confirm it's even satisfiable before building everything that depends on it — order the work by what you learn per unit of effort, not by what's easy to start (a judgment call: de-risk the load-bearing assumption first, so a dead end shows up before you've built on top of it). A tree of green sub-checks is what later lets the mechanism stay as simple as each sub-goal allows while the whole still hits a hard target.

**Derive each sub-check's bar from the top-level check, and write the line that composes them back up.** Bars picked seam by seam don't add up: where every stage has to land and the errors are roughly independent, four stages at 90% each leaves ~66% end to end — so a tree that is green everywhere and red at the goal is the normal outcome, not a surprise. Work in the direction that binds: start from the top check's number, back out what each seam has to hold, and write the one-line composition beside the tree — a product down a chain, a weighted average across a partition of cases, a subset relation for a contribution. Where stages are correlated, or a wrong stage can still produce a right answer, say so and treat the product as a floor; that is still stating the composition. If you can't state one at all, the tree is diagnostic only — it localizes a failure but proves nothing about the goal, so re-cut it rather than build on it. (**compound-v:evals** carries the compounding arithmetic itself; state the composition here, don't restate it.)

## Worked example — framing "resolve billing disputes end-to-end" (a heavy AI goal)

A founder says: "Build an agent that resolves customer billing disputes end-to-end." Tempting to open a chat loop with tools and see what happens. That skips the frame, and an agent with no success check fails silently on the disputes that matter most. Frame it first.

**Input distribution.** Real dispute tickets: duplicate charges, "I cancelled and got billed," partial-refund asks, fraud claims, and a long tail of confused or angry free-text — including ones with missing account context. The tail is the point; a frame built on the clean cases is theater.

**Transform (intent, not mechanism).** Read the dispute and account history, decide the correct resolution, and execute it. No commitment yet to rules vs. one model call vs. an agent — that's the next skill.

**Output contract.** A structured resolution: `{decision: refund | partial_refund | deny | escalate, amount, reason_code, customer_message}`. Invariants: `amount ≤ original_charge`; `deny` and `escalate` issue no money; `customer_message` cites the specific charge.

**Hard constraints.** p95 under ~30s; cost per ticket below the human-handling cost it replaces. **Stakes:** issuing a refund is **irreversible** — so any refund above a threshold is gated (the contract carries an `escalate` path on purpose), and that tag tells the later build it needs idempotency and a human gate, not free-running retries.

**Success check (one line).** *On 200 held-out tickets already resolved by senior human agents, the system's decision matches the human decision, and the refund amount is within tolerance, on ≥ 90% — with zero over-refunds and zero unhandled tickets.* That is the eval; build it before the agent.

**Tree of checkable sub-goals**, each bar *derived from that 90%*, not chosen at its own seam:

- **Classify** the dispute type → matches the human label on ≥ 96.6% of held-out tickets.
- **Retrieve** the relevant charge + account history → the right charge is in the retrieved set on ≥ 96.6% (a retrieval check, distinct from the decision check).
- **Decide** the resolution given dispute + evidence → matches the human decision on ≥ 96.6%.
- **Execute** the action idempotently → a refund is issued exactly once and never above the original charge (the irreversible-action check).

**Composition:** `0.966³ ≈ 0.90` — and a floor, not an estimate, because the stages aren't fully independent and a misclassification can still land the right decision. Execute contributes no rate: it's an invariant that either holds or fails the run.

Now "works" is defined at every seam, the riskiest sub-goal (Decide) is the one to validate first, and the build can pick the *simplest mechanism each sub-goal's check allows* and climb only where a check forces it — without ever having shrunk the original ambition. The mechanism choice is **REQUIRED:** use compound-v:simplest-thing-that-works; making each chosen mechanism hold every time is **REQUIRED:** use compound-v:make-it-stable.

## Red flags

| Symptom | The actual problem |
| --- | --- |
| The plan opens with a tool, model, or agent | You picked a mechanism before defining "works." Frame the success check first, then choose. |
| "Works" is a vibe ("handle it well"), not a runnable line | There's no tripwire; a silent failure ships looking healthy. Write a pass/fail or measurable check. |
| You shrank the goal to something easy to measure | Criteria drift — you'll optimize a proxy that diverges from what the user wants. Frame the full ambition; the check tracks it. |
| Building an AI feature with the eval "for later" | The success check *is* the eval and sets the ceiling. Define it before building; construct the judge in compound-v:evals. |
| A heavy goal framed as one giant undefined blob | A complex system designed complex never works. Decompose into sub-goals, each with its own check (Gall's Law). |
| The frame only covers the happy-path inputs | The tail is where it breaks and where "works" matters most. Frame the messy input distribution. |
| Irreversible actions (charge/send/delete) left untagged | Stakes decide how much stability the build needs. Tag reversible vs. irreversible in the constraints now. |
