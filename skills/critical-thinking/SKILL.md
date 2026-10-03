---
name: critical-thinking
description: Distrust your own reasoning before you commit to it — the in-flight self-skepticism pass over a conclusion you are about to state as the answer. Use when you're about to commit to a conclusion, recommendation, design rationale, root-cause call, or verdict that feels obviously right; when your own confidence is the main thing backing it and every piece of evidence you hold happens to agree; when someone asks "are you sure?"; when picking between options or defending the one you already prefer; and whenever the call is load-bearing or hard to reverse — even unprompted. Self-skepticism over your OWN reasoning; recheck reviews finished work, verification-before-completion proves an output, startup-taste judges whether to build.
---

# Critical Thinking

The moment a conclusion feels *obviously* right and nobody is pushing back is the moment you're least likely to check it. This is the discipline of red-teaming your *own* reasoning before you commit — turning the search for confirmation into a search for where you're wrong.

## When to use
- You're about to commit to a conclusion, recommendation, design rationale, or "this is the answer" — and your own confidence is the main thing backing it.
- The call is load-bearing or hard to reverse, or you notice you've only gathered evidence that agrees with you.
- You're converging on a design in **compound-v:brainstorming** — pressure-test the approach you're about to recommend instead of confirming your first instinct (it should beat the *real* alternative, not a strawman). This is the discipline's prime home during design.
- **Skip it** for trivial or reversible calls — red-teaming a rename is its own overkill; this is for reasoning with consequences. And it is self-skepticism over your OWN in-flight reasoning: **compound-v:recheck** reviews finished work, **compound-v:verification-before-completion** runs the command that proves an output, **compound-v:startup-taste** judges whether to build at all. And when the call is load-bearing, has no checker, and your own gates keep landing on "I can't tell from here" — that is the handoff to **compound-v:council**, which buys independent fresh-context takes instead of more solo reasoning.

## The gates (run the relevant ones; name what you find)

**Check whether the claim has a checker before you reason about it.**
Sort the conclusion first. If it is correctness-checkable — a test can run it, a compiler can reject it, a query can return it, a file can be read — go get that signal instead of reasoning harder. Self-critique on checkable claims measurably *degrades* results: you hallucinate errors that aren't there, miss the ones that are, and edit toward the invented fault, talking yourself out of correct answers as readily as you fix wrong ones. Where no formal checker exists — a design call, a priority, a strategy, a piece of prose — your own critique genuinely is the best instrument available, and the gates below are how you sharpen it. So: **run the command on the checkable claims, run the gates on the judgment calls.** (Once it's a finished artifact rather than an in-flight conclusion, that's **compound-v:verification-before-completion**.)

**Felt-certainty is a flag, not a verdict.**
When your chain-of-thought feels obviously right and nothing is pushing back, treat that confidence as the cue to look *harder*, not as proof. (The most conventional-minded people are the surest they think for themselves.) Your own stated reasoning isn't evidence — a chain-of-thought rationalizes a conclusion as easily as it reaches one. The deeper failure is sloppy *degree* of belief, not just false belief: left unexamined, the probable hardens into the certain and the unlikely into the impossible. Knowing all of this does not immunize you — awareness of a bias never suspends it, which is why the check runs per-decision instead of once, as a declaration that you're a careful thinker. So don't ask only "is this right?" — ask "how sure am I, and is that calibrated to the evidence I actually have?" Three moves make that runnable:

- **Calibrate against evidence you can name.** Put a number on it ("I'm ~80% sure"), then list the concrete evidence you actually hold. If you can't name evidence proportional to the number — if the confidence rests on the reasoning *feeling* right — that gap *is* the miscalibration; drop the number to what the evidence carries.
- **Attack the weakest joint.** Name the one assumption that, if false, collapses the whole conclusion — that's the load-bearing joint, and it's where to push, not the parts that already convinced you (the same de-risk-the-load-bearing-assumption move **compound-v:startup-taste** and **compound-v:frame-the-goal** use).
- **Trace a value to what writes it before you calibrate on it.** Naming your evidence is not the same as knowing it, and the checker gate above is only as good as the process behind the signal it returns. A dashboard metric, an `is_fraud` or `is_verified` column, a README benchmark, a green badge — each is a claim by whatever emitted it, wearing a measurement's costume. So push one level on whatever the conclusion rests on: what writes this, under what rule? *The dataset says fraud* → *labelled by ops* → *nobody has read the SOP they label by* means you don't know it was fraud; you know someone wrote it down. When the chain bottoms out in *presumably someone, somewhere*, that item carries no weight toward the number you were about to state — grep for the one write site and read the rule applied there instead of reasoning further on top of it.
- **Say ungrounded rather than guess.** When you can't ground a claim, saying so beats producing a plausible one. A hedge the reader can see is recoverable; a confident wrong answer gets built on before anyone thinks to test it. The guess is worse than the gap.

