# Corroboration — deciding what to believe when top sources disagree

Mining returns claims. This file decides which of them you are allowed to act on, and what to do
when two people who both clearly know what they are talking about say opposite things.

It applies to every channel equally — a local library, a conference talk, an X thread, an exemplar
repo. The source of a claim changes how you *find* it, never how hard you check it.

## The failure this exists to prevent is not lying. It is agreement that isn't there.

Nobody in a good corpus is making things up. The failure is **one claim wearing several costumes**,
which reads as convergence and is the single most persuasive thing a research pass can hand you.

Measured on this kit's own mining runs, twice:

- One practitioner supplied **~11 of 96 findings** and was counted as **three independent lanes** —
  two talks and two posts by the same person restating one doctrine. He is also a vendor,
  benchmarking his own thesis against his own company's codebase.
- A pool of **70 keepers collapsed to ~26 claims from ~22 primaries**, and its largest cluster —
  nine separate "delete your instruction files" findings — traced to **one event at one company**.

**So count distinct SOURCES, never findings.** Before a claim gets a second vote, ask: is this a
different person, at a different organisation, who arrived at it independently — or the same claim
having travelled? A summary of someone else's work is not a source. A downstream kit that adopted
the advice is not a replication of it. Two employees of the same team describing their shared house
practice are **one** source with two bylines.

**Collapsing by company is not enough — check the ORBIT.** An exhaustive pass over 369 episodes of
one channel produced 59 findings from ~40 people, which looks like breadth. Pooled: GitHub +
Microsoft Research + Microsoft + Bing supplied **13 of 59 (~22%)**, and adding OpenAI — whose largest
investor is Microsoft — took one commercial orbit to **~18 of 59, about 31%**. Every individual slice
flagged its own local version and none could see the total, because the concentration only exists at
the pool level. Two further collapses hid inside the same pool: one researcher appeared under **two
different company labels** across two episodes making substantially the same argument, and one person
was counted **three times** across two slices.

So the counting question is not only *"different company?"* but *"different interest?"* — and it is a
question only the chair over the pooled set can answer. A per-item filter structurally cannot see it.

## Three registers, and the difference is load-bearing

| Register | Bar | How to write it |
|---|---|---|
| **Default** | 3+ independent sources across 2+ lanes | State it plainly. This is what you build on. |
| **Conditional** | Top sources genuinely disagree | Keep **both** positions and name the **axis** the disagreement turns on. Never resolve it by picking the more famous speaker. |
| **Contested** | One top source, verified, load-bearing, cutting against common practice | Cite it as one source, attach its speaker's constraints, and give its falsifier. **Never in a sentence that implies agreement.** |

The third register exists because a three-source bar silently discards the sharp, unreplicated
material — nobody replicates the interesting thing — and that is often where the alpha is. Discarding
it quietly is worse than carrying it labelled.

## When two top sources conflict, the disagreement is usually about scope

A real conflict between two people who both shipped is almost never one of them being wrong. It is
two correct answers to two different questions that nobody separated. So the move is not to pick —
it is to **find the axis** and turn the conflict into a conditional you can apply.

The four questions that recover the axis:

1. **What were their constraints when they decided?** A team A/B-testing a harness across millions
   of interactive sessions with a human watching every diff, and a team running unattended with
   nobody watching, will disagree about pushed checks forever, and both are right at home.
2. **What scale and what blast radius?** Advice that holds at one deployable inverts at 750 packages,
   and the inversion is not a contradiction — it is the axis.
3. **What did each of them have that the other did not?** Where one team dropped human code review
   successfully and another dropped it and had to rip the system out, the difference was machinery:
   enforced dependency order, architecture linters, a downstream human gate. State the machinery as
   the condition.
4. **Which one is describing a role the other is not?** Two rules about "what a subagent should be
   told" that look opposite turn out to be about *implementers* and *reviewers* — intent flows to
   one and is deliberately withheld from the other.

**Then adapt it to the case in front of you.** A conditional is not a hedge; it is an instruction
with an `if`. Write it as one: *"pre-merge human reading may be dropped only in proportion to how
much of 'good architecture' you have made machine-checkable, and only if a human gate exists
somewhere downstream."* That is usable. "Experts disagree" is not.

## What disqualifies a claim regardless of who said it

- **A number whose source cannot be landed.** If you cannot open the paper and find the figure, the
  number goes and the mechanism stays. Three claims shipped in this kit with its own ledger telling
  it not to; each argument survived the number's removal intact, which is the usual outcome and the
  tell that the number was decoration.
- **Every AI-productivity number you will find was produced by the seller of the tool it describes,
  on a unit the seller chose.** This is not a caution about one bad source — it is the measured state
  of the whole literature. Across seven organisations publishing such figures (GitHub, GitLab,
  OpenAI, Anthropic, Block, and others), not one number in the sweep came from a party without a
  commercial interest in the result, and several were self-reported hours saved validated by an
  undisclosed formula. The honest move is not to discard them but to **carry the seller's name inside
  the sentence** and to prefer a number whose unit the seller did not pick. Note also what the same
  sources concede when asked: the gains are reported on greenfield work and *"in very complex code
  bases that already exist those gains are not quite there yet."*
- **A vendor multiplier about their own product.** "It will 2-3× the quality" from the person selling
  the thing is marketing until someone independent reproduces it, however credible the name.
- **A number the author disclaims in the next sentence.** One "11× more slop" finding was carried as
  measured while its own author wrote *"there's a mountain of asterisks on this finding"* two lines
  later, and had generated the comparison ruleset for the occasion.
- **A retrieval tool's paraphrase.** A search digest and a fetch summary are the tool's words, not
  the page's. One in sixteen quotes in a measured pass was a fabrication produced by the retrieval
  layer itself. Re-check any web quote against the raw bytes before it enters anything you ship.
- **A cap that bound.** When every lane in a sweep returns exactly its finding limit, the count is an
  artifact of the brief and the tail of each lane is its weakest material. Weight it near zero.

## The honest outcomes

**Keeping zero is normal.** Measured yield on the practitioner channel is roughly 7% of posts, and a
pass that keeps most of what it found did not run the filter. Padding a keep-list to hit a number is
the failure this file exists to prevent.

**"I could not ground this" is a result, not a failure.** It is strictly better than a confident
citation to something nobody opened, and it tells the next run where to look.

**And a claim can be right and still not apply here.** A canonical pattern is canonical *against a
particular failure*, and outside that failure it can push the other way — a team reached for the
standard reputation-ranking algorithm, got exactly what it advertises, and then found their real
problem was polarization, where that class of algorithm *amplifies* the bias instead of correcting
it. So record the failure a claim was built against, and where that is not your failure, carry it
back as unproven here rather than as the answer.
