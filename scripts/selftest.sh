#!/usr/bin/env bash
# selftest.sh — prove this kit's own instruments against a KNOWN-BAD reference before anyone
# trusts a number they printed.
#
# Every gate here ships two references: a good one it must pass, and a bad one it must catch on
# the exact axis it claims to measure. The bad reference is always the lazy-but-plausible version
# — the one a weaker instrument already passes — never a strawman, because a strawman proves only
# that the gate is not literally absent.
#
#   bash scripts/selftest.sh            # every tier
#   bash scripts/selftest.sh routing    # one tier: routing | publish | constants | boundaries | coverage
#
# Exit 0 = every instrument discriminated. Exit 1 = at least one is broken or a no-op.
# Exit 2 = could not run (a named missing tool, never an empty result).
#
# Keyless and offline. The routing tier replays canned CLI output through a shim on PATH, so it
# exercises the REAL scripts/trigger-eval.sh — its parser, its scoring, its quota branch — at zero
# API cost. Re-implementing that parser here to test it would be the fake-green this kit warns
# about: the copy would pass while the shipped one rotted.
#
# Honest limits:
#   - scripts/check.sh does NOT call this file. It cannot: this tier proves check.sh by RUNNING it
#     against planted references, and a gate that invoked its own prover would recurse, on top of
#     tripling the runtime of the one command everybody runs. That is exactly the opt-in-flag trap
#     this kit criticises elsewhere, committed here knowingly: the mitigation is that it is one
#     command, needs nothing installed, and belongs in the pre-publish sequence beside
#     `bash scripts/hooks-test.sh`.
#   - The coverage tier greps THIS file for a script's name. A script mentioned only in a comment
#     counts as covered, so read that table as an upper bound on coverage, never as proof of it.
#   - It proves instruments DISCRIMINATE. It cannot prove they measure the thing you care about;
#     that is the fixtures' job (scripts/trigger-fixtures.tsv) and it is a different argument.
#   - The planted references write two files into the working tree and delete them on exit. It
#     refuses to start if either name already exists rather than clobbering anything.

set -uo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
cd "$root" || exit 2

tier="${1:-all}"
case "$tier" in all|routing|publish|constants|boundaries|coverage) ;;
  *) printf 'unknown tier: %s (all|routing|publish|constants|boundaries|coverage)\n' "$tier" >&2; exit 2 ;;
esac
want() { [ "$tier" = "all" ] || [ "$tier" = "$1" ]; }

pass=0; miss=0; warn=0
declare -a failures=()
ok()   { pass=$((pass + 1)); printf '%-52s %-10s ok\n' "$1" "$2"; }
bad()  { miss=$((miss + 1)); failures+=("$1 — $3"); printf '%-52s %-10s MISS %s\n' "$1" "$2" "$3"; }
note() { warn=$((warn + 1)); printf '%-52s %-10s warn %s\n' "$1" "$2" "$3"; }

printf '%-52s %-10s %s\n' CASE AXIS RESULT
printf '%.0s-' {1..96}; printf '\n'

# ================================================================================================
# TIER: routing — scripts/trigger-eval.sh, replayed offline
# ================================================================================================
if want routing; then
  # A missing tool disables ONE tier, never the run. Stock macOS ships no `timeout`, and exiting
  # here took the four tiers that need no external tool with it — a fresh-machine operator got zero
  # proof and a tool error, which is the same screen as "nothing to check".
  if ! command -v timeout >/dev/null 2>&1; then
    printf 'routing: UNRUNNABLE — GNU timeout not found (brew install coreutils).\n' >&2
    printf 'This is a TOOL failure, not a clean result. The remaining tiers still run.\n' >&2
    ROUTING_UNRUNNABLE=1
  fi
  if [ -z "${ROUTING_UNRUNNABLE:-}" ]; then
  shim="$(mktemp -d)"; trap 'rm -rf "$shim"' EXIT
  export SELFTEST_CALLS="$shim/calls" SELFTEST_PROBE="$shim/probe.json" SELFTEST_BODY="$shim/body.json"

  # The shim answers call 1 (the arm's activation probe) from PROBE and every later call from BODY,
  # so an arm that must fail activation and an arm whose ROWS must fail are separable cases.
  cat > "$shim/claude" <<'SHIM'
