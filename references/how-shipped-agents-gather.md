# How shipped agents gather context before they act

Read this before you brief a recon worker or design a gathering pass. **compound-v:gathering-context**
says what the pack must hold; this file says how eight shipped agent systems actually gather it, and
the trap each one hit on the way. Every quoted line was checked against the raw bytes at the source
named beside it on 2026-09-21. Talks are paraphrased and marked *[talk]* — captions are substance,
never quotation. **Each system is one commercial source describing its own product**, so each entry
grounds a mechanism, never a measurement; where a number appears, the party that measured it is
named, and it is usually the seller.

## Contents

1. The traps, across systems
2. Claude Code (Anthropic)
3. Codex (OpenAI)
4. Cursor
5. Cognition — Devin and Windsurf
6. Amp
7. HumanLayer
8. Manus
9. Factory
10. Also read — aider, gemini-cli and opencode, Warp, Airbnb, Cloudflare, BMAD, Chroma, one paper, one talk
11. What this file does not claim

## 1. The traps, across systems

Collapsed by mechanism, not by vendor: a row with three names is three commercial orbits converging,
which is the only thing that lifts a row above one vendor's say-so.

| The trap | Where it bit | The counter-move |
|---|---|---|
| **The worker never saw the house rules.** A subdirectory's instruction file is absent until something reads there, and some workers skip the files outright | Claude Code, Codex, gemini-cli, opencode — §2, §3, §10 | read the `AGENTS.md`/`CLAUDE.md` of every directory in the edit set; restate them in the brief |
| **The digest became the evidence.** The context that decides acted on a worker's summary | Cognition, HumanLayer, Anthropic's feature-dev plugin — §2, §5, §7 | the worker returns files and line ranges; the decider opens them |
| **The research knew the goal.** A documentarian told what is being built returns opinions | HumanLayer — §7 (talk, with a written trace) | one context turns the goal into questions; a fresh one that never sees it answers them |
| **A question the repo could answer went to the person** | Codex, HumanLayer, BMAD — §3, §7, §10 | explore first; ask only preferences, with a recommended default taken if nobody answers |
| **A standing overview stood in for search** | Cursor removed it — §4; the repository-overview null is in `references/sources.md` | keep a small environmental set; fetch the rest per task, and map only a layout that does not describe itself |
| **Requirements arrived after the start** | Cognition — §5; one paper — §10 | hand the pack over whole before the implementer begins |
| **The environment made the agent guess** | Amp, Cognition, Factory — §5, §6, §9 | a readiness command, a dev login, a seconds-fast local check — named in slot 1, or built as the first slice |
| **Budget pressure set the stopping point** | Chroma, measured against its own design — §10 | do not nag a gatherer to conclude; compare what it saw with what it handed back |

## 2. Claude Code (Anthropic)

**Delegating investigation is the documented recommendation, and the worker starts blank.** The
best-practices page: *"Delegate research with `"use subagents to investigate X"`."* The sub-agents
page on what that worker lacks: *"It doesn't see your conversation history, the skills you've already
invoked, or the files Claude has already read."* — https://code.claude.com/docs/en/sub-agents.

**Trap — the built-in researchers skip the house rules.** *"Explore and Plan skip your CLAUDE.md files
and the parent session's git status to keep research fast and inexpensive."* An Explore worker sent to
gather slot 1 never sees the constraints slot 1 exists to carry, unless the brief restates them. Same
page: *"The built-in Explore and Plan agents are one-shot and return no agent ID, so Claude can't
resume them"* — a recon that may need a follow-up question goes to a general-purpose or custom worker.
Docs for one harness: re-read the page before relying on a default, because defaults move.

**Trap — a subdirectory's rules load only once something reads there.** *"Files in subdirectories
load on demand when Claude reads files in those directories"*, and *"By default, Claude reads
`AGENTS.md` only when you have no `CLAUDE.md` in your working directory or above it."* —
https://code.claude.com/docs/en/memory. After compaction: *"Path-scoped rules and nested CLAUDE.md files
load into message history when their trigger file is read, so compaction summarizes them away with
everything else."* — https://code.claude.com/docs/en/context-window. A write into a directory nothing
has read carries none of its rules, and rules a long session did load are gone after the first
compaction.

**The pack after compaction.** The same page: Claude Code *"re-reads up to five of the files Claude
has read or edited in the session, choosing the ones modified most recently"*, and *"A file over 5,000
tokens comes back as a path reference without its content"*. A large pack, or one written early and
not touched since, does not come back on its own — re-read it after a compaction instead of assuming
it is still in the window.

