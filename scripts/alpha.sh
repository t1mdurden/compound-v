#!/usr/bin/env bash
# alpha.sh — one topic, every verified lane, in one command. Returns POINTERS, not content.
#
#   bash scripts/alpha.sh "<topic>" [tier] [language]
#     tier      channel tier to sweep: core (default) | platform | research | podcast | all
#     language  optional language hint for the code lane (typescript, go, python, rust…)
#
# WHY A SCRIPT AND NOT A FAN-OUT OF AGENTS FOR THIS PART.
# Breadth is mechanical and therefore free: listing every candidate costs a few seconds and zero
# tokens. Spending an agent to *find* things burns context on work `grep` does better, and then the
# agent has less room left for the part only it can do — reading a source and judging it. So this
# script does the finding; agents do the reading. Dispatch them over the shortlist it prints, one
# lane each, per compound-v:dispatching-parallel-agents.
#
# RECALL FIRST. Be generous with the topic regex. A false positive costs one transcript; a false
# negative costs a source you never knew existed and cannot later discover, because nothing will
# tell you it was missing.
set -uo pipefail

# Dependency check. Sourced, not duplicated: five scripts need the same answer, and a missing
# tool must become a NAMED failure rather than an empty result that reads like "nothing found".
_pf="$(dirname "${BASH_SOURCE[0]}")/preflight.sh"; [ -r "$_pf" ] && . "$_pf"

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
topic="${1:?usage: alpha.sh \"<topic>\" [tier] [language]}"
tier="${2:-core}"
lang="${3:-}"
enc="$(printf '%s' "$topic" | sed 's/ /%20/g')"
# arXiv spans every field, so an unconstrained term lands in the wrong one: "idempotency" returned
# six pure-algebra papers (semirings, Okubo algebras) and nothing about retries. Constrain to the
# CS categories that carry engineering work. Override with ARXIV_CATS for another field.
CATS="${ARXIV_CATS:-cs.SE+OR+cat:cs.DC+OR+cat:cs.AI+OR+cat:cs.PL+OR+cat:cs.CR+OR+cat:cs.DB+OR+cat:cs.LG}"

hr(){ printf '\n══ %s ══════════════════════════════════════\n' "$1"; }

hr "1. TALKS — verified channels (references/channels.tsv)"
if [ -x "$here/scripts/yt.sh" ]; then
  # NOT 2>/dev/null. That redirect discarded the one channel of information that separates a lane
  # with nothing in it from a lane that never ran: yt.sh writes its tool-failure notice to stderr
  # and exits 3. Measured before this fix — alpha.sh printed a complete 5,786-byte report at exit 0
  # with (0) beside all 32 channels and no hint that yt-dlp had failed on every one of them.
  bash "$here/scripts/yt.sh" sweep "$topic" 200 "$tier"
  if [ "$?" = "3" ]; then
    echo "#   ^^ THE TALKS LANE IS DEAD, NOT EMPTY — yt-dlp failed on every channel." >&2
    echo "#   Treat every (0) above as UNMEASURED. Diagnose with: bash scripts/preflight.sh" >&2
  fi 
else
  echo "  yt.sh missing"
fi

hr "1b. TALKS ALREADY READ — the curated list (references/talks.tsv)"
# The sweep above sees each channel's newest 200 titles, and a channel's canon is usually older than
# that: on the AI Engineer channel (1,159 talks on 2026-09-21) "12-Factor Agents" sat at #814 and
# "No Vibes Allowed" at #629, so the sweep could never surface either. This registry holds talks that
# were READ IN FULL and kept because a builder speaks first-person. The match runs over every column.
if [ -r "$here/references/talks.tsv" ]; then
  awk -F'\t' -v t="$topic" '!/^#/ && NF>=5 && (tolower($0) ~ tolower(t)) {n++; printf "    https://www.youtube.com/watch?v=%s  %s\n        %s\n", $1, $2, $5}
    END {if (!n) print "  (0) no curated talk matches — the sweep above is the recall lane for this topic"}' \
    "$here/references/talks.tsv" | head -30
else
  echo "  references/talks.tsv missing — this lane did not run"
fi

hr "2. PAPERS — arXiv, newest first"
# The API needs -L and a UA; without them it returns nothing and looks like "no papers exist".
# A fixed /tmp path means two concurrent runs silently swap results — run A prints run B's
# papers under run A's heading — and `curl -o` follows a symlink a stranger pre-created there.
ax="$(mktemp -t alpha_ax.XXXXXX)"; trap 'rm -f "$ax"' EXIT
curl -sL --max-time 30 -A "Mozilla/5.0" \
   "http://export.arxiv.org/api/query?search_query=all:%22${enc}%22+AND+%28cat:${CATS}%29&start=0&max_results=8&sortBy=submittedDate&sortOrder=descending" \
   -o "$ax" 2>/dev/null
