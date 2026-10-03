---
name: searching-patterns
description: Read the real source before writing code against a dependency — the installed copy first, then the canonical pattern and its matching anti-pattern at your locked version. Use before writing against any library, API, framework or SDK; when coding a third-party endpoint, price or response shape from a spec, PRD, ticket or memory rather than its current docs; on any silent-wrongness surface where the wrong version compiles and passes — auth, secrets, retries, concurrency, idempotency, money, SQL, path handling, deserialization, an optional parameter whose default moved; when unsure how a framework wants something done or which major you are on; when picking between libraries; or to confirm a best practice during review — even if nobody asks. Run scripts/stack.sh to resolve the stack and its versions. Skip the external lookup for a loop, a standard-library call, or a shape the repo already demonstrates.
---

# Searching Patterns

This fires at the moment you write the line. **compound-v:gathering-context** fires before the design exists and answers a different question — *what must be true of this whole build* — so a pack from it is the input to this, not a substitute for it.

Before writing something you're not sure about, find how it's *actually* done now — then carry back both the canonical pattern and the anti-pattern it replaces. Models confidently generate plausible-but-wrong or outdated API usage; a 60-second lookup against primary sources prevents a class of bugs and a round of review churn.

## When to search (and when not)

**The cheap rung is not optional, and it is not a search.** Before writing against any dependency,
read the copy on disk — `node_modules/<lib>` and its `.d.ts`, `site-packages/<pkg>`, the vendored
source — plus the shape the repo already uses. That costs one `grep`, no network, and it survives a
sandboxed run. There is no confidence level at which skipping it is correct, because it is not
buying you a probability, it is reading the contract you are actually compiling against.
`scripts/stack.sh` does the first half for you — resolve it against the kit root (`${CLAUDE_PLUGIN_ROOT}/scripts/stack.sh`, or two levels up from this skill's base directory), not against the project you are standing in.

**The expensive rung — the external lookup — is scoped, and the scoping is the whole discipline.**
The naive rule ("look it up whenever you're unsure") is what turns a reflex into a tax. The reason
to scope it is *not* that an agent cannot recover from a mistake: when an API **raises**, the
error-driven loop usually works and the task completes. What that loop cannot cover is the class of
mistakes that **never raise**. So spend the external lookup on the silent-wrongness surfaces:

- **The API accepts it and does something else.** An optional parameter whose default changed, a
  semantic that moved between majors without a signature change, a flag that is now a no-op. Nothing
  errors and nothing is right.
- **Auth, secrets, deserialization, SSRF, path handling, SQL.** The wrong-but-plausible version
  compiles, passes, and is a vulnerability rather than a nit.
- **Money, retries, concurrency, idempotency.** A double-charge does not raise. Neither does a race
  that only shows up under load.
- **Any third-party SaaS/API client** — pricing, endpoints, response shape, auth headers — fetched at
  implementation time. A prior spec, PRD, design doc or earlier memory is an **input, never the
  authoritative reference**; a stale internal spec is a trap masquerading as a source, and it will
  send you to confidently code last quarter's endpoint.
- **Confirming a best practice during review** — when you flag "this isn't how X is done," verify it
  instead of asserting it.

**And the output of the lookup is the page at your installed version, not the fact that you looked.**
Comparing the two version numbers is the point: where the docs render a different major than the
lockfile holds, *that mismatch is the finding*, and it is the single most common source of
confidently-wrong generated code. A lookup that returns "I read the docs" without a version stamp did
not run.

Below that bar — a loop, a standard-library call, basic string handling, a well-trodden shape the
repo already demonstrates — write it from memory and let the compiler and the tests raise. Spending a
network round trip there is the overkill this kit treats as a defect.

**And stop when you have the answer, not when the sources are exhausted.** The stop condition is: *you can name the pattern and its anti-pattern*, or *two independent primary sources converge on the same one*. Everything past that is restatement, and restatement is where a lookup quietly turns into a research project — a broad question over a good corpus returns mostly the same finding in different words, so it is the **question**, not the number of sources, that decides what a lookup costs. Ask one question that names the decision it will settle; if you cannot state it in a sentence, you are not ready to search yet. This is the same instinct as catching an agent's architectural dead end early rather than nitpicking lines.

## How: read the primary source

The default tools need zero setup. Reach for the heaviest one that fits, lightest first:

- **Check the local convention first.** If the repo already has an established shape for this — a house wrapper, an AGENTS.md/CLAUDE.md rule, a pattern in neighboring files — that overrides the external canonical one. Match the local shape; don't import a clashing "correct" pattern. Only reach outward when the repo has no precedent. Preserve an existing design system's established patterns rather than replacing them.
- **The copy you actually installed** — `node_modules/<lib>` and its `.d.ts`, `site-packages/<pkg>`, the vendored source. It *is* the API contract, it is version-exact by construction (a lockfile-vs-docs mismatch is impossible), and it costs one `grep` with no network — which is also why it is the only rung that survives a sandboxed run. Read it first when the question is a signature, a parameter, an enum, an error class or a default; go outward when the question is *why* or how the pieces are meant to compose, which types don't carry.
- **A docs-MCP server** (context7-style `resolve-library-id` + `query-docs`), *when one is available* — the lightest step for library/framework docs: it returns the current, version-pinned API surface without you hunting a URL. Prefer it ahead of `WebSearch`/`WebFetch`; fall through to those when no such server is wired up.
- **`WebSearch`** — find the current canonical page when you don't have the URL ("`<lib> <version>` retry middleware docs").
- **`WebFetch`** — read one known page (a docs section, a guide). The common case.
- **`gh`** — read the upstream repo directly: `gh api` for file contents, releases, or the `CHANGELOG`. **Do not reach for `gh search code`** — it returns `[]` without the right token scope, and an empty result is indistinguishable from "no prior art exists" (probed: `--repo facebook/react "useState"` → `[]`). To search a repo's contents, use `scripts/exemplar.sh grep`, which sparse-checkouts the subtree and greps it locally. This is how you reach the *real* source and private/authed pages — pin it to the tag in your lockfile, because the default branch is HEAD, not the version you're running.

Prefer the library's own repo and docs over blog posts and forum answers — primary sources outrank secondary ones. **Pin the version**: default docs often render an older major than you're on, so read the docs for the version in your lockfile and note which version the pattern applies to. And don't stop at the first hit — the top search result is often a stale major or an SEO blog, so run a second query with different wording and prefer the result that matches your lockfile version. (Look past the first seemingly relevant result; run multiple searches with different wording, and include version numbers in technical queries.)

**Before you quote a vendor page, check whether the vendor has retracted it in place.** Frontier-lab
documentation is revised under its original URL, so the link still resolves, the page still reads as
current, and the recommendation you are about to repeat may already carry a banner deprecating it.
Anthropic's think-tool page now opens under the heading **Extended thinking update, Dec 15, 2025**
with *"Extended thinking capabilities have improved since its initial release, such that we recommend
using that feature instead of a dedicated think tool in most cases"*; *Building effective agents*
opens with *"Much of the tooling landscape described in this post has changed since December 2024"*.
Both were fetched live on 2026-09-07 and both still answer at the URLs everyone cites. So make it an
operation rather than a habit: fetch the page **this session**, read its head for a revision or
deprecation block before you extract anything, and record the banner's date beside the quote. A
cached read, a search digest or a remembered page cannot see a banner that appeared after you last
looked — which is the version-pinning rule one level up, because the version you are on is right and
the advice has still expired.

**The retraction is usually partial, and that is why nobody catches it.** That agents page still
carries the workflow taxonomy this kit cites it for, while the tooling half the banner names has been
rewritten under it — the live framework list is Claude Agent SDK, AWS Strands, Rivet and Vellum. A
reader who spot-checks the half they remember confirms the page and carries the expired half out with
it. Count your own exposure the same way — every citation you hold of a
partially-retracted page, checked against the half the banner names — and expect most to survive:
that is the check working, not an exemption from running it.

**And where a vendor publishes guidance about its own model, the artifact it SHIPS outranks the
guide.** The prompt in its own cookbook, plugin manifest or client bundle is what the vendor's
engineers actually run; the guide is what they recommend, and the two drift. Diff them and *the
divergence is the finding* — the same move as reading the installed copy over the docs, one rung up.
The trap: a shipped prompt is scaffolding scoped to one model generation and expires without saying
so, so carry the divergence rather than the artifact, and give any shipped-prompt finding an
`applies:` that names a model version and keeps it short.


When the thing you're implementing ships an **official conformance suite** — a protocol, a wire format, a standard's test vectors — that suite *is* the primary source: precise, executable, and it doesn't drift the way prose docs do. Point the implementer at it and write code until those tests pass (e.g. WebAssembly's spec test suite).

