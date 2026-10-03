---
name: brainstorming
description: Turns a vague feature/component/behavior idea into an approved, written design before any code is written. Use when scoping or starting any non-trivial build — "let's add X", "build a Y", "I want it to do Z", a feature request, or a behavior change — even when the user jumps straight to implementation.
---

# Brainstorming

Pin down what you're building and why, and get it approved, before you touch code. The expensive mistakes are decided here, not in the editor.

## When to use

- A feature, component, subsystem, or behavior change where more than one reasonable design exists.
- The request is bigger than one obvious function — there are choices to make about shape, data flow, or boundaries.
- You caught yourself about to scaffold a project from a one-line ask.

**Skip it when** the change is trivial or small per the `using-compound-v` tier table — a typo, a rename, a config flip, or one function with a clear spec. Forcing a design phase onto a one-liner is exactly the overkill this kit refuses. For those, just make the change and verify. When unsure which tier, route down, but if you find yourself inventing the design as you code, stop and come back here.

## The gate

For a Standard-or-larger build, do not write code, scaffold, or invoke an implementation skill until you have presented a design and the user has approved it.

The reason is leverage: a wrong assumption caught in conversation costs a sentence; the same assumption caught after implementation costs the whole branch. "This is too simple to need a design" is the trap — the simple-looking builds are where unexamined assumptions do the most damage, because nobody slowed down. A design can be three sentences for a modest Standard build; it still gets presented and approved.

The gate's strongest form is a **capability lock**, not a politeness rule. When you're running autonomously (no human turn between you and the editor), stay in read/search/plan tools only — Read, Grep, Glob, the design write-up — until the design is approved. Treat "design approved" as the event that unlocks Edit/Write/Bash-that-mutates, the way exiting plan mode does. A soft "please ask first" you can rationalize past at 2am; a tool you don't reach for, you can't.

## The flow

1. **Read the context first.** Look at the existing code, docs, and recent commits before asking anything. Half your questions answer themselves, and your proposals will fit what's already there instead of fighting it.

2. **Check scope before you refine.** If the request is actually several independent subsystems ("a platform with chat, billing, file storage, and analytics"), say so now — don't burn questions refining a thing that needs to be split. Decompose it into sub-projects, name how they relate and what order they build in, then brainstorm the first one through this flow. Each sub-project gets its own design → plan → build cycle. **Record that sequence — and which sub-projects have landed — on the PRD's core-functions spine** (`compound-v:writing-prd`), updated as each lands; don't open a roadmap or backlog file for it. It is the one piece of state a Large build needs that outlives every individual plan, and a spine that already caps itself at "the handful" is what keeps it from silently becoming a wish-list.

