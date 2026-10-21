---
name: get-shit-done
description: Take a whole project from a stated goal to a real, working thing someone outside the build has used, and hold it to the MEP bar at the end. Use when the ask is a project rather than one feature — "build me X", "make this real", a wish-list, a founder brief, a PRD, an idea that sounds too hard to finish, an overnight or multi-session run — and again when someone asks "is this actually done", "is it real", "did we drift from what I asked for", or "will the next change force a rewrite". Not for a single feature (compound-v:brainstorming) or a one-liner.
---

# Get Shit Done

Most projects that look impossible are a handful of parts, two of which are genuinely unknown. Find those two, learn how they are already solved, and most of what is left is typing — Thorsten Ball's code-editing agent was ~300 lines and three tools, the rest *"Elbow grease."* Overestimating is the default failure: asked for a hard thing, a model reaches for architecture instead of the two facts that would collapse it. But **buildability is rarely the constraint; effectiveness past the demo is** — *"creating products and systems that are effective—beyond a demo—remains deceptively difficult."* Stages 3 and 4 are aimed there.

This skill is the **project-level spine**: four stages, each handing the actual work to a skill that already owns it, and a loop rather than a line — an incident re-enters at the top.

## When to use

- The ask is a whole product, system, or multi-part build; or a sprawling brief where nobody has said what the parts are.
- A long or unattended run is about to start from a goal rather than from a plan.
- A run is about to be called finished because the tests are green, the boxes are checked, or the branch merged. Stage 4 runs standalone for this.
- **Skip it** below Large tier (**compound-v:using-compound-v** carries the tier table) — a Standard feature is **compound-v:brainstorming** → **compound-v:writing-plans** → **compound-v:batched-implementation** → **compound-v:recheck** — and skip it when the ask names no outcome anyone outside this session consumes. An internal API, CLI, job or library is *in scope*; its user is whoever calls it. A skip is announced where the verdict would have gone.

## Two units: the slice you build, the row you count

A **slice** is one capability a user can reach end to end — the sentence they would say: *"I get a DM on day 7 when a storyboard is late."* Not a layer, not "the database". A project is 3–7 slices; more and you are listing tasks, fewer and it is a feature — route down. **Slices are the build order.**

A **row** is one function inside a slice, at the grain of a thing a person could attempt. **Rows are the denominator.** A handful of slices can carry two hundred rows, and the 10% that never lands is invisible at slice grain — nine of ten done still looks like a slice in progress.

| Stage | What the spine decides | Who does the work |
|---|---|---|
| 1 Carve | the slices, their order, their checks | **compound-v:frame-the-goal** turns a fuzzy check into a real one |
| 2 Recon | how much research each slice earns | **compound-v:searching-patterns** for the pattern + anti-pattern |
| 3 Build | one slice at a time; what closes it | **compound-v:writing-plans** → **compound-v:batched-implementation** → **compound-v:recheck** |
| 4 Reckon | the verdict, and what outlives the run | **compound-v:finishing** lands the branch first |

Cede rather than re-derive: whether to build at all is **compound-v:startup-taste**, one claim is **compound-v:verification-before-completion**, a pass rate over a probabilistic path is **compound-v:evals**, reaching anyone is **compound-v:founder-distribution**. This skill never reads a diff and never emits a severity-tagged finding list.

## The ledger: what makes 100% enforceable

A long run degrades silently unless its procedure and its state live on disk: sessions are discrete and *"compaction isn’t sufficient"* to carry a procedure across them. Anthropic ran this at over 200 rows for one app, every row failing at the outset, letting the agent change nothing but the status field.

> **The done rule — every declared row is `passed` or `dropped`-with-attribution. Nothing may remain `todo` or `building` at the verdict, and `blocked` is not success.**

That is what makes *"we're at about 90%"* unsayable. Five invariants hold it up, conditions true or false at any moment rather than steps in an order. **references/completion-ledger.md** carries the schema, the status vocabulary and the reasoning — read it when you open a ledger and again at the gate.

