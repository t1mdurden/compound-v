---
name: using-compound-v
description: Routes any task to the right Compound V skill and the right effort tier before work starts. Use at the start of every task — scoping, building, reviewing, design, or a quick fix — to decide what's worth doing and how much machinery it deserves.
---

# Using Compound V

Match effort to the task, and only build what compounds. Overkill is a defect, not a safety margin.

You don't have to remember what each skill does — match the **task** to a trigger and invoke that skill with the `Skill` tool **before acting**, even for a question, even when the user didn't name it. The descriptions fire on intent, not keywords; when a skill might apply, invoke it and let it bow out if it doesn't fit. Silently skipping a skill that applies is the failure this kit exists to prevent.

## Where this kit's own files live — resolve the path before you conclude a file is missing
Skills cite `references/<file>.md` and `scripts/<file>.sh` **relative to the kit root**, and you are
almost never standing in it. Two bases are wrong and one is right:

- **Your cwd is the user's project.** `bash scripts/check.sh` there is `No such file or directory`.
- **The skill's own base directory** — which the harness reports when it loads a skill — is
  `<kit>/skills/<name>/`, *not* the kit root. So a bare `references/…` citation misses from there too.
- **The kit root is one level up from that**: `<skill base>/../../`. Use
  `${CLAUDE_PLUGIN_ROOT}` where it is set (the hooks use it), otherwise take the base directory the
  harness just printed for the skill you are reading and go up two.

Resolve it, don't route around it. If a reference does not open on the first try that is a path
problem, not a missing file — several of these carry the operative content, not merely provenance,
and a skill that silently continues without one is running on the half it happened to have.

## Instruction priority
User CLAUDE.md > Compound V skills > default behavior. If the user's instructions contradict a skill (e.g. "don't use TDD here"), the user wins — always. This is a precedence rule, not a load order: a later-loaded instruction does not outrank an earlier one.

Claude Code ships review and cleanup skills of its own, and the exact set changes between releases — check the session's own listing rather than assuming. Where a name collides, the more specific installation wins, so reach for a bundled skill deliberately when you want something only it has: `/code-review ultra`, for instance, is a billed multi-agent cloud review the user must trigger and you cannot launch yourself.

## The master gate
**Does this grow taste, distribution, or a primitive?** None of the three → it's the bullshit; cut it.

That gate screens the *request*. Run a second one on what you produced: **strip the framing off your answer, plan, or finding and name the residue in one sentence.** If the residue is the title restated, something a two-minute search answers, or nothing — cut it. Few or zero survivors is the correct outcome; padding to hit a count is the defect, in a finding list, a plan, or a set of options.

## Both sides, always
Overkill is a defect — and so is its overcorrection. Stripping a thing past its essence leaves *emptiness instead of essence*: nothing to hold onto at 2am. Don't over-engineer before you have users; don't under-engineer after they arrive. State both halves of a trade-off rather than one, because a one-sided rule gets overfit — a model handed only the cost of escalating learns never to escalate. And expect the pull: **complexity is the cheap default.** Accreting components until they somehow fit costs less thought than composing the version that doesn't need them, so work drifts complex unless someone spends the thinking to make it simple.

## Non-negotiables
- **Honest** — evidence over claims, no praise-padding, no false "done"; surface bad news plainly. Steelman the counter-argument to your own conclusion before committing (compound-v:critical-thinking).
- **Safe** — never trade security to ship; flag vulns (incl. the lethal trifecta). No harmful code.
- **Grounded** — these skills come from real systems and practice, not vibes; if a claim isn't grounded, say so.

## Tier routing — smallest box that fits; route *down* when unsure

The kit's bet is that adaptive effort is something the model is increasingly good at on its own; this table makes that judgment explicit rather than trusting it implicitly (a JUDGMENT-CALL stance — `references/sources.md`). Use it as the explicit floor, not a replacement for judgment.

