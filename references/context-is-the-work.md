# Context is the work — one ladder, and where it ends

The premise under this whole kit, stated so it can be argued with.

**The short version.** Prompt, context, harness and loop engineering are not four subjects. They are
one **ladder of scope**: the unit of concern moves from one instruction, to one model call, to one
agent run, to recurring runs, and each layer subsumes the one below it. Most of what people call
"the agent got it wrong" is the agent not holding something it needed. So the kit's first move is to
go get it.

**And the scope, stated up front, because the claim is weaker than it first looks.** This is a theory
of what limits an agent's **output**, at a **fixed model**, on a **task someone already knows how to
do**. It is *not* a theory of where capability comes from — that overreach did not survive checking,
and the research lane is the most opposed to it. Whether it extends to how genuinely new things get
built is a separate and still-open question, carried below at the register one account earns. The
closing section lists, by name, everything that failed.

---

## The ladder

| Layer | Unit of concern | What the work actually is |
|---|---|---|
| **Prompt engineering** | one instruction | say what to do, clearly |
| **Context engineering** | one model call | put the right information in the window — *and only that* |
| **Harness engineering** | one agent run | the mechanisms around the model: skills, subagents, hooks, tools |
| **Loop engineering** | recurring runs | bound a worker nobody is watching |

Collapsing the first two is not this file's inference — it is the vendor's published position.
Anthropic's Applied AI team: *"we view context engineering as the natural progression of prompt
engineering,"* defining context as *"the set of tokens included when sampling."*
[Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents), 29 Sep 2025.

Karpathy, who put the term into circulation, defines the job the same way and — importantly — states
**both** failure directions in the same breath:

> "in every industrial-strength LLM app, context engineering is the delicate art and science of
> filling the context window with **just the right information** for the next step… Too little or of
> the wrong form and the LLM doesn't have the right context for optimal performance. **Too much or
> too irrelevant** and the LLM costs might go up and performance might come down."

*(Karpathy, 25 Jun 2025. He was amplifying Tobi Lütke, who had posted the term days earlier — so
those two are **one event with two bylines**, not two independent sources. Anthropic's post is
independent.)*

**Harness engineering is the layer this kit occupies**, and it belongs in the list — three research
groups place it between context and loop, and `references/sources.md` already cites it. A ladder
that skips it is missing the rung the reader is standing on.

**And the harness rung carries a cost the other three do not: what makes context PERSIST is ambient,
and an ambient mechanism contaminates every measurement of itself.** A discipline is not active
because it was loaded once — a spawned subagent, a compaction and a resumed session each drop
whatever the host does not carry across, so anything that reliably survives them is delivered by
something that fires automatically: a session hook, a globally-enabled plugin, user-level config.
That same automatic firing reaches the *control* cell of any A/B you run over the discipline, and a
published benchmark of one always-on ruleset was superseded for exactly that reason — its
`SessionStart` hook fired on every arm, so the baseline was secretly running the treatment.

**So persistence and measurability trade against each other directly, and nothing warns you.** The
better your delivery mechanism, the more certainly it is present in the cell that was supposed to be
without it; the leak is native to this ladder's third rung, so the more seriously a project takes
harness engineering, the less able it is to measure it. That is a limit on the premise rather than a
reason to abandon it, and the three pieces that make it workable live elsewhere: the procedure for
building an arm that survives it is in **compound-v:evals**, this kit's own contaminated instrument
is worked through in `references/skill-listing-budget.md`, and `bash scripts/arm.sh --probe` prints
what each arm actually loaded instead of what you assumed it loaded.


**"Graph engineering" is deliberately absent.** It spread from a small number of posts that a close
observer of that moment describes as jokes about how quickly the field renames things. It has an
academic paper and effectively no practitioner usage — a sweep of every verified channel in
`references/channels.tsv` returned **zero** talks. Do not put it in the ladder.

---

## Where the ladder is *not* about context — and this is the honest part

Three things decide outcomes and are not information you could put in a window.

**1. Sampling.** Self-consistency and logit masking change the output while leaving the token set
byte-identical. "Supply the right context" cannot describe them, and this kit's own
`context-engineering` skill already prescribes one of them.

