# The completion ledger — making the last 10% impossible to lose

Operational detail for **compound-v:get-shit-done**. The skill states the four rules; this is how to
run them. Read it when you open a ledger, and again at the final gate.

The failure it exists to prevent is specific, and it is the normal outcome rather than a rare one: a
run ends with most of the declared functionality built, everything that got built working, and nobody
able to name what is missing. Nothing lied. The missing items were simply never anywhere a check
could look at them.

Be precise about what this buys, because the overclaim is easy: the ledger does not make undone work
doable. It withholds the done verdict and forces the remainder to be named and attributed. Whether
the named remainder then gets built or explicitly cut is a judgment you now have to make out loud
instead of one that gets made silently by forgetting.

## The done rule

> **Every declared row is `passed` or `dropped`-with-attribution. Nothing may remain `todo` or
> `building` at the verdict, and `blocked` is not success.**

You reach 100% by passing a row or by cutting it out loud with a name attached — never by forgetting
it. This is what makes "we're at 90%" unsayable: the ledger either names the other 10% and who
dropped each one, or the run is not finished.

## The slice — and where recon lands

A slice carries `id`, `capability`, `check`, `unknown`, `confidence` and its `rows`. Stage 2 adds
four more, and they are the only durable record that recon happened at all:

```json
{"id": "s2", "capability": "...", "check": "...", "unknown": "...", "confidence": 0.65,
 "shape": "mirror the provider's data locally, advanced by one durable cursor per account",
 "trap": "the cursor expires, so a full-resync path is a day-one requirement",
 "delete": ["per-rule API round trips — the mirror answers them", "our own retry queue — the page-loop is the retry"],
 "force":  [{"what": "an event-type filter filters but does not project; omit delete events and the mirror diverges silently"}],
 "rows": [...]}
```

**`shape` and `trap` are one thought, never one without the other.** A shape with no trap is a
diagram; the trap is the part only somebody who operated the thing would know, and it is the half
worth carrying to the next project. `trap` is also what **compound-v:recheck** receives as a named
checkable assertion, so a slice with a shape and no trap hands the review nothing.

**`delete` is a list and it may be empty — but empty must be written, not omitted.** `[]` says recon
looked for work to remove and found none; a missing key says nobody looked. The skill's rule is that
an empty DELETE is a red flag rather than a clean bill, and a red flag you cannot see is not one.
This is the only field in the ledger that measures whether research made the build *smaller*.

**Why these four and not more.** The bar here is set by two fields this document already cut —
`steps` and the five-value `from` enum — both specified, both written zero times, both removed with
the same reasoning: *one field that gets written beats two where the second is a rule nobody
enforces.* These four clear that bar on evidence rather than on intent. In the only field ledger
that exists, `shape`, `trap` and `delete` appear **zero** times across four slices while stage 2 ran
and cost real tokens, so its entire output died with the session — and `force` was written on the
two slices at confidence `0.9` and skipped on both at `0.65`, which is the rule exactly inverted.
They also differ from the cut pair in the way that matters: `steps` duplicated `does` + `evidence`
and `from` duplicated `discovered: true`, whereas nothing else in the ledger carries an architecture
or its cost. **And they have a reader** — `ledger-extract.jq` warns when a slice below `0.7`
confidence carries no `shape`, which is the enforcement `steps` never had.

It warns rather than refuses, for the same reason untyped drops warn: requiring the key outright
would brick every ledger written before it existed.

## The row

Nest rows under their slice in `.claude/slices.json`. A row is one thing a user can do, phrased so a
person could attempt it — not "auth works" but "a signed-out visitor who submits a valid login lands
on the dashboard".

```json
{"id": "s2-f07",
 "does": "a signed-out visitor who submits a valid login lands on the dashboard showing their name",
 "status": "todo",
 "evidence": null,
 "attempts": [{"what": "raised the gateway timeout to 60s", "result": "still timed out on the 4GB account"}]}
```

**`attempts` is where a failed try lives before a row is `blocked`, and it is what both three-strike
caps count.** Append at any status; never overwrite. Without it a row with two failed attempts is
still `todo` and reads as untouched, so the next session inherits it and reaches for the approach
that already failed — which is the precise failure the ledger exists to defeat, since *"compaction
isn't sufficient"* to carry that history in context. It is also the evidence a `blocked` row owes
(the attempt count, the named blocker, the evidence per attempt) and the input to
**compound-v:get-shit-done-3-build**'s repair-or-replace call, whose trigger is the third patch onto one
shape. Appending to it is a legal write; editing an earlier entry is not.

