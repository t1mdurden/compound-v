---
name: writing-plans
description: Turns an approved design or spec into an implementation plan of exact files, the decisions a builder can't make alone, and runnable checks. Use when you have requirements for a multi-step task and are about to start building, or when an agent will execute the work.
---

# Writing Plans

A plan is where most of the quality is decided, and it exists because a decision is cheapest to change before code depends on it, not because it is shorter than its diff. **A plan is the set of decisions the implementer cannot make alone, plus the facts research found that they cannot find with one grep.** It is not the program written in markdown: a plan longer than the code it describes has written the code instead, and a line that decides nothing is the opposite failure. Get the research and those decisions right and the implementation almost writes itself.

## When to use

- You have an approved design (from `compound-v:brainstorming`) or a clear spec, and the work is more than one obvious edit.
- An implementer — a subagent or a fresh session — will execute the plan without your current context.
- Producing the product's stable PRD instead? That's its own skill — **compound-v:writing-prd**.

**Skip the plan doc** for trivial and small changes per the `using-compound-v` tier table — make the change and verify. The plan earns its cost on Standard-or-larger work.

**Cap the plan at 200 lines, and keep it cheap to throw away.** Past roughly 200 lines nobody re-reads it, and an unread plan controls nothing. If the work doesn't fit, split the work — don't write a longer document. A second cap sizes each task for its *executor*: a task spanning nine or ten files spends a fresh implementer's window reading before it writes, and batching groups tasks but never splits one — so split it here. Keep the approval light for the same reason: **if being wrong at task 4 would be socially or procedurally expensive, the plan is too heavy.** If a plan reads "this will take weeks", re-scope into shippable slices.

## Research before plan, plan before code

The leverage runs uphill: a bad line of code is one bad line, a bad plan decision is hundreds, a bad piece of *research* — misunderstanding where data flows or where the change belongs — is thousands. So **Research → Plan → Implement**, spending most at the top.

**Research first.** Read the code the change touches; don't assume. **While planning, the only file you write is the plan** — a planner that "just fixes" something it read leaves the plan describing a codebase that no longer exists. Name real files and line ranges so the implementer doesn't re-discover the codebase, and the existing functions and helpers the change should reuse, with their paths. A change that repeats one pattern across many files gets the pattern once and a few representative paths, not every file and line.

**Search the pattern first when it's unfamiliar.** For a non-trivial, unfamiliar, or security-sensitive pattern, or a library/API choice, use `compound-v:searching-patterns` to pull the canonical pattern *and* its anti-pattern, and put both in the plan. Skip it for code you know cold.

## Order tasks by risk, not by comfort

