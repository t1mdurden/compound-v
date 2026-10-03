# Shapes and their traps — the arrangement an experienced person would reach for

Read this when the question is **what shape should this be**, before a design exists — from
**compound-v:searching-patterns** when you are choosing an arrangement rather than an API call, and
from **compound-v:gathering-context** (slot 3), **compound-v:get-shit-done-2-recon**, where a hit here *is* the whole of recon for that slice.

It lives outside the skill because it is a lookup table: needed at one moment, read at none of the
others, and long enough that carrying it inline pushed its own skill past the size where a skill
starts silently shedding its later instructions (references/skill-format.md).

**It is a cache with a miss path, and most slices miss.** A miss is the rule working. On a miss you
get one hunt scoped to that one domain, at build time, never a standing sweep.


The rows above answer *how is this API used*. The expensive question is one level up — *what shape should this be* — and it is where an agent is weakest: it has read more code than any of us and carries none of the scar tissue, so it reaches for the architecture rather than for the two facts that collapse it. A **shape** is the architecture an experienced person would reach for, and it is only worth writing down paired with its **trap**, because the trap is what the scar tissue actually is.

| Shape | Reach for it when | Its trap |
|---|---|---|
| **Mirror + durable cursor.** Keep a local copy of the third party's data, advanced by one cursor per account that moves only after a whole page-loop succeeds; query the mirror, not the API | "one API round trip per rule per record" — any integration read many times | **The cursor expires**, so a full-resync path is a day-one requirement, not an incident runbook. And an event-type filter *filters, it does not project*: omit the delete event and the mirror never learns about deletions and diverges forever, with no error anywhere |
| **Idempotency key on a domain tuple.** Mint the key, commit it to the domain row *before* the outbound call, and put it somewhere the provider can be asked about later | any at-least-once retry that touches a third party — charge, send, publish, provision | Keying on the **job id** looks right and absorbs nothing: a re-dispatch mints a new one. It must be a domain tuple under a unique index. And the window between "they accepted" and "we committed" is never closed, only narrowed — what closes it is a *probe on the next attempt*, which means the key has to be queryable back out of the provider |
| **Append-only with a validity interval.** Never overwrite; append a new value with its interval and the actor, and define "current" as the projection where the interval is open | anything you will later be asked "who set this, when, what was it before" — CRM fields, agent memory, any column both a human and a job write | **There is no delete, and deleting the source does not delete what was derived from it** — the extracted relations outlive the data they came from, so erasure and offboarding become a second subsystem nobody budgeted. Index the open-interval predicate on day one or every read scans history |
| **Desired-state reconciler.** Store what *should* be true; on a tick, read what *is*, classify absent / identical / drifted, act only on the difference | you notice you are writing a `create` path and an `update` path that are the same code | The loop **has no memory of intent**, so any out-of-band action is indistinguishable from drift and gets silently reverted on the next tick. Every reconciler grows a second piece of state to fix this — a cooldown, a "this write was mine" flag — and each is a new bug surface. The tick interval is your convergence latency *and* your load on whatever you poll, and it is almost never made configurable |
| **Frozen prefix, variance at the tail.** Freeze the system prompt and tool definitions; append everything that changes — the time, live state, task status — as a message at the end | any agent loop where cost or latency matters — production agents run on the order of 100:1 input:output, so cache behaviour dominates the bill far more than output length does | Putting the current date or a flag in the system prompt costs nothing on day one and then **invalidates the whole cache on every call**, so the bill scales with the prefix rather than with the new tokens. The tidy-up you would reach for later is the thing that breaks it. **And the frozen content is the other half of the bill, with a sign that flips by model class:** a ruleset frozen into the prefix is re-sent as input on every call, so its cost scales with call count while its benefit scales with the chance to over-build — a model that is already terse, or one that spends thinking tokens deliberating the rules, pays the input and collects none of the saving. One always-on minimality ruleset measured **42–75% cheaper across three Claude models and 26–39% MORE expensive on two OpenAI reasoning models**, the pricier one also slower (first-party: its author benchmarking his own ruleset, against his own pitch). So measure a standing prompt on a reasoning model before you claim a saving — and check the cost telemetry is real first, because a repeated-prompt harness is the exact workload prefix caching targets: one provider returned the repeats as `cached` with prompt, completion and cost zeroed, so the repetitions added for statistical power were the ones with no usable cost |
| **One central change, auto-merged everywhere.** Open the same mechanical change as a PR against every repo that needs it and merge each on green CI, instead of asking each owner to do it by hand | "hundreds of teams doing the same operation by hand" — a version bump, an API migration across an estate | **The human reviewer you just deleted was your actual test suite.** Owners had been in the loop on every merge for years, which let them stay quietly sloppy about test automation because a person always eyeballed the diff. The instant you auto-merge, every gap that review was silently covering becomes a production defect |
| **Split the decider from the executor.** A big model writes a sketch with placeholders; a small fast one performs the mechanical edit, using the existing artifact as its draft tokens | a slow expensive *judgment* sits right next to a fast mechanical *execution* — the reported win is ~13× on the execution half | The handoff drops the decisions the sketch never stated. Actions carry implicit choices — style, edge cases, what to do at a boundary — so the split only holds where the execution is genuinely mechanical. Where it is not, you get two half-right answers and a merge, which is the cost you moved rather than removed. **The cheap direction fails for a narrower reason than "don't escalate from cheap" — see the escalation note below the table.** |
| **Read-only fan-out, single-threaded writes.** Parallelise the reading and the judging; keep every write on one thread | you want parallel speed on one codebase | Parallel writers make conflicting implicit decisions — style, edge cases, patterns — and reconciling them at merge is the cost you moved, not the cost you removed |
| **Expose the completeness watermark.** Alongside the mirrored data, publish the boundary of what is final — the timestamp through which this row is enriched, settled or safe to read — and clamp every window and comparison to it | you mirror anything a third party revises after first publishing it: ad spend, analytics, billing, an enrichment pipeline running behind the crawl | **The provisional tail reads as real data and every aggregate silently under-reports.** Nothing errors: a flat account showed **$750 against a true $1,750** because the display window ran to today while the sync was three days behind. Worse, a comparison gates one end and not the other — the current window is the short one, so a flat series renders a permanent decline. And the day-one state where the value is legitimately absent is not a failure: collapse *absent* into *failed* and the product tells a new user it is broken |
| **A check the author cannot see.** Apply the grading check from outside the workspace, after the run | the same agent writes both the code and its test | A check the author can read is a check the author can satisfy. The failure is silent: everything passes and nothing was measured |
| **A tool failure is a tool result, not an exception.** Catch everything at the dispatch boundary, put the error text in the function-call output against the same `call_id` so the loop continues, and keep exactly one escape variant for "the harness itself is broken" | any model calling tools in a loop — a typo'd path, a malformed argument or a denied permission should cost a turn, not the session | **There is no third bucket, and the safe-looking wrong answer is silent.** Codex renders a failed `tool_search` as `status: "completed", tools: Vec::new()` — the model is told the search *succeeded* and found nothing, so it will not retry and will conclude the capability does not exist. And no variant means "this failed permanently, do not retry", so a dead credential or an unreachable MCP server becomes a puzzle the model burns the entire budget on. Ship no Fatal variant at all and you get the other edge: vercel/ai's `createToolModelOutput` returns `getErrorMessage(output)` — plain `error.toString()` — *before* it ever consults your `toModelOutput`, so the shaping and redaction you wrote covers the success path only and the raw driver message, connection string included, goes straight into context |
| **Read the retryable bit; do not compute one.** Obey a bit set closer to the wire — the server's own `x-should-retry` header, or an `isRetryable` flag a provider adapter freezes onto the error at construction — and keep your 429/5xx table only as the fallback for when nobody upstream had an opinion | any client against a metered or rate-limited API, and doubly so an agent loop where one turn is one such call | **The bit arrives with a delay attached, and the delay has no ceiling.** Anthropic's client caps its *own* backoff at 8s and then honours a server `Retry-After` verbatim — `timeoutMillis = timeoutSeconds * 1000; await sleep(timeoutMillis)` — so a `Retry-After: 3600` from a CDN error page parks an hour inside your request. You know the trap is real because the other vendor wrote the guard: vercel/ai clamps the same header at 60s under `// check that the delay is reasonable:`. Two more compound it — `timeout` is **per attempt**, so a 10-minute timeout with the default `maxRetries: 2` quietly authorises ~30 minutes plus backoff; and the sleep accepts an `AbortSignal` that the retry path never passes, so a cancelled request still waits out the full delay before the abort is honoured. You delete the retry loop and the backoff maths; you still owe yourself the clamp and one deadline spanning all attempts |
| **The HTTP status is a property of the envelope, not of the operation — and streaming spends it before the operation finishes.** Derive the status from the assembled body when you have one, hard-code 200 when the body will be streamed, and put per-item errors in the body | any API offering both a buffered and a streamed transport over the same handlers — batch vs batch-stream, SSE, NDJSON exports, token streams | **The same handler throwing the same error answers 401 buffered and 200 streamed** — one link swap in the client, and the streaming link is the default many teams adopt for the latency win. The error is still in the body, so the app keeps working and every test keeps passing; what silently goes to zero is everything keyed off the envelope — WAF rate-limits on 401, log alerting on 5xx, APM error rate, gateway retry policy, uptime checks. Your error rate becomes 0% while errors continue. Your `responseMeta` hook cannot compensate either: the streaming path hands it `errors: []`. Route error observability through the **error's own code** — cal.com's `getHTTPStatusCodeFromError(error)`, then gate on `>= 500` — never through the response status |
| **The re-read before an irreversible act must fail CLOSED.** Before deleting or taking ownership on the strength of a cached list, search index or watch, re-read that one object from the authoritative store — and treat only a *typed* not-found as confirmation of absence | any loop that derives a destructive or ownership-taking action from a projection that can lag behind reality | **The fail direction is the opposite of every other guard in the same loop, and both versions compile.** The de-dup barrier sitting beside it must fail OPEN — k8s returns `true` from `SatisfiedExpectations` when the entry is missing *or* has expired at 5 minutes, because a dropped watch event would otherwise leave the controller "asleep forever" — while this check must fail closed, because a transient error is not evidence of absence. Swap them and you get a wedged loop or a wiped table, and neither logs anything. Second: the re-read is N+1 by construction, so you will amortise it behind a `sync.Once` and immediately owe yourself a fresh manager per sync pass or you are trusting a cached "yes, you may adopt". Third, the window never closes, it only narrows — grafana re-checks the same store *again* after the work, "may have deleted it if the namespace was removed while we were working" |
| **Ownership is a field on the managed object, and it carries an identity, not a category.** Write `{kind, uid, controller: true}` into the object's own metadata; ignore anything whose controller uid is not yours, release what you own but no longer match, adopt matching orphans — and send the object's uid as a precondition on the adopting patch | the moment a second writer can touch the same row — a human, git-sync, terraform, a second loop | This is the answer to "the reconciler reverted my hand edit" that a cooldown is not, and **both cheap deviations cost.** A *category* marker (`file` / `api`) instead of an instance cannot survive a lossy legacy path: grafana's coarse `Provenance` collapses `{terraform, identity}` to `ProvenanceAPI` on the way out, so every legacy write silently downgraded the owner and dropped its Identity until a `ProvenanceMatchesManager` special case was added to recognise the store's own lossy view. And a marker in a *sidecar table* is not written in the object's transaction — its source carries `// TODO: Add a unit-of-work pattern` and `// TODO: Clean up stale provenance records periodically` — while the read-then-write it needs re-opened a MySQL insert-intention deadlock that is now two code paths behind a feature flag. Names are reusable and uids are not: without the uid precondition, a delete-and-recreate under the same name gets adopted as if nothing happened |
| **Asymmetric sandbox: bound writes and network, leave reads unbounded.** `has_full_disk_read_access()` returns `true` for every policy variant with no `match` at all, while write access is a real four-arm match and the default workspace policy sets `network_access: false` | an agent running model-authored commands in a real home directory, where the toolchains it must run read from paths nobody can enumerate — a read-allowlist breaks half of `cargo`/`npm`/`pytest` and then gets switched off wholesale, which is strictly worse | **It is a blast-radius control on the machine, not a confidentiality control on the data.** Under the default policy the agent reads `~/.ssh/id_rsa`, `~/.aws/credentials` and every `.env` on the box; it cannot write them or open a socket, but the channel that actually leaves the machine is the model transcript, and no filesystem or network policy sits on that path. Bounding writes *reads like* a security control and is not one. Retrofitting deny-reads later is not an addition, it is a change to every escalation path you already shipped: the instant `has_denied_read_restrictions()` existed, the escalate-to-unsandboxed hatch silently voided it — the only reason `sandbox_permissions_preserving_denied_reads` exists, downgrading `RequireEscalated` back to `UseDefault` so asking for more permission cannot grant a denied read. Any agent that got an escape hatch before it got deny-reads has this hole and nothing reports it |