| Tier | Trigger | Workflow |
|---|---|---|
| **Trivial** | typo, rename, one-liner, config flip | Just do it → `verification-before-completion`. No plan, no agents, no skill. On a branch, `finishing` still lands it; a typo fixed in place has nothing to land, and turning every one-liner into a merge ceremony is the overkill this table prevents. |
| **Small** | one function/file, clear spec | `gathering-context` (slot 1 only — the installed versions and the repo's own shape) → plan mode for explore-and-plan → inline `test-driven-development` → verify. Skip the plan doc. **On a branch, land it through `finishing`** — the tier sizes the build, never the landing. |
| **Standard** | a feature, ~2–8 tasks | (open "should we?" → `startup-taste` first) → **`gathering-context`** → `brainstorming` → `writing-plans` → `batched-implementation` → `recheck` → `code-review` → `finishing`. |
| **Large** | multiple subsystems · a one-way door · schema or public API | `get-shit-done` runs the whole thing: it owns the **one confirmed decomposition** above the sub-projects — never a plan-of-plans — and each slice below it runs its own Standard cycle. Attended, the decomposition is approved before anything touches disk; unattended, it is written down and the run proceeds — what binds in *both* modes is the one-way door (schema, public API, spend, irreversible write), which stops the run either way. Fan out only across disjoint files, in worktrees. Its stage 4 closes over the assembled product, **once**, never per sub-project. |**The row is a guess from the prompt, and the prompt does not carry the difficulty** — "fix the
export bug" is a one-line edge case or a re-architecture, and only the code says which. So at Small
and above, **re-tier once, out loud, after the first read of the code the change touches**, on what
that read found rather than on how the ask sounded: an irreversible, or a judgment call a reviewer
could answer differently, moves the row up even when the diff is one file; otherwise the footprint
the read revealed picks it. Routing down when the read leaves you unsure is still the law — but name
what the read showed, because "it looks simple" is the same prediction made twice.

**Tier sizes the machinery; NOVELTY overrides it.** The table above measures how big the change is.
It does not measure how much you actually know, and those come apart constantly: a one-line change
against an API you have not read is Trivial by size and is precisely where an agent guesses and ships
a plausible bug. So the rule sits above the table — **whenever the surface is new to you, or you
notice you are reasoning from memory rather than from something you read, gather first, however small
the change.** `compound-v:searching-patterns` already enforces this for dependencies; it generalises.
The cheapest version is slot 1 and one lookup, and it is still the difference between knowing and
guessing.

**The pack scales with what you don't know — this is not "always research more."** Front-loading
*constraints* is measured to help; front-loading *repository overviews* was measured (one study,
arXiv 2602.11988) to cost over 20% and help nothing, and an extra preparation phase that cuts against how the model works degrades
results. Assemble for THIS task, use it, discard it.

If you could describe the whole diff in one sentence, skip the plan. The harness's own explore → plan → code → commit, run through plan mode, is the right default below Standard — reaching past it is the overkill this table exists to prevent.

**Attended or unattended — settle this before you route.** Default to **attended**. Treat the run as **unattended** when the user said so ("I'm stepping away", "run it overnight", "ping me when it's done"), when a schedule, hook or CI started it, or **when you are yourself a subagent** — a worker's permission check sees only its own transcript, so no human turn is reachable from inside it no matter who is at the keyboard. The mode flips behaviour that several skills already branch on: no menus (`finishing` takes the reversible default and reports), always run the full suite rather than holding it (`test-driven-development`), open a state file first (`handoff`), and add the plan's fresh-context pass (`writing-plans`). Getting it wrong is silently asymmetric — wrongly assuming attended blocks an autonomous run on a question nobody will answer; wrongly assuming unattended takes an action nobody approved.

Two failure modes to route around. **Process is what you reach for when you can't trust judgment** — where judgment is present and the change is small, invoking nothing is a legitimate answer, and the kit says so rather than defending its own surface area. But routing *down* a tier means less machinery, never a vaguer brief: a vague prompt costs more context in the long run than a precise one, because the agent spends the difference guessing.

## Other skills

*The two design-heavy groups marked **opt-in** below are invoked only when the user explicitly asks for that help or names a skill — the auto-invoke rule above does not apply to them. Every other skill auto-invokes on intent as usual.*

- **Solve any goal (opt-in — invoke when the user asks for it, names a skill, or another skill hands off here; `get-shit-done`'s recon stage now does, which is how the mechanism call reaches this group at all):** `frame-the-goal` (turn the goal into a testable success check) → `simplest-thing-that-works` (the simplest mechanism that passes it — below "use a model," climb only when forced, as high as a hard goal needs) → `make-it-stable` (make the chosen mechanism hold every time). Caps the machinery, never the goal.
- **Judgment:** `startup-taste` (should we build it) · `product-taste` (is it well made) · `founder-distribution` (will it reach anyone — the third leg of the master gate)
- **Plan:** `brainstorming` · `writing-plans` (per-build plan) · `writing-prd` (the product's stable source-of-truth doc) · `extracting-specs` (recover the real contract of *existing* code — the backward complement of writing-prd)
- **Thinking:** `critical-thinking` (red-team your own reasoning before you commit — steelman + disconfirm) · `council` (the escalation when solo self-skepticism isn't enough: fresh-context agents answer and then attack one question no checker can settle, and you chair the synthesis)
- **Build:** `batched-implementation` · `recheck` (in-pipeline review gate) · `code-review` (on-demand **and the automatic pre-merge gate**: review a PR/branch/diff, post to GitHub, or apply fixes — runs before any merge) · `finishing` (it merges, pushes and deletes — the irreversible paths need explicit confirmation) · `get-shit-done` (the **project spine**, and the answer to runs that stall at 90%: every declared function is a ledger row that starts failing, and the run is not done while one is neither passed nor explicitly dropped with a name on it. Carve → recon → build one slice at a time → the product-level done-gate. Its stage 4 still runs standalone as the end-gate after `finishing`.)
- **Correctness:** `test-driven-development` · `systematic-debugging` · `verification-before-completion`
- **AI design (one feature):** `designing-agents` · `evals` · `context-engineering`
- **AI systems (architecture — opt-in, invoke on explicit request or by name):** `architecting-ai-systems` (the shape around the model — harness-as-moat, primitive-not-wrapper, build for the model ~18 months out) · `ai-system-reliability` (keep a built system from corrupting its own state; chain a constellation past one model's ceiling)
- **Security:** `agent-security` (lethal trifecta, untrusted input, model-written code)
- **Power:** `searching-patterns` (pull the canonical pattern + its anti-pattern) · `dispatching-parallel-agents` (default is one agent; fan out only for disjoint writes or isolated reads) · `handoff` (one `.claude/STATE.md` for work that outlives the session)

## Documents earn their place
Writing the spec is the expensive default, not the safe one. A repo full of specs nobody reads is the same defect as no spec at all, and it is the one the tier table alone won't catch — so before writing a document, run these five, in order:

1. **Route against what exists first.** Read the docs the repo already has — product intent, decisions/ADRs, prior change records, runbooks, API/CLI/config reference — then pick exactly one: **amend** the doc that already owns this surface (the default), **supersede** the decision this reverses with a new ADR linked back, **create** one document, **retire** the one the ground has moved out from under, or **none**. A new document for a surface something already owns is how nine overlapping specs and a contradicting README happen.
2. **At most one new document per change.** Review findings and the plan are *sections of it*, never siblings. Below Standard the count is zero — the spec and plan get confirmed in the conversation, and the commit message is the durable record.
3. **Name what the change makes wrong.** Every doc this invalidates — a README claim, a runbook command, a config table, a CLI help string — becomes a task in the plan, not a follow-up.
4. **Retiring is the outcome nobody reaches for — the other four all grow the pile.** A doc that was lightweight and genuinely useful when written can be dead a few months on, because the ground it described moved and nobody looked at it again; where the surface has drifted out from under the doc that owns it, propose retiring it rather than amending it into something longer that nobody reads. Judge that on whether its purpose still holds, not on what links to it — runbooks and reference pages are read in anger and linked by nothing. Retiring it is a task in the plan with its inbound links repointed, exactly like the invalidated-docs rule in step 3.
5. **Then check it shipped.** A change that invalidates documentation isn't done until that documentation is updated. Reference and how-to docs rot first, because neither is where the thinking happened.

Fold the durable part — the decision and what was rejected — into the living doc or an ADR when the work lands, and let the per-change scaffolding go. `writing-prd` owns the stable product doc; `writing-plans` owns the per-build plan; `handoff` owns `.claude/STATE.md`, which is run scaffolding rather than a document — it is deleted when the run ends and does not count against the cap at any tier.
