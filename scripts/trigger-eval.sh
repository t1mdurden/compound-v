#!/usr/bin/env bash
# trigger-eval.sh — measure whether Compound V skills actually FIRE.
#
# The kit's whole claim is that every line changes what the agent does. A skill that
# never gets invoked changes nothing, and it fails silently: a description that the
# harness truncated is indistinguishable from one that simply didn't match. This is the
# instrument that turns "does this line earn its keep?" from taste into a number.
#
# It drives the real CLI on your existing session auth (no API key, no SDK) and reports
# which skill each realistic prompt actually invoked.
#
#   bash scripts/trigger-eval.sh                 # every fixture
#   bash scripts/trigger-eval.sh recheck         # only rows expecting recheck
#   REPS=3 bash scripts/trigger-eval.sh          # 3 reps/row; variance IS the signal
#   ARM=ambient bash scripts/trigger-eval.sh     # the contaminated room, on purpose (see scripts/arm.sh)
#
# Exit 0 = every case hit. Exit 1 = at least one miss.
#
# Honest limits, so nobody over-reads the number:
#   - It measures ROUTING (did the right skill fire), never OUTPUT QUALITY.
#   - Each run is one cold turn. It cannot see decay over a long session, which is a
#     real and separate failure mode.
#   - Fixtures are hand-written, so they measure the kit against our guess at how users
#     talk. Rewrite a row the moment a real user phrases it differently.
#   - It measures ROUTER + DESCRIPTION, never the description alone. The kit's own SessionStart
#     hook injects the whole router — which names every skill and its triggers — into every arm,
#     including the isolated one. That is deliberate (the hook is how the discipline is delivered),
#     but it means a passing row does not prove the description would have fired on its own. The
#     mechanism that makes the kit reliable is the same mechanism that contaminates its own
#     measurement, and there is no arrangement of flags that gets you both.
#   - It denies Read, Grep, Glob and Bash as well as the tools that write, and those are how a model
#     handles a task directly instead of consulting a skill. Anthropic's own trigger eval
#     (skill-creator, run_eval.py) restricts no tools and warns that a simple ask "may not trigger a
#     skill even if the description matches perfectly". So a hit here likely reads higher than in a
#     real session, and a NONE row earns its place only as a near miss for a real skill.

set -uo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 2

command -v claude >/dev/null || { echo "claude CLI not found on PATH"; exit 2; }

fixtures="scripts/trigger-fixtures.tsv"
filter="${1:-}"
REPS="${REPS:-1}"
CASE_TIMEOUT="${CASE_TIMEOUT:-300}"
pass=0; miss=0; quota=0
declare -a failures=()

# Everything that could write, spend, schedule, or spawn. Skill stays reachable; nothing
# else that matters does. Denied here rather than merely left off an allow-list, because
# a non-interactive run has nobody to refuse a permission prompt.
DENY='{"permissions":{"deny":["Bash","Edit","Write","NotebookEdit","Task","Agent","WebFetch","WebSearch","TaskCreate","TaskUpdate","TaskStop","CronCreate","CronDelete","RemoteTrigger","ScheduleWakeup","PushNotification","DesignSync","EnterWorktree","ExitWorktree","Workflow","SendMessage","Monitor","Artifact"]}}'

command -v timeout >/dev/null || { echo "GNU 'timeout' not found (brew install coreutils)"; exit 2; }

# The arm. A fixture that misses in a crowded listing is a budget problem scored as a wording
# problem; scripts/arm.sh builds the isolated room and prints which one this run used. ARM=ambient
# runs the contaminated room deliberately — a legitimate but DIFFERENT question.
. scripts/arm.sh
arm_banner
# Activation is observed, never assumed: a --plugin-dir that resolves to nothing yields an arm with
# no kit in it, and every row then reports a well-formed miss. Gate the spend on seeing the plugin.
if ! arm_probe >/dev/null; then
  echo "arm not proven — refusing to spend a session quota on an unmeasurable run" >&2
  exit 2
fi
printf '\n'

printf '%-52s %-26s %s\n' "PROMPT" "EXPECTED" "FIRED"
printf '%.0s-' {1..110}; printf '\n'