**The shipped recon shape: explorers name files, the orchestrator reads them.** Anthropic's
feature-dev plugin sends two or three explorers, each on a different aspect of the code: *"When
launching agents, ask them to return lists of the most important files to read. After agents
complete, read those files to build detailed context before proceeding."* Each returns *"a list of
5-10 key files to read"*. — anthropics/claude-code @ bf7d404,
`plugins/feature-dev/commands/feature-dev.md`. **Trap:** a three-commit plugin, so it shows a shape,
not a design tuned against use.

**A map only where the layout does not describe itself.** Anthropic's applied team recommends
*"Building codebase maps when the directory structure doesn’t do the work"*, and symbol search over
string search in a large repo: *"LSP returns only the references that point to the same symbol, so
the filtering happens before Claude reads anything."* —
https://claude.com/blog/how-claude-code-works-in-large-codebases-best-practices-and-where-to-start
(2026-05-14). This is the condition the repository-overview null does not state: a map earns its
tokens where directories are unconventional, not by default.

**The context nobody wrote into the repo lives with a person.** Anthropic's security guidance: *"The
most common cause of false positives is that the model lacks a good understanding of your trust
boundaries"*, with a CISO's summary — *"good context of the code, but not good context of us"*. The
fix is two steps in a fixed order: bootstrap a draft from code, docs and history, then *"have the
model interview someone who knows the system well"* — *"Run the bootstrap step first so the
interviewee isn’t starting from scratch."* — https://claude.com/blog/using-llms-to-secure-source-code
(2026-05-27). The person edits a draft; they do not dictate from nothing.

**The person's own unknowns are a gathering target too.** Thariq Shihipar, Claude Code: *"Fable is
the first model where I find the quality of the work is bottlenecked by my ability to clarify its
unknowns."* His pre-implementation moves, in order: a *blind spot pass* when the area is new to the
person — *"Can you do a blindspot pass to help me figure out my relevant unknown unknowns and help me
prompt you better."* — then an interview ordered by consequence — *"prioritize questions where my
answer would change the architecture"* — and, when the behaviour cannot be described, a reference:
*"the absolute best reference is source code."* — https://x.com/trq212/status/2073100352921215386 (X
article, 2026-07-03). Launch-adjacent writing from the vendor; the method does not depend on the model
it was written for.

## 3. Codex (OpenAI)

**Explore before asking, and sort the unknowns into two kinds.** The Plan-mode template: *"Before
asking the user any question, perform at least one targeted non-mutating exploration pass"*.
Discoverable facts: *"Never ask questions you can answer from your environment"*. Preferences:
*"Provide 2–4 mutually exclusive options + a recommended default."* and *"If unanswered, proceed with
the recommended option and record it as an assumption in the final plan."* "Non-mutating" is drawn at
repo-tracked state — *"Tests, builds, or checks that may write to caches or build artifacts"* are
allowed while planning, *"so long as they do not edit repo-tracked files"*. — openai/codex @
rust-v0.155.1, `codex-rs/collaboration-mode-templates/templates/plan.md`.

**Trap — the rules that win are the ones cut first.** Codex preloads `AGENTS.md` from the repo root
down to the working directory and tells the model to find the rest itself: *"When working in a
subdirectory of CWD, or a directory outside the CWD, check for any AGENTS.md files that may be
applicable."* (`codex-rs/core/gpt_5_2_prompt.md`). The preloaded chain shares one byte budget — 32 KiB
by default — spent root-first, and the overflow is *"silently truncated"*
(`codex-rs/core/src/config/mod.rs`). So the deepest file, the one that takes precedence, is the one
that loses its tail, and nothing in the prompt says so.

**Every injected item carries its own cap.** The maintainers' own instruction file: *"No items larger
than 10K tokens."* and *"Highlight new individual items that can cross >1k tokens as P0. These need an
additional manual review."* — openai/codex @ rust-v0.155.1, `AGENTS.md`. For a pack: a slot that can
grow without bound — a pasted log, a whole file — is the one to turn into a pointer.

## 4. Cursor

**Most static context was removed; a small environmental set stayed.** *"At various points, that
included the folder layout of the codebase, code snippets that semantically matched the query, and
compressed versions of files that the user manually attached. That is mostly long gone. We still
include some useful static context (e.g., operating system, git status, current and recently viewed
files)"* — https://cursor.com/blog/continually-improving-agent-harness. An operator's source for
front-loading only what a tool call cannot reach, independent of the one study the skill cites.

