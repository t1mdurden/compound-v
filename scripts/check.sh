#!/usr/bin/env bash
# check.sh — verify Compound V against its own constitution and publish boundary.
# No dependencies. Run from anywhere:  bash scripts/check.sh
# Exit 0 = clean, 1 = at least one failure.

set -uo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 2

fail=0
warn=0
err()  { printf 'FAIL  %s\n' "$1"; fail=$((fail + 1)); }
note() { printf 'warn  %s\n' "$1"; warn=$((warn + 1)); }

# 1. Frontmatter, name matches directory, description present, line budget.
#    Constitution: target <=250 lines, hard ceiling 500.
for f in skills/*/SKILL.md; do
  d="$(basename "$(dirname "$f")")"
  head -1 "$f" | grep -q '^---' || err "$f: missing frontmatter opener"
  name="$(awk -F': *' '/^name:/{print $2; exit}' "$f")"
  [ "$name" = "$d" ] || err "$f: name '$name' does not match directory '$d'"
  awk '/^description:/{ok=1} END{exit !ok}' "$f" || err "$f: no description"
  n="$(wc -l < "$f")"
  if   [ "$n" -gt 500 ]; then err  "$f: $n lines (over the 500 hard ceiling)"
  elif [ "$n" -gt 250 ]; then note "$f: $n lines (over the 250 target)"
  fi
  # Words, not lines, are the real budget: a body can double in size with the line count
  # flat just by merging paragraphs, so a line check alone silently stops bounding
  # anything. Compaction re-attaches only the first ~5,000 TOKENS of a skill (~3,750
  # words) — past that, the tail of the file stops existing exactly when context is
  # tightest, so anything below the line has to be expendable.
  w="$(wc -w < "$f")"
  if   [ "$w" -gt 5000 ]; then err  "$f: $w words (over the 5000 hard ceiling)"
  elif [ "$w" -gt 3750 ]; then note "$f: $w words (past the ~5000-token compaction head — the tail may not survive)"
  fi
done

# 2. Publish boundary: shipped files must never name a local path or a private corpus.
#    Private names live in local/private-pattern.txt (gitignored, one per line) or in
#    COMPOUND_PRIVATE_PATTERN; with neither set the structural patterns below still run, so the
#    gate degrades rather than disappearing. NOTE: .gitignore ALSO lists the names as a path-level
#    guard, and that duplication is deliberate. An earlier pass removed them from .gitignore
#    arguing that publishing a denylist leaks what it defends — but this repo's own history
#    already published those names, so the argument was void and the change deleted a working
#    guard for nothing. Content gate here, path gate there; keep both.
#    scripts/ IS scanned — only scripts/check.sh is exempt, because it is the one file that must
#    name the patterns. Exempting the whole directory left every shipped script unscanned.
#    `~/…` counts as an absolute path too: a tilde form once carried a private repo name
#    through this gate untouched, because only the /Users/ spelling was matched.
PRIV="${COMPOUND_PRIVATE_PATTERN:-}"
# One name per line is the natural format and the one README/.gitignore imply. Joining with
# `tr -d '\n'` concatenated them into a single word that matches nothing — the gate kept
# printing 0 failures while checking for a string nobody would ever write. Join on `|`.
[ -z "$PRIV" ] && [ -r local/private-pattern.txt ] && \
  PRIV="$(grep -vE '^[[:space:]]*(#|$)' local/private-pattern.txt | paste -sd'|' -)"
PRIV="${PRIV:-^$}"
# -I skips binaries: a .DS_Store matches path fragments and reports only "Binary file matches",
# which is noise, not a finding. Binaries are caught by their own check below instead — this kit
# ships text, so a binary in the shipped tree is suspect on its own terms and gets named.
# The named subdirectories missed a dated run folder (`research/aie-2026-09-21/`) that a shipped
# file then pointed at. Match any LOCAL research/ path instead — anchored so a URL that merely
# contains /research/ (anthropic.com/research/…, a vendor's research index) is not a hit, because a
# gate that fires on legitimate citations is one people learn to ignore.
leak="$(grep -rInoE "$PRIV"'|(^|[^./A-Za-z])research/[A-Za-z0-9._-]+|_manifest\.json|/Users/[a-z]|/home/[a-z]|~/(Desktop|Users|Documents|src|repos|code)/' \
  skills/ agents/ hooks/ references/ scripts/ README.md .claude-plugin/ 2>/dev/null \
  | grep -v '^scripts/check.sh:' || true)"
if [ -n "$leak" ]; then
  err "internal-corpus references in shipped files (these must never publish):"
  printf '%s\n' "$leak" | sed 's/^/        /'
fi

# 2b. Path-level pass: would `git add -A` stage anything private RIGHT NOW?
#     The scan above greps file CONTENTS under six directories. That is structurally blind to a
#     private directory sitting at the repo root — which is exactly how a .gitignore edit in this
#     project un-ignored a live API key and ~966 private files while this gate printed 0 failures
#     through four independent reviews. A content scan cannot see an unignored path; only a path
#     scan can. Check the filenames git would actually stage, against the same private pattern
#     plus the directories this kit is known to sit beside.
if git rev-parse --git-dir >/dev/null 2>&1; then
  # Plain -E over a stream of filenames. The first version of this check used the flags from the
  # content scan above (-Ino) and then `cut -d: -f3-`; reading from a PIPE grep emits `line:match`
  # with no filename field, so the cut discarded every hit and the check silently found nothing —
  # a gate that reports clean because it is broken is worse than no gate. Proven against a planted
  # case before being trusted.
  stageable="$(git ls-files -o --exclude-standard 2>/dev/null \
    | grep -E "$PRIV"'|^(research|researchfms|guidesfm|local)/|(^|/)\.(env|twitterapi_key|netrc|npmrc|pypirc)$|(^|/)id_(rsa|ed25519)$|\.pem$' \
    | sort -u || true)"
  if [ -n "$stageable" ]; then
    err "UNIGNORED private path(s) — \`git add -A\` would stage these into a public repo:"
    printf '%s\n' "$stageable" | head -20 | sed 's/^/        /'
    printf '        (add them to .gitignore before committing)\n'
  fi
fi

# This kit ships text. A binary in the shipped tree is either OS junk (.DS_Store, which carries
# filesystem path fragments) or something nobody reviewed — both worth naming rather than scanning
# past. Reported, not failed: a legitimate binary asset is possible, just not currently expected.
binaries="$(find skills agents hooks references .claude-plugin -type f 2>/dev/null \
  | while read -r bf; do grep -qI . "$bf" 2>/dev/null || printf '%s\n' "$bf"; done)"
[ -n "$binaries" ] && note "binary file(s) in the shipped tree — review or delete:
$(printf '%s' "$binaries" | sed 's/^/        /')"

# 3. Cross-reference integrity: every <ns>:<name> resolves to a real skill.
#    The namespace is read from the plugin manifest rather than hardcoded, so the generated
#    public edition (a different plugin name, the same skills) checks itself with this same
#    script instead of carrying a patched copy that then drifts from this one.
NS="$(awk -F'"' '/"name"/{print $4; exit}' .claude-plugin/plugin.json 2>/dev/null)"
NS="${NS:-compound-v}"
# Digits belong in the class: a skill name is ^[a-z0-9-]+$ (references/skill-format.md), and a class
# without them cut `get-shit-done-1-carve` to `get-shit-done-` and reported a live skill as dangling.
for r in $(grep -rhoE "${NS}:[a-z][a-z0-9-]+" skills/ agents/ hooks/ README.md 2>/dev/null | sed "s/${NS}://" | sort -u); do
  [ -d "skills/$r" ] || err "dangling cross-reference: ${NS}:$r (no skills/$r)"
done
# A reference to a namespace this plugin is not resolves to nothing for anyone who installed it.
# The check stays namespace-agnostic so a fork under a different plugin name still gets it.
stale="$(grep -rhoE 'compound-[a-z]+:[a-z][a-z0-9-]+' skills/ agents/ hooks/ references/ README.md 2>/dev/null \
         | grep -v "^${NS}:" | sort -u || true)"
[ -n "$stale" ] && err "references to a namespace this plugin is not ('${NS}'):
$(printf '%s' "$stale" | sed 's/^/        /')"

# 4. No @path skill links (they force-load and burn context).
if grep -rnE '@[a-z][a-z0-9-]*/SKILL|@compound-v' skills/ >/dev/null 2>&1; then
  err "@path skill link found (use 'compound-v:<name>' by name instead):"
  grep -rnE '@[a-z][a-z0-9-]*/SKILL|@compound-v' skills/ | sed 's/^/        /'
