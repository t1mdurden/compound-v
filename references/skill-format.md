# Compound V — Skill Format Constitution

The authoritative spec for writing a Compound V skill. Lean by construction: if a line gives <5%
lift, it does not belong. This file is itself the example — short, dense, every rule earns its place.

## Frontmatter (required)

```yaml
---
name: <kebab-case>            # ^[a-z0-9-]+$, ≤64 chars, matches the directory name
description: <Imperative WHAT it does, one clause>. Use when <concrete triggers / intents / phrasings>, even if <the user doesn't name it>.
---
```

- This kit requires `name` and `description`; Claude Code itself treats every key as optional and
  only recommends `description`, while the Agent Skills spec path (claude.ai upload, the Skills API)
  requires both and rejects Claude-Code-only keys. The harness documents more — `when_to_use`,
  `argument-hint`, `arguments`, `allowed-tools`, `disallowed-tools`, `disable-model-invocation`,
  `user-invocable`, `model`, `effort`, `context`, `agent`, `background`, `hooks`, `paths`, `shell`,
  `license`, `compatibility`, `metadata` (code.claude.com/docs/en/skills, rev. 2026-09-17) — and
  `scripts/check.sh` gates that set. **A gate that copies someone else's table goes stale silently:** when the harness
  ships a field, the gate reports it as *unknown*, which reads exactly like a typo, so read the
  harness's frontmatter reference before adding a key rather than trusting this list.
- **`disallowed-tools` is the capability lock; `allowed-tools` is its opposite, and the names invite
  the mistake.** `allowed-tools` *grants* — the tools the model may use without asking permission
  during the turn that invokes the skill — so reaching for it to constrain an agent widens it
  instead, skipping the prompt on exactly the tools you were nervous about. `disallowed-tools`
  removes tools from the pool while the skill is active, and it is the enforcement
  **compound-v:brainstorming** asks for when it calls its design gate *"a capability lock, not a
  politeness rule"*. **The trap: the scoping is a turn, the instructions are a session.** Both keys
  clear when the user sends the next message while the body stays resident — so the skill goes on
  telling the agent it is locked long after the lock is gone, and nothing reports the gap.
- **`context: fork` is the only lever that buys a large body without paying for it every turn.** The
  body is pay-per-use, but the unit is not the invocation: once loaded it stays in the window and is
  re-sent on every later turn, so a long skill invoked early in a long session is billed for the rest
  of it. A forked skill runs in its own thread and returns only its answer, so its body never enters
  the main window. **The trap: fork defaults to background** — the invoking turn gets a handle, not
  the answer, unless the skill sets `background: false`, so forking a link in a workflow chain hands
  the next step nothing, and an empty result is indistinguishable from a missing one. Fork a terminal
  skill; wait on a chained one. **And fork only a body that is a task:** the fork gets no conversation
  history, so a body of guidance — most of this kit — has nothing to apply itself to and *"returns
  without meaningful output"* (the harness docs). A `claude -p` test always waits, so it cannot show
  the background trap; test a forked link interactively.
- **`disable-model-invocation: true` — right for a dead end, wrong for a link in a chain.** The flag
  enforces what a prose plea ("opt-in, do not auto-trigger") only asks for, so prefer it *when no
  other skill hands off to this one*. If a skill sits mid-workflow, the flag breaks every upstream
  handoff: the harness refuses the call and tells the model not to reproduce the steps another way,
  so an attended run hands the step back to the user and an unattended one stalls at that link. It
  also removes the description from context entirely — for a plugin skill the only per-skill lever
  that frees listing budget, bought with every handoff. For those, keep the prose and put the real protection where it belongs: an
  explicit confirmation gate on each irreversible action inside the skill. Consequence-gating and
  invocation-gating are different jobs; don't substitute one for the other.

### The economics that govern every authoring choice
**The body is pay-per-use; the description is always loaded.** Every description in the session is
resident before any task starts, so that is where the always-on cost lives — and it is a *shared*
budget: the skill listing is capped near 1% of the context window, and when the listing overflows,
**descriptions get shortened**. Three consequences, in order of importance:

1. **Front-load the trigger.** Truncation eats the tail, so the discriminating "use when…" clause goes
   in the first sentence, never after a paragraph of what-it-does. A trigger that gets truncated is a
   skill that stops firing — and it fails silently, indistinguishably from a skill that was never a
   good match.