### Note — escalation, and why the cheap direction actually fails

**And the cheap direction fails for a narrower reason than "don't escalate from cheap."** The rule is
**never let the model at its limit be the one that calls it** — a weak primary judging its own
ceiling mid-trajectory is the part that breaks, and AWS measured it: a Claude pair reaches 79.2% on
SWE-bench Verified at $0.72 where raw mid-trajectory escalation gets 69.2% at $1.61, with quality
recovery at 47% — strictly dominated by simply restarting. Every version that *works* moves the
decision out of the primary: a separately trained router, a calibrated signal, a value-based reader
of the partial trajectory, or an external observable (three identical request hashes auto-escalate).
Decide **before** generation where you can, since a cascade pays the cheap model before every
escalation. **And do not forward the weak model's full trajectory on escalation** — AWS measured the
opposite of the intuition here: dropping the weak model's reasoning while keeping its working-tree
edits is what lifts recovery. *(The general claim that cheap-to-expensive routing fails is REFUTED —
FrugalGPT reports GPT-4 parity at up to 98% cost reduction, RouteLLM 2x+. What survives is the
mid-trajectory self-assessment failure, at 2 independent sources.)*

**One refuted finding, recorded so nobody re-files it.** A pattern-mining pass flagged
`drizzle-orm/src/sql/sql.ts` writing `'drizzle.query.params': JSON.stringify(query.params)` into an
OpenTelemetry span — which reads as every bound value (passwords, tokens, PII) going to the tracing
backend. **It is dead code:** `tracing.ts` has its `await import('@opentelemetry/api')` commented
out, so the tracer is permanently undefined and the span attributes never run. A grep-window read
ships that as a security finding; only opening the neighbouring file refutes it. That asymmetry is
the whole argument for reading code over reading matches — and it is why a finding here must carry
`path:line` at a pinned ref rather than a snippet.