fi

# 5. Frontmatter keys must be in the harness's documented set. Widen this list from the harness's
#    own frontmatter reference when it ships a field — a stale allowlist reports a real key as
#    "unknown", which reads exactly like a typo and is how a shipped capability stays unreachable.
for f in skills/*/SKILL.md; do
  awk 'NR==1&&/^---/{p=1;next} p&&/^---/{exit} p&&/^[a-zA-Z][a-zA-Z0-9_-]*:/{sub(/:.*/,"");print}' "$f" \
  | while read -r k; do
      case "$k" in
        name|description|when_to_use|argument-hint|arguments|disable-model-invocation|user-invocable|allowed-tools|disallowed-tools|model|effort|context|agent|background|hooks|paths|shell|license|compatibility|metadata) ;;
        *) printf 'FAIL  %s: unknown frontmatter key "%s"\n' "$f" "$k" ;;
      esac
    done
done
unknown="$(for f in skills/*/SKILL.md; do
  awk 'NR==1&&/^---/{p=1;next} p&&/^---/{exit} p&&/^[a-zA-Z][a-zA-Z0-9_-]*:/{sub(/:.*/,"");print}' "$f"
done | sort -u | grep -vE '^(name|description|when_to_use|argument-hint|arguments|disable-model-invocation|user-invocable|allowed-tools|disallowed-tools|model|effort|context|agent|background|hooks|paths|shell|license|compatibility|metadata)$' || true)"
[ -n "$unknown" ] && fail=$((fail + 1))

