#!/usr/bin/env bash
# skills-audit.sh — which skills actually FIRE in real sessions.
#
# trigger-eval.sh measures SYNTHETIC routing: hand-written fixtures, one cold turn each.
# This measures REAL routing — it counts Skill tool invocations in your own local Claude Code
# transcripts. Cold routing vs. warm routing are different questions and you need both.
#
#   bash scripts/skills-audit.sh                 # last 90 days
#   bash scripts/skills-audit.sh --days 3650     # everything on disk
#   CLAUDE_PROJECTS_DIR=/path bash scripts/skills-audit.sh
#
# READ-ONLY, and it must stay that way. This is ONE machine's usage; what ships goes to
# everyone. Wiring an auto-archive to this number would take a global decision on a
# single-user signal. Nothing here writes to skills/.
#
# Two traps it exists to not fall into. Both have already produced a confidently wrong
# report about this kit:
#   1. Names appear BOTH namespaced ("compound-v:evals") and bare ("evals"). A bare name
#      means a personal-level copy is shadowing the plugin (see the install note in
#      README.md). Count only the prefixed form and you undercount — sometimes to zero.
#   2. A zero is absence of evidence, not evidence of death. Opt-in skills say "do not
#      auto-trigger" in their own description, so their zero is compliance. Flagged as such.
#
# Honest limit: --days filters on file MTIME, which is per-file, so a long-lived session file
# counts wholly inside the window. Read a windowed count as an upper bound on recency.
# Per-invocation token cost is NOT reported: a Skill call's tokens are not separable from its
# turn in the transcript. The two size columns are the skill's own cost instead.
#
# No dependencies (find/grep/sed/awk/sort). Slow by nature — it reads a multi-GB corpus, so
# it belongs in a terminal, never in check.sh or a pre-commit hook.
#
# Exit 0 = report printed. Exit 2 = nothing to measure (never a silent table of zeros).

set -uo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 2

days=90
while [ $# -gt 0 ]; do
  case "$1" in
    --days)   days="${2:-}"; shift 2 || exit 2 ;;
    --days=*) days="${1#--days=}"; shift ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) printf 'unknown argument: %s (try --days N)\n' "$1" >&2; exit 2 ;;
  esac
done
case "${days:-}" in ''|*[!0-9]*) printf -- '--days needs a whole number of days\n' >&2; exit 2 ;; esac

corpus="${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}"
[ -d "$corpus" ] || { printf 'no transcript corpus at %s — set CLAUDE_PROJECTS_DIR\n' "$corpus" >&2; exit 2; }

tally="$(mktemp)"; rows="$(mktemp)"
trap 'rm -f "$tally" "$rows"' EXIT

# One pass over the corpus: every Skill invocation, by name. Same block shape trigger-eval.sh
# greps for, so the two instruments count the same event.
find "$corpus" -name '*.jsonl' -mtime "-$days" -exec \
  grep -hoE '"name":"Skill","input":\{"skill":"[^"]+"' {} + 2>/dev/null \
  | sed -e 's/.*"skill":"//' -e 's/"$//' | sort | uniq -c > "$tally"

total="$(awk '{n += $1} END {print n + 0}' "$tally")"
[ "$total" -gt 0 ] || {
  printf 'zero Skill invocations in %s over the last %s day(s).\n' "$corpus" "$days" >&2
  printf 'Refusing to print a table of zeros — that reads as "nothing ever fired" and is how\n' >&2
  printf 'a broken query becomes a finding. Widen --days or check CLAUDE_PROJECTS_DIR.\n' >&2
  exit 2
}

shadowed=0
for f in skills/*/SKILL.md; do
  s="$(basename "$(dirname "$f")")"
  ns="$(awk -v k="compound-v:$s" '$2 == k {print $1}' "$tally")"; ns="${ns:-0}"
  bare="$(awk -v k="$s" '$2 == k {print $1}' "$tally")"; bare="${bare:-0}"
  [ "$bare" -gt 0 ] && shadowed=1
  desc="$(awk '/^description:/{sub(/^description: */,""); if ($0 ~ /^[>|][-+]?$/) {b=1; next} print; exit} b && /^[ \t]/{sub(/^[ \t]+/,""); o = o (o == "" ? "" : " ") $0; next} b{print o; exit}' "$f")"
  flags=''
  [ "$((ns + bare))" -eq 0 ] && flags='never-fired'
  case "$desc" in *[Oo]pt-in*|*"o not auto-trigger"*) flags="${flags:+$flags }opt-in" ;; esac
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$((ns + bare))" "$s" "$ns" "$bare" "${#desc}" "$(wc -w < "$f" | tr -d ' ')" "$flags" >> "$rows"
done

printf '%-30s %6s %6s %6s %6s  %s\n' SKILL FIRED NS BARE DESC WORDS/FLAGS
printf '%.0s-' {1..78}; printf '\n'
# Never-fired first: the rows you are here to look at should not be buried mid-table.
sort -k1,1n -k2,2 "$rows" | while IFS=$'\t' read -r tot s ns bare dchars words flags; do
  printf '%-30s %6s %6s %6s %6s  %6s  %s\n' "$s" "$tot" "$ns" "$bare" "$dchars" "$words" "$flags"
done

never="$(awk -F'\t' '$1 == 0' "$rows" | wc -l | tr -d ' ')"
printf '\n%s Skill invocation(s) over %s day(s); %s of %s skill(s) never fired.\n' \
  "$total" "$days" "$never" "$(wc -l < "$rows" | tr -d ' ')"
[ "$shadowed" -eq 1 ] && printf 'BARE > 0: a personal-level copy is shadowing the plugin. See the install note in README.md.\n'
printf 'A zero is absence of evidence, not evidence of death — read the opt-in flag before acting on one.\n'
exit 0