# A throttle is NOT an absence, and rendering it as one is the worst thing this lane can do:
# "no papers on your topic" and "arXiv refused to answer" look identical in the output and mean
# opposite things. arXiv returns a bare "Rate exceeded." body, so detect it by name and retry once
# — it asks for ~3s between calls.
if grep -qi "rate exceeded" "$ax" 2>/dev/null || [ "$(wc -c < "$ax" 2>/dev/null || echo 0)" -lt 200 ]; then
  sleep 4
  curl -sL --max-time 30 -A "Mozilla/5.0" \
     "http://export.arxiv.org/api/query?search_query=all:%22${enc}%22+AND+%28cat:${CATS}%29&start=0&max_results=8&sortBy=submittedDate&sortOrder=descending" \
     -o "$ax" 2>/dev/null
fi
if grep -qi "rate exceeded" "$ax" 2>/dev/null; then
  echo "  RATE-LIMITED by arXiv after a retry — this is a CHANNEL FAILURE, not an absence of papers."
  echo "  Wait ~10s and re-run. Do not record this lane as empty."
elif [ -s "$ax" ] && grep -q "<feed" "$ax" 2>/dev/null; then
  python3 - "$ax" <<'PY' 2>/dev/null || echo "  (parse failed — read $ax directly)"
import re, pathlib
import sys
x = pathlib.Path(sys.argv[1]).read_text()
es = re.findall(r'<entry>(.*?)</entry>', x, re.S)
if not es:
    print("  (0) no arXiv hits — try a broader term, or the phrase the FIELD uses")
for e in es:
    t = re.sub(r'\s+', ' ', re.search(r'<title>(.*?)</title>', e, re.S).group(1)).strip()
    d = re.search(r'<published>(.*?)</published>', e).group(1)[:10]
    u = re.search(r'<id>(.*?)</id>', e).group(1)
    print(f"  {d}  {t[:88]}\n            {u}")
PY
else
  echo "  arXiv unreachable this run — that is a channel failure, not an absence of papers."
fi

hr "3. CODE — how a project that ships this actually did it"
if [ -x "$here/scripts/exemplar.sh" ]; then
  echo "  registry rows matching /$topic/i:"
  awk -F'\t' -v t="$topic" '!/^#/ && NF>=4 && (tolower($0) ~ tolower(t)) {printf "    %-30s %-26s %s\n", $1, $2, $3}' \
    "$here/references/exemplars.tsv" || true
  echo "  discover + vet beyond the registry (stars are NOT scored):"
  echo "    bash scripts/exemplar.sh find \"$topic\"${lang:+ $lang}"
else
  echo "  exemplar.sh missing"
fi

hr "4. WRITING — engineering blogs, papers, practitioner sites"
echo "  These need a fetch each, so the script names the targets rather than crawling 24 sites."
echo "  Run the searches, then WebFetch what looks real:"
awk -F'\t' '!/^#/ && NF>=4 {printf "    %-46s [%s] %s\n", $1, $3, $2}' \
  "$here/references/publications.tsv" 2>/dev/null | head -30
echo
echo "  Scoped queries to run:"
echo "    WebSearch: \"$topic\" site:anthropic.com/engineering OR site:aws.amazon.com/builders-library"
echo "    WebSearch: \"$topic\" engineering blog postmortem -site:medium.com"
echo "  A row marked [browser] bot-blocks a plain fetch — drive a browser or skip it, but do not"
echo "  record the 403 as 'nothing there'."

hr "5. PEOPLE — who to read on this"
awk -F'\t' -v t="$topic" '!/^#/ && NF>=2 && (tolower($0) ~ tolower(t)) {printf "    @%-20s %s\n", $1, $2}' \
  "$here/references/practitioners.tsv" 2>/dev/null | head -12
echo "    (no name match is normal — the roster is indexed by person, not by topic.)"
echo "    Prefer their WRITING over their posts: an essay is quotable, a caption is not."

hr "NEXT"
cat <<'EOT'
  Read the shortlist, do not read everything. Then judge what comes back against
  references/corroboration.md — count distinct SOURCES rather than findings, and where two top
  sources genuinely disagree, name the axis it turns on and keep both positions.

  Transcripts:  bash scripts/yt.sh transcript <url>     (~5,000 words for a 25-min talk)
  Code:         bash scripts/exemplar.sh grep <repo> <subtree> "<pattern>"

  Captions are SUBSTANCE, never QUOTATION — YouTube mishears proper nouns even on tracks it
  labels "manual". To quote a speaker, confirm against something they wrote.
EOT