#!/usr/bin/env bash
n=$(( $(cat "$SELFTEST_CALLS" 2>/dev/null || echo 0) + 1 )); printf '%s' "$n" > "$SELFTEST_CALLS"
if [ "$n" = 1 ]; then cat "$SELFTEST_PROBE"; else cat "$SELFTEST_BODY"; fi
exit "${SELFTEST_RC:-0}"
SHIM
  chmod +x "$shim/claude"
  PATH="$shim:$PATH"; export PATH

  INIT_OK='{"type":"system","subtype":"init","skills":["compound-v:evals","compound-v:recheck"],"slash_commands":["compound-v:evals"],"agents":["general-purpose"],"plugins":[{"name":"compound-v","path":"/replay","version":"0.0.0"}],"mcp_servers":[]}'
  INIT_DEAD='{"type":"system","subtype":"init","skills":[],"slash_commands":[],"agents":[],"plugins":[],"mcp_servers":[]}'

  # run_replay <probe-json> <body> <expected-exit> ; echoes the run's stdout
  run_replay() {
    printf '%s\n' "$1" > "$SELFTEST_PROBE"
    printf '%s' "$2" > "$SELFTEST_BODY"
    : > "$SELFTEST_CALLS"
    CASE_TIMEOUT=20 ARM_PROBE_TIMEOUT=20 bash scripts/trigger-eval.sh "$3" 2>&1
  }

  # GOOD reference: a real Skill tool_use block. The instrument must score it as a hit.
  out="$(run_replay "$INIT_OK" '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Skill","input":{"skill":"compound-v:evals"}}]}}' evals)"; rc=$?
  # The numerator must be non-zero AND the fixture must be named. trigger-eval.sh prints
  # "0/0 fired correctly" and exits 0 when no row matched, so asserting rc+substring alone passes
  # with nothing executed — the green-because-nothing-ran failure this file exists to catch.
  if [ "$rc" -eq 0 ] \
     && printf '%s' "$out" | grep -qE '^[1-9][0-9]*/[1-9][0-9]* fired correctly' \
     && printf '%s' "$out" | grep -q 'evals'; then
    ok "routing: real Skill call scores a hit" "good-ref"
  else
    bad "routing: real Skill call scores a hit" "good-ref" "exit $rc — no non-zero hit naming the fixture; the parser or the fixture set moved"
  fi

  # BAD reference, lazy-but-plausible: the model NARRATES the skill instead of calling it. A parser
  # that greps for the skill name anywhere in the stream passes this; the shipped one must not.
  # This is the artifact class that produced 41 of 74 recorded failures in that run — a parser bug
  # reported as a capability result (a further 31 were a wrong test oracle, a different defect).
  # benchmarks/results/2026-06-16-correctness-gate-fix.md:28,32.
  out="$(run_replay "$INIT_OK" '{"type":"assistant","message":{"content":[{"type":"text","text":"I will use the Skill tool with skill compound-v:evals for this."}]}}' evals)"; rc=$?
  if [ "$rc" -eq 1 ] && printf '%s' "$out" | grep -q 'MISS'; then
    ok "routing: narrated skill is NOT a hit" "bad-ref"
  else
    bad "routing: narrated skill is NOT a hit" "bad-ref" "exit $rc — prose about a skill scored as an invocation"
  fi

  # BAD reference: nothing came back at all. For a row expecting NONE this is the dangerous case —
  # "ran fine and correctly routed nowhere" and "never ran" are byte-identical outputs.
  out="$(run_replay "$INIT_OK" '' NONE)"; rc=$?
  if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q 'run failed'; then
    ok "routing: empty output is not a NONE pass" "bad-ref"
  else
    bad "routing: empty output is not a NONE pass" "bad-ref" "exit $rc — a run that produced nothing scored as correct routing"
  fi

  # A quota refusal is not a routing result. Pooling the two produces a report that reads like the
  # kit is broken when in fact it was never asked.
  out="$(run_replay "$INIT_OK" 'You'"'"'ve hit your session limit. Resets 3pm' evals)"; rc=$?
  if [ "$rc" -eq 2 ] && printf '%s' "$out" | grep -q 'NEVER RAN'; then
    ok "routing: quota refusal is unmeasured, not a miss" "classify"
  else
    bad "routing: quota refusal is unmeasured, not a miss" "classify" "exit $rc — a quota wall was pooled with routing results"
  fi

  # The arm itself (scripts/arm.sh): a plugin dir that loaded nothing must stop the run BEFORE it
  # spends. The rows would otherwise all report well-formed misses and read as a kit-wide regression.
  out="$(run_replay "$INIT_DEAD" '{"type":"assistant","message":{"content":[]}}' evals)"; rc=$?
  if [ "$rc" -eq 2 ] && printf '%s' "$out" | grep -q 'refusing to spend'; then
    ok "routing: unactivated arm refuses to spend" "gate"
  else
    bad "routing: unactivated arm refuses to spend" "gate" "exit $rc — an arm with no kit in it was allowed to produce numbers"
  fi

  rm -rf "$shim"; trap - EXIT
  PATH="${PATH#*:}"
  fi   # end ROUTING_UNRUNNABLE guard
