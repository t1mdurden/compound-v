---
name: founder-distribution
description: Pressure-tests how a product will actually reach people — first-100 sequencing, channel choice, entry friction, and whether a number means anything. Use when there are no users or growth has stalled, when picking or defending an acquisition channel, when deciding what to gate or what to send, when a launch or roadmap assumes users will simply arrive, or whenever a plan grows the product but not its reach — even if nobody asked about distribution. This is the distribution leg of the master gate; startup-taste judges whether to build, product-taste judges whether it's well made.
---

# Founder Distribution

Code is commodity. The three things that compound are **taste, distribution, and a primitive nobody else has.** There are skills for taste and for judging the primitive. This is the one for distribution — the leg that gets skipped, because it is the only one you cannot make progress on by building.

The tell that you skipped it: a long, healthy commit history and no users. Shipping feels like progress and is measurable daily; distribution feels like exposure and is measurable only in rejections. Teams drift toward the first without ever deciding to.

## When to use
- No users, few users, or growth flat — **especially** when the instinct is to fix the product first.
- Choosing or defending an acquisition channel; planning a launch; writing a roadmap that assumes users arrive.
- Deciding what to gate, what to charge for, what to send, how often.
- A metric moved and someone wants to celebrate.
- **Skip it for:** a product with real retention that needs to be made better, not bigger — that's `product-taste`. Whether to build the thing at all is `startup-taste`.

## The master gate, applied here
**Does this put the product in front of a person who doesn't already know you?** No → it is not distribution, however much work it is. Instrumenting, refactoring the funnel, and polishing the landing page all fail this gate.

## The gates

### Sequence by what you demand before you give
The variable that predicts first-cohort velocity is not push-vs-pull, paid-vs-organic, or B2B-vs-B2C. It is **how much a stranger must do before the product does anything for them.**

Win the first 100 on a surface that delivers real value in a **single zero-configuration interaction** — open a page, paste a public identifier, run one query. Anything that requires an account, a connection, a credential, or a configured preference is a **second-stage** surface, for people who already have a reason to trust you.

This is the observed sequencing across the reference-data tools that got big: a free, no-signup, browse-or-paste-an-address surface first; alerts, personalization, and push layered on **years after** a base existed, as a retention layer rather than an acquisition one. CoinMarketCap was a top-200 global site before it shipped its first watchlist, five years in. Etherscan's own product timeline reaches the top 1,000 sites with no accounts milestone on it at all. The reflex to lead with the personalized surface is strong — it's the most impressive thing you built — and it is backwards.

**The condition, because this is not universal.** Every case above is a product whose first-use value is a *public fact a stranger can verify instantly*. Where the value is user-*contributed* or the inventory is scarce, a gate at the door can be accretive: Glassdoor required contribution from day one and exited at $1.2B. And the friction is not free in either direction — one published A/B test found a registration wall lifting signups over tenfold while costing 18% of engagement, which is why the team refused to ship it. So: when first-use value is a public, instantly-legible fact, put it behind zero friction. When it is contributed or scarce, decide deliberately and measure both sides.

Ask: *what is the least a stranger can do and still get something real?* Put that first. If the answer is "nothing, everything needs setup," you have a distribution problem disguised as a product.

### Concentrate effort on one channel — after testing three
Five channels at 20% effort is how you get zero on all five. But the concentration is the *endpoint* of a deliberate test, not the starting posture, and the framework everyone cites for it says so: focus on one **"only after you've identified a channel that seems like it could actually work"**, having run about three cheap tests in parallel first. Skipping the parallel test is skipping the only operationally load-bearing step.

Be honest about the stage, too. That framework aims at the channel that unlocks your *next* growth stage; its own authors describe getting the first customers as an explicitly plural scramble — talks, guest posts, warm email, conferences, at once. Expect the first hundred to arrive that way. Expect concentration to start mattering somewhere in the first few thousand. Expect the winning channel to change at every stage, because channels decay.

