# The listing budget — why a good skill silently stops firing

A skill delivers nothing unless it fires, and whether it fires is decided by a layer *above* the
skill: the always-loaded listing of names and descriptions. That listing has a budget. When it
overflows, the harness does not warn the model — it **drops descriptions, starting with the skills
you invoke least**, leaving a bare name that no user's phrasing matches. The name itself stays in the
listing, so a handoff that names the skill exactly still reaches it — the failure is in matching, not
in invocation.

So the failure looks exactly like a badly-written description, and it is not. A skill can be perfect
and unreachable. This file is the owner of that failure.

## The constants

From the harness's own documentation (`code.claude.com/docs/en/skills`), current as of 2026-09:

| Constant | Value | Consequence |
|---|---|---|
| Per-entry description cap | **1,536 chars**, `description` + `when_to_use` **combined** | The **tail** is cut. Put the key use case first; trigger phrases parked at the end are the first thing to go. |
| Listing budget | **1% of the model's context window** | Scales with the model. A kit that fits on a large-context model can overflow on a smaller one. |
| Overflow behaviour | **Drops descriptions starting with the skills you invoke least** | A feedback loop: low use → description dropped → cannot match → lower use. |
| Post-compaction re-attachment | First **5,000 tokens** per skill; **25,000 tokens** combined, filled most-recently-invoked first | Anything past ~3,750 words in a `SKILL.md` may not survive compaction. Older skills can be dropped entirely. |

Two settings move these: `skillListingMaxDescChars` (the 1,536 cap) and `skillListingBudgetFraction`
(the 1%), plus `SLASH_COMMAND_TOOL_CHAR_BUDGET` for a fixed character count. `skillOverrides` can set
an entry to `"name-only"` to free budget — but not a plugin's: *"Plugin skills are not affected by
`skillOverrides`. Manage those through `/plugin` instead"* (same page, rev. 2026-09-17), so for this
kit's own entries the levers are a shorter description or `disable-model-invocation`. `/doctor` estimates the listing's cost and its biggest
contributors; on overflow the harness also writes a warning to the debug log.

## It is not hypothetical — it is happening to this kit

Observed live, 2026-09-01, in a session with this kit plus roughly a hundred other installed skills:

**`compound-v:council` carries a 679-character description in its own file and appeared in the
session listing as a bare name with no description at all**, while every other Compound V skill
carried its full text. `council` is the least-invoked skill in the kit — **1 invocation in 60 days**,
against 223 for `critical-thinking`.

That is the documented behaviour, caught in the act, and it reverses the obvious conclusion. A
usage audit reads `council: 1` as evidence the skill is redundant and should be cut. The real
causation runs the other way: its description was dropped, so it could not match, so it did not fire,
so it stayed first in line to be dropped. **Cutting it would have been treating the symptom.** The
kit's own audit script already warns that a zero is absence of evidence rather than evidence of
death; this is the mechanism behind that warning.

Compound V's own descriptions cost several thousand tokens before a
single other skill is installed. `bash scripts/check.sh` prints this number on every run.

## What to do about it

**Measure before trimming.** This kit spent its whole life enforcing a **1024**-character description
cap that the harness does not use anywhere — a self-inflicted constraint 33% tighter than the real
1,536, paid for in deleted trigger phrases. The gate now reads 1,536 and counts `when_to_use` toward
it. Check the number against the docs before believing any cap, including this one.

**Order every description by trigger value.** The cut is a tail cut, so the first clause must be the
thing a user would actually say. A description that opens with a category label and buries the
trigger phrases is a description that truncates into uselessness.