**Long output goes to a file, never through a truncation.** *"we instead write the output to a file
and give the agent the ability to read it"*; after summarization *"we give the agent a reference to the
history file"*; one folder of tool descriptions per MCP server *"reduced total agent tokens by 46.9%
(statistically significant, with high variance based on the number of MCPs installed)"*. —
https://cursor.com/blog/dynamic-context-discovery (2026-01-06, Cursor's own A/B).

**Condition — grep alone thins out on large repos.** Cursor's A/B of grep against grep plus its
trained index: code *"retention increases by 0.3% when semantic search is available. This effect
increases to 2.6% on large codebases with 1,000 files or more."* — https://cursor.com/blog/semsearch.
Cursor sells the index, so carry the size axis, not the size of the effect.

**Trap — a checklist narrows open work.** From Cursor's long-running agent runs: *"Constraints are more
effective than instructions"*, and a list of things to do on open-ended work means *"You also
implicitly deprioritize unlisted things."* — https://cursor.com/blog/self-driving-codebases
(2026-02-05). A pack's must-not list is a closed set and reads fine as a list; its goal is not, and a
goal written as a checklist shrinks to the list.

## 5. Cognition — Devin and Windsurf

**The retrieval worker returns locators, and precision beats recall.** *"A fast model summary can draw
wrong conclusion and mislead the smart model"*, so the worker *"is designed to retrieve a list of
files with line ranges"*, and *"polluting the context of the main agent was more detrimental than
leaving some context out, as the agent is typically only a few searches away to recover any remaining
context."* Base rate: trajectories were *"spending >60% of their first turn just retrieving context"*,
and going from four to eight parallel searches per turn cut the search from six turns to four at the
same quality. — https://cognition.ai/blog/swe-grep (2025-10-16). **Condition:** the precision bias holds
because the reader can search again; Chroma in §10 is the branch where it cannot.

**Verification needs its own gathering.** Devin's test mode writes its plan from the code first:
*"This plan must be grounded in source, not assumptions"*, because models otherwise *"like to assume
they can go down paths in the app that don’t exist"*; and it states the expected result before each
action, since the agent *"will lie less about its findings if it annotates its expected behavior right
before performing an action"*. — https://cognition.ai/blog/testing-development. The services, flags and
roles a walk needs are an input to slot 5, read from code, not discovered halfway through.

**Trap — requirements added mid-run.** *"Devin handles clear upfront scoping well, but not mid-task
requirement changes. It usually performs worse when you keep telling it more after it starts the
task."* — https://cognition.ai/blog/devin-annual-performance-review-2025 (a vendor self-review, weaknesses
section included).

**Difficulty is a finding of the investigation, not of the prompt.** Scott Wu, Cognition's CEO:
*"The initial agent prompt isn't enough to know the difficulty of the task."* — you *"can't know until
you've actually investigated the code."* — https://x.com/ScottWu46/status/2071718682250928421
(2026-06-29; the post sells a router). Size the rest of the pack after the first read of the code,
never from the wording of the ask.

## 6. Amp

**Test the context layer with agents that were not told about it.** Thorsten Ball: one agent edits
the tooling and `AGENTS.md`, then *"spawns 3 new orbs and tells them to do a certain task (without
mentioning the change we made)"*, reads their threads, and *"Then it tweaks, pushes, tries again."* —
*"Orbs as evals for how agent-friendly the codebase is."* —
https://x.com/thorstenball/status/2097184659150889267 (2026-09-08). Success is read from the
trajectory — did the fresh agent find and use it — never from its report. It is the runnable form of
the skill's stop test, *could a competent stranger holding only this produce the thing?*

**Don't make the agent guess about the environment.** From Amp's own repo: *"/__dev/preflight returns
a JSON readiness report"* on secrets, server health and the test user's setup; a dev-only login route
so the agent stops forcing its way in by creating users or changing passwords; and *"41 AGENTS.md files
that the agent will read on-demand"*, holding among other things the bugs the team wants avoided. The
note's own summary: *"productive in our codebase: don’t make them guess."* —
https://ampcode.com/notes/putting-an-agent-in-an-orb (2026-07-02).

**Depth on demand, not uniform effort.** Quinn Slack: *"We've found GPT-5/6 models' high/xhigh effort
levels to overthink, taking way longer and using more tokens than you'd want. Instead, Amp gives the
agent the oracle, which lets it go deep when truly needed, but otherwise not overthink."* —
https://x.com/sqs/status/2096002673007038727 (2026-09-04). Same company as Ball; count them once.

## 7. HumanLayer