Sequence the work so the riskiest assumption gets tested first, with the cheapest task that resolves it. (Identifying *which* assumption is load-bearing is **compound-v:startup-taste**'s job; this is where it becomes task order.)

**The cheapest resolution is often not a task at all.** A step that reads as one thing — one onboarding call, one endpoint, one config path — routinely forks into per-partner or per-tenant branches. Existence is not arity: while researching, grep the call sites and sibling implementations of every symbol the change touches, so the plan either covers all N branches or builds one and puts the rest on `Deferred:` — priced before approval, not discovered after.

The risk clusters at the edges: setup (environment, dependencies, scaffolding) and the finish (deploy, env vars, prod config) are where builds fail. Add those tasks early.

**When a feature crosses layers, cut its tasks as slices, not layers.** Left alone, a model plans in stack order — migrations, services, API, UI — so nothing can be driven until the last task. End each feature task in something you can hit from outside, faking what sits below until a later task makes it real. Setup and deploy tasks are exempt. Check the finished list: a feature task nobody can drive from outside is a layer.

## Write for a capable implementer who wasn't in the room

The implementer writes idiomatic code in this language once they know the exact interface and the exact test, and makes a reasonable choice wherever the plan leaves one open. What they cannot know is **what you decided and what you found**: which files, which names and signatures, which values the spec pins, which constraint binds, which trap research turned up, which test proves each task. Document those, and only those. They may read tasks out of order, so each task stands alone.

High-level does not mean thin: the tricky cases and the consequential choices stay in the plan. **The two-sided test, per step:** could a capable engineer new to this repo do it without coming back to ask? If they'd have to ask, a decision is missing — add it. If they'd have to read past code they could have written themselves, it's a transcript — cut it.

### File structure first

Before defining tasks, map which files get created or modified and what each is responsible for — this is where the decomposition is locked in. One clear responsibility per file; files that change together live together (split by responsibility, not layer). In an existing codebase, follow its patterns rather than imposing new ones.

### What a step contains

Each task produces a self-contained, testable change, in the test-first rhythm — failing test, see it fail, implement, see it pass, commit (`compound-v:test-driven-development`). That per-task commit is the rhythm, not a verdict: **compound-v:batched-implementation** marks the batch's *final* commit as the verified one. **A step is done when the implementer can carry it out without guessing what you decided** — unambiguous about your decisions, not complete:

- **A test step:** the test's name and its assertions, as code, with the spec's exact values in them.
- **A code step:** the file, the exact signature (name, parameters, return type), and the decisions and values that signature and test don't already determine — a trap from research, a constraint, the exemplar to imitate (`path:line`). The implementer writes the body. A body appears only for an algorithm the signature and tests don't determine, for exact copy the spec fixes, or for an edit you have already settled to the line — there, give the line, because prose describing code is the lossy copy of it — and **code that does appear is source, not illustration**: the implementer transcribes it faithfully, so a plan can be 100% conformant and still ship two blocking bugs that were in the plan. Snippets carry the shipped-code bar.
- **A verification step:** the command and the output that means it passed.
- **A reference to another task:** through that task's **Interfaces** block — never "similar to Task N", and never its code repeated.

**Detail follows fragility, not length.** Where there is one safe way through — a migration order, a signing algorithm, a wire format another service parses — pin it exactly: that is a decision, and a guess there is expensive. Where several approaches are valid, give the goal, the constraint and the test, and let the implementer choose. A plan that is uniformly detailed spent its words on the open field and has none left for the cliff edge.

```markdown
### Task N: <component>

**Files:**
- [NEW]    `src/exact/path.py`
- [MODIFY] `src/exact/existing.py:123-145`
- [DELETE] `src/exact/dead.py`
- [TEST]   `tests/exact/path_test.py`

**Fulfills:** R3, R4 (the spec's numbered requirements)

**Interfaces:** consumes `issue_token(user: str, ttl_s: int) -> str` (Task 2) ·
produces `verify(token: str) -> bool`, which Task 5 calls.

- [ ] Write the failing test:
      ```python
      def test_rejects_expired_token():
          assert verify(issue_token("u1", ttl_s=-1)) is False
      ```
- [ ] Run `pytest tests/exact/path_test.py -v` → expect FAIL ("verify not defined")
- [ ] Implement `verify(token: str) -> bool` in `src/exact/path.py`: expiry compares against
      `clock.now()` (`src/auth/clock.py:12`), never `datetime.now()` — tests freeze that clock.
- [ ] Run `pytest tests/exact/path_test.py -v` → expect PASS
- [ ] Commit: `git rm -q src/exact/dead.py && git add src/exact/path.py src/exact/existing.py tests/exact/path_test.py && git commit -m "feat: reject expired tokens"` (explicit paths — `-a`/`-A` sweeps in whatever else the tree holds)
```

### The preamble

Start the plan with what every task inherits — a fresh batch implementer sees only its own tasks plus this, and silently regresses anything unstated to model defaults:

- **Goal** — one line — and a plan-level **`Done = <machine-checkable signal>`**: the command or eval that says the whole plan is finished.
- **Approach** — two or three sentences, key libraries, and one approach: the alternatives were brainstorming's job, and an option left open in a plan is a guess the implementer makes. Lead with the decisions a reviewer is most likely to change — data model, public interfaces, anything user-facing. Label it what it is: **non-binding tactics**. What binds the implementer is `Done`, the constraints, the Interfaces other tasks consume, `Deferred:`, and anything under `## User Review Required`; how a task gets there may change once the code is open.
- **Constraints** — the **global constraints every task must honor**: version floors, dependency limits, naming/style, security/perf rules, platform requirements — one line each, carrying the failure it prevents ("timestamps stored in UTC — local time shifts an hour at the DST change"): a rule with its reason gets applied to the case you didn't list, a bare rule gets pattern-matched. **Plus which one wins for any two that can pull against each other**: an unranked pair (a latency budget against a retry policy) gets resolved by each batch whichever way its own tasks make cheapest, green either way.
- **`Deferred:`** — the literal label starting its own line, inside the preamble (not its own heading): what this plan deliberately does *not* build and the settled decisions an implementer must not reopen. `compound-v:recheck` greps it to prove the deferred thing was not built — the kit's one executable anti-overkill check. **"Deferred: none" is a first-class answer**; inventing plausible non-goals only sends the reviewer hunting features nobody proposed.
- **Research fold-in** — the real files, line ranges, data-flow facts, and the canonical/anti-pattern you found. This is the part of a plan that is most often worth its length: what you learned and don't write here, the implementer re-discovers or guesses.
- **Divergence rule** — if a load-bearing assumption proves false mid-build, so that a binding part can't hold, the implementer stops and reports rather than improvising in code; a tactic that doesn't survive contact with the code is changed, named in the batch report, and logged as a dated line in the plan's `## Clarifications` before recheck runs — recheck judges the diff against the plan it is handed, and an unlogged tactic change reads as divergence. After ~3 failed attempts at the same thing, surface it instead of grinding.
- **User-Review flag** — anything destructive or irreversible (a migration or backfill, a deleted public API, a prod-config change) is called out so the human signs off before it runs autonomously: a `## User Review Required` block as the plan's second section.

A line that decides nothing is still a plan failure — "TBD", "implement later", "add appropriate error handling / validation / edge cases" (name them), "write tests for the above" with no test, a type or function no task defines. Each is a decision pushed onto someone with less context, and it comes back as a guess in the code.

## Verification Plan

**Every plan ends with this section; it is not optional.** Done-criteria are commands with their expected results, never prose — that is what lets a reviewer rule a finding blocking against a criterion stated in advance, rather than on opinion.

- **Automated** — the exact commands a fresh session runs, each with the result that counts as pass: `pytest -q` green, `npm run build` exit 0, `curl -s localhost:8000/health` returns 200. This is `Done =`, made executable.
- **Implied cases** — up to five inputs or failure modes the spec implies but never names that are most likely to bite a person using this, each with the behavior a reasonable person expects and the test in its owning task that pins it. The spec is a statement of intent, not an inventory of everything the software will meet, and its silence on an input is not permission for that input to break the program. None worth naming is a legitimate answer — say so.
- **The subject decides the judge.** Where the subject is *model-generated output*, it is an eval, not a test — route to **compound-v:evals**. Where it is a *user-facing surface*, add a **compound-v:product-taste** pass. Neither applies to a deterministic change with no model output and no UI.
- **Manual** — only what a machine can't assert: the thing to click, the screen to eyeball. If a step can be automated, move it up.

The tests are the done-signal, so the plan must **forbid editing a test to make it pass** — when a test fails, the suspect is the code under test. Pair each criterion with the negative constraint that rules out the cheat: *tests pass* **and** no assertion weakened, no expected output hardcoded — an agent rewarded only for green will hardcode the green. Pin that check to a fixed base (`git diff <base-sha> -- tests/`): after the per-task commits, a diff against the working tree prints nothing whatever happened.

## Self-review the plan

After the plan is complete, read it against the spec with fresh eyes — your own pass, not a subagent (one autonomy-gated exception below).

- **Resolve every reference — run this, don't read it.** `ls` each path (and confirm `[NEW]` paths don't exist yet), grep each symbol, check the manifest, and run each Verification Plan command in its cheapest form (`--help`, `--collect-only`). This is the only plan-time check that isn't an opinion — no reviewer catches a plan built on a misremembered repo by reading it. Spend here first.
- **Spec coverage** — every numbered requirement is claimed by a task's `Fulfills:` line **and** by a Verification Plan line that proves it as a user would observe it; grep the numbers rather than re-reading prose. A requirement mapped only to a task is one nothing asserts, and a requirement no task claims is one nobody builds.
- **Step scan, both ways** — a line that decides nothing is a gap; a body the signature and test already determine is a transcript. **Proportion:** a plan several times longer than the spec it implements, or one whose code blocks are most of the document, has written the program — replace bodies with signatures, decisions and test assertions, then check each step is still unambiguous.
- **Re-scope staleness** — if the scope moved while you planned, re-read earlier sections against the *final* scope and name every task now obsolete or needing rework. Whenever an answer or round of feedback *changes* the plan, append `Q: <what was open> → A: <what was decided>`, dated, to a `## Clarifications` section placed after the last task and before the Verification Plan; if the answer binds the implementer, write it into the preamble too — `compound-v:batched-implementation` briefs from the preamble and task text only. A plan nobody revised has no Clarifications section, and that is correct.
- **Task justification** — for each task, and each new file, abstraction, config surface and interface, name the requirement it serves. Anything serving none is the cut. Ask once: re-asking an unchanged plan to "find more over-engineering" manufactures findings.
- **Structure check** — by grep, not memory: `grep -nE '^## Verification Plan|^[[:space:]]*[-*]?[[:space:]]*\**Deferred:|Done =' <plan>` must hit all three, `grep -nE '(TBD|TODO|implement later|fill in|Similar to Task)' <plan>` must hit nothing, and `^## User Review Required` must hit if and only if the plan introduces something destructive or irreversible. Then *read* for the global constraints and the divergence rule, which have no fixed string. You wrote the file, so you are the reader least likely to notice a section that never got written.
- **Type consistency** — `clearLayers()` in Task 3 and `clearFullLayers()` in Task 7 is a bug waiting to happen; the Interfaces blocks are where it shows.