- **The floor** — a capability with open rows and no passing row **did not ship**, whatever the percentage says.
- **Denominator** — rows come from the brief, the plan, and whatever the build discovers. **A requirement with zero rows is scope nobody was assigned**, the largest single source of the missing 10%.
- **Flip** — green only on a check seen **red first, for the right reason** (**compound-v:test-driven-development**'s red step) plus an end-to-end run driven as a user.
- **Delta** — appending is legal, flipping is not. A drop declares its kind: `void` (nothing owed) or `moved` (a successor row is mandatory). A drop that moved and named no successor is how a capability quietly empties out.
- **Blocked is not done** — three failed attempts marks a row `blocked`, blocker named (**compound-v:systematic-debugging** owns the cap). Give the run a legal way to say *this did not work*.
**The agent may not edit what grades it.** Status flips, appended rows and stage-2 slice fields (`shape`, `trap`, `delete`, `force`) are legal writes; a row's `does`, a drop already made, and any check are frozen. A superseded `shape` is appended to rather than overwritten, carrying what falsified it.

**The ledger needs an engine, or it is only a record of where you stopped.** This kit ships one: a `Stop` hook that **refuses the exit** while any row is open or the ledger cannot be read honestly — an unreadable row counts as open, never done. `bash scripts/ledger.sh --open` prints the same number for a human.

The run holds two files, both scaffolding, both deleted when it ends: **`.claude/STATE.md`** (prose, owned by **compound-v:handoff** — its **Next** names a row id) and **`.claude/slices.json`**. JSON deliberately: the model is *"less likely to inappropriately change or overwrite JSON files compared to Markdown files"*.

**One intake round, then no question until a hard gate.** After reading the repo, before stage 1, ask every decision you can foresee in one `AskUserQuestion` call — at most four, those whose wrong default costs most, recommendation first: what is out of scope, who outside the build judges the checks, how finished work lands, any one-way door the ask implies. Decide the rest. Answers and every default, each with its reason, go under `## Decisions` in `.claude/STATE.md`: the approval carve and recon used to wait for. Later choices read or append to it. **A hard gate** — irreversible or outward-facing, money, a credential or identity check, a taste call with no defensible default, a one-way door recon did not resolve — marks its rows `blocked` naming the gate; build what does not depend on it, then send every pending gate in one message. In a worker session (its first message was another session's brief) the brief is the intake, and that message goes to the master by `SendMessage`, never the user.

## The stages — four skills, invoked in order

**Invoke them with the Skill tool, in this conversation and in this order** — never wrapped in a
subagent, where a stage loses both its route to a hard gate and its own dispatch:

1. **compound-v:get-shit-done-1-carve** — first, once **Decisions** holds the intake. The slices, their order, their checks.
2. **compound-v:get-shit-done-2-recon** — once the slices exist. A slice whose lookup misses gets
   its hunt, where its band buys one, at build time.
3. **compound-v:get-shit-done-3-build** — for each slice, in carve order.
4. **compound-v:get-shit-done-4-reckon** — once, over the assembled product. It also runs
   standalone, when the ask is whether a run is actually done.

**Route by what the ledger shows, not by memory — a `Next` pointer can run ahead of unfinished
work:** no **Decisions** → the intake round; no `slices.json` → stage 1, unless the ask is whether a run is done, which is stage 4
standalone; a slice about to be built with no `shape` → stage 2; `todo` or `building` rows → stage
3; none left — every row `passed`, `dropped` or `blocked` → stage 4.
An incident re-enters at stage 1. Advancing a stage never approves a one-way door — the gate above
binds at every boundary. After compaction or in a new session, re-invoke this skill and the stage
you are in: a skill's body is not re-read on its own, and the oldest one is dropped first.

## Red flags

Nothing here blocks on its own; every row routes back to a stage, and the clamp decides.

| Smell | What it means |
|---|---|
| Recon came back and the plan got *bigger* | You researched how to build it, not whether to. Re-run stage 2 for the DELETE list. |
| A slice with a check like "it looks right" | Not a slice yet: the verifiable criterion is what makes the speed real. **compound-v:frame-the-goal**. |
| "Basically done, just polish left" / "this laid the foundations" | Nothing a user can do today that they couldn't yesterday, counted as nearly finished. Name what's left; that list is the remaining project. |
| A ledger bit flipped without a walk, or a check edited late in the run | The two failure modes this skill is built around. Confirm the check goes red without the change, and suspect it hardest at the end of a long run. |
| The same gap N rounds running, or a different gap every round | **compound-v:systematic-debugging**'s attempt cap. The product-level addition: if every remaining gap needs something you don't hold — a real user, a credential, a live environment — no round closes any of them. Each is a hard gate: name it on its rows and send the batch. |
| "Too complex / would take days" | Not authorization to deliver less. Say it out loud, go back to stage 2, and find who already solved it. |
| A third patch onto the same shape, a shim over a design nobody defends, a rebuild declined on an unmeasured estimate | The replace-or-repair call made by default. Build the replacement in a worktree against the existing check and read the result. |
| Round after round of engineering and the metric will not move | An **invisible asymptote**: the ceiling belongs to the path, not the effort. Name a different path out loud; another round is not one. |