**Steelman your own claim, then keep only what survives.**
Build the strongest form of the *counter*-argument — the one its smartest proponent would make, not a strawman you can knock down — and name who would make it. Let it shave your claim down to the load-bearing part still standing. You don't own an opinion until you can argue the other side better than the person who holds it. Where two people you respect genuinely disagree is the frontier: sit in the contradiction and form your own bet rather than picking a side.

**Seek the disconfirming case, not agreement.**
Pressure-test a conviction by hunting for the input or argument that *breaks* it — breadth-first, looking for the limit — instead of collecting wins that confirm it. (A claim is only worth something if you can say what would falsify it — so probe for where it fails, not for more demos that confirm it.) **And look where disconfirmation actually lives: with the population that opted out** — the people who did not buy, did not adopt, did not click, did not reply. Whoever stayed can only tell you why the thesis holds; only the refusers know where it stops. That population is the one you never hear from by default, so going to get it is the work (its commercial instance — interrogate non-buyers, not fans — is in **compound-v:startup-taste**). Two tells you're fooling yourself: your reasoning lands exactly where everyone already is, or no evidence could change your mind — that's an identity, not a conclusion. **And check the frame, not just the claim:** the deepest disconfirmation is finding you're rigorously right about the *wrong question*. Ask why the problem is even posed this way — "why does this workflow exist at all?" not "how do I make it faster?" The real heretic questions the premise itself, not the answer inside the frame.

## Why your own confidence cannot be the check — the measured version

The intuition is that experience calibrates you, and that with enough feedback your confidence
starts tracking your accuracy. **Measured, it does not.** Tournament chess players — who receive
feedback that is objective, precise, public and continuous, and who have an exact number attached to
their skill — still rated their own ability roughly **89 Elo points above their actual rating**, and
only a small minority of the overconfident ones ever reached the level they claimed. If years of
unambiguous scored feedback does not calibrate a person, a few hours of reasoning about your own
conclusion will not either. The same gap has been measured on the question closest to this kit —
*did the tool make the work faster?* In a randomized trial, experienced open-source developers
forecast that AI would cut their task time by 24%, still estimated a 20% cut after doing the work,
and were measured taking 19% longer. The sign of that effect is dated (early-2025 tools; the same
lab's 2026 follow-up points to speed-ups); what has not dated is that the people who did the work
misread its sign. So a claim that a tool, an agent or a change made work faster needs a timed
comparison, never the felt speed-up — your own included.

Two consequences for how this skill is run:

- **The gates below are external instruments, not introspection.** "I thought about it carefully and
  I am confident" is the state the chess players were in. Run a gate that can return a result you
  did not want, or you have not run one.
- **Beware the tempting explanation that you were simply under-informed.** Missing context does
  produce confident error — but this result shows the reverse is not guaranteed: supplying the
  information does not reliably remove the overconfidence. Do not treat "I'll go read more" as
  having addressed the problem. See `references/context-is-the-work.md`, which carries the same
  finding as a limit on the kit's own premise.

*(One study, and one that cuts against a claim this kit makes elsewhere — which is why it is here.)*

## Shared with startup-taste — use them there, don't re-derive
- **Idea vs ego at a wall** (persistence and obstinacy split on whether you're attached to the *goal* or your *means*) and **actually contrarian, or just confident?** (the contrarian-insight + timing test) both live in **compound-v:startup-taste**.

## Worked example — running the gates on one conclusion

You're about to conclude: *"This test is flaky because of the CI environment, not our code — mark it `skip` and move on."* It feels obviously right. Run the gates before you commit:

- **Calibrate.** "I'm ~90% sure it's the environment." Evidence actually held? It passed on my machine once. That's a sample of one, nowhere near proportional to 90% — drop to ~50%. **Weakest joint:** the assumption that "passes locally" means "our code is correct." If that's false — a race only CI's slower box exposes — the whole conclusion collapses. That joint is where to push.
- **Steelman the counter.** The strongest form of "it *is* our code," and who'd make it: an engineer who's seen this pattern says *intermittent failures under load are usually a real race, not flaky infra.* That threatens the claim far more than the strawman "CI is just slow."
- **Disconfirm + check the frame.** What input would break the environment theory? Run the test 50× locally under load — a single local failure kills it. And check the frame: I was asking "how do I make this red test go away," not "why does it flake" — the second is the actual bug.

What survives isn't "skip it" — it's *"there's likely a real race; reproduce under load before touching the test."* The gate turned a confident wrong call into the right one.

## Red flags
| Smell | Why it's the tell |
|---|---|
| "It's obviously right" and nobody's disagreeing | Absence of pushback isn't agreement — it's that you haven't looked. Build the counter-argument yourself. |
| You only have evidence that fits | You searched for confirmation, not truth. Name what would falsify the claim, then go look for *that*. |
| The counter-argument you "considered" is easy to beat | That's a strawman. Steelman it to the version that actually threatens the claim before you dismiss it. |
| Your fix for a reasoning failure is "add an instruction telling it to think harder" | Instructions don't add capability, and some behaviors — knowing *when to stop and when not to* — resist prompting almost entirely. Predict that fix to fail; reach for an external gate, a tool, or a check that observes the outcome. |