**2. The top of the ladder is a control problem, not a retrieval problem.** Loop engineering's own
working definition is a list of *bounds*: a machine-checkable stop condition, a cost ceiling, a
permission boundary on what an unattended run may change, an escalation policy, and independence
between the verifier and the implementer. Add git worktrees for parallel isolation and you have
mutual exclusion between concurrent writers — which is not information at all. If everything were
context, the top of the ladder would be a retrieval problem. It is not.

**3. Prompt and context are not synonyms; they split on control vs information.** The prompt says
*what to do*; the context supplies *what to know*. Only the second half is "supplying context."

---

## Why missing context produces error

Four failure modes. Two are measured; the third needs its famous name removed; the fourth is the one
where gathering reliably pays.

**It guesses.** Measured: with insufficient context, models hallucinate rather than abstain
**15.4–40.4%** of the time (Joren et al., Google, ICLR 2025). An independent multi-agent failure
taxonomy isolates the same behaviour as its own category.

**It refuses, or declares the thing impossible.** Weakly attested. Carried as an observation, not a
finding.

**It is confidently wrong — and here the intuition outran the evidence.** The obvious label is the
Dunning-Kruger effect. **Do not use it.** The famous chart plots a test score against itself, so it
reproduces the crossing lines from random numbers; the *causal* claim — that not knowing is what
hides the error from you — has been disputed in print since 2002 and is unresolved. Worse for the
thesis: tournament chess players, who get objective, precise, public feedback on their exact skill
for years, still rated themselves ~89 Elo above their real rating. **Overconfidence is not only a
missing-context problem**, and this kit should not claim it is.

**The context does not exist yet.** Measured, and this is where supplying it reliably pays: a
hand-classification of all 300 SWE-bench Lite problems found **10.0%** could not be solved from what
the repository contained. When the missing thing is genuinely absent, no amount of reasoning
substitutes for going and getting it.

**The quantifier "mostly" does not survive.** Replace it with the axis: **when the missing thing is
retrievable evidence, context sufficiency dominates the outcome. When the missing thing is the
inferential or executional step over evidence already present, supplying more context does nothing.**
That distinction is worth more than the word it replaces.

---

## The direction the thesis had no slot for: too much

The sharpest counter-evidence is not too little context. It is too much.

- **Context rot.** As token count rises, recall of what is in the window falls — *"this characteristic
  emerges across all models."* Context is *"a finite resource with diminishing marginal returns,"*
  and good context engineering means *"finding the smallest possible set of high-signal tokens."*
  (Anthropic, same post.)
- **Repository context files measured as a null.** Across multiple agent-model pairs, providing
  repository context files did not generally improve task success and raised inference cost by
  **over 20%** — with repository *overviews* singled out as *"popular and recommended by model
  providers"* yet *"not helpful"* (arXiv 2602.11988). The narrowing axis: guidance the agent could
  have reached with a tool call is redundancy you pay for.

So the operating verb is **minimisation, not supply** — the smallest high-signal set, not the largest
defensible one. Which is why the pack this kit assembles is task-scoped and then thrown away.

---

## Synthesis across projects — one account, and why the silence proves little

**The claim.** A system that is genuinely new is usually not one insight. It is an assembly: the
indexing approach from one project, the orchestration shape from a second, the memory model from a
third, each adapted rather than copied. Building that way requires having read all three, which
makes originality partly a context problem.

**Register: CONTESTED — one first-person practitioner account, from this kit's author, who reports
working exactly this way across his own projects.** That is one source, and per
`references/corroboration.md` a single source is carried labelled, never in a sentence implying
agreement. It should also carry its speaker's position, which is this: the person reporting it is
the person whose kit is built on it. That does not make it false — most durable engineering claims
start as one practitioner's account — but it is why it sits here rather than in the ladder above.

**What a sweep found: nothing, in either direction.** Across ~2,900 enumerated titles and 16 full
transcripts, no published first-person account of working this way, and no measurement for or
against.

**Why that silence is weak evidence.** This kit already carries the asymmetry that explains it: *the
wrong half of a pattern is almost never written up as an essay.* The same applies here, and harder.
People publish the **result** — the architecture, the launch, the postmortem — not the assembly
method that produced it. "I took the indexing idea from A, the orchestration from B, and the memory
model from C" reads as derivative when you write it down and as judgment when you do it, so the
incentive is to describe the outcome and omit the seams. An absence produced by what people choose
to publish is not an absence in practice. Treat the zero as *unmeasured*, not as *refuted* — those
are different findings and only one of them licenses ignoring the claim.