**`does` is a witness case, not a title.** One concrete situation with an input and an observable outcome, so a person who was not there can attempt it and disagree with the result. *"auth works"* is not a row; *"a signed-out visitor who submits a valid login lands on the dashboard showing their name"* is. A separate `steps` array was specified here for one revision and cut: in the only real run this has had, it was filled on 0 of 19 rows and read by no code, while `does` plus `evidence` carried the whole thing. One field that gets written beats two where the second is a rule nobody enforces.

**`status` is a closed set of exactly five words — `todo` · `building` · `passed` · `dropped` ·
`blocked` — and anything else counts as OPEN.** Not as an error to shrug at: a row whose status is
`done`, `in_progress`, `Passed`, `" todo "`, `null`, or missing is an unbuilt row hiding from both
counters, and treating it as absent is how a ledger reports 93% on unfinished work. The same goes
for a row that is not an object, a duplicate row id, and status buckets that do not sum to the row
count. An unreadable ledger resolves toward open, never toward done — the audit command refuses to
print a number at all in those cases, because a number that does not add up is worse than none.

A row found during the build carries **`discovered: true`** — that one bit is what the scope delta reads, and it is the shape the field actually writes. (A five-value `from` enum was specified and cut: it was never written once, so the delta reported `discovered +0` on a run that discovered two rows and traced them to production.) A passed row also carries a
**`discharge`** target — the thing that outlives this file — in exactly one of three forms:
`{"rerun": "<command>"}` for anything re-runnable, `{"observable": "...", "query": "..."}` for
behaviour only production can show you, or `{"owner": "...", "check": "..."}` for a judgement only a
named person can make. `bash scripts/ledger.sh --discharge` refuses the landing while any passed row
has none. `evidence` on a passed row is
`{"how": "<what you actually ran or drove>"}` — one line a third party could repeat, and it is the
part people skip: a walk a stranger can repeat is checkable, and a row without one degrades into a
vibe within two sessions.

## R1 — The denominator: rows come from three places, and the third is where the 10% hides

Write every row before any code. Harvest from the PRD or brief, then the plan, then — continuously —
whatever the build discovers. A requirement with no row is invisible to every downstream check, and
the gate cannot miss what it cannot see.

**Cross-check the two directions.** Every requirement must map to at least one row, and every row to
at least one slice. A requirement with zero rows is scope nobody was assigned — the single largest
source of the missing 10%, because it never looked like it was failing; it never looked like
anything. GitHub's spec-kit builds the same cross-check into its `analyze` step and treats an
unmapped requirement as blocking. Do the same.

## R2 — The flip: what it costs to turn a row green

Three conditions, all of them:

1. **The check failed against nothing first.** Before the implementation exists, run the row's steps
   and confirm they fail. A check that passes against an empty implementation measures zero, and a
   ledger full of those is precisely 90% wearing a checkmark. This is
   **compound-v:test-driven-development**'s red step applied to the ledger, and it is the cheapest
   high-value gate on this page — **including the half of that step people drop: the red has to fail
   for the right reason.** A run that fails because the route does not exist yet is guaranteed and
   tells you nothing about whether the check measures the property. **When the agent wrote the check
   as well as the code, use the mutation form:** run the check against the real implementation and
   again with the body of the thing under test replaced by a no-op stub, and require pass-then-fail.
   The measured dominant failure of agent-written tests is assertions that are trivially true on a
   stubbed implementation — the check covers the function and cannot tell whether it does anything.
   A check that passes both ways is not a check; rewrite it to assert observable post-state. So for the row classes where the
   check binds weakest to the implementation — a latency budget, an authz property, a refactor with
   no behavior change — and for any row guarding behavior that already exists, use the other form:
   break the thing on purpose and confirm the check notices.
2. **An observed end-to-end run, driven the way a user would.** Not the unit test, not `curl`.
   Anthropic's harness work found a frontier model would make the change, run unit tests, hit the dev
   server, and still not notice that *"the feature didn’t work end-to-end"*; the fix was driving it
   *"as a human user would"*.
3. **Evidence recorded** — one line naming what you actually ran or drove, so a third party can
   repeat it. *Not* a commit sha. An earlier version of this rule required one and treated any row
   behind `HEAD` as unverified, which has no fixed point: the commit that records the evidence
   advances `HEAD` past every sha it just wrote, so the whole denominator is stale the instant it is
   written. Decay is still real — a row that passed in slice 3 is routinely broken by slice 9 — and
   it is already caught by the slice-open re-run in the build loop, which drives the previous slices
   before a new one starts. A pass→fail there is a hard stop, not a re-flip.