3. **Ask one question at a time — interview, don't take dictation.** One question per message, asked with the question tool when you have one so the user picks from concrete options; a canned checklist you read down is the weak version. You are usually better at extracting requirements from the user than the user is at specifying them, so drive the interview toward the three things that actually determine the design: the purpose (what does success look like?), the constraints (what can't change?), and the boundaries (what's explicitly out of scope?). Batched questions get shallow answers and let contradictions slip through. **Type every answer** as a goal (what must be true), a method (how the user imagined getting there), or a constraint (a hard boundary) — a method the user floated in passing gets promoted to a goal remarkably easily, and the design then optimizes for the wrong thing. **Record hard constraints verbatim**, in the user's words: paraphrase is where "never do X" degrades into "prefer not to do X" by the time an implementer reads it three artifacts downstream. **Then ask once whether a hard constraint is actually firm.** When a constraint you were handed is the only thing ruling out the approach you'd otherwise recommend, don't pick between the two silent failures — narrowing to what fits without saying what was dropped, or reporting the ask isn't feasible. Say what the stated constraints get you, then name the one constraint whose removal changes the recommendation and what it buys. Constraints you inherited are often someone else's to lift, and they can't lift one you never named. Ask only when the lift genuinely changes the answer, ask once, and if they confirm it's firm, design inside it and don't reopen it.

4. **Propose 2-3 approaches with a recommendation.** Never present one option as if it were the only one — that hides the tradeoff you're silently making. Lead with the one you'd pick and say why, then give the real alternatives and what each costs. The user's pick (or pushback) is signal you can't get any other way. Before you recommend, red-team your own pick with **compound-v:critical-thinking**: steelman the alternative you're *not* choosing (the real version, not a strawman) and name what would make your choice wrong. A recommendation that only wins against weak alternatives is your first instinct wearing a comparison.

5. **Present the design in sections, approved as you go.** Scale each section to its weight — a sentence for the obvious parts, a paragraph for the nuanced ones. Cover the architecture, the components and their boundaries, the data flow, error handling, and how it gets tested. Confirm each section before the next so a wrong turn gets caught at the turn, not at the end. **A question asked twice is a signal about the design, not a failure of your explanation.** When the user circles back to the same part without adding new information, the reflex — say it again, with more detail — is the wrong one; more detail on the answer they already heard never reaches the thing sitting under it. Stop answering and go find the concern: ask what is behind the question ("what are you worried about here?", then "what would have to be true for this to be fine?"). It is usually one they haven't articulated to themselves, so waiting for them to name it doesn't work — and what surfaces is usually a constraint nobody wrote down, so type it per step 3 and expect the design to move, not just the write-up.

6. **Write the design down, self-review it, and have a stranger check it only when no person
   will.** Save the approved design to `docs/specs/YYYY-MM-DD-<topic>.md` (the user's location preference wins), and give it one piece of fixed structure: a **numbered list of the requirements** this design must deliver — `R1`, `R2`, … so the plan's tasks can cite them — one line each, carrying the hard constraints in the user's own words. Write each as **one observable behavior** — something a tester who never saw the code could check — and keep the *how* (libraries, class names, steps) in the design sections and the plan, where it can change without the requirement changing — except a hard constraint that names a how ("use the existing Stripe client"), which stays in the list in the user's words. Where a requirement has an edge or error case you would be upset to see broken, add one `WHEN … THEN …` line naming it: the case a spec implies but never names is the one implementers most often ship broken. `compound-v:writing-plans` maps *each requirement in the spec* to the task that implements it and to the Verification Plan line that proves it — prose is not enumerable, so against a spec whose requirements live only inside paragraphs that check quietly degrades into a re-read. Then read it back with fresh eyes for the four things below and fix them inline. The written spec is the input to `compound-v:writing-plans` next — its quality caps the quality of everything downstream.

   **The stranger check is gated on who reads it, not on tier.** When the person approved the
   design section by section, they are the check. When nobody will read the written design before
   it is built — an unattended run, a design you approve on the user's behalf — hand it to
   **compound-v:recheck** in artifact mode and ask for two things only: gaps (a requirement with no
   design decision behind it) and contradictions (two sections that cannot both be true). It sees
   the design and the ask, never this conversation. The trap: a reviewer asked "is this the right
   design?" manufactures alternatives, and the person, not the reviewer, owns the key engineering
   decisions.

A committed spec file is the default for anything you'll build over more than a sitting; for a small in-session feature, an approved design in the conversation is enough. Don't manufacture ceremony the task doesn't need.

## Design self-review

After writing the spec, check it for the failures that quietly become bugs later:

- **Placeholders** — any "TBD", "TODO", or vague requirement. Resolve it now; a gap here is a guess downstream.
- **Internal contradiction** — does the architecture actually match the feature descriptions? Do two sections disagree?
- **Scope** — is this one coherent implementation, or did it quietly grow into something that needs splitting?
- **Ambiguity** — could a requirement be read two ways? Pick one and write it explicitly. An agent reading it later will pick the other one.

Fix inline and move on — no re-review loop. But if a fix changed anything material — you resolved a placeholder by *deciding* something, narrowed an ambiguous requirement, or split the scope — surface that change back to the user before handing off. They approved the design section by section; a silent edit during self-review means they're now approving something they never saw.

## Principles that shape good questions

- **Notice, don't ideate.** The best feature ideas come from naming a real friction the user already hit, not from brainstorming what *could* be cool. Anchor every question on the actual problem in front of you; a feature nobody felt the lack of is the bullshit, however clever. The higher-value move is to *attack* rather than generate — pull the evidence a human hasn't had time to synthesize (support tickets, past PRs, usage data, the code itself) and use it to challenge their roadmap. They bring the point of view; you bring the disconfirming evidence.
- **Would you want to use v1?** The bar for the first version isn't "complete," it's "good enough that you'd reach for it yourself." If the honest answer is no, you're either solving the wrong problem or padding it with things that should be cut — find the smaller thing you *would* use.
- **Cut to the named purpose, design for boundaries.** YAGNI and clean unit boundaries are how the design earns its keep — see **compound-v:startup-taste** for what to cut and **compound-v:writing-plans** for the file-level decomposition that locks it in. Of all the plausible things you could build here, nearly all are distractions, and knowing that does not immunize you — so run the cut section by section as you present the design, instead of declaring the design lean once at the start and coasting.
- **Be flexible.** If an answer reveals you misunderstood, go back. The flow is a spine, not a script.

## Next step

The only thing you do after an approved design is invoke `compound-v:writing-plans` to turn it into an implementation plan. Not a frontend skill, not a scaffolder — the plan comes next.