**Its falsifier, so it is not unkillable.** If teams that deliberately survey prior art before
designing produce work that is measurably *more* derivative — closer to the mean of what they read —
than teams that do not, the claim is wrong in the direction that matters. Nothing in the sweep tests
this. It is a real open question, not a rhetorical one.

**What would move it to DEFAULT:** two or three more first-person accounts from unrelated people who
shipped something hard, each naming the specific patterns they lifted and from where. Named
instances — this pattern, that project, this adaptation — are worth more than a dozen restatements
of the principle, and they are the thing this kit's registries are built to make cheap.

## Context quality is the binding constraint

The best-supported part of the whole thesis, carried by independent interests across academia, labs
and vendors: **junk context is worse than no context**, because it does not merely fail to help — it
displaces and degrades the good material sharing the window.

That is the entire reason this kit ships **verified source registries** rather than a search box, and
why `exemplar.sh vet` scores what cannot be bought instead of stars. Marketing and technical signal
look identical to a retrieval tool and are not the same input.

---

## What did not survive, recorded so nobody re-derives it

An honest ledger of the overreaches, each checked and each failing.

- **"The corpus substitutes for a CTO's accumulated experience."** The *premise* survives and is
  conceded even by the thesis's sharpest critics — experiential context is the binding thing and
  cannot be written down in advance. The *remedy* does not. This kit's own earlier pass over eight
  primary essays reached the same conclusion independently: **port the method that generates the
  answer, never the settled answer.**
- **"As Palantir put it, the best AI systems are really just excellent software."** The attribution
  is refuted — 136 titles enumerated and 13 talks transcribed, including the CTO's, with no version
  of the statement. The *idea* is real and well-attested; the landable source is **Dex Horthy**
  ([12-Factor Agents](https://github.com/humanlayer/12-factor-agents)): most products billing
  themselves as AI agents are *"not all that agentic… mostly deterministic code, with LLM steps
  sprinkled in at just the right points,"* and *"Agents, at least the good ones… are comprised of
  mostly just software."*
- **The Dunning-Kruger citation**, for the reasons above.
- **"Graph engineering."**

**And one observation about the term itself, worth keeping in view:** in a sweep of every verified
channel, every "context engineering" hit came from a vendor or tooling channel — cloud providers,
framework vendors, course platforms. **Zero came from a research-lab channel.** The people selling
tools to fill context windows talk about filling context windows. That does not make the idea wrong,
and this file argues it is substantially right — but it is a reason to hold the frame loosely, and to
notice that the research lane locates capability somewhere else entirely.

---

## Three read-once notes, moved here from the skill

**How to tell whether the work is actually novel, rather than well-recalled.** It is a design of
the *check*, not of the work: a biology team established their result was first by choosing
validation targets **whose solution could not be in the corpus**, so any hit was provably novel
rather than retrieved. The transferable form — **if it matters that the output is not derivative,
evaluate it on a task whose answer is not in what you learned from.** Grading against
corpus-derived exemplars cannot distinguish novelty from recall; that is a scope failure in the
instrument, so tightening the gate never reaches it.

**Be honest about how weak the rest of the evidence here is.** The tidy claim — that an agent can
build a v2 from a v1 but cannot originate a v1 — rests on **one source who hedges it on record**.
The opposite is at least as well attested: the two most-cited novel products in the sweep came from
a *felt defect in daily use* and from an *operational constraint someone had already hit*, not from
a blank page. Nobody in the evidence resolves it, so neither does this skill.

**And the expiry test, which nothing else in this kit applies:** would this line still earn its place
on a *stronger* model? A rule that only lifts a weak one is scaffolding for a deficiency being
deleted week by week — mark it with an expiry rather than carrying it as doctrine.

*(These three live here rather than in `skills/gathering-context/SKILL.md` because they are read
once, not per task — and an always-loaded file only has room for what changes what you do today.
That is the same structure the depth benchmark uses: a short index over deep files.)*