2. **Cut bodies ruthlessly; spend on descriptions deliberately.** These pull in opposite directions and
   the correct policy is asymmetric. Reliable triggering can genuinely take a paragraph, and cutting a
   description below that threshold is how a skill quietly stops being invoked. So don't shorten a
   description to save space — *re-spend* it: drop any clause describing the workflow (Ruling A) and
   buy more trigger situations with the words you free.
3. **Fewer skills is also a description-budget decision.** Every skill you add shortens every other
   skill's description. A skill that fires rarely is not free.
- **Ruling A — description = WHAT + WHEN, never the workflow.** State what the skill does + when to
  reach for it + searchable keywords. Be slightly *pushy* ("…even if not asked") to fight
  under-triggering — **but a trigger's breadth is also authority over scope**: whatever the body
  lists becomes part of done on every task the trigger catches (a team deleted a guardrails skill
  triggered by "most substantial coding work" because it *"made its entire checklist part of the
  apparent definition of done"*; OpenAI reported skills *"triggering too often"*). So before widening
  a trigger, read the body against the narrowest task it will now catch; where an item neither
  applies nor sizes itself, narrow the trigger or add a near-miss clause naming the neighbour to use
  instead ("Not for a single feature (compound-v:brainstorming)"). **Never** summarize the steps/flow — a description that encodes the workflow makes
  the model follow the description and skip the body (superpowers' #1 tested failure). Third person.
  ≤1,536 chars — and that cap counts `description` + `when_to_use` COMBINED. (This spec said 1024 for its whole life; the harness uses that number nowhere, so every description was trimmed against a cap 33% tighter than the real one. Verify a cap before enforcing it.)

## Body structure (target ≤250 lines; hard ceiling 500)

```
# Skill Name
One-sentence core principle.

## When to use            ← bullets with concrete symptoms + a "skip it when" line
## <the substance>        ← the actual technique/gates/checklist (the bulk)
## Red flags (optional)   ← two-column table ONLY for discipline skills with real failure modes
```

- **Progressive disclosure.** Keep the body lean; push heavy reference (>100 lines) or reusable code
  into `references/` or `scripts/` and point to it with a one-line "read X when Y". Don't pre-load
  what's only sometimes needed — that is context-engineering applied to the skill itself.
- **One excellent example beats five mediocre ones.** Pick the most relevant language; make it real
  and runnable, not a fill-in-the-blank template.

## The size limit is not only about compaction — a long skill silently sheds its own steps

`scripts/check.sh` warns past ~3,750 words because compaction re-attaches only the first ~5,000
tokens of a skill. That is real, but it is the *second* reason to stay short. The first is worse,
because it happens with a full context window and leaves no trace.

Two practitioners report the same failure independently. A team whose flagship workflow prompt
reached **85 instructions** found it *"silently dropping the deepest ones"* — the agent appeared to
follow the workflow while shedding exactly the constraints that made it reliable; they split it into
stages of **under 40 instructions** each and moved the sequencing out of prose into real control
flow. A second engineer abandoned shipping his harness as a skill for the same reason, and quotes the
agent saying it outright: *"you told me to do that. I decided not to."*

Both are ASR-derived conference-talk quotes, so treat the wording as approximate and the phenomenon
as attested twice rather than measured once. The steps really do go missing; **the count does not explain it, so do not split to a count.** The ceiling
behind "forty" came from a 2025 benchmark of a few hundred named constraints, and its 2026
replication puts current frontier models *"closer to 2,000"*. What that team saw skipped was
specific: the ask-questions and approve-the-outline steps, the agent writing the plan straight away.
Another practitioner sees the same in plan mode — the plan is the visible goal, so the questions get
only a perfunctory pass — and moves the questions into a skill of their own (a talk, paraphrased). So when
a skill sheds steps, **find the step that sits before a deliverable the model can see, and take the
order out of prose** — a stage of its own, or real control flow; trimming leaves that step exactly as
skippable. The replication scores named items, not ordered steps — *"evidence that long skills files
are viable, not proof that every kind of instruction in them is followed"* — so length is no longer
the charge against a long skill; the compaction ceiling still is.

**Apply the expiry test to THIS kit, not only to the rules it writes for other people.** The kit
tells others to ask whether a rule would still earn its place on a stronger model; nothing asks it of
Compound V's own lines. It should, because there is now an outside measurement that a written rule
can make output **worse**: a DX engineer measured one of his own skills at **77% correct with it
loaded against 97% without**, and deleting 95% of that generated content (10,000 lines down to 553
lines of gotchas) made his eval both faster and more accurate. He only knew because he was measuring.

That is the honest bar for every line here: not "is this true?" but "does loading this beat not
loading it?" — and nothing in this kit currently answers that question with a number. **The
instrument now ships with the harness: `claude plugin eval`** runs each case three times with the
plugin and three without, isolated from user settings and other plugins, and reports the difference.
Its without-arm drops the router hook with every skill, so it prices the kit whole; to price one
edit, run the suite against a copy holding the pre-edit skill (skill-creator's protocol), since the
question is whether the edit beats what it replaced. Its `tool_order` grader also checks that a
handoff fired after the skill that named it — a first-hop trigger score cannot. Treat every rule as
provisional until it has been run both ways.

**And be careful about who does the trimming.** The caution that pairs with the measurement above is
sharper still: letting a model expand a skill *"converts high-level guidance into brittle procedural steps, and the
fact that it understood the high-level version is the proof it did not need them."* Keep the guidance
high-level, keep the gotchas concrete, and prefer deleting to explaining.

**A model upgrade is a silent breaking change, but NOT for the reason it first looks like.** A team's
agent stopped obeying a skill after a model bump with *"not a single line in the skill changed"*, and
the obvious diagnosis — the new model weights the top of the file, so move critical instructions to
the front — **does not survive checking, and the kit briefly carried it.** Zero sources support it.
Anthropic's own long-context guidance says the opposite (*"putting the instructions at the END of the
prompt, as we want Claude's recall of them to be as high as possible"*), a Tencent WeChat AI result
improved instruction-following by moving the instruction *after* the input, and a practitioner source
in this kit's own registry reports the bias runs to **both** peripheries with degradation by
instruction count that is uniform rather than positional.

The phenomenon is real and independently attested — a prompt with 17 MUSTs and 11 ALWAYSes treated as
suggestions after a version step; a 12.8pp compliance gap between two models of one family at
identical config; Anthropic itself retiring its repeat-critical-instructions advice. Only the
diagnosis was wrong. So when a skill silently stops working after an upgrade, check in this order:

1. **How far into the SESSION** the failure happens — within-session attenuation was the largest
   effect anyone measured (~5.6% lower odds of compliance per generated function), and it is a
   session-position effect, not a file-position one.
2. **Whether the instruction is an absolute the newer model now reads as defeasible.**
3. **Whether compaction dropped it.**
4. Then **re-run the eval on the new model** rather than reasoning about what it must now weight.

## Every gate in this kit rewards deletion — so pair each one with its opposite

`scripts/check.sh` measures lines, words, and description characters. Every one of those is a
*less-is-better* metric, and a less-is-better metric is always won by degrading whatever it does not
measure: the cheapest route to a green line count is deleting the paragraph that was doing the work.
No size gate can distinguish a tightened skill from a gutted one, and none of them reports that it
cannot.

The failure is measured, not theoretical. Across four minimality arms on the same tasks, the arm that
wrote the least was the only one that broke: *"yagni-oneliner wrote the fewest lines (6) and went
unsafe **once in four**"* — 19/20 against 20/20 for the other three — and the post-mortem names what
the missing lines were: *"The ~3 lines ponytail kept **were the path-traversal check**"*
(DietrichGebert/ponytail, `benchmarks/results/2026-06-18-agentic.md`; first-party). A three-line
difference, and the three lines were the guard.

So each size gate is read against an opposing signal that can only be satisfied by content existing:

| Less-is-better gate | The opposite it must be read beside |
|---|---|
| words / lines per `SKILL.md` | trigger fixtures per skill — `check.sh` **fails** a skill with none, so a skill cannot be trimmed into unroutability unnoticed |
| `always-on description cost` | the routing result for the skills whose descriptions you just trimmed |
| deleting a skill to free listing budget | `references/skill-listing-budget.md` — the drop is a property of the *budget*, so the next-least-invoked skill simply inherits the trap |

Two second-order costs. **Publishing that an opposing instrument exists is not publishing its
result** — an unrun counter-check and one that was run and disliked look identical from outside, so
grep the results for its output, not the method for its description. And **exempting your own
prescribed behaviour from a metric is correct and is a degree of freedom that favours you**: if the
constitution asks for a worked example and worked examples are then exempt from the word count,
somebody outside that decision has to confirm the exemption doesn't disproportionately fit one
author's habits.

## Authoring checklist (the rules the kit follows but rarely states)
- **Description = WHAT + WHEN, never the steps** — Ruling A above is the single most load-bearing
  authoring rule; encoding the flow makes the model follow the description and skip the body.
- **Refs one level deep.** A SKILL points to one `references/…` file; that file does not point to a third
  hop the model has to chase. Any reference material over ~100 lines lives outside the SKILL (see
  progressive disclosure) — a long doc in the body burns context on every load whether it's needed
  or not.
- **One default, not a menu.** Give the recommended path; mention an alternative only when the choice
  is real and the trade-off is named. A menu makes the model pick (often wrong); a default makes it act.
- **Consistent terminology.** Pick one term per concept and reuse it verbatim across the SKILL and
  its refs — synonyms read as distinct things and dilute retrieval.
- **Match specificity to fragility.** Rigid step-by-step gates only for documented failure modes
  (verification, design-before-code, root-cause-before-fix); everywhere else give the reasoning and
  trust judgment (Ruling C). Over-specifying a robust step is the same defect as overkill.
- **Default to qualities; script only where the failure is measured.** On a graded eval, listing the
  **qualities the output should have** moved a prompt from **2.32 → 7.86**; replacing those qualities
  with a list of **process steps** scored **7.3 — lower**, and the author reverted. The mechanism is
  that the reasoning path is *already* in a post-trained model's output space and simply does not rank
  first, so prescriptive steps do not add a capability: scaffolding recovers ~73% of a **base** model's
  gap and about **7%** of a post-trained one's, and that number keeps falling. The strongest
  counter-example reconciles rather than overturns — a step-by-step scaffold reporting a ~47-point win
  was measured on a 2024 base-rung model, and the same author now removes scaffolding. **So: describe
  what a good answer looks like; script only a step that names the failure it prevents.** Two
  consequences worth holding: prompting style is per-model rather than per-project, so re-measure
  rather than inherit; and when a sequence of steps collectively underperforms even though each step
  performs well, *the decomposition is the bug* — stop hunting for the weak stage.
- **Name the operation and the object it runs on; a sentiment computes nothing.** The rule above
  governs *what* a line describes. This governs how a line that survived it must be **worded**: the
  operation, the thing the operation runs on, and what stops it — "grep every caller of the function
  you touch and fix the shared function once", never "trace the flow end to end". A three-arm run on
  one task separates the two: *"pre-fix ponytail and a plain-prose version (\"trace the flow end to
  end\") both scored 0/3 on Opus; only the grep-the-callers directive moved it to 6/6"*
  (DietrichGebert/ponytail, `benchmarks/results/2026-06-22-issue-245-217-comprehension.md` —
  first-party, the author measuring his own skill). The prose arm **tying** the no-rule arm is the
  proof that the wording, not the idea, was the treatment, so a two-arm test cannot tell you this —
  and prose is the arm that reads better in review and survives an editing pass. Two costs travel
  with the rule. It needs a model with the headroom to execute a multi-step instruction: on a
  smaller one *"the baseline also fails it (0/6)"* (same file), which is a floor, not a regression,
  and only reading the control cell tells the two apart. And an operational line is a
  change-detector — "grep every caller" fires as a false requirement the day the code has no callers
  to grep, where "understand the flow" would have degraded quietly instead.
- **Immunise a skill against the skill that would strip it.** Where one skill adds what another
  removes, the pair needs an explicit exemption or the removing skill wins by default and nobody can
  see which rule lost: `simplest-thing-that-works` must not cut what `test-driven-development`
  requires, `recheck` must not flag as over-engineering the guard `agent-security` mandates. Write
  the clause in the **removing** skill, where the decision actually happens — a permission stated
  only in the adding skill is not in the room at the moment something gets deleted.
- **Match the *form* to the failure, not just the rigidity.** Specificity is one axis; the *shape* of
  the guidance is another, and it's failure-type-specific. A **discipline** failure (the model knows
  the rule but skips it under pressure) wants a prohibition / red-flag row; a **wrong-output-shape**
  failure wants a positive recipe or example; an **omitted-element** failure wants a structural
  `REQUIRED:` slot. Crucially, a prohibition list *backfires* on a shaping problem — in head-to-head
  wording tests the "don't X" arm produced *more* of the unwanted output than a positive-recipe arm,
  and trended worse than no guidance at all; and "don't X unless it matters" only reopens the
  negotiation (superpowers, "writing-skills"). So reach for a table when the model knows-but-skips,
  never to shape an output.
- **Mind validation.** `name`/`description` are the only required keys; a key outside the documented
  set fails validation — check that set against the harness's reference, not against the frontmatter
  list above, which is the copy that goes stale. `name` must match `^[a-z0-9-]+$`, ≤64 chars, and
  equal the directory name.

## Ruling B — tier-routing is the anti-overkill law
Match effort to the task. A trivial change never triggers the full pipeline. The router
(`using-compound-v`) owns the tier table; every workflow skill respects it and routes *down* when
unsure. Overkill is a defect, not a safety margin.

## Ruling C — explain *why*, not all-caps MUSTs
Today's models have good theory-of-mind; a reason generalizes where a rigid rule overfits. Reserve
hard gates for documented failure modes (verification, design-before-code, root-cause-before-fix).
Everywhere else: give the reasoning and trust judgment. All-caps ALWAYS/NEVER is a yellow flag.

## Flowcharts — only when they earn it
Use a small graphviz `dot` flowchart ONLY for a non-obvious decision or a loop where the model might
stop too early. Conventions: `diamond` = question, `box` = verb-action, `octagon` = STOP,
`doublecircle` = entry/exit; label edges yes/no. **Never** put code, reference material, or linear
steps in a flowchart — use lists/tables/code blocks for those.

## Cross-referencing other skills
Refer by name with an explicit marker: `**REQUIRED:** Use compound-v:recheck`. Never use `@path`
links — they force-load the file and burn context before it's needed.

## The no-bullshit / no-overkill bar (apply to every skill before shipping)
- **Target is Opus 4.8.** Write for a model with strong theory-of-mind — do *not* pad for weaker
  ones. No Iron-Law liturgy, no rationalization tables, no all-caps reinforcement walls. And no
  mandatory pressure-test-before-every-edit gate: that ceremony would turn a one-line deepen into a
  multi-day exercise and break the kit's ship-in-hours discipline. Test a *new* skill or a risky
  change; don't gate every word. When you do test a load-bearing wording, do it cheaply: always
  include a **no-guidance control** (if the control doesn't exhibit the failure, there's nothing to
  fix — don't author the guidance), run **5+ reps** per variant (single samples lie), and treat
  **variance as the signal** — five different readings across five reps means the wording isn't
  binding yet.
- Every section answers: would a senior engineer be *worse off* without it? If not, cut it.
- No ceremony, no triple-reinforced rationalization walls, no dated "in session X we…" narratives,
  no motivational filler, no model cost-tiering (we run Opus 4.8).
- Estimate work in hours/days, never weeks/months — and never let a skill imply otherwise.
- Every claim of fact traces to a real source. The grounding map is `references/sources.md` — it
  maps each load-bearing numeric/factual claim to its public primary URL and marks the recipe-knob
  judgment calls that need none. If a number isn't in that map, add a row citing its primary source
  (a real URL) or cut it; if you can't ground it, mark it clearly as a judgment call.
- **A set that agrees with itself is not verified — anchor it outside the set.** Three files state
  the description cap. For this kit's entire life all three said **1024**, agreed perfectly with each
  other, and the harness uses that number nowhere: every description was trimmed against a cap 33%
  tighter than the real one, paid for in deleted trigger phrases. Mutual consistency makes *drift*
  visible and says nothing about *correctness*, so any constant repeated across files carries one
  external anchor named beside it — for the listing constants that is the harness's own docs page,
  cited in `references/skill-listing-budget.md`. `bash scripts/selftest.sh constants` fails when the
  copies disagree and fails when the external anchor stops being named; what it cannot do is tell
  you the anchor is still true, which is why the rule is to re-read the page rather than trust the
  green. The trap is that the green looks the same either way.