**The context that decides reads the files itself.** `create_plan`: *"DO NOT spawn sub-tasks before
reading these files yourself in the main context"*; after research, *"read ALL files they identified
as relevant"* and *"Read them FULLY into the main context"*; and a correction from the user is checked
against the code, not accepted — *"DO NOT just accept the correction"*. — humanlayer/humanlayer @
99abe67, `.claude/commands/create_plan.md`. The research command keeps its own orchestrator *"focused
on synthesis, not deep file reading"* (`research_codebase.md`): a context that makes a map delegates the
reading; a context that makes a decision does not.

**Trap — the documentarian rule leaked while the goal was in the room.** The research prompt:
*"You and all sub-agents are documentarians, not evaluators"* (`research_codebase.md` @ 99abe67). The
team's own workshop at 5486c0c opened research by handing over the issue — *"We are working on the
issue in the issue.txt file. Please read the issue and research the codebase"* — and conceded the rule
needed saying twice: *"This is baked into the base prompt, but it helps to repeat it."*
(`docs/workshop.mdx`). *[talk]* In *Everything We Got Wrong About Research-Plan-Implement*
(https://www.youtube.com/watch?v=YwZR6tc7qYg, 2026), Dex Horthy reports that most users pasted the
ticket into research, that knowing what was being built turned facts into opinions, and that the fix
had to be deterministic rather than a better-worded rule: one context turns the ticket into questions,
and a fresh context that never sees the ticket answers them — query planning for a codebase. **Scope:**
research into what is true in this repo. A prior-art search cannot run blind; the goal is its query.

**Rejecting the codebase's bad patterns happens on a short design artifact, after research.**
*[talk]* Same talk: a design discussion of about 200 lines — current state, desired end state,
patterns to follow — is where a person reads every pattern the agent found and strikes the ones that
came from an engineer who has left. The written trace is the pattern-finder agent, changed to
catalogue rather than rank: *"DO NOT identify anti-patterns or code smells"*
(`.claude/agents/codebase-pattern-finder.md` @ 99abe67).

**Trap — research that stops at the direct callers.** *"the research steps didn't go deep enough
through the dependency tree, and assumed classes could be moved upstream without introducing deeply
nested hadoop dependencies"*, and the lesson drawn: *"you probably need at least one person who is an
expert in the codebase"*. Wrong research is re-run, never patched: *"I threw that research out and
kicked off a new one, with more steering."* — humanlayer/advanced-context-engineering-for-coding-agents
@ 18608de, `ace-fca.md`. For a move, remove or extract, walk the transitive dependency tree.

HumanLayer sells an IDE for this pipeline and its public repo is deprecated at HEAD; the talk retracts
the company's own earlier advice, which is the part worth trusting.

## 8. Manus

**The file system is the context, and compression must be restorable.** *"we treat the file system as
the ultimate context in Manus: unlimited in size, persistent by nature, and directly operable by the
agent itself"*; *"the content of a web page can be dropped from the context as long as the URL is
preserved, and a document's contents can be omitted if its path remains available in the sandbox."* —
Yichao 'Peak' Ji, https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus
(2025-07-18). The pack's pointer-over-paste rule, from a system whose *"typical task in Manus requires
around 50 tool calls on average."*

**Trap — a uniform context teaches a rut.** *"If your context is full of similar past
action-observation pairs, the model will tend to follow that pattern, even when it's no longer
optimal."* Manus answers with deliberate variation. For a pack, the reading is the one exemplar that
matters over several that look alike.

## 9. Factory

**'Done' is inventoried before the work narrows it, by a role that does not build.** *"These checks
inherit the scope of the work that produced them."* Factory has a separate validator derive the
inventory from the sources of truth before decomposition, and *"the implementer never authors it,
runs it, or sees its cases or raw output"*. —
https://factory.ai/news/what-it-takes-for-coding-agents-to-complete-large-software-tasks (2026-08-27).
Its caveats travel with its numbers: one campaign per cell, hand-picked tasks, runs *"not
compute-matched"*. Slot 5 is that pre-narrowing inventory, and a builder writing it alone passes on
the builder's blind spots.

**The feedback loop is part of the context.** *"Missing pre-commit hooks mean the agent waits ten
minutes for CI feedback instead of five seconds."* — https://factory.ai/news/agent-readiness (Factory
sells a readiness report). Name in slot 1 the fastest check the implementer can run locally; if there
is none, that is the first slice, not a surprise in the middle of the build.

## 10. Also read