**Do not fix an overflow by deleting skills.** Deleting the least-invoked skill promotes the next
least-invoked one into the same trap, and you lose a capability to buy budget you could have bought
with a shorter description (or `skillOverrides`, for skills that are not a plugin's). The population that gets dropped is a property of the
*budget*, not of the skills.

**Route around the listing where the work is important.** A `SessionStart` hook injects text
unconditionally, outside the listing budget entirely. That is why this kit's router
(**compound-v:using-compound-v**) is hook-injected and why it names every skill and its trigger: a
skill whose description was dropped is still reachable through the router. **The router is the
kit's redundancy against its own delivery layer**, which is the strongest argument for keeping it
exhaustive rather than short.

**But the hook route is not free and not universal.** It is outside the listing budget because it is
its own budget: the router is re-sent in full at every injection — 14,231 characters today, which you
measure (`wc -c skills/using-compound-v/SKILL.md`) rather than assume — and `hooks/user-prompt-submit`
adds a 349-character reminder on **every turn**. Cost therefore scales with turn count while the
benefit scales with how often routing was about to go wrong, and that trade flips sign by model
class: the same always-on ruleset that was tens of percent cheaper on several models came out *"39%
more expensive"* on a terse reasoning model, because *"the ruleset is re-sent as input every call and
the baseline output is already terse, so the input and reasoning-token overhead outweighs the lines
saved"* (DietrichGebert/ponytail, `benchmarks/results/2026-06-17-cost-verification.md`; first-party,
and disclosed against that author's own pitch). Never carry a cost claim across a model class you did
not measure on.

**And the route stops at three boundaries the host does not cross for you.** `bash scripts/selftest.sh
boundaries` reports each one every run:

| Boundary | What ships today | Why it matters |
|---|---|---|
| `SessionStart` matcher | `hooks/hooks.json` matches `startup\|clear\|compact`; the documented sources are `startup, resume, clear, compact, fork` | A resumed or forked session starts with no router, and is indistinguishable from one that has it |
| subagent spawn | nothing registered on `SubagentStart` | Every worker `dispatching-parallel-agents` fans out runs router-unaware — the redundancy stops precisely where the kit does its heaviest work |
| the tail of a long session | `UserPromptSubmit` re-asserts a one-liner, not the router | Deliberate and correct: the full router every turn would cost more than the drop it prevents |

Closing the first two is a decision, not a chore. Re-injecting the router at `SubagentStart` costs
14,231 characters **per worker**, against delegation economics this kit has already measured as
expensive per handoff ("every token crossing the boundary is billed twice",
`compound-v:dispatching-parallel-agents`). Make the call on that number; the number belongs here.

## The redundancy is also the contamination

The router is why a dropped description still fires. It is also why you cannot measure whether the
description would have fired on its own: it names every skill and its triggers, the hook injects it
into every arm, and no flag separates them — so `scripts/trigger-eval.sh` reports *router +
description*, always. The same property in both directions. **The mechanism that makes the delivery
reliable is the mechanism that makes it unmeasurable**, and nothing warns you, because the
contaminated number is not obviously wrong.

What you *can* isolate is everything that is not the kit. `bash scripts/arm.sh --probe` builds each
arm and prints what it actually loaded, read out of the CLI's own init event rather than inferred.
Measured on one machine, same repo, same prompt, minutes apart:

|          | skills | slash commands | agents | plugins | MCP servers |
|---|---|---|---|---|---|
| isolated |     51 |             85 |      7 |       1 |           0 |
| ambient  |    166 |            204 |     27 |       3 |           2 |

166 skills competing for the listing budget instead of 51 — and the documented response to an
overflowing listing is the drop this file exists to explain. So a fixture that misses in the ambient
arm gets written up as a wording problem when it may be a budget problem, and it lands first on the
skills that were already least-invoked. Both arms are legitimate; they answer different questions.
Ask the ambient one when the question is "does this fire on a real machine", the isolated one when
the question is about the description itself, and never pool them — `trigger-eval.sh` prints which
arm produced the number at the top of every run for exactly that reason.

## The instruments, and the second harness

**`/skill-doctor`** (Claude Code v2.1.252+) reports per-skill context cost *and* invocation count together and flags never-invoked skills — which is exactly what the case below needed to separate "never invoked because redundant" from "never invoked because its description was dropped", a causal direction this file once got backwards. It is unavailable over Remote Control and in sessions that skip feature-flag fetching, so a blank result is not evidence of a clean listing.

**A second harness budgets the same listing differently, and that it fails the same way is the finding.** Codex allots 2% of the model's context window, or 8,000 characters when the window is unknown; it includes each skill's *file path* alongside name and description, shortens descriptions first, and may omit skills entirely with a warning. Two vendors, different constants, same failure mode — which is why the rule below is about the mechanism and not about anyone's number. The standing rule governs both: **report what the command prints, never a stored number.**

**Suspect this first when a skill stops firing.** Before rewriting a description that was working,
check whether it is still in the listing at all. The rewrite cannot fix a drop, and a description
edited to chase a phantom trigger failure is strictly worse than the one it replaced.

**Never write the current total into this file.** It was hardcoded once as "30 descriptions,
~14,100 characters" and was wrong within the week the 31st skill landed — a stale number in a
budget document is worse than none, because it gets trusted. `bash scripts/check.sh` prints the
live figure (`always-on description cost:`) every run. Read it there.