Fix inline and move on.

### One fresh pass — only when the plan will run unattended

Add a single read-only reviewer in a fresh context (`compound-v:recheck`'s discipline; the `code-reviewer` agent in artifact mode) when **nobody will read a diff between this plan and the merge** — an overnight run, a scheduled build, a handoff to a session you won't be in. **Gate this on autonomy, not on tier:** with a human watching batch 1 land, a wrong plan costs one batch; with nobody watching, it costs the whole run. Hand it the plan and the spec, never the conversation; its structural advantage is **deferral integrity** — every deferred entry absent from the tasks. It returns findings; you decide scope. A subagent cannot dispatch it — skip it and say so. "No findings" is an expected outcome; if its findings are ones batch 1's recheck would have caught anyway, delete this layer.

Then save the plan to `docs/plans/YYYY-MM-DD-<feature>.md` (the user's location preference wins), **commit it before the first batch runs**, and hand off to `compound-v:batched-implementation`. The commit makes the plan a baseline: recheck greps the deferred list and rules findings against the Verification Plan, and both report clean against a plan quietly edited to drop an entry or soften a criterion. Revising the plan mid-run is expected; weakening a done-criterion so a failing batch passes is not — surface that one to the user.

A plan at a path survives compaction, can be diffed, and can be handed to a different model. Before splitting the planner from the executor, read `references/shapes.md`'s *Split the decider from the executor* row: the handoff drops every decision the plan never stated.
