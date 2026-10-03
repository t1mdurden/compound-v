#!/usr/bin/env bash
# exemplar.sh — read how a large, actively-maintained open-source project ACTUALLY does the thing,
# at a pinned version, without downloading the repo.
#
# This is the rung above `stack.sh`. stack.sh answers "what is the signature of the thing I have
# installed". This answers "what SHAPE does a codebase that has lived with this in production use" —
# the question a table of best practices cannot answer, because the answer is code.
#
#   exemplar.sh list                          the registry
#   exemplar.sh ref   <owner/repo>            resolve the version to read at
#   exemplar.sh read  <owner/repo> <path>     one file at the pinned ref
#   exemplar.sh grep  <owner/repo> <subtree> <pattern>   sparse-checkout a subtree and grep it
#
# WHY NOT `gh search code`: it is silently non-functional without the right token scope. Probed
# 2026-09-01 — `gh search code --repo facebook/react "useState"` returned `[]`, a control term that
# must exist. A miner built on it returns nothing and concludes "no prior art exists", which
# references/prior-art.md names as the most expensive thing to be wrong about. Everything below
# uses the contents API and git, which either work or fail loudly.
set -uo pipefail

# Dependency check. Sourced, not duplicated: five scripts need the same answer, and a missing
# tool must become a NAMED failure rather than an empty result that reads like "nothing found".
_pf="$(dirname "${BASH_SOURCE[0]}")/preflight.sh"; [ -r "$_pf" ] && . "$_pf"

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REG="${COMPOUND_EXEMPLARS:-$here/references/exemplars.tsv}"

command -v gh >/dev/null 2>&1 || { echo "exemplar.sh: gh not found. Install the GitHub CLI." >&2; exit 127; }

resolve_ref() {

  # ORDER MATTERS AND IS MEASURED. `tags[0]` is NOT the latest release: on vercel/next.js it returns
  # a monorepo package tag (@vercel/devlow-bench@0.3.4) and on openai/codex an alpha winget tag,
  # so pinning to it reads code from the wrong project or the wrong year. releases/latest first.
  # TEST THE EXIT STATUS, NOT OUTPUT EMPTINESS — the same defect already fixed in `vet`, still live
  # here. `gh api` writes the 404 JSON BODY to stdout, so on a repo that tags without cutting GitHub
  # Releases (python/peps, postgres/postgres, torvalds/linux) `ref` was assigned
  # {"message":"Not Found",...,"status":"404"} — non-empty and not "null", so it passed both guards
  # and was printed AS THE REF. Measured live: `exemplar.sh ref python/peps` emitted that JSON, and
  # `grep`/`read` would then pin a checkout to it.
  local r="$1" ref
  if ref="$(gh api "repos/$r/releases/latest" --jq '.tag_name' 2>/dev/null)" \
     && [ -n "$ref" ] && [ "$ref" != "null" ]; then printf '%s' "$ref"; return 0; fi
  # NO tags[0] RUNG. The tags endpoint is not chronological, so `tags[0]` is arbitrary — measured
  # on the two registry-adjacent repos that tag without cutting Releases, it returned
  # `release-6-3` for postgres/postgres (a 1997 tag) and `lastpy2pep8` for python/peps. Pinning the
  # "read the best implementation" lane to decades-old code is worse than admitting we have no
  # release to pin to, because the reader cannot tell from the output that anything is wrong.
  # Fall through to the default branch instead, which the caller labels as unpinned.
  if ref="$(gh api "repos/$r" --jq '.default_branch' 2>/dev/null)" \
     && [ -n "$ref" ] && [ "$ref" != "null" ]; then printf '%s' "$ref"; return 0; fi
  # All three failed. Return nothing and say so — a ref nobody could resolve must stop the run,
  # not become a checkout target.
  echo "exemplar.sh: could not resolve a ref for $r (typo, private, or the API refused)." >&2
  return 1
}