There is no counted evidence that most companies' first thousand came through a single door — the widely-repeated "70% from one channel" traces to a vendor page with no study behind it. Concentration of *effort* is the defensible claim. Prefer the channel where your buyers **already are** over one you must build.

### A gate is scaffolding with a demolition date
That is the part the case studies actually share, and it is stronger than any rule about gate shape. Gmail's invite era ran three years and ended the moment the hardware allowed. Superhuman carved out self-serve per segment at PMF, then spent three more years engineering the gate away. Both were dismantled on purpose. If you cannot say what would let you take the gate down, you do not have a gate, you have a permanent identity — and that is the failure mode, not the gate itself.

Treat these as pressure, not as a rule with four boxes to tick:

1. **Network effects on the gated side.** Single-player value → slow admission costs little. If the product needs density, gating defers reach and you collect the deferred demand in a burst when you open — Bluesky went 3.1M to 5.1M in the month after dropping invites. Deferral is a real cost, not a fatal one: Gmail, Clubhouse and Facebook all gated network-effects products and grew. What gates on the network side reliably produce is a user base, not retention.
2. **What it screens for.** Fit with the product beats who the person already knows or can pay. Note honestly that nobody publishes the comparison — no case measures fit or retention differences between gated and ungated cohorts. This is the condition you should *want* to be true; it is not one you can cite.
3. **Whether the token is transferable.** A conversation cannot be resold; a code can. Do not treat this as necessary, though — the three largest gated user bases in software all violate it. Gmail invites were bearer tokens with a liquid resale market, and Google's own engineers call the resulting exclusivity unintentional. What transferability actually costs you is *screening*: you inherit a resale market and none of the fit signal. That is the warning, not a veto.
4. **Duration.** The condition the folklore omits and the only one with a sharp measurement behind it. Superhuman's own waitlist operator reports it converting roughly three times worse than the concurrent live funnel, with conversion halving for each additional year someone sat in the queue. **Open within a window measured in months.** A year-long list is not caution, it is decay.

Two gates are cited as the canonical success and they did not do the same thing. Superhuman's was a mandatory human onboarding whose purpose was *instrumentation* — a controlled cohort a survey could run on — and which paid for itself as a sales motion. Gmail's was a rack of second-hand hardware. Neither gated for exclusivity. **A gate with no mechanism behind it is friction wearing a strategy's clothes.**

Failing here rarely means "remove all friction." It usually means **the gate is on the wrong surface**: open the browse surface, gate the thing that actually costs you something.

**That remedy assumes serving is free — on a metered AI product it eats itself.** Every case behind the zero-friction gate is a public fact rendered on a page, costing nothing per interaction. When you pay a provider per call, the surface that delivers the value *is* the expensive one, so "gate what costs you something" puts the gate exactly where the value was. Resolve it by moving the cost to the other budget line rather than by shrinking the surface: **inference spent on free usage is acquisition spend, and belongs against the payback and LTV:CAC gate below, not against gross margin.** The reclassification is not cosmetic — booked as margin the optimizing move is *minimize*; booked as acquisition it is *spend up to the payback floor*. Same dollars, opposite gradient. And unlike ad inventory it is not auctioned, so competitors entering the category don't bid its price up. But that is **reach, not conversion** — nobody publishes a free-generation-to-activated-user rate, so the bridge is yours to measure. The warrant is one operator's account of one company in an exploding category with a small remaining cost base; copy the accounting move, not the generosity, and set the free allowance from your own measured cost per activated user.

### Fix the entry bar before you staff the exit
When a feed, digest, or alert stream is too loud, the reflex is "curate" — assign a human, cut the volume. That is high-lift and rarely happens. The cheaper lever is a **threshold on what is allowed to enter the stream**: a size cutoff, a significance floor, a relevance bar. A stream that admits non-actionable items degrades the recipient's response to *everything* in it, and exit-side triage does not recover that. Google's SRE rule is the clean form: every page should be actionable.

Do not claim more than that: no study compares filter-at-ingestion with curate-at-exit and names a winner, the adjacent evidence cuts both ways (human curation won on source diversity in one audit, the algorithm on clicks in another), and the winner depends on your personalization data and your metric.

