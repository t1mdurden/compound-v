---
name: finishing
description: Wrap up a completed branch — verify the full suite is green with fresh evidence, then land it safely: merge, PR, keep or discard. Use when implementation is done and rechecked and you need to integrate or close out the work — "wrap this up", "merge it", "open a PR", "are we done here", "clean up the branch".
---

# Finishing

Confirm the work is actually green, then land it the way the user chose — or, when nobody is there to be asked, the way that can be undone.

## When to use

- All tasks are built and the branch is **reviewed** — compound-v:code-review clears it before any merge either way, and where the work was built here in more than one batch that pass is also the whole-branch drift read (Step 1); in-session compound-v:recheck verdicts cover the batches, not the branch.
- The user signals the work is done and asks how to integrate or close it out.
- Skip it when the work isn't finished or it hasn't passed review — finishing assumes a green, reviewed branch; route incomplete work back to compound-v:batched-implementation or compound-v:systematic-debugging instead.

## Step 1 — Verify green, fresh, yourself

Run the full suite this turn and read the exit code yourself — the **compound-v:verification-before-completion** gate, applied to integration: no merge/PR decision rides on "they passed earlier" or the implementer's word. A red suite is **not** a finishing situation: **stop**, surface the failure, and route back to **compound-v:systematic-debugging** — never present the options below on red, because every one of them assumes a green branch. Formatting is the one exception to that strictness: iterate at most **3 times** to get lint/format clean on the files this branch changed, not the repo (a violation that predates the branch is not its to fix, and a repo-wide auto-fix buries the real diff under edits code-review is told to skip), then ship and disclose what's still off rather than burning the run on cosmetics — and if the repo has no formatter configured, do not add one.

**Green is necessary, not sufficient — the change must be reviewed before it lands.** Run **compound-v:code-review** before any merge and resolve every Critical/Important finding first; an unreviewed change does not get merged, however green it is. In-session **compound-v:recheck** verdicts do not substitute — they cover the batches, not the branch. When the branch was built in more than one batch, point that review at the *assembled* branch and hunt cross-batch drift specifically (a contract two batches each half-changed, a convention that shifted mid-run) — the one thing a reviewer that only ever saw a single batch's diff structurally cannot see.

**Green ≠ "the change worked" when the change targets a metric.** If the work was meant to move cost, latency, quality, or some observable behavior, a passing suite only proves it didn't break — it does *not* prove the intended effect landed. Finish that work by **measuring the effect with a real post-ship run**, not by asserting it ("should be ~30% cheaper now" is a prediction, not a result). If the measurement is genuinely blocked (needs prod traffic, a scheduled batch, real users), say so and **track/schedule it** — a deferred measurement is an open item, never silently "done." And **sanity-check any auto-generated metric before you relay it**: a number off by a timezone, a confound, or a selection bias is worse than no number, because it reads as evidence.

**Green says nothing about which *default* is live.** The temporary machinery a branch introduces — a feature flag, an env-var default, a short-circuited guard, a stub endpoint, a hardcoded account — is live code sitting on a chosen setting, not dead code a reviewer trips over, and where each test sets the path it needs the suite passes on either setting: the shipping default is the one path nothing exercises. So before you land, list every toggle this branch added and state its shipping value out loud. A flag someone added temporarily and forgot is the shim a contractor walls into a house: it surfaces later as a first-run user staring at an empty screen while every test is green. Aim to land at most one; if a toggle must stay, name who removes it and when.

## Step 2 — Pick the landing path

**Only offer a menu when the user is actually there to answer it.** In an unattended or scheduled run the user is not watching in real time and cannot answer mid-task, so "Want me to…?" simply blocks the work. There, take the **reversible** default — commit, push, open the PR, leave the branch standing — and report what you did. Stop and wait for explicit confirmation only on the irreversible paths: merging into the default branch, force-pushing, or discarding work. When the user *is* present, offer a small structured menu, not an open-ended "what now?":

1. **Merge locally** into the base branch.
2. **Push and open a PR.**
3. **Keep the branch as-is** (leave it for later).
4. **Discard** the work.

Pick the base branch deliberately (the branch this work forked from, usually `main`/`master`). State it so the user can correct it.

## Step 2.5 — Harvest the trap (the step that makes experience compound)

Before you land, ask one question — and expect the answer to be "nothing" most times:

> **What bit us that we could not see on day one, and would it bite the next person the same way?**

A strong engineer's advantage across projects is accumulated scar tissue: the traps they have already
paid for. An agent starts every session without it, and this is the only step in the kit that adds
any. Without it, `references/shapes.md` grows only when someone runs a research pass, and the work
you just finished teaches the next run nothing.

**Harvest the pair — the shape and its trap — and let the trap decide whether it is worth a row.**
The table's columns are `Shape | Reach for it when | Its trap`, so a trap with no shape attached is
unusable; you cannot warn about a cost in the abstract. What is asymmetric is scarcity: the shape is
often reconstructable from the problem, the trap never is, because it is the half somebody paid for.

