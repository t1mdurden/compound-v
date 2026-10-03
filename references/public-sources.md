# Public source channels — grounding with nothing but the open web

The recon ladder in **references/prior-art.md** says *what* to look for. This file says *where*, using
only channels anyone has: no private corpus, no API key, no paid seat.

**Run `bash scripts/preflight.sh` before your first sweep.** The lanes shell out to `gh`, `yt-dlp`
and `curl`, and a missing or logged-out tool makes a lane return nothing — which reads exactly like
*"there is nothing to find"*. That is the failure this whole file teaches you to hunt, and it is the
one you are most likely to commit yourself on a fresh machine. If preflight reports anything missing,
install it (the README's Prerequisites table has the command) before you conclude a lane is empty.

Read it when a slice's unknown is real, when **compound-v:searching-patterns** sends you outward past
the installed copy, or any time you are about to answer from memory on something expensive.


## The registries — who and what to read, and the command that reaches each

Five data files, all shipped, all verified row by row. They hold **pointers, never payloads**: a
handle is 40 bytes and never goes stale, while a stored transcript is a snapshot that rots, costs
disk, and — worst — was summarised on the way in, so the detail you need later is exactly what got
dropped. Mine on demand.

| Registry | What it holds | Reach it with |
|---|---|---|
| `references/channels.tsv` | **the verified YouTube channels in `references/channels.tsv`**, tiered — core / platform / research / podcast | `yt.sh sweep "<regex>" [limit] [tier]` dumps every title and greps them **locally**; `titles <handle>` dumps one channel (~1,100 titles in ~13s); `transcript <url>` pulls ~5,000 words |
| `references/publications.tsv` | **25 engineering blogs, conference sites, practitioner sites and one written-transcript lane**, each marked `fetch` or `browser` | `WebFetch` a known page, `WebSearch` to find one. Prefer these when a claim must survive as a **quote** |
| `references/practitioners.tsv` | **45 verified practitioners** — writing, talks, code, posts, in that order | `WebSearch` their name and topic; many speak on the channels and maintain the repos above |
| `references/exemplars.tsv` | **the large open-source repos in `references/exemplars.tsv`** + the subtree each is exemplar *for* | `exemplar.sh grep <repo> <subtree> "<pattern>"`, then `read <repo> <path>` — at a pinned release |
| `references/talks.tsv` | the AI Engineer talks **read in full** and kept — the lane a sweep cannot reach, because it sees only each channel's newest titles | `alpha.sh` prints the matching rows; then `yt.sh transcript <url>` |
| `references/corroboration.md` | How to decide what to believe when two of them disagree | Read it before acting on anything mined |

**One command sweeps every lane at once:** `bash scripts/alpha.sh "<topic>" [tier] [language]`.
It runs the channel sweep, queries arXiv, matches the exemplar registry, names the publications and
practitioners worth a fetch, and prints the shortlist — **pointers, not content**. Breadth is
mechanical and therefore free: listing candidates costs seconds and zero tokens, so spend agents on
*reading* the shortlist rather than on *finding* it. That is the split worth keeping — an agent sent
to find things burns the context it needed for judging them.

It reports a failure as a failure: a rate-limited arXiv says so instead of printing "no papers"; a
channel that returned nothing prints an explicit `(0)`; a channel whose fetch FAILED is counted
separately and, if every channel failed, the sweep refuses its own summary and exits non-zero rather
than reporting a clean zero. An empty lane and a broken lane look identical otherwise, and they mean
opposite things.

**That last clause was a promise this file made and the scripts did not keep.** Audited against a
clean clone on a machine without the tools, `yt.sh sweep` printed `(0)` beside all 32 channels, "0
titles matched", exit 0, and advice to widen the regex — when in fact yt-dlp had failed on every one
of them; `alpha.sh` discarded yt.sh's own missing-tool message with `2>/dev/null`; and `exemplar.sh`
returned an empty ref against a logged-out `gh`. The rule was stated here and implemented at about
half the call sites. Read this paragraph as the specification it always was, and `bash
scripts/preflight.sh` as the thing that tells you whether the lanes can run at all.

**Recall first, then filter — `sweep`, not `mine`.** YouTube's own in-channel search is fuzzy and
matches titles only, so it silently under-collects, and a talk you never listed cannot be judged. A
full title dump costs ~13 seconds per channel, so breadth is nearly free. Measured on one comparison:
YouTube's search returned **9** results where a local sweep over the same channels returned **338**.
Be generous with the regex — a false positive costs one transcript; a false negative costs a source
you never knew existed.

**The real filter is the SOURCE, not the search.** Technical video is mostly marketing — launch
announcements, tool promos, PR dressed as education — and that noise is not filterable by keyword,
because it uses the same words as the real thing. It is filterable by *who published it*, which is
why these lists are curated and short rather than a search over everything. The `tier` column exists
so a cheap pass can sweep `core` and a thorough one can go `all`.

Two rules that make these registries worth having rather than dangerous:

**Verify a row before you trust it, and re-verify one that starts looking wrong.** `@Anthropic` is a
Super Mario Maker gameplay channel; the lab is `@anthropic-ai`. `@NextJS` is a Spanish music video.
`carlini` is a Brazilian account with 367 followers, not the security researcher. A guessed pointer
silently mines a stranger and every finding downstream inherits it — `yt.sh verify <handle>` and
`exemplar.sh grep` exist for exactly this, and six roster candidates were dropped rather than guessed.

**A row must earn its claim, not merely resolve.** A Stripe row sat in the channel registry claiming
to be the best public source on idempotency; probing returned a brand film called "The beauty in
simplicity". That is true of Stripe's *docs* and false of their channel. Probe the claim, and delete
the row when it does not survive.

**One tooling limit worth knowing before you read a zero as an answer:** YouTube's in-channel search
matches titles and metadata, **not transcript content**. Phrase a query the way a speaker would
*title* a talk. A zero means nothing is titled that way, not that the lane is empty — and `yt.sh mine`
prints an explicit `(0)` per channel so silence and emptiness stay distinguishable.

## The order — cheapest rung that answers the question wins

**1. The copy you installed.** `node_modules/<lib>` and its `.d.ts`, `site-packages/<pkg>`, vendored
source. Version-exact by construction, one `grep`, no network, and the only rung that survives a
sandboxed run. `bash scripts/stack.sh [dir]` reads the manifest plus the installed tree and prints
every recognised dependency **at the version on disk** with its canonical source. Answers a
signature, a parameter, an enum, an error class, a default. Does not answer *why*.

**2. The repo's own history.** `git log -S<term>` finds the last time someone touched this problem and
what they concluded. A house wrapper or an `AGENTS.md`/`CLAUDE.md` rule **overrides** the external
canonical pattern — match the local shape rather than importing a clashing "correct" one.

**3. The maintainer's docs, pinned to the version from rung 1.** Default docs render the current
major, which is often not yours. **Where the docs version and the installed version differ, that
mismatch is itself the finding** — it is the most common source of confidently-wrong generated code
and it is invisible unless you compare the two numbers.

**4. The upstream repo at your tag.** `bash scripts/exemplar.sh grep <repo> <subtree> "<pattern>"`
sparse-checkouts just that subtree and greps it; `read <repo> <path>` pulls one file at the resolved
release. **Do not reach for `gh search code`** — it returns `[]` without the right token scope
(probed: `--repo facebook/react "useState"` → `[]`), and an empty result is indistinguishable from
"no prior art exists". The default branch is HEAD, not what you are running.

**5. A large real codebase using it in anger** — only when the question is *what shape should this
be*, never for a signature. Pick one that is actively maintained and genuinely large; read how it
composes the pieces, not how it names them.

**6. Talks and interviews** — where practitioners say what broke, months before it reaches
documentation. See below; this is the channel most people skip and it is the one carrying negative
results.

## Video: `scripts/yt.sh` (yt-dlp — no key, no login)

```
scripts/yt.sh sweep "<regex>" [limit] [tier]   # RECALL-FIRST: dump every title, grep locally
scripts/yt.sh titles <handle> [limit]          # one channel's full title list (~1,100 in ~13s)
scripts/yt.sh channels                         # the registry
scripts/yt.sh verify <handle>                  # read back the channel name — the collision guard
scripts/yt.sh transcript <url>                 # clean prose + a provenance header
scripts/yt.sh search "<query>" [N]             # plain YouTube search, all of YouTube
scripts/yt.sh csearch <handle> "<q>" [N]       # YouTube's in-channel search (precision; under-collects)
```

A 25-minute talk yields roughly 5,000 words of clean text for one command, which makes this the
cheapest primary-source channel that exists.

**Captions are SUBSTANCE, never QUOTATION, and the metadata will not warn you.** Measured directly: a
talk listed under YouTube's *manual* subtitle section — not the automatic one — still rendered
"Claude Code" as "Cloud Code" from beginning to end. The manual track was itself ASR-derived. So a
provenance check that trusts the section header will confidently label machine transcription as
verbatim, which is how a misheard word becomes a fake quotation in something you ship.

Use captions to learn *what* was said and to decide whether a source is worth pursuing. To **quote**
a speaker, confirm the wording against the audio or against something they wrote, and say that you
did. Mark anything carried straight out of a caption `[ASR — wording approximate]`.

**Search for the talk, not the tutorial.** Prefer engineering conferences, a named engineer
describing a system they operate, and postmortems. Cut on sight: "10x your productivity", "I spent
N hours with X", faceless channels, and any title that is a number plus a promise. Those are the
bulk of what a query returns.

## X / Twitter without a key

`WebSearch` constrained to `x.com` returns real post URLs plus an extracted digest, with no
credentials. That is the default path; start there.

- **The digest is a PARAPHRASE, not the text.** Fine for deciding whether a source matters, useless
  as a quotation. Anything carried into a plan as a fact needs the actual words.
- **Expect a plain fetch of a post URL to fail.** X serves authorization walls to unauthenticated
  fetchers, and a headless browser with a fresh profile hits a login wall. That is the wall, not a
  bug to debug.
- **Never mint a credential and never automate a login to get past it.** If the only route is the
  user's own session and you do not have it, the honest output is "this channel is closed in this
  run" — see **compound-v:agent-security**.
- **The unit to extract is the outbound link**, not the post. A practitioner's post is a pointer; the
  essay it points at is the source.

## Judging what comes back

**Never rank by engagement.** Measured on two independent harvests: announcement-shaped links
out-engaged everything else by 7.8× mean on one roster and 2.7× on another, filling 9 of the top 10
by likes in the first. Meanwhile the single account behind a canonical architectural finding returned
**zero** posts clearing a likes filter, while a million-follower account returned 75% — nearly all
release news. A metric filter drops the best practitioner and keeps the noise.

**Seed from people, not organisations.** A named engineer writing in the first person about what
broke is this channel working; the company account announcing a partnership is the noise it filters
worst, because it carries the most engagement.

Five gates, all of which a keeper must pass:

1. **Primary** — the person who did the thing, in their own words. Verify the author actually has the
   standing they claim; an invented insider is the largest category of fake technical content and is
   cheap to manufacture.
2. **Non-obvious** — not answerable by a two-minute search.
3. **Changes a decision** — a mental model, a trade-off, a concrete harness move. Pure how-to fails.
4. **Insight ≥ length** — one idea stretched to 3,000 words fails even if every word is true.
5. **Not stale consensus** — unless it is the canonical statement of the idea.

Cut regardless of polish: sales CTAs, "N tips" listicles, hot takes on a release, summaries of
someone else's work, vendor marketing dressed as education, and **a credible name on a thin post** —
which is the most common way noise gets through a filter that was working.

**Expect to keep a minority.** Measured yield on the practitioner channel is roughly **7% of posts**.
Keeping most of a batch means the filter did not run; keeping zero is a normal outcome. Padding a
keep-list to hit a number is the failure this bar exists to prevent.

**Hunt the negative results hardest.** *"We tried X and stopped"* is the highest-value thing this
channel carries and it is almost never written up as an essay, because nobody publishes a paper about
what did not work. Search for the shape directly: *used to*, *no longer*, *we removed*, *turned out*,
*made it worse*, *overengineered*. A lane that returns three abandonment reports has out-earned one
that returns twenty endorsements.

## Two failure modes that have already produced wrong shipped claims

**A retrieval tool can fabricate.** A fetch of a real page returned a fluent sentence that does not
appear anywhere in that page — the summarizing model's own words presented as page content. Roughly
one in sixteen candidate quotes in that pass. **Any web quote not re-checked against the raw fetched
bytes is unverified**; `curl` the page and `grep -F` the sentence before it enters anything you ship.

**A vendor number is not a measurement.** A multiplier asserted by the company that profits from the
conclusion is marketing until someone independent reproduces it, however credible the speaker. State
who measured it and what they sell, or drop the number and keep the mechanism. The same goes for a
benchmark whose author is measuring their own thesis against their own codebase.

**No registry count is written into this file.** Two were, and both were wrong the day they shipped
(25 against 32 channels, 8 against 14 repos) — the same rot this kit cites elsewhere to justify
replacing a hardcoded table with a script. Count them live when you need the number:
`grep -cvE '^[[:space:]]*(#|$)' references/<registry>.tsv`.