### Resolve the exemplar for the stack in front of you — by running it, not by reading a table

For the stack you are actually on, go straight to its **canonical exemplar**: the **maintainer's own** docs/examples (they track the version; a blog doesn't), or a **large, actively-maintained real codebase** using it in anger.

**Run the kit's `scripts/stack.sh [dir]`** (resolve it against the kit root, per the router). It reads the manifest and the *installed* tree, prints each recognised dependency at the version **actually on disk**, and names where that library's canonical pattern lives. Then it prints the read-order below. Only its output costs context; the script itself never enters the window.

This used to be a four-row table, and the table is why it is now a script. The table asserted that a referenced skill carried "70 perf rules"; the installed copy has **64**. A hardcoded count in a shipped file is a claim that decays silently — the same defect this skill's own no-index rule warns about, committed by this skill. A lockfile read at call time cannot rot, because it is not a memory of the answer, it is the answer.

Three things the script gives you that a table structurally cannot:

- **Installed, not declared.** `package.json` says what someone asked for; the lockfile and `node_modules` say what you will actually run. Only the second can be wrong in a way the docs will never mention.
- **The version-drift finding.** Where the docs render a different major than you have installed, *that mismatch is itself the finding* — it is the single most common source of confidently-wrong generated code, and it is invisible unless you compare the two numbers.
- **The long tail, honestly.** A stack with no row is the rule working, not a gap: the script says so and falls through to the read-order, where "the installed copy, then the maintainer's docs, never a blog" already covers it.

