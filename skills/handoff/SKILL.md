---
name: handoff
description: 'Open, continue, or close the state file for work that will outlive one session. Use when starting multi-session or unattended work, before ending a session with work unfinished, or when the user says continue or resume (in any language) and a run may already be in progress. Triggers in any language, including Russian: "дай промпт на продолжение", "передай следующей сессии", "запиши где мы остановились", "сохрани состояние".'
---

# Handoff

One human-owned state file per repo: `.claude/STATE.md`. Never a second "plan" or "analysis" sibling
— a handoff split across two documents is a handoff that will go stale in one of them.

## Two state files, two owners

`.claude/STATE.md` holds intent — the goal, the decisions, the next step — and is written by the
human and the model. It lives in git and is what a fresh session reads to continue.
`<repo>/.claude/state/live.md` holds the physical stopping point and is written only by the
`state-live` hook. It is machine-owned and excluded from git. Read it when you need to know where
the process actually stopped; never write it, never delete it, never hand it to anyone as the
handoff.

The single exception is **compound-v:get-shit-done**'s `.claude/slices.json`, and it is an exception
because it is not narrative: it holds the declared-scope rows and their status — what exists, what
has passed its check — which is exactly the thing a long run quietly rewrites in its own favour. A
row carries the short structured fields that make it checkable by someone who was not there (what it
does, its numbered steps, the evidence for a pass); what it must not carry is the run's story. The
split is strict and it is what keeps both files honest — no narrative in the JSON, no status bits in
the Markdown, and **Next** naming a row id rather than restating it. Two files that can disagree is
the failure above; two files that *cannot* overlap is not.

## Which repo

`git -C <the files you are changing> rev-parse --show-toplevel`. The state file goes there — not
in the working directory, which may be a folder that merely *contains* repos. A state file outside
a git work tree describes no single project and is loaded by every session that opens that folder.

If the run touches two repos, write two state files, each covering only its own repo and naming
the other in one line. Never a shared one above them.

## If `.claude/STATE.md` already exists

1. `git log --oneline -20` and `git status --porcelain`.
2. Read the file.
3. Continue from **Next**. Do not re-plan what it already settled. Do not retry anything under
   **Do not**. **Done** is trustworthy only as far as the commit that last moved it, so let step 1
   arbitrate: what a commit in `git log` backs needs no re-verification, but a dirty tree or commits
   newer than this file's rewrite timestamp are work that happened and was never recorded — which is
   exactly what a session killed mid-step leaves behind. Re-verify that tail; don't trust it and
   don't redo it. **Claim only the part this run can account for**, though: a change that neither the
   state file nor the plan explains may be the user's, or a parallel session's in the same working
   tree — leave it, never revert it, and ask before building on it.
4. If the goal is still open and the work is unattended, quote the **Goal** line back to the user.
   If their harness has a goal or watchdog mechanism, that text is what arms it — a skill cannot
   arm one on their behalf.

## If it does not exist

1. Copy this skill's `STATE.md` template into `<repo>/.claude/STATE.md` and fill it in.
2. If the work is risky or spans days, branch first: `git switch -c run/<slug>`.
3. Commit it alone: `chore: open run state`.
4. Say in one line: the branch, and the **Goal** text the run is aimed at.

## While working

- One completed step = one commit, and that commit also updates **Done** and its evidence line. Under **compound-v:batched-implementation** the step is the *batch*, not the task: the implementer's intermediate per-task commits are exempt and must not move **Done**, because they have not been rechecked yet and **Done** records what is verified, not what is written. The batch's trailered commit is the one that moves it.
  Outside that one exemption, never commit code without moving the state file.
- **One writer owns this file.** When batches fan out in parallel (**compound-v:batched-implementation**), the workers never touch it — the orchestrator writes **Done** itself, one returned batch at a time, in the order verdicts land. File-disjointness between workers buys nothing here: they are disjoint in the code and identical in the path they would both write, and that is the collision, not the exception to it. If two runs genuinely have to be live at once, give each its own branch and its own state file there; a fixed name plus "whoever finishes last wins" is not concurrency safety.
- Append to **Do not** whenever an approach fails. That section is what stops a fresh session
  repeating a dead end — it is the part git history cannot recover.
- **Write a user's mid-run steer into the state file, in their words, before you act on it** — a
  new constraint, a redirect, a reversal of something **Next** or **Do not** assumed — dated, under
  **Goal**, with its object when the words alone do not carry it ("not that" is nothing without
  what it refers to). Its only other home is the transcript, which a fresh session never reads, and
  a paraphrase hands the next session your reading of the instruction rather than the instruction.
  If it replaces part of the goal, rewrite that part and stop the work that served only it. A
  correction spent once this step lands stays out; the file holds what must still bind next session.
- Anything blocked goes in **Open decisions**. If it's a *judgment* — a retry cap, a deploy target, a product call — write it as a **proposal, not a question**: the answer you'd pick, the one-line reason, "agree?". Whoever holds the constraint rarely holds your context, so an open question comes back "it depends" or not at all, while a concrete proposal is answerable in seconds and a *no* comes back naming the constraint you were missing. Write it to be rejected, not rubber-stamped — a proposal shaped to be nodded through buys a yes and loses the constraint. If it's a thing only a person can hand over — a credential, an account, access — there is nothing to propose: name it exactly, and what it unblocks.
- No calendar estimates. Size by steps and by what must be verified.