`references/shapes.md` carries the admission bar and it is deliberately high: the shape must recur in
a context you can name, the trap is the payload, it must still earn its place on a stronger model,
and adding a row means being willing to evict one. **Most runs harvest nothing — that is the bar
working, not a miss.** If the lesson is real but does not clear the bar, put it in the commit message
and let it earn a row the next time it happens.

Below Standard tier, skip this: a typo teaches nothing, and looking for a lesson in one is how a
curated table becomes an index.

## Step 3 — Execute the choice safely

**Merge / PR:** run the merge (or push + `gh pr create`), then **re-run the suite on the merged result** — a clean merge can still produce a broken combination. If the merge hits a **conflict**, **stop and surface it** — resolve it deliberately, or hand it back. The PR path needs the branch pushed first (`git push -u origin <branch>`) and `gh` authenticated; check both before `gh pr create` rather than after it fails. Green locally is not green in CI. After the PR is open, surface the remote check status (`gh pr checks --watch`) rather than declaring done at `gh pr create` — a merged-result suite you ran can still diverge from the repo's CI, and the branch isn't landable until those checks pass.

**The PR body is an artifact, not a title — put the evidence inside the repo's two native sections, don't invent a competing layout.** Under `#### Summary`, at most three bullets on what changed and why, plus the review verdict (`APPROVED`) and any follow-up you deliberately deferred. Under `#### Test plan`, a checklist whose items are the **actual commands you ran and their result lines** — `pytest -q → 214 passed`, never "tests pass". A reviewer should be able to trust the branch from the body alone.

**Discard or any destructive cleanup:** require a **typed confirmation** ("type `discard` to confirm") — a yes/no is too easy to fire by reflex, and this is the one path the unattended default above may never take on its own. Make that confirmation *informed* by first surfacing the work that would vanish unrecoverably: **unpushed commits** (`git log --branches --not --remotes --oneline`, or `git log <base>..HEAD`), which no status check will show you.

**Where this hands next.** On a Large run the landing is not the end: **compound-v:get-shit-done**'s stage 4 (**compound-v:get-shit-done-4-reckon**) is the product-level done-gate and it runs *after* this skill, once, over the assembled product — `using-compound-v` routes it that way and nothing else in the kit closes over the whole build. On Standard and below, landing is the end.

**Retire the per-change scaffolding in the landing commit.** `using-compound-v` requires that the durable part — the decision and what was rejected — folds into the living doc or an ADR when the work lands, and that the scaffolding then goes. This is the step that executes it: the per-build plan and its design spec have no readers once the work is merged, and left behind they become the "repo full of specs nobody reads" the document rule exists to prevent — the same reason `compound-v:handoff` deletes its run scaffolding in the final commit. Fold, delete, and say in one line what you folded and where. **Whatever you delete, drop or repoint the links that named it** — the PRD links to the plan and the design spec by rule (`compound-v:writing-prd`), so a silent delete leaves the product's stable source of truth pointing at nothing, and a stale durable doc an agent trusts as fact is worse than no doc. Keep a plan only when something still open points at it, and say what.

**Fold the deviations with the decision.** The plan was approved before the code existed, so the durable record is not the plan but where the build left it and what forced that — the degree-level fixes the batch reports carried under `DONE_WITH_CONCERNS`, the kind-level ones that sent a batch back to the plan. Reread the plan against the merged diff, write each departure as one line with its reason beside the decision it changed, and let the rest of the plan go. A bare decision detaches from its context and gets re-litigated or routed around by the next reader; a decision with its deviation is the one thing the diff cannot show.

**Worktree cleanup order** (the footgun): merge → **`cd` out of the worktree** → remove the worktree → then delete the branch. Both ends bite, but only one is loud: deleting the branch first errors out (`cannot delete branch 'feat' used by worktree at …`, exit 1) and self-corrects. Removing the worktree from inside it *succeeds* — exit 0, directory gone — and strands your shell in a deleted cwd, where `pwd` still prints the old path while every later command dies with an unrelated-looking `fatal: Unable to read current working directory`. The dangerous case is the one that returns success, which is why the `cd` comes first. Only remove worktrees you created (under a gitignored `.worktrees/` or similar) — never one the harness owns.

## Step 4 — See the original scenario work where it shipped

**A merge is not a release, and a green suite on the branch says nothing about the deployed thing.**
Once the change is live wherever it lands — a preview URL, staging, production — drive the scenario
the ask was about, on that surface, and read the result: the deploy's own output, the migration's
outcome, the first real request through the new path. This is the moment the whole cycle was for,
and it is the one nobody owns once the PR is closed. Help the person check readiness and the deploy
result, then exercise the original scenario end to end; where the environment does not give you a
way to reach it, say so rather than inferring from the branch. The trap: "it deployed" is a status
line, not evidence — a rollout that reports success with the old code still serving is the common
shape, so confirm the scenario, not the pipeline's mood.