**Decide which rows a human must flip, explicitly — and select them by irreversibility, not by
taste.** Every other mechanism on this page is an agent checking an agent, which closes some of the
loop and not all of it. But a human gate placed on "does this feel right" makes the reviewer the
bottleneck and buys little; placed on the action boundary — money moving, data deleted, something
sent, a migration run — it is the only thing that works. Mark those rows in the ledger, and give the
person the row's steps to check rather than a request to approve, or you have added a signature and
not a gate. The same axis **compound-v:make-it-stable** already draws.

## The floor: a capability with no passing row did not ship

The aggregate cannot see a dead capability. Rows are not spread evenly across slices, so one that
delivered nothing disappears into a healthy-looking percentage — observed in the field at 89% with
one of four capabilities at zero. So the report is **per capability first, aggregate second**, and a
slice with open rows and no passing row is named as the open item rather than leaving its rows to
speak for it. Two exclusions, each earned: a slice whose rows were *all* dropped was cut, and the
attribution on those drops covers it; and a slice whose only unresolved rows are `blocked` must not
hold the stop, or the floor wedges the run on the one thing it cannot do.

## R3 — The delta: scope moves, and it must move visibly

Appending a row is **always** legal; flipping one is not. The moment the build discovers a
requirement, it enters at `todo` with `discovered: true` — not at the end, when it will be forgotten
or quietly absorbed. Dropping a row requires a reason, a name, and a **kind**:

- **`void`** — the requirement does not exist in the world (the field it needed is not there). The
  capability legitimately shrinks and nothing is owed.