**Every threshold buys quiet by spending sensitivity.** The one discipline worth copying comes from the clinical alarm literature, which is the only place this is genuinely measured: before you raise a bar, name in advance the measure that must *not* degrade, and check it afterwards. Product teams almost never do this. Raising the bar and never looking at what stopped arriving is how you hide the item that mattered.

### Retention sets the ceiling — but the ordering is not settled
A product with modest virality and long retention beats one with high virality and 30-day churn. That much is arithmetic rather than observation: growth runs as `K^(t/ct)`, a loop below K=1 converges to a finite multiple of what you seed, and K is itself gated by retention because invites accrue over repeat sessions. Say "arithmetic under stated assumptions" and you are on solid ground. Note also that most products never reach K>1 at all — real viral factors cluster around 0.2–0.3 — so a sub-1 loop is an amplifier that *requires* a paid or content source underneath it, not a substitute for one.

**Do not say "fix retention before optimizing acquisition."** It is contested, and the Ehrenberg-Bass Institute contradicts it directly: the belief that retention is cheaper than acquisition, they argue, was sold to marketers without evidence. For anything with network effects the ordering is incoherent anyway — retention is not stably measurable until acquisition supplies liquidity.

What survives is a claim about *interpretation*, not work order: **acquisition performance carries no information about retention**, so acquisition wins are not evidence of fit, and a flattening retention curve is what makes acquisition spend recoverable rather than merely spent. The two are a joint constraint. A curve that flattens at 10% is fine or fatal depending entirely on whether your acquisition motion can reach the volume that implies.

### Distinguish reach from conversion — and don't assume the bridge
A large audience on a free surface is a **reach asset**. Reach is not conversion, and the step between them is a separate mechanism you must actually build: a filtered tier, a product layer, a reason to move.

Be suspicious here: this is a place where public numbers are systematically unavailable. Impressive follower counts are published constantly; the conversion rate from those followers to product users is published almost never. **If you cannot find the number, say so** rather than borrowing a plausible-looking benchmark from a vendor's content-marketing post.

### A metric earns its place by naming an action
Waitlist size, registered users, subscribers, total messages sent — these are the original worked examples of a vanity metric, and they are still the right ones. But the test that condemns them is not that they cannot go down. It is Ries's question: *you have 10,000 of them. Now what?* A number earns its place when a movement in it names an action you could take and you can attribute the movement to something you did. A weekly-active count can fall and still fail that test.

So: name the **user outcome** the number is a proxy for, and check the outcome moved too. Prefer rates and ratios over totals, and cohorts over aggregates. **The exception worth keeping:** pre-PMF, a cumulative count is admissible as a rough leading indicator — it tells you something is happening. It stops being admissible the moment it appears in a goal, a board deck, or a fundraise, because that is when someone starts optimizing it.

### PMF is a number — but not the number you think
Survey existing users with *"how would you feel if you could no longer use this?"* and build for the segment that answers **very disappointed**. The instrument is good and cheap. The famous 40% bar is not: Sean Ellis introduced it in 2009 and called it "a bit arbitrary" in the same sentence, derived from roughly a hundred startups he advised, with no published dataset and no peer-reviewed validation since. Superhuman — the case everyone cites — scored 22% and went on to $100M+ ARR.

Use it as a **trend line, not a gate**: same wording, same segment, quarter over quarter, and report the delta. Never quote a score without its n, its segment definition, its activity filter, and whether churned users were excluded — because the standard method surveys only recent active users, which excludes by construction the people whose churn defines fit, and because *narrowing the segment raises the score without changing the product*. That is not a hypothetical: it is how the canonical success case got its first ten points. Below about fifty responses do not quote a percentage at all; read the open-ended answers instead, which is where the signal actually is. Where you have cohort retention data, it outranks the survey. Treat a high score as necessary, not sufficient — Ellis conceded that himself.