- **aider** — the counter-shape to *overviews don't help*: a map rebuilt every turn, ranked by
  personalised PageRank over the symbol graph toward the identifiers in the current request, and cut
  to a token budget; plus a localisation prompt that keeps files to edit apart from files that are
  merely relevant — *"Only include the files that are most likely to actually need to be edited."* —
  Aider-AI/aider @ v0.86.0, `aider/repomap.py`, `aider/coders/base_prompts.py`. Never measured against
  no map.
- **gemini-cli and opencode** — both attach a subdirectory's instruction file just-in-time when a tool
  touches it, and both shipped the same bugs: one file injected twice by parallel reads, and in
  gemini-cli a file *"permanently marked as loaded but never injected — a permanent context loss."* —
  google-gemini/gemini-cli PR #22679; anomalyco/opencode @ v1.18.31,
  `packages/opencode/src/tool/read.ts`.
- **Warp** — tried a separate agent for planning and context gathering and kept one: *"the most
  consistent, reliable architecture remained our single primary agent"*, changing the same agent's
  tools per phase because *"using the same agent with a restricted tool set is more reliable due to
  context window preservation."* — https://www.warp.dev/blog/swe-bench-verified (single-issue
  benchmark). The axis against delegating recon: whether the gathered detail must be present verbatim
  at edit time.
- **Airbnb** — a bulk test migration where *"the main success driver we saw was choosing the right
  related files"*, assembled by code before the model ran, over prompt wording —
  https://airbnb.tech/infrastructure/accelerating-large-scale-test-migration-with-llms/. The condition
  under which deterministic pre-run assembly beats *fetch it yourself*: unattended, one-shot, many
  near-identical units.
- **Cloudflare** — one agent session *"can cover maybe a tenth of a percent of the surface in a useful
  way"* on a large repo; what worked was a recon stage that *"produces an architecture document
  covering build commands, trust boundaries, entry points, and likely attack surface"* and *"Gives
  every downstream agent shared context."* — https://blog.cloudflare.com/cyber-frontier-models/. A
  task-shaped map shared by many narrow workers is not the standing overview the skill's cited study
  measured.
- **BMAD** — the test for keeping a line is what a miss costs, not whether the fact is derivable (their
  `best-practices.md`, bmad-code-org/BMAD-METHOD @ v6.12.0), written after the derivability test
  *"gutted a ~200-line maintainer-authored file to ~15 lines"* (PR #2715). And the ask criterion: a
  question reaches the person only for *"things the request does not say, the code cannot settle, and
  the user would notice in the result"* (`src/bmm-skills/ship/bmad-build/step-02-plan.md`).
- **Chroma** — the reverse of Cognition's precision bias, with its reason: *"missing a critical
  document is often worse than including an irrelevant one, since the downstream model can still
  filter but cannot recover information that was never retrieved."* And a measured cost of pressing a
  gatherer to finish: *"the token budget constraint often leads to early termination."* —
  https://www.trychroma.com/research/context-1 (a result against Chroma's own pruning design). The
  axis between the two vendors: can the reader of the gathered context fetch more.
- **Laban, Hayashi, Zhou & Neville** — a fully specified task split across turns showed an *"average
  drop of 39% across six generation tasks"*, because *"LLMs often make assumptions in early turns and
  prematurely attempt to generate final solutions, on which they overly rely."* —
  https://arxiv.org/abs/2505.06120. Measured on chat-style splitting, not agent tool loops; it is the
  measured mechanism under *hand the pack over whole*.
- **Netflix** *[talk]* — Jake Nations, *The Infinite Software Crisis*
  (https://www.youtube.com/watch?v=eIoohUmYpGI): an auth migration woven through hundreds of files
  defeated research-plan-implement — the agent stalled a few files in, or rebuilt the old logic inside
  the new system — until engineers migrated one instance by hand. That change surfaced the invariants
  no analysis had found and became the seed for every later research pass. He credits Horthy for the
  pipeline, so he is independent of §7 on the hand-done instance only.

## 11. What this file does not claim

- **No row here measures this kit's own gathering.** Every number belongs to the vendor or paper that
  published it, and most vendors are measuring their own product.
- **Left out because the source could not be read at raw bytes on 2026-09-21:** OpenAI's account of
  why Codex Security does not seed discovery with static-analysis findings (a bot wall to both a plain
  fetch and a headless browser), and Stripe's post on hydrating context before a run
  (JavaScript-rendered). Re-read either before citing it.
- **Grep versus an index is CONDITIONAL, not settled.** Cursor measured a gain that grows past about
  1,000 files; a vector-database vendor's three-arm test *[talk]* found a semantic tool raised
  precision but not recall, each tool winning different task types. Both sell indexes. Name which side
  of the axis your repo sits on rather than quoting either.