## Harvesting — how a row gets in, and why the bar is this high

This table is the kit's accumulated experience: the thing a strong engineer carries across projects
and an agent otherwise starts each session without. It only compounds if finished work feeds it, so
**compound-v:finishing** runs a harvest when work lands. Most runs harvest nothing, and that is the
mechanism working.

**Both halves, and the trap is the one that earns the row.** The table's own columns are
`Shape | Reach for it when | Its trap` — a row with an empty first column is unusable, because you
cannot warn about a trap in the abstract; it has to attach to the arrangement that produces it. So
harvest the pair.

What is asymmetric is their *scarcity*, not their necessity. The shape is often guessable from the
problem; the trap never is, because it is the part someone had to pay for. So the question at the end
of a run is not "what did we do?" — that half you can reconstruct. It is:

> **What bit us that we could not see on day one — and would it bite the next person the same way?**

If you can answer that, write the shape beside it. If you cannot, you have a war story rather than a
row.

**A caution on the related finding, stated so it is not over-applied here — as it was once already.**
There is a measured result that giving an agent past *failure* cases improves its work while past
*successes* can invite it to copy the answer back rather than reason. Its real scope is narrower than either
reading: the source is describing an agent re-reading **its own prior trajectories** in a long
context window, and its author disclaims the area on record. It does not transfer to a registry row: a shape-plus-trap pair is
a decision aid, not a template to mimic. Reading it as "record only failures" produces rows with no
shape, which is how this section was first written and why it is worth naming.

