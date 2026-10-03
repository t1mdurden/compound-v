# Compound V

A skill set for Claude Code that covers **the judgment around the code**: what's worth building, how
it should feel, what context to assemble before a line is written, how to keep a long session sharp,
how to review for bugs and security without flattery, and how to tell whether an AI feature actually
works.

The bet is that code got cheap and judgment didn't. So most of these skills are about the decisions
around the typing, not the typing. They're short on purpose — if a line doesn't change what the agent
does, it's cut, and the kit runs its own checks to keep it that way.

**35 skills · 1 agent · 4 hooks · 10 scripts · 4 source registries.** Everything it reads is public.

---

## Install

```bash
/plugin marketplace add LeventySeven/compound-v
/plugin install compound-v@compound-v-dev
```

Then, once per machine:

```bash
bash scripts/preflight.sh
```

### Prerequisites — install these, or the source lanes go dark

The skills are markdown and need nothing. The **source lanes shell out**, and a missing tool makes a
lane return nothing — which reads exactly like *"there is nothing to find."* That is the failure this
kit teaches you to hunt, and it is the one you are most likely to hit on a fresh machine. `preflight.sh`
names what is missing, what it disables, and how to get it.

| Tool | Needed for | Install |
|---|---|---|
| `git` | the code lane's sparse checkouts | preinstalled nearly everywhere |
| `curl` | papers (arXiv) and engineering blogs | preinstalled on macOS and most Linux |
| `jq` | both Stop hooks and `ledger.sh` | `brew install jq` · `apt install jq` |
| `gh` **+ `gh auth login`** | the code lane — reading real repos at a pinned release | `brew install gh` · [cli.github.com](https://cli.github.com) |
| `yt-dlp` | the talk lane — the verified channels in `references/channels.tsv` | `brew install yt-dlp` · `pipx install yt-dlp` |
| `python3`, `node` | optional; only `stack.sh`'s Python and Node lanes | your existing toolchain |

**`gh auth login` is not optional.** `gh` makes **no** anonymous requests — logged out it refuses
every API call. Before this was guarded, `exemplar.sh ref` printed one newline and exited **0**, so
`grep` and `read` ran against an empty ref while `read` blamed the path for what was really a missing
login. Those subcommands now exit **3** with a named error. `exemplar.sh list` still works with no
account and no network, because it only reads a local file.

**`jq` is a hard dependency of both Stop hooks, and they fail open by design** — without it the
verification gate silently does nothing and the session looks identical to one where it works. The
SessionStart hook now says so once per session rather than letting you find out later.

### Local development

Point a directory marketplace at your clone and enable the plugin — **don't also copy or symlink the
skills into `~/.claude/skills/`.** A personal-level copy takes precedence over the plugin, so you run
a snapshot while editing the repo, and every skill appears twice in the listing: two entries competing
for one shared, truncated description budget. The failure is silent in both directions — your edits
don't take effect, and the extra entries shorten everyone else's triggers.

---

## If you are an agent reading this

Six operating rules. They are here because each one has already been violated, usually by this kit.

1. **Run `bash scripts/preflight.sh` before your first source sweep.** If anything is missing, install
   it from the table above — asking the user first if installing software needs their approval — and
   re-run until clean. Never report a failing lane as "nothing found."

2. **Script and reference paths are relative to the KIT ROOT, not the user's project.** You are almost
   never standing in it. Use `${CLAUDE_PLUGIN_ROOT}` where it is set, or take the base directory the
   harness printed when it loaded the skill and go up two. A cold run lost its first attempt to exactly
   this, and `No such file or directory` reads like a broken kit rather than a wrong working directory.

3. **A tool failure is never an empty result.** A rate limit, a 403, a bot-wall, a logged-out `gh`, a
   missing binary — each must be reported as a named failure. `yt.sh` counts per-channel failures and
   exits 3 when every channel failed; `alpha.sh` surfaces that instead of printing a clean report.
   An empty lane and a broken lane mean opposite things.

4. **Captions are SUBSTANCE, never QUOTATION.** YouTube's "manual" track is often ASR-derived — one
   rendered "Claude Code" as "Cloud Code" throughout. Never put caption text in quote marks. This kit
   shipped that defect itself and had to cut the sentence.

5. **Count registries live; never trust a number written in prose.** `grep -cvE '^[[:space:]]*(#|$)'
   references/<file>.tsv`. Counts written into documents are stale by construction — two shipped here
   were wrong the day they were written.

6. **Stage explicit paths, never `git add -A`.** Working trees here are shared, and `-A` commits a
   peer's files. `scripts/check.sh` has a path-level gate for exactly this, added after a `.gitignore`
   edit un-ignored a live API key and 966 private files while every content check reported clean.

**The output contract.** When a skill asks for a finding — a pattern, an anti-pattern, a constraint —
it takes this shape. Prose is not a finding.

````
<prefix>-<slug>                                 impact: Critical | Important | Minor
why:     one or two sentences — the MECHANISM, never the rule restated
applies: <stack>@<version> · <path glob> · the situation — and where it does NOT hold

**Wrong (<the cost, in ≤8 words>):**
```<lang>
the smallest code that shows it
```
**Right (<the condition, or the win>):**
```<lang>
the smallest code that fixes it
```
from:    <source> @ <pinned ref or version>
````

---

## The workflow

```
using-compound-v → gathering-context → brainstorming → writing-plans → batched-implementation ⇄ recheck → finishing
  (route the tier)   (the context pack)  (design gate)   (plan or PRD)    (1 impl / 2-3 tasks)     (read-only)   (merge/PR)
```

Every session starts at the router. `using-compound-v` loads up front and **sizes the task first**, so
a typo just gets fixed and a real feature earns the full pipeline. A one-line change never spawns four
agents. A five-task plan lands in about four dispatches.

### The premise

Prompt, context, harness and loop engineering are one **ladder of scope**, not four subjects: the
unit of concern moves from one instruction, to one model call, to one agent run, to recurring runs.
Anthropic calls context engineering *"the natural progression of prompt engineering"*; this kit is
the harness rung. Most of what reads as "the agent got it wrong" is the agent not holding something
it needed, so the first move is to go get it.

The claim is narrower than it sounds, and the narrowing matters: it governs an agent's **output** at
a **fixed model** on a **known task**. It says nothing about where capability comes from, and the
sharpest counter-evidence runs the other way — too *much* context measurably degrades recall, and
repository context files were measured as a null result at **20%+ added cost**. So the operating verb
is **minimisation**: the smallest high-signal set, assembled per task and thrown away.
**references/context-is-the-work.md** carries the full argument, the three things on that ladder that
are *not* context, and an honest list of the parts that did not survive checking.

**`gathering-context` runs before the design gate and is why the rest is cheap.** A CTO brings
experience; an agent has none — it has read more code than any of us and been burned by none of it —
so the corpus is its substitute. The pack carries both halves: what to do and **why**, the options,
and what *not* to do. Six slots, assembled **for this task and then discarded.**

That distinction is load-bearing rather than stylistic. Front-loading instructions a model cannot
infer is measured to help; front-loading repository overviews was measured to cost **over 20% and help
nothing** (arXiv 2602.11988). So the pack never becomes a standing document. The heaviest *effort*
goes to how it must not be done — not because the positive half matters less, but because a negative
result is almost never written up, so it is the half you cannot reconstruct.

Two pieces carry most of the remaining weight:

- **`batched-implementation`** runs one implementer per two or three related tasks — sized by what one
  review pass can hold in judgment, not by what fits in a context window. It passes no model parameter,
  so each worker inherits the session model rather than being silently downgraded. It keeps going
  instead of stopping to ask permission, and reports each batch with a four-status contract.
- **`recheck`** is a single read-only pass, ordered cheapest-disqualifying-first: goals, plan, bugs,
  vulnerabilities, re-test, over-engineering. It returns severity-tagged findings and one verdict, and
  caps the fix loop at three rounds. It stays read-only because a reviewer that can edit ships its own
  unreviewed bug.

---

## The skills

| Group | Skills |
|---|---|
| **Foundation** | `using-compound-v`: the router. Tiering, the taste/distribution/primitive gate, the non-negotiables. |
| **Solve any goal** (opt-in) | `frame-the-goal` (turn any goal into a testable success check) → `simplest-thing-that-works` (the simplest mechanism that provably passes it — zero-AI first, climb only when forced, as high as a hard goal needs) → `make-it-stable` (make it hold every time). Caps the machinery, never the goal. |
| **Taste** | `startup-taste` (whether and what to build), `product-taste` (how it feels), `founder-distribution` (whether it will reach anyone — the leg that gets skipped, because it's the only one you can't make progress on by building) |
| **Context** | `gathering-context` — the pack an implementer needs before any code: constraints the model cannot infer, **how it must not be done**, the candidate shapes and the axis between them, what prior art lets you delete, what to build out of, what "done" means, and what is still unknown. Assembled per task from the source registries via `scripts/alpha.sh`, then discarded. |
| **Plan** | `brainstorming` (design before code; proposes 2–3 approaches and picks), `writing-plans` (a per-build plan of the decisions a builder can't make alone — interfaces, tests, traps — not the code itself), `writing-prd` (the product's stable source-of-truth doc), `extracting-specs` (recover the real contract of *existing* code — the backward complement of `writing-prd`) |
| **Thinking** | `critical-thinking` (red-team your own reasoning before you commit) and `council` (when solo skepticism isn't enough: fresh-context agents answer and cross-examine one unverifiable question, findings not votes, and you write the verdict) |
| **Build** | `batched-implementation`, `recheck` (the in-pipeline gate), `code-review` (on-demand reviewer **and automatic pre-merge gate**), `finishing`, and `get-shit-done` (the **project spine**, aimed at the run that stops at 90%: every declared function becomes a ledger row that starts failing, a row goes green only on a check seen red first plus an end-to-end run driven as a user, and the run is not done while any row is neither passed nor explicitly dropped with a name attached; it runs as an entry skill plus four stage skills — `get-shit-done-1-carve` → `-2-recon` → `-3-build` → `-4-reckon` — each invoked in turn and each small enough to survive compaction whole, and invoking `get-shit-done` still starts it) |
| **Correctness & security** | `test-driven-development`, `systematic-debugging`, `verification-before-completion`, `agent-security` (build-time defense: the lethal trifecta, source-trust, sandboxing model-written code) |
| **AI design** (one feature) | `designing-agents` (a call, a workflow, or an agent?), `evals` (does the AI actually work?), `context-engineering` |
| **AI systems** (opt-in) | `architecting-ai-systems` (harness-as-moat, primitive-not-wrapper, build for the model ~18 months out) and `ai-system-reliability` (keep a built system from corrupting its own state) |
| **Power** | `searching-patterns` (the canonical pattern and the anti-pattern it replaces, from primary sources), `dispatching-parallel-agents`, `handoff` (one `.claude/STATE.md` for work that outlives a session) |

One agent ships with it: **`code-reviewer`**, the spawnable read-only form of `recheck`. It reads the
actual diff, re-runs the tests itself, and returns severity-tagged findings plus one verdict. In
artifact mode it reviews a plan or spec before implementation instead of a diff, resolving every path
and command the plan names rather than opining on prose. It never edits; the implementer applies fixes.

### Documents earn their place

The router carries one rule the tier table can't express: **writing the spec is the expensive default,
not the safe one.** Before a document gets written, route the change against the docs the repo already
has — amend the one that owns this surface, supersede the decision it reverses, create one, retire the
one the ground has moved out from under, or none — and cap the output at **one new document per
change**, with findings and the plan as sections of it rather than siblings. Below Standard that count
is zero: the plan is confirmed in conversation and the commit message is the record. Then name every
doc the change makes wrong, make each a task, and treat the change as unshipped until they're updated.

---

## Where the kit reads from

Everything is public. No paid key, no private corpus — a free `gh auth login` is the only account.

### The source registries

Four TSVs, each row verified rather than assumed. **Count them live; the numbers below rot.**

| Registry | What it holds | Reached by |
|---|---|---|
| `references/channels.tsv` | verified YouTube channels — lab developer accounts, YC, a16z, Lenny's Podcast, Dwarkesh, AI Engineer, InfoQ | `scripts/yt.sh` |
| `references/publications.tsv` | engineering blogs and conference sites, each marked `fetch` or `browser` | `curl`, `alpha.sh` |
| `references/practitioners.tsv` | verified practitioners, **writing preferred over posts** — an essay is quotable, a post usually isn't | `alpha.sh` |
| `references/exemplars.tsv` | large open-source projects that ship the thing, read at a pinned release | `scripts/exemplar.sh` |

Take the **developer** account, not the marketing one — `@palantirdevelopers`, not `@palantirtech`.
And **stars are not signal**: `sindresorhus/awesome` has half a million of them and scores 1/5 on
`exemplar.sh vet`, which scores what cannot be bought — recency, release hygiene, whether changelogs
carry bug fixes, whether anyone has had to keep it working.

### The scripts

| Script | Does |
|---|---|
| `preflight.sh` | names every tool, what it disables, how to install it. Run once per machine. |
| `alpha.sh` | one topic, every lane — talks, arXiv, exemplar repos, blogs, practitioners. Returns **pointers, not content**. |
| `yt.sh` | `titles · sweep · mine · csearch · transcript · tracks · verify · channels` over the channel registry. Turns a talk into ~5,000 words of clean text. |
| `exemplar.sh` | `list · find · vet · ref · read · grep` — read a real codebase at a pinned release, not at HEAD. |
| `stack.sh` | the **installed** versions from the lockfile, not the declared ranges, with each dependency's canonical source. |
| `check.sh` | 11 structural gates over the kit itself (below). |
| `hooks-test.sh` | 89 synthetic cases proving the Stop gates. |
| `trigger-eval.sh` | do the skills actually fire? Drives the real CLI on fixtures. |
| `skills-audit.sh` | which skills fire in *real* sessions, from your local transcripts. |
| `ledger.sh` | computes completion from `.claude/slices.json`. Never asserts it. |

### How the lookup is scoped

`searching-patterns` runs before you write against any dependency, and **its first rung is not a
search**: read the copy on disk — `node_modules/<lib>` and its `.d.ts`, `site-packages/<pkg>`, the
vendored source — plus the shape the repo already uses. One `grep`, no network, survives a sandboxed
run, version-exact by construction. `bash scripts/stack.sh [dir]` automates it.

That used to be a four-row table of "for stack X read Y", and the table is why it's now a script: it
asserted a referenced skill carried "70 perf rules" when the installed copy had **64**. A hardcoded
count in a shipped file decays silently; a lockfile read at call time cannot, because it is not a
memory of the answer.

The **external** lookup is scoped, and the scoping is the discipline. Not because an agent can't
recover from a mistake — when an API *raises*, the error-driven loop usually works. What it can't
cover is the class that **never raises**: an optional parameter whose default moved, a semantic that
changed between majors without a signature change, auth, money, retries, concurrency, idempotency.
Those get the lookup; a loop or a standard-library call does not. And the output is the page **at your
installed version** — where the docs render a different major than the lockfile holds, that mismatch
*is* the finding.

### Why sources, not snapshots

An earlier version read a local library of transcripts and essays. Those transcripts came from
somewhere — channels, blogs, papers, repos — so the kit now carries **the sources instead of the
snapshots**. `channels.tsv` was built by resolving the actual video URLs the transcripts came from,
not by guessing. A pointer is forty bytes, never goes stale, and yields the full text on demand; a
stored transcript rots, needs re-syncing, and was summarised on the way in, so the detail you need
later is exactly what got dropped.

That is also why there is no separate "public build". An earlier design generated a stripped public
edition from a private source; once the registries were public, the generated kit was the same kit
with a renamed namespace, so the generator was deleted rather than maintained.

**Keeping your own private directories out:** list them in `.gitignore` **and** in
`local/private-pattern.txt` (itself gitignored). `check.sh` reads the second for its content scan and
also runs a path-level pass over what `git add -A` would stage. Both halves are deliberate. An earlier
version removed the names from `.gitignore`, arguing that a denylist committed to a public repo is
itself the leak — but this repo's own history had already published those names, so the argument was
void and the change deleted a working guard for nothing. It was caught only after a review found that
`git add -A` would have staged a live API key and 966 private files that no content check could see.

---

## What the kit holds itself to

- **Honest.** Evidence over claims, no praise-padding, no false "done." When something doesn't work,
  it says so.
- **Safe.** Security is a review axis that blocks a merge. It's never traded away to ship, and the kit
  won't write harmful code.
- **Grounded.** The skills come from how production coding agents actually behave and from primary
  engineering sources, not invented best practice. Load-bearing claims map to a public source in
  `references/sources.md`, which also carries **REFUTED and REMOVED rows** — things that looked true,
  didn't survive checking, and are recorded so nobody re-derives them. An accurate ledger with known
  gaps beats one that quietly implies everything is covered.

`references/corroboration.md` is the counting rule: **count distinct sources, not findings.** One
practitioner supplied ~11 of 96 findings across three "independent" lanes in a measured run. Collapse
by person, by company, and by commercial orbit — in one exhaustive pass, a single orbit supplied ~31%
of the findings, and no individual slice could see it.

---

## The hooks

Four, and the always-on cost is the router plus one line.

- **SessionStart** injects the small router each session, and warns once if `jq` is absent.
- **UserPromptSubmit** re-asserts the routing directive each turn — one self-gating line, so skills
  keep firing as context grows instead of decaying after the opening turn.
- **Stop (verify)** is the mechanical floor under `verification-before-completion`. It refuses exactly
  one thing: a turn that edited files, ran **no command at all**, and then claimed the work was done.
  It blocks at most once per turn, discards clauses carrying a negation or a progress marker (a bare
  `working` match would fire on "I'm still working on it"), fails open on anything unexpected including
  a missing `jq`, and `COMPOUND_V_STOP_GATE=off` turns it off. It also refuses a turn whose only
  commands were **contentless** — `echo`, `true`, `:` — because `echo ok` cleared this gate for its
  whole life, which is precisely the forgeable-attestation failure the kit warns others about,
  committed by the kit. The list stops at those three on purpose: `ls` legitimately answers "was the
  file written", so widening it would start false-blocking real checks.
- **Stop (ledger)** is the engine under `get-shit-done`'s completion ledger. While any row in
  `.claude/slices.json` is still `todo` or `building` — or while the ledger can't be read honestly —
  the stop is blocked and the open rows come back. A prose goal can be reinterpreted down to whatever
  fits the turn; a row can only be closed. The working part is the message, not the refusal: it
  re-injects the declared scope into a context that has drifted from it.

**The residual limit is real and worth stating plainly:** beyond those three contentless commands, the
verify gate still cannot tell whether the command you ran proved anything. `npm test --
--testNamePattern=nothing` clears it. It is a floor, not the gate — passing it means *a command ran*,
never *the work is verified*. The contract stays with `verification-before-completion`.

---

## Checking the kit

The kit checks itself, structurally and behaviourally. All of it runs offline except `trigger-eval.sh`
and `arm.sh --probe`.

**`bash scripts/check.sh`** — 11 gates. Frontmatter and naming; the publish boundary (content scan over
every shipped file **plus** a path-level pass over what `git add -A` would stage); cross-reference
integrity; no `@path` links; the allowed frontmatter keys; the description budget against the harness's
1,536-char listing cap (`description` + `when_to_use` combined); no pinned worker models; **ledger
anchors still greppable in the files they point at**; trigger-fixture coverage; and every resource a
shipped file names must exist *and be tracked by git*. The size budget counts **words, not lines** — a
body can double while the line count stays flat just by merging paragraphs. No dependencies; drops
straight into CI.

**`bash scripts/selftest.sh`** — the gate on the gates: **has any of this been watched fail?** Every
check above is itself unchecked, ships whatever default branch its author wrote, and reports a pass on
its first run and every run after. This one puts a known-good and a known-bad reference in front of
each instrument and requires it to discriminate — the bad reference being the lazy-but-plausible
version, never a strawman. It caught the description-cap check certifying a constant that had drifted,
and the routing check scoring `0/0 fired correctly` as a hit. Keyless and offline; the routing tier
replays canned CLI output through a shim, so it exercises the real `trigger-eval.sh` at zero API cost.
Run it beside `check.sh` before publishing. A tier whose tool is missing is reported UNRUNNABLE and the
rest still run — a tool failure must never render as a clean result.

**`bash scripts/arm.sh`** — before any measurement spends anything: **is the control arm actually a
control?** It enumerates what reaches an unisolated run (the ambient skills, agents, plugins, hooks and
instruction files competing with the kit's own), builds an arm that excludes what it can, and with
`--probe` refuses to let a paid run start until it has *seen* the treatment activate — because a plugin
directory that loads nothing produces a well-formed, entirely fake data point. `trigger-eval.sh` sources
it and prints which room a run happened in.

**`bash scripts/hooks-test.sh`** — 89 synthetic cases proving both Stop gates. No CLI, no network. The
ALLOW cases are the important half: on a Stop hook a false block costs a wasted turn, and
over-triggering is exactly as wrong as under-triggering.

**`bash scripts/trigger-eval.sh`** — the harder question: **do these skills actually fire?** A skill
that never gets invoked changes nothing, and it fails silently — a description the harness truncated
looks exactly like one that simply didn't match. It drives the real CLI on your session auth with
realistic phrasings from `scripts/trigger-fixtures.tsv`. Everything that could write, spend or spawn is
denied by settings. Negative fixtures are included: over-triggering on "fix the typo in the readme" is
exactly as wrong as under-triggering on a real one. **A quota-truncated run exits 2, not 0** — it once
printed "3 of 1 fixtures NEVER RAN" and exited green, which is the instrument committing the failure it
exists to catch.

It measures routing, not output quality, and each case is one cold turn — so it can't see a skill
decaying over a long session. A miss is also not automatically a skill defect: the fixture can be wrong,
and bending a skill to satisfy a bad fixture is how a suite starts lying to you.

**`bash scripts/skills-audit.sh`** — the other half: **which skills fire in real sessions?** It counts
Skill invocations in your own local transcripts (`--days N` windows it) and sorts never-fired rows to
the top. Two traps it exists not to fall into, because both have already produced a confidently wrong
report about this kit: skill names appear **both namespaced and bare** — a bare name means a
personal-level copy is shadowing the plugin, and counting only the prefixed form undercounts, sometimes
to zero — and **a zero is absence of evidence, not evidence of death**, so opt-in skills are flagged
rather than counted as dead. Read-only, and it must stay that way: this is one machine's usage, and
what ships goes to everyone.

---

## How it was built

Compound V is built with its own loop: batched implementers and a read-only `recheck` on every batch,
plus adversarial fresh-context reviews and **cold-use runs** — where an agent with no context follows a
skill on a real task instead of auditing it.

The loop keeps earning its place, mostly by finding defects in the kit itself. A recent set: a
`.gitignore` edit that would have published a live API key while every gate reported clean; `yt.sh`
rendering a bot-walled sweep as `(0)` on all 32 channels at exit 0; a fabricated quotation assembled
from ASR captions; a rubric that told you to reject the exact artifact held up as its own quality
benchmark. Three separate times an agent's report didn't survive being checked — which is why the
kit's own instruction is to verify a finding before acting on it, including one of its own.

## License

MIT