### Hand-recruit the first hundred — it is research that happens to collect users
The first cohort comes through you, one at a time. Graham's point is not that manual recruiting grows you; it is that over-engaging with early users is *"a necessary part of the feedback loop that makes the product good."* The unscalable work is where the signal is: the exact words people use for the problem, the trigger that made them look, the objection you didn't anticipate. Success here is not "100 users" — it is "the product changed as a result." And the change does not reverse: product evolution is path-dependent on what the early adopters wanted. YC's case is Tesla — a first cohort that would pay $150,000 for an impractical car because it wanted tech and acceleration, and a decade later the mass-market Model Y still out-accelerates a Lamborghini and rides worse than a Toyota. So the first hundred is a *selection* decision, not only an acquisition one: recruiting whoever answers is choosing blind which preferences get compiled into the product permanently. Ask of each early cohort before you work it: if the next three years of this product bend toward these people's priorities, is that where we wanted to end up?

Two things the popular version drops. It **presumes the market exists**: you can always sign up a hundred people by hand, so this tests execution, not demand. And it needs an **exit trigger** you have to set yourself, because the essay gives none — the documented failure is a team that committed to a call with every user and kept it past the point where quality survived. Write down the number of users at which the manual motion has to be replaced, before you start it.

A YC founder survey anchors both ends of that motion. Customers 1–3 come from your first- and second-degree network almost without exception — "there were basically no counter-examples to this pattern" — because at that stage people are betting on the founder, not the product; customers 4–10 come from work that does not scale. The named mistake is starting at the wrong end: founders "spend weeks setting up outreach tools when they actually have a lot of second-degree connections they haven't" worked. That gives you the exit trigger too — prospecting tooling starts paying somewhere around 10–20 quality customers, and the precondition is not the count but what the count bought you: a refined pitch, case studies, and "a message that's worth scaling." Automate before you have one and you have only scaled a message that doesn't land.

Interview by asking about their **past behavior**, never about your idea. "What did you do the last time this happened?" beats "would you use this?" — the second question has no wrong answer and therefore no information. The warrant is better than the handbook everyone cites: the intention–behaviour literature finds a medium-to-large change in intention yields only a small-to-medium change in behaviour, and it names your problem exactly — the *inclined abstainer*, who sincerely means yes and never buys. Do **not** repeat the folk claim that people overstate willingness to pay by 2–3x; the meta-analysis puts the median at 1.35 and says "only 1.35" to correct that belief. The real hazard is the shape, not the size: the distribution is severely right-skewed, so most answers are mildly inflated, a minority wildly so, and nothing tells you which one you are holding. At n=20, this is a week of calendar, not a program.

**These two rules do not conflict, and the distinction matters.** The past-behaviour rule governs *discovery*, with people who are not yet users, where you are asking them to forecast adoption. The PMF survey governs *retention diagnostics*, with people already using the thing, who are reporting on an existing behaviour by imagining its removal. Applying the hypothetical-bias literature to the second is a category error. Its real weakness is elsewhere: nobody has validated the leap from stated affect to observed retention.

**Who you ask and whose asks you take are different questions.** Targeting the very-disappointed is not licence to source the roadmap from them — they already love it, so their asks pull toward the edges. Superhuman's operator ran his engine the other way: ask the lovers what specifically they love and take that as the **main benefit**; don't act on the not-disappointed at all; then take the roadmap from the **somewhat**-disappointed who cite that same benefit, and politely disregard the somewhat-disappointed who like it for something else — which he names as the hard part, because building what they ask pulls you off the benefit that produced the lovers. Split the planning cycle roughly in half: deepen what the lovers named, remove the objections of the resonant somewhat-disappointed. And a third thing resets the baseline alongside wording and segment — **delivery method**: an in-product interstitial and an emailed survey are not the same instrument. Warrant: one operator's account of his own procedure, no control — a default worth copying, not a measured finding.

### Check where the value actually accrues
A growing market does not mean a growing market **for your category**. Ask who captures the money in this ecosystem today — and whether that is the category you're in. Compute it per user: what they pay you against what the same workflow pays the layer beneath you. A coding-agent orchestrator with 30,000 monthly actives — mostly free — shut down because a paying user spent about $30 with it, then pressed a button that spent about $3,000 with the agent vendor. If the volume accrues to a neighboring category, that is a positioning problem sitting upstream of every channel decision, and no amount of channel work fixes it.

