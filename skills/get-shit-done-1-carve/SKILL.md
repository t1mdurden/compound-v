---
name: get-shit-done-1-carve
description: 'Stage 1 of compound-v:get-shit-done — carve the ask into slices and rows in slices.json. Invoked by get-shit-done.'
---

# Get Shit Done — 1 · Carve

Stage 1 of **compound-v:get-shit-done**, which holds the ledger this stage writes against and the red flags every stage routes back to — if its body is not in your context (a new session, or after compaction), invoke it first. When the slices and their rows are in `slices.json`, invoke **compound-v:get-shit-done-2-recon**.

## Stage 1 — Carve

**If nobody has yet asked whether this should exist, that gate runs before the carve** — **compound-v:startup-taste**. Carving is a commitment to build.

Quote the **original ask verbatim** into the ledger's `ask` field first — not your summary, and not the plan or spec, both of which get written mid-run and absorb the drift.

Stage 1's output is `slices.json`, and it exists before any code. Per slice, four things and no more:

- **Capability** — the user's sentence.
- **Check** — what run command, or what one named human, says this slice works. Vague here is fatal; hand it to **compound-v:frame-the-goal**. **One row carries it, marked `is_check: true`** — a slice that never turns its check into a row can pass everything it has and still miss the thing it was for.
  **Write the check from what would show the goal UNMET, because that is what differs between kinds of goal.** A *behaviour* goal's ground truth is a run. A *replication* goal's — *"like X"*, *"port this"*, *"match the design"* — is the source, so the check is a comparison, and a row that never touches the reference measures the wrong thing however green it goes. A *property* goal's is an adversarial probe, never the happy path. A *removal* goal's is absence plus nothing-else-broke. A *migration* goal's is old and new agreeing. A check aimed at the wrong truth passes while the goal fails.
- **Unknown** — the one line naming what might not work.
- **Confidence** — Steinhardt's buckets, coarse on purpose: *no unforeseen difficulties* (~95%), *"modulo Murphy's law"* (~90%), *the basic path is visible and every step should work* (~65%), *"only … a murky view of the path"* (~30%).

**Then fill each slice with its rows** — every function the goal declares, each a witness case with a concrete input and an observable outcome, all starting failing. A function that is not a row here is one no later check will ever look for. **Nothing else will write this file for you, and the gate is silent without it**: skipping stage 1 does not get you a lenient pipeline, it gets you no pipeline.

**Order by what fails fastest, not by what is easiest.** Easiest-first wastes the easy work when the hard part turns out infeasible — *"The work on the easy parts was mostly wasted."* Sort by information per unit time: a quick slice you have never done outranks a long one you have done many times. **De-risk all components, then execute.**

**Slice 1 is the burning function, end to end, with the hard parts faked.** Wire the whole path with a cheating version of the hard component: if it works, a real implementation will too; if it doesn't, you saved building it. Its pair is a baseline, the dumb off-the-shelf version — *"complicated methods often underperform simple baselines"* — and a baseline that clears the check deletes the slice outright.

**Then say what the ask named that is not a slice, and who asked for it** — as `notSlices`, one entry per item with `item`, `askedBy` and `why`. Anything with no answer is drift-in before a line is written. This is where a sprawling brief gets honest: *an AI that runs the whole agency* is not a project, it is four named parts, one of which is a job that reads a date and sends a message.

**Next:** invoke **compound-v:get-shit-done-2-recon**.