fi

# ================================================================================================
# TIER: publish — scripts/check.sh, against planted references
# ================================================================================================
if want publish; then
  planted_doc="references/.selftest-planted.md"
  planted_key="selftest-planted.pem"
  if [ -e "$planted_doc" ] || [ -e "$planted_key" ]; then
    printf 'refusing to run: %s or %s already exists. Delete it (it is a test artifact) and re-run.\n' \
      "$planted_doc" "$planted_key" >&2
    exit 2
  fi
  cleanup_planted() { rm -f "$planted_doc" "$planted_key"; }
  trap cleanup_planted EXIT

  # GOOD reference: the tree as it stands must pass. Without this half, a gate that fails on
  # everything would score perfectly on the bad references below.
  if bash scripts/check.sh >/dev/null 2>&1; then
    ok "publish: clean tree passes" "good-ref"
  else
    bad "publish: clean tree passes" "good-ref" "check.sh already fails — fix that before trusting anything below"
  fi

  # BAD reference for the CONTENT gate: a private token inside a shipped file.
  printf 'SELFTEST-PLANTED-LEAK-TOKEN\n' > "$planted_doc"
  out="$(COMPOUND_PRIVATE_PATTERN='SELFTEST-PLANTED-LEAK-TOKEN' bash scripts/check.sh 2>&1)"; rc=$?
  if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q 'internal-corpus references'; then
    ok "publish: content gate catches a planted token" "bad-ref"
  else
    bad "publish: content gate catches a planted token" "bad-ref" "exit $rc — the leak gate is a no-op"
  fi
  rm -f "$planted_doc"

  # BAD reference for the PATH gate, which is a different gate with a different blind spot: a
  # content scan cannot see an unignored directory, and only this pass can.
  printf 'not a real key\n' > "$planted_key"
  out="$(bash scripts/check.sh 2>&1)"; rc=$?
  if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q 'UNIGNORED private path'; then
    ok "publish: path gate catches an unignored secret" "bad-ref"
  else
    bad "publish: path gate catches an unignored secret" "bad-ref" "exit $rc — \`git add -A\` would stage a .pem silently"
  fi
  cleanup_planted; trap - EXIT

  # The gate must DEGRADE rather than disappear when nobody configured a private list. check.sh
  # says it keeps the structural patterns in that case; this plants one (an absolute home path) and
  # proves it, so a future edit that short-circuits the whole gate on a missing list is caught here
  # instead of on the day something publishes.
  # Assembled at runtime on purpose. Writing the literal home path here would trip check.sh's leak
  # gate on THIS file — scripts/ is scanned and only check.sh itself is exempt — so the prover
  # would fail the gate it exists to prove. Caught by running it, which is the argument for
  # running it.
  printf 'see /%s/someone/private-notes for the real numbers\n' Users > "$planted_doc"
  out="$(COMPOUND_PRIVATE_PATTERN='^$' bash scripts/check.sh 2>&1)"; rc=$?
  rm -f "$planted_doc"
  if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q 'internal-corpus references'; then
    ok "publish: gate degrades, never disappears" "fail-closed"
  else
    bad "publish: gate degrades, never disappears" "fail-closed" "exit $rc — with no private list the gate stopped checking anything"
  fi
fi