## Before a session ends with work unfinished

Rewrite **Next** as one concrete action for a reader with zero context: the file, the function,
the command. Fill **Suggested skills** with what the next session should invoke first. Commit.
Then say in one line how to resume.

## Harness friction goes in a log, not in your head

**When the agent hits friction in the environment — a wrong flag set, a stale documented path, a
cwd trap, a missing helper — it appends one line and keeps working**, instead of silently routing
around it so the information evaporates. One tracked file at the repo root, one entry per hit:
timestamp, model, and one sentence saying what you were doing, the exact action, the exact failure,
and the change that would have avoided it. Give the file `merge=union` in `.gitattributes` so
parallel worktrees do not conflict on it.

This is **not** the always-loaded instruction file — **compound-v:context-engineering**'s write-gate
correctly bans transient failures from that, and this has a different reader: whoever repairs the
environment, reading in batches, never per turn. **The trap is that a log with no resolution path is
a graveyard.** It earns its place only if something periodically reads it and changes the
environment, and an entry closes when that change lands, not when someone reads it. One team has now published a yield,
from the same loop inside a product: they gave their own agent a channel to report tooling
friction, and *"approximately 20% of messages warranted a mergeable PR"* — their own number,
self-reported and uncontrolled. The first one named a tool that had been failing for months on
filenames carrying a non-breaking space, which nothing else had surfaced. Two conditions travel
with it: the agent reports only where it is genuinely blocked — *"too pushy and we'd get a flood
of 'I had to think for a moment' non-issues; too cautious and the agent silently ground through
the same broken tool ten times before giving up"* — and an entry is a lead, never a verdict on
the run. And the repair has to
be made by the team using the kit rather than handed down, or it becomes an artifact people use
where it works and quietly abandon where it does not.

## When the work is done

Rewrite `.claude/STATE.md` to match what was actually built, then commit it with the final change:
**Done** carries the finished behavior and the evidence line that proves it, **Next** becomes the
follow-up or `none`. Delete the file only when the entire run is finished *and* the human has
confirmed it is finished — `.claude/slices.json` goes with it if the run opened one. Until then it
stays in git: a session ending is not a run ending, and a fresh session has nothing else to resume
from.

Sweep before you delete. **Do not** is the one part you already wrote down as what git history
cannot recover, so read it and the evidence lines once more and sort each entry: a dead end that
only makes sense against this goal dies with the file, but the command that finally reproduced the
bug, the env quirk that cost an hour, and the approach that will look attractive again in a later
session are facts about the repo. Their home is `CLAUDE.md`/`AGENTS.md` — the file every session
already reads, so a line there takes you out of the loop entirely (**compound-v:context-engineering**
owns what qualifies and how to keep it small). Promote in the same commit that deletes; a fact you
meant to move afterwards is a fact you lost.

## What an unattended run owes you — five bounds

Work that outlives a session is work nobody is watching, and the discipline for that has a name and
a definition. Loop engineering — coined by Addy Osmani, *"replacing yourself as the person who
prompts the agent"* — bounds each run with five things. State them in `.claude/STATE.md` before a
run goes unattended, because every one of them is unrecoverable after the fact:

1. **A machine-checkable stop condition.** Not "when it's done" — a predicate something can evaluate.
   `get-shit-done`'s ledger rows are this kit's version.
2. **A cost ceiling.** Inference spend, wall clock, or both.
3. **A permission boundary** — what the run may change without asking. One-way doors (schema, public
   API, spend, irreversible writes) sit outside it by default.
4. **An escalation policy** — the named condition on which it stops and asks, decided in advance
   rather than in the moment.
5. **Independence between the verifier and the implementer.** Whatever checks the work must not be
   the thing that produced it; that is why `recheck` is read-only.

Note what these are: a termination predicate, a budget, a permission model, an escalation rule. **None
of them is information you could put in a context window** — this is the one part of working with
agents that gathering more context cannot help with, which is exactly why it needs writing down.

**Bounds 3 and 4 both end in "stop and ask" — name who they ask, and how.** An unattended run is
unattended because nobody is reading the transcript, so a permission boundary or an escalation that
resolves to a message in the log is a run that has quietly stopped, not one that has escalated. Name
one out-of-band channel before the run starts and write it in the state file beside the escalation
condition. **The trap is that a channel used for progress stops being read** — a stream that admits
non-actionable items degrades response to the whole stream — so fire it only on the escalation
conditions and on terminal state, never per step or per landed batch.


## Budget

Keep it under 30 lines — the same argument `writing-plans` makes at its 200-line cap. A state file
longer than that stops being re-read in full, and a handoff nobody reads to the end is one whose
tail silently stops existing. If your harness re-injects it at session start, that injection
truncates too, which only sharpens the limit.

This file is **run scaffolding, not a document**: it does not count against the one-new-document-per-change
cap in `using-compound-v`, and it is removed only once the run is over and the human has said so.