# Every subcommand below except `list` calls the GitHub API, and `gh` makes NO anonymous requests:
# logged out, it refuses everything. Check ONCE here, in the main shell. It cannot go inside
# resolve_ref — that runs in a command substitution, where `exit` kills only the subshell: measured,
# the warning printed while rc stayed 0 and the caller carried on with an EMPTY ref, so `grep` and
# `read` ran against nothing and `read` blamed the path for what was really a logged-out gh.
# `list` is exempt: it reads the local TSV and must keep working with no network and no account.
case "${1:-}" in
  ref|read|grep|vet|find)
    declare -F gh_ready >/dev/null && { gh_ready || exit 3; } ;;
esac

case "${1:-}" in
  list)
    awk -F'\t' '!/^#/ && NF>=4 {printf "  %-34s %-16s %s\n     -> %s\n", $1, $2, $3, $4}' "$REG" ;;

  ref)
    # Emit tag AND short commit. On a monorepo, releases/latest is frequently a SUB-PACKAGE tag that
    # names a different package than the subtree you are reading: vercel/ai resolves to
    # `@ai-sdk/xai@4.0.51` while packages/ai is version 7.0.88, and anthropic-sdk-typescript resolves
    # to `aws-sdk-v0.6.6` while the package is 0.122.0. The checkout is correct either way — the
    # CITATION is what goes wrong, because the tag alone names the wrong thing. The commit does not
    # have that ambiguity, so quote both.
    r="${2:?owner/repo}"; # resolve_ref now returns non-zero when every lookup failed. Without checking it, the caller
    # carried on with an empty ref and printed a broken line with the raw 404 JSON in it.
    ref="$(resolve_ref "$r")" || exit 4
    sha="$(gh api "repos/$r/commits/$ref" --jq '.sha[0:7]' 2>/dev/null)"
    if [ -n "$sha" ]; then echo "$ref ($sha)"; else echo "$ref"; fi ;;

  read)
    r="${2:?owner/repo}"; path="${3:?path}"
    # resolve_ref now returns non-zero when every lookup failed. Without checking it, the caller
    # carried on with an empty ref and printed a broken line with the raw 404 JSON in it.
    ref="$(resolve_ref "$r")" || exit 4
    echo "# $r @ $ref :: $path"
    gh api "repos/$r/contents/$path?ref=$ref" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null \
      || { echo "exemplar.sh: could not read $path at $ref (wrong path, or a directory — try 'grep')" >&2; exit 1; } ;;

  grep)
    r="${2:?owner/repo}"; sub="${3:?subtree}"; pat="${4:-}"
    # resolve_ref now returns non-zero when every lookup failed. Without checking it, the caller
    # carried on with an empty ref and printed a broken line with the raw 404 JSON in it.
    ref="$(resolve_ref "$r")" || exit 4
    # Cache the checkout per repo+ref. Without this, a lane reading twenty files across three
    # monorepos paid twenty full sparse clones — minutes instead of seconds, and unstable line
    # numbers between calls. Set COMPOUND_EXEMPLAR_CACHE=off to force a fresh clone.
    cache="${TMPDIR:-/tmp}/compound-exemplar/$(printf '%s@%s' "$r" "$ref" | tr '/:@ ' '____')"
    # CONCURRENCY. This kit dispatches readers in parallel, so several processes hit one cache dir
    # at once. Testing `-d "$cache/.git"` was wrong three ways, all measured: .git appears the
    # instant a peer STARTS cloning, so a second process took the cache hit against an unpopulated
    # tree and printed "EMPTY — that subtree does not exist at this ref" as a confident finding;
    # a failed clone's `rm -rf` deleted the directory a peer was mid-read of; and three concurrent
    # cold calls all failed outright. No lock is needed — build private, publish atomically, and
    # gate the hit on a marker written only after sparse-checkout has actually populated the tree.
    ready="$cache/.exemplar-ready"
    if [ "${COMPOUND_EXEMPLAR_CACHE:-on}" = "on" ] && [ -f "$ready" ]; then
      d="$cache"; cached=1
    else
      mkdir -p "$(dirname "$cache")" 2>/dev/null
      d="$cache.$$.tmp"; rm -rf "$d" 2>/dev/null; cached=0
    fi
    # --filter=blob:none --sparse fetches the tree without the blobs, then sparse-checkout pulls
    # only the subtree's contents. A 140k-star monorepo becomes a few hundred files.
    if [ "${cached:-0}" = "1" ]; then :
    elif ! git clone --depth 1 --filter=blob:none --sparse -q --branch "$ref" \
         "https://github.com/$r" "$d" 2>/dev/null; then
      git clone --depth 1 --filter=blob:none --sparse -q "https://github.com/$r" "$d" 2>/dev/null \
        || { echo "exemplar.sh: clone failed for $r" >&2; rm -rf "$d" 2>/dev/null; exit 1; }
      ref="$(git -C "$d" rev-parse --short HEAD) (default branch — the tag would not check out)"
    fi
    git -C "$d" sparse-checkout set "$sub" >/dev/null 2>&1
    if [ "$cached" = "0" ]; then
      # Publish. A peer that won the race owns $cache already — take theirs and drop ours rather
      # than replacing a directory someone may be reading out of.
      : > "$d/.exemplar-ready"
      if mv "$d" "$cache" 2>/dev/null; then d="$cache"
      else rm -rf "$d" 2>/dev/null; d="$cache"; git -C "$d" sparse-checkout set "$sub" >/dev/null 2>&1; fi
    fi
    n="$(find "$d/$sub" -type f 2>/dev/null | wc -l | tr -d ' ')"
    echo "# $r @ $ref :: $sub  ($n files)"
    if [ "$n" = "0" ]; then
      echo "# EMPTY — that subtree does not exist at this ref. That is a finding about the registry" >&2
      echo "# row, not about the pattern: re-probe the path before trusting the row again." >&2
      exit 1
    fi
    if [ -n "$pat" ]; then
      ( cd "$d" && grep -rn --include='*.*' -m3 -E "$pat" "$sub" 2>/dev/null | head -40 ) \
        || echo "# no match for /$pat/ in $sub — try the term the CODEBASE would use, not yours"
    else
      ( cd "$d" && find "$sub" -type f | head -40 )
    fi
    [ "${COMPOUND_EXEMPLAR_CACHE:-on}" = "on" ] || rm -rf "$d" ;;

  vet)
    # Decide whether a repo is technical alpha or a popular artifact. STARS ARE DELIBERATELY NOT
    # SCORED, and that is the whole point: sindresorhus/awesome has 501,961 stars — 4x openai/codex,
    # 10x calcom/cal.com — and is a curated link list with no language, no releases and no tests.
    # Stars measure reach, and reach is what marketing buys. What cannot be bought cheaply is a
    # codebase someone has had to keep working: releases that fix things, tests, recent commits.
    r="${2:?owner/repo}"
    # Test the EXIT STATUS, not output emptiness: gh api writes the 404 JSON body to stdout, so
    # `[ -n "$meta" ]` was dead code and `vet no/such-repo` scored a full rubric on a repo that does
    # not exist — the same 2/5 it gives torvalds/linux.
    meta="$(gh api "repos/$r" --jq '[.language // "NONE", .archived, .pushed_at[0:10], .stargazers_count, .description // ""] | @tsv' 2>/dev/null)" \
      || { echo "vet: cannot read $r (typo, private, or rate-limited)" >&2; exit 1; }
    IFS="$(printf '\t')" read -r lang archived pushed stars desc <<< "$meta"
    # Both of these read the SAME endpoint, so a project that tags without cutting GitHub Releases
    # lost two points for one cause — torvalds/linux and postgres/postgres both scored 2/5. Score
    # release-hygiene ONCE, and give tagging its own signal so a tags-only project is not punished
    # twice for a publishing convention.
    rel="$(gh api "repos/$r/releases?per_page=10" --jq 'length' 2>/dev/null || echo 0)"
    # Stable releases only: a project cutting daily alphas fills the ten newest slots with
    # ~25-byte prerelease bodies, so openai/codex scored fix-notes 0 while its latest stable
    # release opened with "## Bug Fixes". Read the ten newest NON-prerelease bodies instead.
    # Capture the API's own status: a failed call must not score 0. The heavier page size makes a
    # 5xx likelier, and a swallowed failure prints the same "nobody has lived with it" verdict this
    # block exists to stop — a broken instrument reading as a measurement.
    rel_bodies="$(gh api "repos/$r/releases?per_page=100" --jq '[.[] | select(.prerelease | not)][:10] | [.[].body // ""] | join(" ")' 2>/dev/null)"; fixes_rc=$?
    if [ "$fixes_rc" -eq 0 ]; then
      fixes="$(printf '%s' "$rel_bodies" | grep -ciE 'fix|bug|patch|regression' || true)"
    else
      fixes=""   # unmeasured, not zero
    fi
    tags="$(gh api "repos/$r/tags?per_page=5" --jq 'length' 2>/dev/null || echo 0)"
    tests="$(gh api "repos/$r/contents" --jq '[.[].name]|map(select(test("test|spec|__tests__";"i")))|length' 2>/dev/null || echo 0)"
    # RECENCY, not just "not archived". `archived != true` passes a repo that is dead but merely
    # un-archived: measured, tj/commander.js had 0 commits in the trailing 90 days and still scored
    # 5/5, and left-pad/left-pad — archived, deprecated, last pushed 2019 — scored 3/5, the same as
    # torvalds/linux. A rubric that cannot separate a famous corpse from an operating project is
    # not measuring what "has this been kept working" means.
    recent="$(gh api "repos/$r/commits?per_page=1&since=$(date -u -v-90d +%Y-%m-%d 2>/dev/null || date -u -d '90 days ago' +%Y-%m-%d)" --jq 'length' 2>/dev/null || echo 0)"
    score=0
    [ "$lang" != "NONE" ] && score=$((score+1))
    { [ "$archived" != "true" ] && [ "${recent:-0}" -gt 0 ]; } && score=$((score+1))
    # ONE point for release hygiene, from EITHER signal. Scoring `rel` and `fixes` separately paid
    # a repo that cuts GitHub Releases twice out of one endpoint while a tags-only project got one,
    # which is a publishing convention being scored as engineering quality.
    { [ "${rel:-0}" -gt 0 ] || [ "${tags:-0}" -gt 0 ]; } && score=$((score+1))
    [ "${fixes:-0}" -gt 0 ] && score=$((score+1))
    [ "${tests:-0}" -gt 0 ] && score=$((score+1))
    echo "$r  — $desc"
    printf '  language      %-14s %s\n' "$lang"      "$([ "$lang" != NONE ] && echo 'ok — it is a codebase' || echo 'FAIL — no language: a list, docs, or a collection')"
    # THE DISPLAY MUST EXPLAIN THE SCORE. These two lines described the old scoring and were never
    # updated: left-pad printed two passing signals and scored 3/5, because the tags fallback and
    # the recency term were computed but never shown. A rubric the reader cannot reconcile with its
    # own number is worse than either half alone.
    printf '  maintained    pushed %-7s %s\n' "$pushed" "$({ [ "$archived" != true ] && [ "${recent:-0}" -gt 0 ]; } && echo 'ok — not archived, and commits in the last 90d' || { [ "$archived" = true ] && echo 'FAIL — archived' || echo 'FAIL — no commits in the last 90d: un-archived is not the same as alive'; })"
    printf '  versioned     rel=%-3s tags=%-4s %s\n' "${rel:-0}" "${tags:-0}" "$({ [ "${rel:-0}" -gt 0 ] || [ "${tags:-0}" -gt 0 ]; } && echo 'ok — someone ships versions (releases OR tags)' || echo 'FAIL — never versioned')"
    if [ -z "${fixes}" ]; then
      printf '  fix-notes     %-14s %s\n' "—" "UNMEASURED — the releases API call failed; re-run before reading this row"
    else
      printf '  fix-notes     %-14s %s\n' "$fixes" "$([ "$fixes" -gt 0 ] && echo 'ok — changelogs carry BUG FIXES, not just features' || echo 'FAIL — features only: nobody has lived with it')"
    fi
    printf '  tests         %-14s %s\n' "${tests:-0}" "$([ "${tests:-0}" -gt 0 ] && echo 'ok — top-level test dir' || echo 'weak — none at top level (may be nested)')"
    printf '  stars         %-14s NOT SCORED — reach is what marketing buys\n' "$stars"
    echo
    # A row that could not be measured makes the total a FLOOR, never a verdict — say so rather
    # than letting a failed API call read as a repo nobody maintains.
    floor=""; [ -z "${fixes}" ] && floor=" — and one row is UNMEASURED, so this is a floor, not a verdict: re-run"
    if [ "$score" -ge 4 ]; then echo "  VERDICT: usable as an exemplar ($score/5). Now check the SUBTREE actually contains the pattern.$floor"
    else echo "  VERDICT: do NOT use as an exemplar ($score/5). Popular is not the same as operated.$floor"; fi
    echo "  A score is a floor, never a reason. The real test is whether a team had to KEEP THIS"
    echo "  WORKING for someone — read the issues strangers filed and whether anyone answered."
    echo
    echo "  SCOPE: this rubric is for CODE exemplars and MIS-SCORES knowledge repos — a skill pack,"
    echo "  a guide or a rules collection has no bug-fix changelog and no tests by nature, so it"
    echo "  loses points for being what it is. Never read a low score here as a verdict on one."
    echo "  (No score is quoted in this help text on purpose: one was, naming a repo at 3/5, and"
    echo "  the repo shipped and moved to 4/5 while the text stayed put. Scores drift; rules do not.)"
    echo "  Automated"
    echo "  signals do not separate a curated link-list from a real knowledge base either:"
    echo "  ComposioHQ/awesome-claude-skills has 28 contributors and an Organization owner, same as"
    echo "  the real ones. For a docs/skills repo, open two files and look: a rule carries a correct"
    echo "  and an incorrect example; a list carries links. That read is the discriminator." ;;

  find)
    # ADAPTABLE PER PROJECT. The registry seeds the common stacks; this handles everything else.
    # Discovery uses `gh search repos`, which DOES work (unlike `gh search code`), and then every
    # candidate is vetted stars-blind — because search ranks by popularity and popularity is the
    # thing we specifically refuse to trust.
    q="${2:?usage: exemplar.sh find \"<term>\" [language] [n]}"; lang="${3:-}"; n="${4:-8}"
    echo "# candidates for \"$q\"${lang:+ in $lang} — ranked by GitHub (i.e. by popularity), then vetted"
    cands="$(gh search repos ${lang:+--language="$lang"} --limit "$n" "$q" --json fullName --jq '.[].fullName' 2>/dev/null)"
    [ -n "$cands" ] || { echo "# no candidates. Try the term the ECOSYSTEM uses, not yours." >&2; exit 1; }
    printf '%s\n' "$cands" | while read -r c; do
      [ -n "$c" ] || continue
      v="$("$0" vet "$c" 2>/dev/null | grep -E '^  VERDICT' | sed 's/^  VERDICT: //')"
      printf '  %-42s %s\n' "$c" "${v:-unvettable}"
    done
    echo "# Then: exemplar.sh grep <repo> <subtree> \"<pattern>\" to confirm the pattern is really there."
    echo "# A repo that vets 5/5 and does not contain your pattern is not your exemplar." ;;

  *) echo "usage: exemplar.sh {list|find|vet|ref|read|grep} ..." >&2; exit 2 ;;
esac
