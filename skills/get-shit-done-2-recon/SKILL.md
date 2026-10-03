---
name: get-shit-done-2-recon
description: 'Stage 2 of compound-v:get-shit-done — recon each slice to a shape, its trap and its delete list. Invoked by get-shit-done.'
---

# Get Shit Done — 2 · Recon

Stage 2 of **compound-v:get-shit-done**, which holds the ledger this stage writes against and the red flags every stage routes back to — if its body is not in your context (a new session, or after compaction), invoke it first. Needs `slices.json` — without it, invoke stage 1. When every slice has been looked up — a hit or a held shape written, a miss left for its build-time hunt — invoke **compound-v:get-shit-done-3-build**.

## Stage 2 — Recon: one question, and the answer is a shape

**Ask one question per slice, and make it this one:** *what is the simplest thing that has actually shipped for this, and what did it cost the people who shipped it?* An open question over a good corpus returns mostly restatement — it is the question, not the number of lanes, that makes recon expensive.

**The output is a decision, not a report — and it lands in `slices.json` or it did not happen.** Name the **shape** (the architecture someone experienced would reach for), its **trap** (the second-order cost invisible on day one), and what the shape lets you **delete** — these land as slice fields in **references/completion-ledger.md** (which carries a fourth, `force`, for what the plan did not name), and a shape left in the conversation dies with the session. Shape-and-trap is the whole reason the corpus exists: an agent has read more code than any of us and has none of the scar tissue. The mechanism climb and the Simple/effective/scalable test are **compound-v:simplest-thing-that-works**; the API-level pattern is **compound-v:searching-patterns**.

This stage is **compound-v:gathering-context** applied to one slice — its slots 3 and 4, the
candidate-shapes-and-trap and the DELETE list. A slice usually has one arrangement worth taking, which
is why this stage is written in the singular; where it genuinely has two, carry the one you rejected
and the reason it lost, so the next session cannot reopen a question this one already closed. Invoke that skill when the slice needs the other four
slots too (constraints you cannot infer, how it must NOT be done, what "done" means, what is
still unknown); stay here when the shape is the whole question.

**Look the shape up before you research it.** **references/shapes.md** carries curated arrangement-plus-trap pairs, and a hit *is* the whole of recon for that slice. On a miss, run **`bash scripts/alpha.sh "<the slice's unknown>"`** — one command sweeps every verified lane (talks, arXiv, exemplar repos, engineering blogs, practitioners) and returns a shortlist of pointers for a few seconds and zero tokens. Read the shortlist; do not read everything. Judge whatever comes back against **references/corroboration.md** — count distinct sources, not findings, and where two top sources conflict, name the axis and keep both. It is a cache with a miss path, so most slices miss and a miss is the rule working. On a miss you get **one hunt, scoped to that one domain**, at build time, never a standing sweep. The budget is the `confidence` stage 1 wrote down:

| `confidence` | what recon costs |
|---|---|
| ~95% — *no unforeseen difficulties* | nothing. Write the shape you already hold. |
| ~90% — *modulo Murphy's law* | the lookup only; on a miss, write what you know and move. |
| ~65% — *the basic path, and the steps should work* | one lane, the one question, one pass. |
| ~30% — *a murky view of the path* | the full ladder — three channels cheapest-first, **references/prior-art.md**. |

When the hunt dispatches an agent, its brief is **references/prior-art.md**'s dispatch block, pasted verbatim. That file also owns how to read a corpus — enumerate lanes live, a local library is several lanes, `MUST`/`STRONG`/`OPTIONAL` sets **order, not inclusion** — which is context the dispatch block itself does not carry, so hand the worker both. If the environment ships a corpus-investigation skill (`workflow-investigation` is one), invoke it rather than re-deriving where things live.

**The band is a pre-investigation guess, so an observable signal can overturn it** — a shape-table miss on a slice you banded ~0.9, or a first read contradicting its `unknown`. Re-band once, out loud, in the ledger, and **the legal revision is upward in recon** — which on this table means *downward in confidence*, from ~0.9 toward ~0.65 and its extra lane. Re-banding the other way mid-hunt, to buy yourself less work and an earlier stop, is the same move as editing a check to make it pass. Both failures are live and opposite — the measured sweeps over-researched what was known, while the one real ledger skipped recon on exactly the slices that needed it.

**Stop when you can name the shape and its trap, or when two independent sources converge** — not when the lanes are exhausted, and never on a source's grade. A lane at zero is a defect you justify, not a gap you pass over. **An empty `delete` is a red flag, not a clean bill**: write `[]`, never nothing.

**Recon returns a file:line map, not prose** — a cited line either exists or it does not, where a confidently hallucinated architecture reads exactly like a real one. Feed it forward: the shape into the plan, the trap into **compound-v:recheck** as a named checkable assertion, all three into the ledger. At Reckon, a shape that will recur graduates into the table — **compound-v:finishing** step 2.5 runs that harvest and **references/shapes.md** carries the admission bar. Harvest the trap, not the win: most runs graduate nothing, which is the bar working.

**Next:** after the pass over every slice, in an attended run the Carve+Recon approval, then **compound-v:get-shit-done-3-build** for the first slice; after a build-time hunt, straight back to **compound-v:get-shit-done-3-build** for that slice.