### When the question is a SHAPE, read a codebase that lives with it

Docs tell you the signature. They do not tell you what an experienced team reaches for, and that is
the question an agent is weakest on — it has read more code than any of us and has paid for none of
it. For that, read a large project that has run this in production, **at a pinned release**:

```
bash scripts/exemplar.sh list                                    # the registry and what each is FOR
bash scripts/exemplar.sh grep calcom/cal.com packages/trpc "middleware|protectedProcedure"
bash scripts/exemplar.sh read calcom/cal.com packages/trpc/server/procedures/authedProcedure.ts
```

`grep` sparse-checkouts just that subtree — a 48k-star monorepo becomes a few hundred files — and
`read` pulls one file at the resolved release. **references/exemplars.tsv** carries the registry:
which repo is the exemplar for which stack, and which subtree to open.

**Your stack is probably not in the registry, and that is expected** — it seeds the common cases.
`exemplar.sh find "<term>" [language]` discovers candidates and vets each one, and
`exemplar.sh vet <repo>` judges any repo you already have in mind.

**Never pick an exemplar by stars.** Measured control: `sindresorhus/awesome` has **501,961 stars** —
4× openai/codex, 10× calcom/cal.com — and is a list of links with no language, no releases and no
tests. Stars measure reach, and reach is what a launch buys. `vet` scores what cannot be bought
cheaply and prints the star count as NOT SCORED: is it a codebase, is it maintained, does it ship
releases, **do its changelogs carry bug fixes rather than only features**, does it have tests. The
fix-notes signal is the sharpest — features are what you write while shipping, fixes are what you
write after real users hit real edges. Proof of usage over proof of work.

Three traps, each measured rather than assumed:

- **`gh search code` is silently non-functional without the right token scope.** Probed: searching
  `facebook/react` for `useState` returned `[]`. A lookup built on it returns nothing and concludes
  *no prior art exists*, which is the most expensive thing to be wrong about. The script uses the
  contents API and git, which fail loudly.
- **`tags[0]` is not the latest release.** On `vercel/next.js` it returns a monorepo package tag, on
  `openai/codex` an alpha — so pinning to it reads the wrong project or the wrong year. Resolve via
  `releases/latest` first, and the script prints the ref it used so a wrong pin is visible.
- **An empty subtree is a finding about the registry, not about the pattern.** Paths move between
  releases. Re-probe the row rather than reporting that the shape has no prior art.

Read it for the **seams** — how the pieces compose, where auth threads through, what they did *not*
abstract — never to copy names. And note what the registry deliberately excludes: state management,
auth choice, the ORM wars. No single right answer there, so a named pick is an opinion aging into
wrong; read the primary sources and say the choice is contested.

### A different question, one level up: shapes, not stacks

The rows above answer *how is this API used*. The expensive question is one level up — *what shape
should this be* — and it is where an agent is weakest: it has read more code than any of us and
carries none of the scar tissue, so it reaches for the architecture rather than the two facts that
collapse it. A **shape** is the arrangement an experienced person would reach for, and it is only
worth writing down paired with its **trap**, because the trap is what the scar tissue actually is.