# 6. Description budget. Descriptions are ALWAYS loaded and share a listing budget across every
#    skill in the session; when it overflows, the harness SHORTENS descriptions — silently killing
#    the trigger phrases that sit at the tail.
#    The per-entry cap is 1,536 chars, and it is `description` + `when_to_use` COMBINED, not
#    `description` alone: "the combined `description` and `when_to_use` text is truncated at 1,536
#    characters in the skill listing" (code.claude.com/docs/en/skills, frontmatter reference).
#    This gate said 1024 for its whole life, which is not a number the harness uses anywhere — the
#    effect was self-inflicted: every description was trimmed against a cap 33% tighter than the
#    real one, spending trigger keywords to satisfy a constraint that did not exist. Measure the
#    instrument before trimming the artifact.
#    The cap is configurable via `skillListingMaxDescChars`, so treat 1536 as the default rather
#    than a law; what is NOT configurable is that the tail is what gets cut, so put the key use
#    case first in every description.
DESC_CAP="${COMPOUND_V_DESC_CAP:-1536}"
desc_total=0
for f in skills/*/SKILL.md; do
  d="$(awk '/^description:/{sub(/^description: */,""); print; exit}' "$f")"
  w="$(awk '/^when_to_use:/{sub(/^when_to_use: */,""); print; exit}' "$f")"
  n=$(( ${#d} + ${#w} ))
  desc_total=$((desc_total + n))
  [ "$n" -gt "$DESC_CAP" ] && err "$f: description+when_to_use $n chars (over the $DESC_CAP cap — the tail is truncated away)"
done
printf 'always-on description cost: %s chars (~%s tokens) across all skills\n' \
  "$desc_total" "$((desc_total / 4))"
[ "$desc_total" -gt 14000 ] && note "description budget $desc_total chars — trim or merge skills; the listing is shortened when it overflows"

# 7. Agents must not pin a worker's model. `recheck` states the rule: "do not set a `model`
#    parameter when you dispatch it; a pin can silently downgrade the worker, and the clean
#    context is what buys the catch, not a model tier." An agent file is a dispatch spec, so
#    a `model:` key there is that same pin, written down.
for f in agents/*.md; do
  [ -e "$f" ] || continue
  if awk 'NR==1&&/^---/{p=1;next} p&&/^---/{exit} p&&/^model:/{found=1} END{exit !found}' "$f"; then
    err "$f: pins a model in frontmatter — workers inherit the session model (see skills/recheck/SKILL.md)"
  fi
done

# 8. Ledger anchors must still be greppable in the file they point at.
#    An anchor names either a skill (`recheck`) or a reference (`references/prior-art.md`). Both are
#    resolved and checked; a target that resolves to neither is reported rather than skipped, because
#    a silently-skipped anchor is an unchecked claim that looks checked.
#    references/sources.md states the contract itself: the Anchor phrase is "text that appears
#    verbatim in the current skill body and can be grepped for". Anchors rot silently whenever a
#    skill is reworded, and a rotted anchor breaks the "read its row first" lookup several skills
#    promise their reader. Case- and emphasis-insensitive so markdown edits don't cause noise.
#    WARNING, not failure: anchors in the older ledger sections have already drifted; hardening
#    this to err() is a follow-up that has to re-sync those rows first.
#    A markdown table cell cannot contain a literal '|', so '|' is a safe field separator here.
norm_md() { tr -d '*_`' | tr '[:upper:]' '[:lower:]' | tr '\n' ' ' | tr -s ' '; }
anchor_pairs="$(mktemp)"; anchor_rot="$(mktemp)"
trap 'rm -f "$anchor_pairs" "$anchor_rot"' EXIT
grep -ohE '`(references/)?[a-z][a-z0-9-]+(\.md)?` *(→|->) *"[^"]+"' references/sources.md 2>/dev/null \
  | sed -E 's/^`((references\/)?[a-z0-9-]+(\.md)?)` *(→|->) *"(.*)"$/\1|\5/' | sort -u > "$anchor_pairs"
anchor_last=''
anchor_body=''
while IFS='|' read -r sk phrase; do
  [ -n "${sk:-}" ] || continue
  case "$sk" in
    references/*) anchor_file="$sk" ;;
    *)            anchor_file="skills/$sk/SKILL.md" ;;
  esac
  # The comment above promises an unresolvable target is "reported rather than skipped, because a
  # silently-skipped anchor is an unchecked claim that looks checked." This line used to be
  # `|| continue`, which did exactly what the comment forbids: anchors written `prior-art.md`
  # instead of `references/prior-art.md` resolved to `skills/prior-art.md/SKILL.md`, missed, and
  # vanished. A checker whose code contradicts its own comment is the worst kind, because the
  # comment is what everyone reads when deciding whether the claim was verified.
  if [ ! -f "$anchor_file" ]; then
    printf '%s → "%s" (target %s does not exist)\n' "$sk" "$phrase" "$anchor_file" >> "$anchor_rot"
    continue
  fi
  if [ "$sk" != "$anchor_last" ]; then
    anchor_body="$(norm_md < "$anchor_file")"
    anchor_last="$sk"
  fi
  needle="$(printf '%s' "$phrase" | norm_md)"
  case "$anchor_body" in
    *"$needle"*) ;;
    *) printf '%s → "%s"\n' "$sk" "$phrase" >> "$anchor_rot" ;;
  esac
done < "$anchor_pairs"
if [ -s "$anchor_rot" ]; then
  note "$(wc -l < "$anchor_rot" | tr -d ' ') ledger anchor(s) no longer appear in the file they point at:"
  sed 's/^/        /' "$anchor_rot"
fi

# 9. Trigger-fixture coverage. Every "this skill doesn't fire" and "this one over-fires" argument
#    about this kit rests on scripts/trigger-eval.sh, and that suite is only as good as its
#    fixtures. The file states its own contract — "Three phrasings per skill minimum: one obvious,
#    one oblique, one where the user jumps straight to the work" — and shipped well under it for a
#    long time with nothing reporting the gap, which is the failure mode the kit warns about
#    elsewhere: an instrument that under-measures looks exactly like a clean result.
#    WARNING, not failure: fixtures are written by hand and a thin suite is a known-and-declared
#    state, not a broken build. What is not acceptable is it being invisible.
fx="scripts/trigger-fixtures.tsv"
if [ -f "$fx" ]; then
  fx_rows="$(grep -cvE '^\s*(#|$)' "$fx")"
  fx_missing=''; fx_thin=''
  for d in skills/*/; do
    s="$(basename "$d")"
    n="$(awk -F'\t' -v s="$s" '!/^\s*(#|$)/{split($2,a,","); for(i in a) if(a[i]==s) c++} END{print c+0}' "$fx")"
    if   [ "$n" -eq 0 ]; then fx_missing="$fx_missing $s"
    elif [ "$n" -lt 3 ]; then fx_thin="$fx_thin $s($n)"
    fi
  done
  skills_n_tmp="$(find skills -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')"
  fx_want=$(( skills_n_tmp * 3 ))
  printf 'trigger fixtures: %s rows against a stated minimum of %s (3 x %s skills) — %s%% of spec\n' \
    "$fx_rows" "$fx_want" "$skills_n_tmp" "$(( fx_rows * 100 / (fx_want > 0 ? fx_want : 1) ))"
  [ -n "$fx_missing" ] && err "skills with NO trigger fixture (routing for these is unmeasured):$fx_missing"
  [ -n "$fx_thin" ] && note "skills under the stated 3-phrasing minimum:$fx_thin"
fi

# 10. Every resource a shipped file NAMES must exist and be tracked by git.
#     The install path serves the git tree, not the working tree, so an untracked file that a
#     skill's always-on description advertises is a command a stranger cannot run and a reference
#     they cannot open — while every local check passes, because locally the file is right there.
#     This is the one defect class that is invisible from inside the repo that has it.
missing=''; untracked=''
#     Anchored so a citation embedded in a longer path is not mistaken for one of ours: a URL
#     like `.../openai-docs/references/prompting-guide.md` names another project's file, and
#     flagging it would train the reader to ignore this gate.
for r in $(grep -rhoE '(^|[^/A-Za-z0-9._-])(references|scripts)/[a-z0-9._-]+\.(md|sh|tsv|jq)' \
             skills/ agents/ hooks/ references/ README.md 2>/dev/null \
           | sed -E 's|^[^rs]*||' | sort -u); do
  if [ ! -f "$r" ]; then missing="$missing $r"; continue; fi
  if git rev-parse --git-dir >/dev/null 2>&1; then
    git ls-files --error-unmatch "$r" >/dev/null 2>&1 || untracked="$untracked $r"
  fi
done
[ -n "$missing" ]   && err "shipped files name a resource that does not exist:$missing"
[ -n "$untracked" ] && err "shipped files name a resource that is NOT TRACKED by git (it will be absent for anyone who installs this):$untracked"

# ---------------------------------------------------------------------------------------------
# 11. Deliberate corner-cuts, harvested rather than remembered.
#     references/completion-ledger.md prescribes a `ceiling:` marker on the line where a shortcut
#     was taken. A prose convention is enforced on the days someone remembers, so the harvest runs
#     here. Two scalars, never a health score: total markers, and markers naming no condition after
#     the comma — those are the ones that rot, because nothing will ever bring anyone back to them.
#     Reported, never failed: a deliberate ceiling is a legitimate engineering choice and this gate
#     has no standing to block one. Vendored trees and build output are skipped.
ceil_hits="$(grep -rInE '(#|//|--) ?ceiling:' \
               --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=dist --exclude-dir=build \
               . 2>/dev/null || true)"
ceil_n="$(printf '%s' "$ceil_hits" | grep -c . || true)"
if [ "${ceil_n:-0}" -gt 0 ]; then
  ceil_no_trigger="$(printf '%s\n' "$ceil_hits" | grep -vE 'ceiling:[^,]+,' | grep -c . || true)"
  note "ceilings: $ceil_n deliberate corner-cut(s) marked, ${ceil_no_trigger:-0} naming no upgrade condition"
fi

# ---------------------------------------------------------------------------------------------
# 12. The description the HARNESS receives, not the bytes on disk.
#     Frontmatter is YAML. In an unquoted plain scalar ` #` opens a comment, so everything after it
#     is silently dropped before the model ever sees it — the skill still looks correct in the file,
#     the char budget above still counts the full line, and the trigger phrases past the marker
#     simply never load. That is how a skill stops firing for a reason no reader can see. Caught
#     once, in the one description that cited an issue number: 53% delivered, and the half that
#     vanished was its entire automatic pre-merge trigger. Quote the scalar and the problem is gone.
for f in skills/*/SKILL.md; do
  line="$(awk -F': ' '/^description:/{sub(/^description: */,""); print; exit}' "$f")"
  case "$line" in
    \'*|\"*) ;;                                                   # quoted: YAML comments cannot open
    *" #"*) err "$f: description is an unquoted YAML scalar containing ' #' — everything after it is dropped before the model sees it. Wrap the value in single quotes." ;;
  esac
done

skills_n="$(find skills -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')"
printf '\n%s skills checked — %s failure(s), %s warning(s)\n' "$skills_n" "$fail" "$warn"
[ "$fail" -eq 0 ]