- **`moved`** — the requirement still exists and changed shape (*"reply in DMs instead of the
  thread"*). A successor is mandatory: `replaced_by` must name a row present in this ledger, and a
  `moved` drop that names none fails validation.

That distinction came from three real drops. The two that named a successor left healthy
capabilities; the one that named none emptied its capability while the percentage stayed green.

The gate reports the movement, not just the total:

```
declared 41 · discovered +7 · dropped −3 (named) · passed 45 · blocked 0 · todo 0  → 100%
```

A third party can see the denominator moved and why. A run whose denominator only ever shrinks is
one to distrust.

**Report the delta; never report a saving.** The line above counts things that exist — rows declared,
discovered, dropped by name, passed. A saving does not: *"this approach saved ~400 lines"* or *"cut
two days of work"* subtracts from a version that was never built, so there is no baseline anywhere in
the world and the figure is manufactured by the sentence printing it. The pull is strongest exactly
at the verdict, where a counted artifact feels thinner than an impressive number, and the only
durable answer is to have the counted artifact already in hand — this delta line, the per-capability
report above it, the marker harvest below — and to say the counterfactual was not measured. It is
*compute coverage, never assert it* applied to the one number that cannot be computed at all: **if
you cannot name what the figure is subtracted from, do not print it.**


## R4 — Blocked is not success, and not a resting place

A row that has failed its check three times becomes
`blocked` with the attempt count, the named blocker, and the evidence per attempt. Hand the diagnosis
to **compound-v:systematic-debugging**, whose attempt cap this shares, and escalate — to the human
when there is one, into the verdict when there is not.

This rule is not bookkeeping. A two-state ledger makes a genuinely impossible row look exactly like
an untouched one, so triage is impossible; and an agent facing an unpassable row under a keep-going
instruction has one move left, which is to rationalise a flip. Give the run a legal way to say *this
one did not work and here is why* and it stops needing an illegal one.

## The shortcut inside a passed row — mark it where a grep can find it

**A row can pass on an implementation that cut a real corner, and this ledger has no slot for that.**
`dropped` covers a requirement you cut; `delete` covers work recon removed before anyone built it.
Neither covers the global lock or the naive heuristic you shipped *on purpose* inside a row that is
green and staying green.

So mark it in the code at the moment you cut it, in a form a grep can harvest: a comment carrying
the fixed token `ceiling:`, the limit, and the condition that would end it — written as
`ceiling: global lock, per-account locks if throughput matters` behind your language's comment
marker. `scripts/check.sh` harvests them and counts two scalars: markers, and markers naming no
condition. The token is not `deferred:` because **compound-v:writing-plans** already owns
`Deferred:` for work deliberately *not built*, and the two meanings must not share a grep.

**The trap, and it is the reason to report the counts rather than act on them.** A searchable debt
ledger makes deferring cheap and *legitimate*, so markers accumulate faster than anyone retires
them, and a repo can carry a clean-looking ledger of triggered deferrals not one of which has ever
fired. Whether a stated trigger is ever noticed when its condition arrives is measured by nobody,
here or in the source this is taken from. Report the two scalars; never report them as health.

## Integrity — the agent must not be able to edit what grades it

**The only legal write to the ledger is a status flip plus its evidence.** Any other diff to a row,
its steps, or a check the ledger depends on voids the run's completion claim until a human reviews
it. Treat a check-file change in the same diff as its implementation the way you would treat a test
weakened to go green.

This is not hypothetical caution. Anthropic's own reward-tampering work found that models trained on
progressively gameable environments generalize to *directly rewriting their own reward function* —
so a grader living inside the agent's own write scope is not a grader. Where it matters, keep the
authoritative check outside the working tree and apply it after the run — the same reason a graded
coding benchmark does not ship its tests inside the workspace it hands the model.

**Compute coverage; never assert it.** The completion fraction should come from a command anyone can
re-run against the ledger, exiting non-zero while any row is `todo`, `building` or `blocked`. A
number a person can recompute is a measurement; a number in a summary is a claim.

## The cost, and the grain that fits the run

This machinery is not free, and the honest read of the evidence is that its *content* is endorsed
while its *volume* is indicted. OpenAI's own prompting guidance for its coding harness says to
*"Start with the smallest prompt and tool set that passes your evals. Add an instruction, example, or
tool only when it fixes a measured failure mode"*, and its trim list names *"process instructions for
behavior the model already performs reliably"* — while its keep list retains *"success criteria and
stopping conditions"*, which is exactly what a row is. Practitioners who have benchmarked
spec-driven kits report that many of them make agents measurably worse by over-specifying. So: every
rule on this page should be here because it closes a failure you have actually seen, and a rule you
cannot name a failure for should go.

**The grain scales with the run.** A single-turn task gets no ledger at all — one shipped coding
harness skips its planning tool entirely for *"roughly the easiest 25%"* of tasks and keeps only a
short, deliberately non-persisted checklist for the rest, with one durable objective per thread. The
row ledger is for the other thing: a multi-session build of a product whose scope was declared in
advance and will otherwise be quietly forgotten. If you cannot say which declared function a row
belongs to, you are writing tasks, not rows, and the ledger has started measuring the wrong thing.

## What this does not fix — say so rather than implying otherwise

- **An incomplete spec.** No ledger invents a requirement nobody wrote. It makes the *known*
  denominator honest and visible; it cannot make it complete.
- **A row set that measures the wrong property — partly.** One row per slice carries the slice's own
  check (`is_check: true`), and `--discharge` refuses a landing where a slice never turned its check
  into a row. It forces the question *what would show this goal unmet* to be
  asked once per capability, which is the part that adapts: a behaviour goal is read by a run, a
  replication goal by a comparison to its source, a property goal by an adversarial probe, a removal
  goal by absence, a migration by parity. The reference case is where it was first caught — 135 rows
  passed and every page wrong, each row true about the target and none a comparison to the source —
  but the mechanism is not about references. What it does not close is a check-row that is itself weak:
  the mechanism guarantees the question gets *asked*, never that it was asked well.
- **A weak check — partly.** R2's fail-against-nothing catches a check that measures zero. It does
  not catch one that measures one narrow path of five. The available counter is an inverted
  diagnostic at the end: **if every row is green and the outcome is still bad, the row set is wrong**
  — and that is the author's failure, not the run's. Do not respond by re-litigating the rows that
  passed; respond by asking what a user did that no row describes.
- **Portfolio judgment.** In research, stopping at 90% of a mediocre line of work is often correct —
  impact is distributed such that the last tenth of a weak project loses to the first tenth of a
  strong one. That reasoning is sound where scope is a hypothesis and wrong where scope is a
  commitment. A PRD is a commitment. Abandonment is still legal here, but only as an explicit
  `dropped` row with a name on it — never as a fade.

## Red flags

| Smell | What it means |
|---|---|
| The ledger has slices but no rows | The denominator is 5 when it should be 200. Nothing at slice grain can find a missing function. |
| A row went green and its check was never seen red | It may measure nothing. Run it against the unimplemented state, or break the thing and confirm it notices. |
| Rows only ever get deleted, never appended | Scope discovered mid-run is being absorbed silently. Every build discovers something. |
| A row reads "auth works" | Not a row. No numbered steps means nobody but the author can check it. |
| The completion number appears in prose but no command prints it | Asserted, not computed. Anyone re-running it should get the same number. |
| The same diff touches a row's steps and its implementation | The grader moved. Freeze the steps or get a human to review the change. |
| Everything is `passed`, nothing was ever `blocked` | On a real build, suspect the flip rule rather than celebrating. |

| A shortcut is described in the summary or the handoff, but not marked in the code | Prose does not survive a grep or a new session. The ceiling and the trigger belong on the line that cut the corner; anywhere else and the deferral is permanent by default, which nobody chose. |
| The report names a saving — lines avoided, days saved, work not done | A version that was never built has no line count. Print the delta, the per-capability table and the marker harvest; say the counterfactual was unmeasured. |