### Timing is a variable, not a constant
Some markets are **event-driven**: attention and new users arrive in spikes around scheduled catalysts, then fall hard. Launching into the trough between events looks like a product failure and isn't.

Before committing to a date, ask what the demand calendar looks like and whether the window is rising, flat, or just past a peak. If you must launch into a trough, know that you are, and set expectations to match.

### Every decision names its falsifier
A distribution decision without a measurement that would prove it wrong is a preference. For each one, write down: *what will I measure, by when, and what result makes me reverse this?*

Express thresholds in **units you can actually count** at your scale. At n=20, "conversion improves 15%" is unmeasurable noise; "3 of the next 10 conversations end with someone asking for access" is a real test.

## Honest-warrant discipline
Distribution advice is unusually contaminated: most of what is written about it is content marketing by people selling the channel. Hold three warrant tiers apart and never write them in the same register:
- **Measured** — a real number with a stated method.
- **Converging cases plus a failed search for a counterexample** — strong.
- **Structural inference from two examples** — a reason to prefer the cheap reversible option, not a certainty.

Named cases are all survivors; the matched losers who made the same choice and died are not written up. And every well-known launch has a confound — prior audience, timing, a wave. **A rule that no evidence could break is not a rule.**

## Refusal templates
- **No distribution in the plan:** "Every item here makes the product better for people who already use it. Which one puts it in front of someone who doesn't know us?"
- **Personalized surface first:** "This needs an account and a connected source before it does anything. What's the version a stranger gets value from in one interaction — and can that go first?"
- **Gate with no mechanism:** "This gate screens nothing and protects no capacity — it's friction, not strategy. Either give it a real admission interaction or open the door and gate the expensive surface instead."
- **Gate with no end date:** "What has to become true for us to take this down, and when do we check? A gate without a demolition date is a permanent identity."
- **Vanity number:** "Say the number moved. What would we do differently? If nothing, it isn't a metric."
- **Channel portfolio:** "Five channels at 20% each gets zero on all five. But have we actually tested three cheaply yet, or are we concentrating on a guess? Which one, how deep, by when, and what result makes us abandon it?"
- **Borrowed benchmark:** "That figure traces to a vendor blog with no method. Either we measure our own or we state that no reliable number exists — we don't launder theirs."

## What this skill does not cover — say so rather than implying it doesn't exist
The gates above are about judgment, not tactics, so plenty of real distribution sits outside them. Four worth naming, because silence reads as disapproval:

- **Paid acquisition.** Excluded as a tactic, but its *gate* is a judgment tool and belongs here: paid is fine when CAC is recovered inside roughly twelve months, against an LTV:CAC floor around 3. Below that the cohort P&L goes anemic.
- **Programmatic SEO.** Not a tactic at all — a decision about your data model made before the first user, which is squarely the first-surface question. If the product generates many unique pages, the product's structure *is* the channel.
- **Pricing and packaging.** The first-surface gate stops at the paywall, and the paywall decides whether anyone converts. Free-trial and freemium shapes differ by several multiples on free-to-paid conversion and pull self-serve share the opposite way. That is a distribution decision, not a finance one.
- **Bottom-up B2B and its ceiling.** Everything above takes the individual user as the unit. In B2B the individual is not the buyer; the individual→team→company motion stalls as a sole motion somewhere around $20M ARR. Advice tuned to the first hundred goes quietly wrong at a thousand.

## What this skill is NOT
It is not a growth-hacking tactics list, and it is not optimism. It assumes an operator who can already build and whose scarce resource is honest signal about whether anyone wants it. Name the violated property, offer the cheapest test that would settle it, and cut the hand-holding — not the rigor.

Every empirical claim above is graded, sourced, and where necessary contradicted in `references/sources.md` → `founder-distribution`. If you are about to quote a number from this file, read its row first.