# ================================================================================================
# TIER: constants — the same number stated in three places
# ================================================================================================
# A set that agrees can be uniformly wrong: the description cap sat at 1024 across the gate and
# both documents for the kit's whole life, every copy agreeing with every other, and the number
# appears nowhere in the harness. Mutual consistency is not an anchor; it only makes drift visible.
# The anchor has to be outside the set, and here that is the harness's own docs page, named below.
if want constants; then
  con() { # con <label> <regex> <file>...
    local label="$1" re="$2"; shift 2
    local f absent=''
    for f in "$@"; do grep -qE "$re" "$f" || absent="$absent $f"; done
    if [ -z "$absent" ]; then ok "constants: $label" "agree"
    else bad "constants: $label" "agree" "not found in:$absent"; fi
  }
  # Comparing the OPERATIVE value against the documented one, never asserting a string appears
  # somewhere in the file. check.sh's own comments quote these numbers independently of the code
  # that uses them, so a `grep -q 1536` passes while the gate itself has drifted to anything —
  # proved by mutation: COMPOUND_V_DESC_CAP=2048 printed "ok" against the string form.
  con_op() { # con_op <label> <extract-regex-with-one-capture> <doc-regex-template> <doc-file>...
    local label="$1" ex="$2" tmpl="$3"; shift 3
    local val f absent=''
    val="$(sed -nE "s/.*${ex}.*/\1/p" scripts/check.sh | head -1)"
    if [ -z "$val" ]; then
      bad "constants: $label" "agree" "no operative value matched in scripts/check.sh — the gate moved or was renamed"
      return
    fi
    # Docs write these with a thousands comma ("1,536"), code without. Build a regex that accepts
    # either from the operative digits, so the comparison is on the VALUE, not on its formatting.
    local flex
    if [ "${#val}" -eq 4 ]; then flex="${val:0:1},?${val:1}"; else flex="$val"; fi
    for f in "$@"; do grep -qE "${tmpl//NNNN/$flex}" "$f" || absent="$absent $f"; done
    if [ -z "$absent" ]; then ok "constants: $label (operative $val)" "agree"
    else bad "constants: $label" "agree" "check.sh uses $val; not documented in:$absent"; fi
  }
  con_op "description cap (desc + when_to_use)" \
      'DESC_CAP="\$\{COMPOUND_V_DESC_CAP:-([0-9]+)\}"' 'NNNN' \
      references/skill-format.md references/skill-listing-budget.md
  con_op "compaction warn threshold (words)" \
      '-gt ([0-9]+) \]; then note "\$f: \$w words' 'NNNN' \
      references/skill-format.md references/skill-listing-budget.md
  con_op "body target (lines)" \
      '-gt ([0-9]+) \]; then note "\$f: \$n lines' 'NNNN' \
      references/skill-format.md
  con_op "body hard ceiling (lines)" \
      '-gt ([0-9]+) \]; then err  "\$f: \$n lines' 'NNNN' \
      references/skill-format.md
  con "listing budget = 1% of the context window" '1% of the' \
      references/skill-format.md references/skill-listing-budget.md

  if grep -q 'code.claude.com/docs/en/skills' references/skill-listing-budget.md; then
    ok "constants: an EXTERNAL anchor is named" "anchor"
  else
    bad "constants: an EXTERNAL anchor is named" "anchor" "every copy of the cap now cites only the other copies"
  fi
fi

# ================================================================================================
# TIER: boundaries — where the kit's own delivery layer stops
# ================================================================================================
# A discipline does not persist because it was loaded once. hooks/hooks.json is the only thing that
# re-injects the router, so every boundary its matcher omits is a session running kit-unaware.
# Source for the value list: code.claude.com/docs/en/hooks — "SessionStart | how the session started
# | startup, resume, clear, compact, fork".
if want boundaries; then
  m="$(grep -oE '"matcher": *"[^"]*"' hooks/hooks.json 2>/dev/null | head -1)"
  gap=''
  for src in startup resume clear compact fork; do
    case "$m" in *"$src"*) ;; *) gap="$gap $src" ;; esac
  done
  if [ -z "$gap" ]; then ok "boundaries: SessionStart covers every source" "coverage"
  else note "boundaries: SessionStart misses:$gap" "coverage" "those sessions start with no router"; fi

  if grep -q '"SubagentStart"' hooks/hooks.json 2>/dev/null; then
    ok "boundaries: subagents get the router" "coverage"
  else
    note "boundaries: no SubagentStart hook" "coverage" "every dispatched worker runs router-unaware"
  fi
fi

# ================================================================================================
# TIER: coverage — which instruments have a case here at all
# ================================================================================================
# The selftest that skips the tier your headline came from is worse than none, because the claim
# "every instrument is verified" then reads as true. This prints the gap instead of hiding it.
if want coverage; then
  printf '\n%-26s %-22s %s\n' INSTRUMENT KIND 'PROVED HERE?'
  for s in scripts/*.sh; do
    b="$(basename "$s")"
    [ "$b" = "selftest.sh" ] && continue
    kind='helper'
    grep -q 'claude -p' "$s" && kind='SPENDS (live CLI)'
    case "$b" in check.sh) kind='publish gate' ;; hooks-test.sh|ledger.sh) kind='proved by hooks-test.sh' ;; esac
    if grep -q "scripts/$b" "$SELF"; then hit='yes'; else hit='NO CASE'; fi
    printf '%-26s %-22s %s\n' "$b" "$kind" "$hit"
    if [ "$hit" = 'NO CASE' ] && [ "$kind" = 'SPENDS (live CLI)' ]; then
      note "coverage: $b spends and is unproved" "coverage" "add a replay case or say why not"
    fi
  done
  printf '\n'
fi

printf '\n%s/%s instruments discriminated, %s warning(s)\n' "$pass" "$((pass + miss))" "$warn"
if [ "${#failures[@]}" -gt 0 ]; then
  printf '\nBroken instruments — every number they produced is suspect until these pass:\n'
  printf '  %s\n' "${failures[@]}"
fi
[ "$miss" -eq 0 ]
