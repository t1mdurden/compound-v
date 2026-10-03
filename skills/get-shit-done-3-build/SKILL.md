---
name: get-shit-done-3-build
description: 'Stage 3 of compound-v:get-shit-done — build one slice at a time and close it on a walk as a user. Invoked by get-shit-done.'
---

# Get Shit Done — 3 · Build

Stage 3 of **compound-v:get-shit-done**, which holds the ledger this stage writes against and the red flags every stage routes back to — if its body is not in your context (a new session, or after compaction), invoke it first. Needs this slice's `shape` in `slices.json` — without it, invoke stage 2 for the slice. When the slice has landed, invoke this skill again for the next; when every slice has landed, invoke **compound-v:get-shit-done-4-reckon**.

## Stage 3 — Build one slice at a time

The failure this shape prevents is measured. A frontier model in a loop from a high-level prompt *"tended to try to do too much at once"*, and later *"a later agent instance would look around, see that progress had been made, and declare the job done."* The fix is theirs: **one feature at a time**, *"This incremental approach turned out to be critical"*.

Build it however you build things; **compound-v:writing-plans**, **compound-v:batched-implementation** and **compound-v:recheck** own that. The spine owns what a *closed* slice looks like:

- **You ran what already exists first.** The thing starts, one primary action works, the previous slice still holds. If the agent starts implementing instead, *"it would likely make the problem worse."*
- **The hit band was declared before the build, not after.** What fraction of real inputs this slice handles, and what the misses see. *"It breaks"* is not an answer; *"it says X and routes to a human"* is. Build to the middle and **give the tail a named exit**. The exception is the axis **compound-v:make-it-stable** draws: irreversible writes, money movement, data loss, silent corruption or a stranger-facing surface get the production bar on the bad path too.
- **Every row you are closing was walked as a user, on the assembled product.** A slice walk closes only the rows it demonstrably exercised.
- **You scanned the slice's diff for what you left behind** — `TODO`, `FIXME`, `stub`, `placeholder`, `mock`, `hardcoded`, `for now`, a skipped or `.only` test, a swallowed error. Each hit is a row or a named waiver. A missing declared function is a `todo` row; a stub the implementer *left* was declared by nobody, and that is the hole the denominator cannot see.
- **What you gave up under pressure was elements, not quality.** Shipping all of it worse is how those stubs get written. Delete instead: drop each element whose removal still leaves the slice useful, down to the `is_check` row and not through it. Every cut is a `dropped` row, `moved` where it returns.
- **Nothing that grades the work moved.** Never edit a check to make it pass — *"It is unacceptable to remove or edit tests because this could lead to missing or buggy functionality"*. A threshold quietly widened at hour six is indistinguishable from success.
- **It still answers the ask, and nothing rode in that nobody asked for.** Put the slice beside the
  `ask` field verbatim — not the plan, which absorbed the drift — and answer both directions: what
  the goal asked for that this does not do, and what exists here that no row declared. A slice can
  pass every row it declared and have declared the wrong ones. **compound-v:recheck** runs this per
  batch as its first two gates; this pass is over the assembled slice, where no batch reviewer stood.
- **The landing went through the pre-merge gate, not just the batch gate.** `recheck` closes a
  *batch*, **compound-v:code-review** closes the *branch*, and both run. A slice merged on batch
  verdicts alone has never had its assembled diff read.
- **One slice, one commit, and the commit moves the ledger.**

**The walk is the one rigid condition, because it is the documented failure.** Claude would make the change, run unit tests, curl the dev server — and still not notice that *"the feature didn’t work end-to-end"*. Lint and type-check are the verification that was already automated; the question is **can the agent run the thing**, and it is the first thing dropped when nobody is watching.

**When the walk fails, it is a root-cause question, not a retry** (**compound-v:systematic-debugging**). On the third failed close, say which is true: the slice splits, the check was wrong, or stage 1's unknown was real. Where the answer is *the shape is wrong*, run the call below **before** you mark anything — `blocked` is what you mark when the replacement failed too, not instead of trying it.

### Repair or replace — decide it by running it, never by estimating it

The third patch onto the same shape is a decision being made by default. Make it deliberately and on
evidence: **build the replacement in a throwaway worktree and run the existing check against both** —
*"if one experiment fails, I throw away that worktree and nothing is lost in main."* The
under-selection is measured, so this is a run, never an argument. **references/repair-or-replace.md**
carries the three conditions that separate it from licence — the check must pre-date the replacement,
name which cost you are paying, and the rows move with it — plus what each one is guarding against.
Read it before you mark anything `blocked`.

**Dispatch the check, not the build.** The measured payoff for a fresh context is in *judging* work, not producing it — a clean-context reviewer finds around two real bugs per pull request on code the same system wrote, most severe, precisely because it shares no context with the author. Every measured result on dispatching the *build* runs the other way, and **the skimping is the ledger's job, not dispatch's**: an agent identified **20 call sites**, changed **5**, and stopped, and what fixed it was an in-context checklist. **Do not dispatch because there are many tasks.**

**But DO fan out for coverage, and take the cap off when you do.** The rule above is about
throughput — splitting a build to go faster, which measures worse. Completeness is the opposite
case, it is embarrassingly parallel, and it is worth spending freely on: sweep the ask for functions
no row declared, verify closed rows independently of the worker that closed them, check every call
site rather than the five that were easy, read the source nobody opened.
**compound-v:dispatching-parallel-agents** owns the mechanics — cut the seam at a stable interface,
not an arbitrary file boundary, or "disjoint" files still couple through a shifting API. Nothing here
is capped: if ten agents are what it takes to prove the denominator complete, run ten.

**The condition that separates this from theatre: every lane must be verifiable without reading its
trace** — which coverage work has and build work does not. Past that line you have not parallelised
the work, you have turned one review queue into N. **references/fan-out.md** carries the evidence,
the three stacked boundaries and why the binding one is the supervisor's head rather than the file
graph.

**The hard rule that makes that safe: agents launched and tokens burned are evidence of nothing.**
Not effort, not progress, not thoroughness. The only currency is closed rows and a working thing, so
never report a fan-out as an accomplishment and never widen one to look rigorous. A run that
dispatched thirty agents and closed no rows did nothing, expensively. A large fan-out *feels* like
diligence and reads like it in a summary — which is why the ledger grades the run and the agent
count grades nothing.

**The check is dispatchable; the build is not — and the condition that decides it is this: dispatch a slice only where you can re-run its check yourself, without the worker's trace** — otherwise the split bought context isolation at the price of an unauditable ledger. **The worker returns evidence; the orchestrator flips the row.** Workers never write `slices.json` — the single-writer rule **compound-v:handoff** applies to `STATE.md`, plus one this ledger adds: a worker that can flip its own row is a worker grading its own homework. Its brief carries the slice's rows, check, shape and trap: dispatch makes the ledger the only path from one slice's lesson to the next slice's worker, so a run whose `shape` and `trap` sit empty has no carrier at all.

**Next:** invoke this skill again for the next slice. When every slice has landed, invoke **compound-v:get-shit-done-4-reckon**.
