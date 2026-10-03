---
name: get-shit-done-4-reckon
description: 'Stage 4 of compound-v:get-shit-done — hold the assembled product to the MEP bar and return one verdict. Invoked by get-shit-done.'
---

# Get Shit Done — 4 · Reckon

Stage 4 of **compound-v:get-shit-done**, which holds the ledger this stage writes against and the red flags every stage routes back to — if its body is not in your context (a new session, or after compaction), invoke it first. Runs once every slice has landed, or standalone when the ask is whether a run is actually done.

## Stage 4 — Reckon: the MEP bar over the assembled product

Put the goal beside what exists and say plainly how much is real — including *"we have been busy for six hours and the product is not closer to a user."* The bar is **MEP, the minimum evolvable product**: it survived contact with a real person, and the next change is one you can afford. *Viable* is a bar an agent clears by writing code that runs, which is what produced that six-hour run.

**Afford is priced in migrations, not in retyping.** A next change that forces you to rebuild a component is a Tuesday; one that forces you to migrate accumulated data, or a published surface others depend on, is the thing to have avoided. Only the second is a defect in what you shipped.

**100% is over a declared denominator, never over every axis.** Every row you *declared*, passed or dropped with a name on it — not every requirement anyone could name. The second target does not ship: against a list running reliability, harmlessness, factual consistency, usefulness, scalability, cost, security, privacy and fairness, the verdict is *“If we try to tackle all these requirements at once, we’re never going to ship anything”*. So choose the denominator at Carve, put the rest into `notSlices` with a name against it, then finish **all** of what remains. A run measuring itself against every axis it can imagine is at 80% forever, its missing 20% undeclared rather than unbuilt.

Four checks against the assembled system; **references/mep-gate.md** carries how. **Alignment** — does it still answer the ask, and what exists nobody asked for. **Reachability** — walk every capability end to end on an input you did not construct, then cold-start it. **Survival** — who used it who did not build it, on a clean artifact. **Evolvability** — the two likeliest next changes, and what each forces.

The **clamp**: a finding blocks only if it names a real user blocked from a capability the goal asked for, or a next change that forces a migration you cannot afford.

### The verdict — one word, then the next action

- **DONE** — every capability the goal named is reachable on the assembled product, the survival bar for this ask was met on a clean artifact, and neither next change forces a migration you cannot afford.
- **DONE WITH GAPS** — every goal capability reachable, survival bar met, gaps named and counted in the same breath. It ships; the gaps return at the next finish.
- **UNPROVEN** — built, complete, green, and nobody outside the build has touched it. The remaining work is finding the first user, not more code.
- **NOT_DONE** — the default. Return the remaining work as addable tasks: which capability, which path, what would close it.
- **DRIFTED** — what exists is no longer what was asked for. Route back to the original ask, not to the plan.

A hand-off is not a verdict: "pushed", "PR opened", "ready for review" are all stopping while work is open, and manual steps handed back to the user are unfinished work relabelled. **The next action is the one that closes the biggest gap to MEP, not the most comfortable one** — name the gap, name the comfortable alternative, and say why you are not doing it.

**Discharge before the landing commit** — the ledger goes, but never undischarged: every passed row first names a durable target that outlives the file, and an incident opens a row before it opens a fix. `bash scripts/ledger.sh --discharge` refuses the landing until that holds.

**Next:** the one action the verdict names. Remaining work returns as rows, and an incident re-enters at **compound-v:get-shit-done-1-carve**.