**references/shapes.md** carries the curated pairs — mirror-plus-cursor, idempotency keys on a domain
tuple, append-only with a validity interval, desired-state reconcilers, frozen-prefix caching, and
the rest — each with the second-order cost that is invisible on day one. Check it before you invent
an arrangement; a hit there is the whole of recon for that slice.

**Judging a dependency, not a reference? Weigh usage, not polish.** Documentation and a green test suite used to be expensive enough to mean somebody had lived with the library; an hour now produces both for code its own author has never run — one prolific maintainer ships exactly that and tags it *alpha*, where the tag mostly means "I haven't used this yet." Presentation has stopped discriminating, so reading it as quality is how you take a dependency on a demo. What he wants from other people's software is that *they* used it for months, and that leaves traces you can check in minutes: issues filed by strangers and answered, a changelog carrying bug fixes and not only features, real dependents. Proof of usage over proof of work.

### When you must navigate: drive a real browser

`WebFetch` reads one static URL; it can't drive a JS-rendered site, page through multi-section docs behind interaction, or operate a repo UI. For that, reach for whatever **browser-automation tool your environment provides** — prefer one that works through the accessibility tree (stable element refs) over pixel-scraping.

The loop is snapshot-driven and tool-agnostic: **open** the page → **snapshot** the interactive elements (each gets a fresh ref) → **act** on a ref from *this* snapshot → **re-snapshot after anything that navigates or re-renders**, because refs go stale the moment the page changes. A typical lookup: open the docs or the canonical example in the upstream repo, snapshot to orient, read the section, then page through multi-section docs by re-snapshotting after each navigation.

## What to extract: pattern + anti-pattern + why

Don't just copy the snippet. A lookup is only useful if it captures three things:

1. **The canonical pattern** — the current, idiomatic way the library/framework intends it, with the version it applies to. APIs drift across majors, and default docs often render an *older* major than you're on — pin the lookup to the version in your lockfile and record it, so the implementer doesn't code the v2 shape against a v4 dependency.
2. **The matching anti-pattern** — the wrong-but-tempting version it replaces, and how to recognize it. This is what stops the same mistake recurring; the canonical pattern alone doesn't inoculate against the trap.
3. **Why** — one line on what the right way buys (avoids a race, preserves the cache, closes an injection path). The reason generalizes to cases the example didn't cover.

It generalizes *within its failure model*, and that boundary is the part people skip. A canonical pattern is canonical against a particular thing going wrong, and outside that thing it is not merely inert — it can push the other way. A team building a crowd-rating system reached for the standard reputation-graph ranking and got exactly what it advertises: a ring of accounts upvoting each other, filtered out. Pilot data, not theory, then showed the real problem was polarization rather than the manipulation vector they had designed against — and where one side outnumbers the other, that class of algorithm *amplifies* the bias instead of correcting it. So record the failure a pattern was built against alongside the pattern, and where that isn't the failure you have, carry it back as unproven here rather than as the answer.

Then *use* both:

- **Feed it into the plan.** Write the canonical pattern (with its source) into the implementation plan so the implementer codes from the real shape, not a guess.
- **Feed it into the review.** Hand the anti-pattern to compound-v:recheck as a *named, checkable* item, not a vibe. Worked end-to-end: you looked up SQL access in the **v4.2** docs (the version in your lockfile, not whatever default the docs rendered) → found the trap: a string-interpolated query is an injection hole, and v4.2's canonical form is a parameterized query → record both with the version → that becomes a concrete recheck assertion — "does the diff build any query by string interpolation?" — which turns a vague best-practice opinion into a test the review can actually run *against the right API*.

**A different question, one level up.** This skill asks *how is this used correctly* at the moment you write the line, and hands back a pattern. Asking *has someone already solved this whole slice, and what does that let me delete* — before a design exists, with the answer measured in work removed rather than in a snippet — is stage 2 of **compound-v:get-shit-done** (**compound-v:get-shit-done-2-recon**), and its method (budgeting research by uncertainty, the practitioner/X channel and its filter) is in **references/prior-art.md**. Same sources, different output. Use this one when you are about to type; use that one when you are about to commit to building something.

Designing your own tool's API (an MCP tool, a CLI an agent will call)? That's a different problem — see compound-v:designing-agents for the agent-computer-interface rules.