A row is admitted only if all four hold:

1. **It recurs.** You can name a second, unrelated context where this bites. A one-off is a war
   story; the table is for shapes. If you cannot name the second context, write it in the commit
   message instead and let it earn its place the next time it happens.
2. **It has a trap, and the trap is the payload.** A shape with no second-order cost is a policy
   detached from what produced it, and it will be misapplied. If the entry is really just "we used
   X and it worked," it is not a row.
3. **It survives a stronger model.** Would this still earn its place on a better model, or is it
   scaffolding for a deficiency being deleted week by week? Scaffolding gets an expiry note or gets
   cut. Nothing else in this kit applies this test; apply it here.
4. **It is not already here in other words.** Sixteen rows are easy to re-read before adding a
   seventeenth. Do that; near-duplicates are how a curated table becomes an index.

**And the table is capped on purpose.** A dozen curated pairs beat a thousand retrievable ones, so
adding a row means being willing to evict one. When a row stops earning its place — the framework
changed, the trap became a lint rule, the model stopped falling for it — delete it and say why in
the commit. A registry that only grows is an index, and this file has already refused to be one.

**What does NOT go here:** an API signature (that is `scripts/stack.sh` and the installed copy), a
house convention (that is the repo's own instruction file), a one-time incident with no recurring
shape, or anything you have not seen fail. The kit's own authoring rule applies to this table too —
a line nobody watched fail is a line nobody needed.

**A recon earns a row here only when the shape will recur**, and most will not — which is the same discipline the stack table runs on, and the reason both stay short enough to stay true. Do not turn this into an index of the corpus: that has been tried and refused, because an index over a growing source set rots while `grep -n` over it is current by construction, and a production findings-cache measured zero hits in 133 attempts. A dozen curated pairs beat a thousand retrievable ones.

Most stacks have no row here and that is the rule working, not a gap — the "primary source over a blog" rule above covers the long tail. It deliberately excludes the contested layers (state management, auth, the ORM wars, any "best-practices" listicle): no single right answer there, so a named pick is just an opinion aging into wrong — read the primary sources and say the choice is contested rather than asserting one. And these are **starting points, not pins** — still read the version in your lockfile, because even the canonical exemplar moves.

