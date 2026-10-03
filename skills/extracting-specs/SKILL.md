---
name: extracting-specs
description: Recover the real behavioral contract of unfamiliar or undocumented code — what callers actually rely on, not what the docs claim — as an explicit, checkable spec before you touch it. Use when onboarding or resuming a brownfield / inherited codebase, before changing, porting, or rewriting a module whose behavior is nowhere written down, or when a fresh session keeps re-deriving the same behavior from scratch — even if no one asks for a "spec." The backward complement to writing-prd; not for greenfield design (that's brainstorming / writing-prd) or code already specced.
---

# Extracting Specs

Before you change code you don't fully understand, write down what it *actually* does. The contract is what callers rely on, not what the comments claim — and an implicit contract you can't see is the one you'll silently break.

## When to use
- Onboarding or resuming a brownfield / inherited / long-untouched codebase where "what does this even do?" is the blocker.
- Before modifying a module whose behavior is nowhere written down — you need its contract to know what you must *not* break.
- A fresh session keeps re-deriving the same behavior from the code every time — the recomputation cost **compound-v:context-engineering** warns about; a recovered spec pays it once.
- **Skip it** when the code is already specced and the spec is trusted; when it's greenfield (design *forward* with **compound-v:brainstorming** / **compound-v:writing-prd** — you can't reverse a spec out of code that doesn't exist yet); or when it's a single file small enough to just read now. Route the effort via **compound-v:using-compound-v** — mine the one capability you're about to touch, never the whole repo.

## What a spec is here
A flat list of behavioral assertions, two kinds only:
- **Requirement** — a *triggered* behavior: WHEN ‹condition› THEN ‹observable outcome›. Carries at least one scenario.
- **Invariant** — something *always* true regardless of triggers: "an account's balance equals the sum of its transactions." No scenario.

No "API Contracts" / "Business Rules" / "State Machine" chapters — type-classification is noise a reader greps straight past. The only structure that matters is triggered-vs-always, plus machine-findable metadata: which **entities** the behavior touches and **where it's enforced** (`File.method()`). A Requirement with no enforcement anchor is a promise with no accountability.

```markdown
### Requirement: reject order when stock insufficient
<!-- entities: Order, Inventory --> <!-- enforced: OrderService.place() -->
WHEN an order's quantity exceeds available stock, THEN placement fails with INSUFFICIENT_STOCK and no inventory is decremented.

### Invariant: inventory never negative
<!-- entities: Inventory --> <!-- enforced: Inventory.decrement() -->
```

## The discipline (where this skill earns its keep)
1. **The contract is the callers, not the docs.** A function's docstring says it returns `User | null`, but every caller null-checks and treats null as "not found" — so the real Requirement is "returns the user; null when none exists." Cross-validate every claimed behavior against how it's actually *used*; when the docs and the callers disagree, the callers win. (Hyrum's Law: with enough consumers, every observable behavior is depended on by someone — the contract is the observed behavior, not the stated one.)
2. **Never invent behavior.** If the code doesn't clearly express a contract, record an explicit `<!-- uncertainty: … -->` note — do not manufacture a Requirement from a guess. A confident wrong spec is worse than an admitted gap, and a downstream agent will trust it as fact (same honesty bar as **compound-v:systematic-debugging**'s "say I don't know and go get evidence").
3. **Sample, then expand — don't read everything.** A 50-file module won't fit in context, and trying is the context-rot trap (**compound-v:context-engineering**). Read the entry surfaces first — routers, controllers, service facades, public signatures, and the test suite; they carry most of the behavior. Tests belong at the front because they encode the intent prose docs omit and are the densest source of the WHEN→THEN scenarios a Requirement needs, already written as executable callers. Two limits keep them honest: a suite the team doesn't genuinely treat as its source of truth pins today's bugs as contract, and a heavily mocked tier pins the call shape while hiding what the real dependency does — so lift the scenario from the test but anchor `enforced:` to the implementation, never to the test. For each behavior found, trace *one* level down its call chain to confirm it. Stop when the chain hits an external boundary (DB / HTTP / queue), three expanded files in a row add nothing new, or you've spent your budget (~15 files). List the files you didn't reach as explicitly deferred — silent omission reads as "fully covered."
4. **Flag, don't fix.** You're recovering the contract, not refactoring it. A bug or inconsistency you spot goes in an `uncertainty` note, not a same-breath fix — fixing while mining muddies what the *baseline* actually is. Pair the fix afterward via **compound-v:systematic-debugging**.
5. **Mine what you're about to touch, not the whole repo.** A spec that outpaces its usage rots, and a stale spec an agent trusts as fact is worse than none — the single-source, prune-on-a-cadence discipline of **compound-v:writing-prd**. Extract the capability the current task needs; defer the rest.
6. **The scars are the spec — hunt them on purpose.** Entry surfaces give you the happy path, and a contract recovered only from them is a clean lie. What a rewrite or a port actually loses is the accumulated small fixes, each one a branch someone added after an incident and nobody wrote down. So across the files you already opened in step 3 — not a fresh sweep of the repo — mark the code that looks like an *accident*: the special-cased input, the defensive clause guarding a state the types say cannot happen, the magic constant, the comment that only says don't remove this. Resolve each one with `git log -S '<the odd token>' -- <file>` or blame on that line rather than by judgment; where the introducing commit or PR names the incident, that yields a Requirement no entry surface would ever have shown you. An oddity you still cannot explain is either behavior someone paid for in production or dead code, and those have opposite treatments — record it as an `uncertainty` rather than leaving it unclassified, because quietly normalizing it is how the rewrite reintroduces the bug.
7. **Deadness is out-of-band — reading more code won't settle it.** Duplicate routes, two handlers differing only in name, two enum values for one state, a column that shadows another: the dead one compiles, has tests, and reads exactly like the live one, so tracing its call chain only re-confirms that it *exists*. When the mine turns up two paths that look equally valid, go outside the code for evidence of use — `git log` on each, the last write to the table, request counters or logs, who owns it — and record what you find as an assertion carrying its evidence: `Invariant: the <X> path is dead — no writes since <date>; traffic goes through <Y>`. If none of that is reachable and the call matters to the change, make the evidence rather than guess it: propose a log line or counter on the suspect path and read it after real traffic — Anthropic's daily dead-code routine on its own apps adds logging to suspected-dead code and removes it the next day only if the logging confirms it is dead. Until the reading is in, fall back to item 2: an `uncertainty` note naming both paths as live-candidates, never a deadness call you can't back. Nothing in the repo says which one is live, which is exactly why the next agent picks the dead branch with the same confidence you would have.

8. **The knowledge that never entered the repo is usually written down in support.** A behaviour the code cannot explain is often one the organisation has been living with: a known-bad path with a diagnosis playbook, an on-call note, a runbook step, a "if the customer reports X, do Y" macro. That is tacit knowledge already written down, in the one corpus a code-reading pass never opens, and for a feature whose authors have left it is often the only description that exists. So when item 6 leaves an oddity `git log` cannot resolve, or item 7 leaves a path whose usage evidence is out of reach, ask for the support and incident record for that capability before settling for an `uncertainty` note. **The trap: a playbook records the workaround, not the contract.** "Restart the worker when orders stick in PENDING" is evidence of a Requirement that is a *defect*, and lifting it verbatim pins the bug as behaviour the rewrite must preserve. Record what the playbook proves — that the behaviour occurs and that callers have adapted to it — with the playbook as its evidence, never the remedy as the rule.


## How it fits the kit
Forward, **compound-v:writing-prd** / **compound-v:writing-plans** capture what you're *building*; backward, this recovers what *already exists*. The output is fuel for what follows: **compound-v:writing-plans** modifies with the contract known, so its "don't break X" is grounded rather than guessed; **compound-v:systematic-debugging** gets a pinned definition of "what correct looks like" instead of chasing a drifting symptom; and **compound-v:test-driven-development** turns each scenario into a regression test. Record the result where **compound-v:writing-prd** says the product's truth lives — linked and single-source, not a second forking copy.

## Red flags
| Thought / behavior | What to do instead |
| --- | --- |
| "Let me read the whole module first." | Context blows before you finish. Sample the entry surfaces, expand one level, defer the rest. |
| "The docstring says it returns X." | The callers are the contract. Cross-validate; when they disagree, callers win. |
| "This probably does Y." | Never guess a Requirement. Record an `uncertainty` note and move on. |
| "I'll just fix this bug while I'm in here." | You're mining, not refactoring — flag it. Fixing mid-mine corrupts the baseline you're trying to capture. |
| "Let me spec the entire repo." | Specs that outpace usage rot. Mine the capability you're about to touch. |
| Chapters like "## Business Rules" / "## API Contracts" | Flat Requirement/Invariant list. Classification is noise; the metadata (`entities`, `enforced`) is the signal. |
| "These two routes look identical — I'll spec both." / "Let me read further to see which is live." | Reading deeper only proves the dead one exists. Get usage evidence outside the code (`git log`, last write, traffic), and record deadness with that evidence attached — or an `uncertainty` note if you can't reach it. |