while IFS=$'\t' read -r prompt expected; do
  case "$prompt" in ''|'#'*) continue ;; esac
  [ -n "$filter" ] && [[ "$expected" != *"$filter"* ]] && continue

  for _ in $(seq 1 "$REPS"); do
    # Deny by settings, not by --allowed-tools: that flag is an AUTO-APPROVE list, not a
    # restriction, so naming Skill there does not take anything away. The deny list is
    # what actually stops a fixture mutating the repo or firing something consequential.
    # `timeout` bounds the case — the CLI has no turn cap, so a confused run is otherwise
    # unbounded.
    # `${arr[@]+"${arr[@]}"}` rather than a bare `"${arr[@]}"`: macOS ships bash 3.2, where an empty
    # array under `set -u` aborts the script ("a[@]: unbound variable"), and the ambient arm passes
    # no flags. The whole suite would die on the first row, on the default shell, for every user
    # who is not on brew bash.
    raw="$(timeout "$CASE_TIMEOUT" claude -p "$prompt" \
            --output-format stream-json --verbose \
            ${arm_flags[@]+"${arm_flags[@]}"} \
            --settings "$DENY" \
            --disallowed-tools 'Bash Edit Write Read Grep Glob Agent Task WebFetch WebSearch NotebookEdit' \
            2>/dev/null)"; rc=$?

    # A failed run must never score as a pass. Empty output with expected=NONE would
    # otherwise look identical to "ran fine and correctly routed nowhere" — that is the
    # green-because-nothing-ran failure, and it is the one that survives longest.
    # A rate-limit refusal is NOT a routing result and must not be pooled with one. Running ~90
    # live turns exhausts a session quota, and every case after that point returns "You've hit your
    # session limit" — which the old code filed as RUN FAILED alongside genuine harness errors. The
    # two look identical in a summary and mean opposite things: one says the kit may be broken, the
    # other says the kit was never asked. Counting them together produced a report reading
    # "33 ok, 56 failed" that invited exactly the wrong conclusion.
    if printf '%s' "$raw" | grep -qiE "hit your (session|usage) limit|rate.?limit|resets [0-9]"; then
      quota=$((quota + 1))
      printf '%-52.52s %-26.26s ---  NOT RUN (quota exhausted)\n' "$prompt" "$expected"
      continue
    fi
    if [ "$rc" -ne 0 ] || [ -z "$raw" ]; then
      miss=$((miss + 1))
      failures+=("$expected — RUN FAILED (exit $rc) — \"$prompt\"")
      printf '%-52.52s %-26.26s ERR  run failed (exit %s)\n' "$prompt" "$expected" "$rc"
      continue
    fi

    # Every Skill invocation in the turn, deduped, in order.
    fired="$(printf '%s' "$raw" \
      | grep -oE '"name":"Skill","input":\{"skill":"[^"]+"' \
      | sed -e 's/.*"skill":"//' -e 's/"$//' -e 's/^compound-v://' \
      | awk '!seen[$0]++' | paste -sd, -)"
    [ -z "$fired" ] && fired="NONE"

    # Hit = the expected skill is among those fired. For expected=NONE, hit = nothing
    # fired: over-triggering on a trivial ask is exactly as wrong as under-triggering.
    hit=0
    if [ "$expected" = "NONE" ]; then
      [ "$fired" = "NONE" ] && hit=1
    else
      IFS=',' read -ra want <<< "$expected"
      for w in "${want[@]}"; do
        case ",$fired," in *",$w,"*) hit=1 ;; esac
      done
    fi

    if [ "$hit" -eq 1 ]; then
      pass=$((pass + 1)); mark="ok  "
    else
      miss=$((miss + 1)); mark="MISS"
      failures+=("$expected — got '$fired' — \"$prompt\"")
    fi
    printf '%-52.52s %-26.26s %s %s\n' "$prompt" "$expected" "$mark" "$fired"
  done
done < "$fixtures"

# `total` and `ran` were the same expression and `quota` was in neither, so a truncated run
# printed an impossible denominator ("3 of 1 fixtures NEVER RAN") and still exited 0. An
# instrument that goes green while most of the suite never executed is the failure this
# script exists to catch, committed by the script itself.
ran=$((pass + miss))
total=$((pass + miss + quota))
printf '\n%s/%s fired correctly' "$pass" "$ran"
[ "$ran" -gt 0 ] && printf ' (%s%%)' "$((pass * 100 / ran))"
printf ' — of %s cases ATTEMPTED\n' "$ran"
if [ "$quota" -gt 0 ]; then
  printf '\n%s of %s fixtures NEVER RAN (session quota exhausted mid-suite).\n' "$quota" "$total"
  printf 'Those are unmeasured, not passing and not failing. The percentage above is over what\n'
  printf 'actually executed; do not read it as coverage. Re-run the remainder after the reset, or\n'
  printf 'narrow the suite: bash scripts/trigger-eval.sh <skill-name>\n'
fi

if [ "${#failures[@]}" -gt 0 ]; then
  printf '\nMisses — each one is either a description that needs a trigger phrase or a\nfixture that needs rewriting. Decide which before editing anything:\n'
  printf '  %s\n' "${failures[@]}"
fi

# Exit 2 for "unmeasured" so a truncated run is distinguishable from both a pass and a fail.
if [ "$miss" -ne 0 ]; then exit 1; fi
if [ "$quota" -gt 0 ]; then exit 2; fi
exit 0
