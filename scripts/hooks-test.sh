#!/usr/bin/env bash
# hooks-test.sh — prove the Stop gate blocks the one thing it claims to and nothing else.
#
# A Stop hook runs on every turn in every repo the plugin is installed in, so a false block
# costs a wasted turn and the user's trust in the whole kit. Each case below pins one guard;
# the ALLOW cases are the important half — three of them exist because the trigger as
# originally specified fired on the exact opposite of a completion claim.
#
# Pure bash: synthetic transcripts under scripts/fixtures/stop/, a synthetic hook-input JSON
# piped to the hook. No CLI, no network, no API — unlike trigger-eval.sh, this runs anywhere.
#
#   bash scripts/hooks-test.sh
#
# Exit 0 = every case behaved. Exit 1 = at least one miss.

set -uo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 2

command -v jq >/dev/null 2>&1 || { echo "jq not found — the gate no-ops without it, and so does this test"; exit 2; }

hook="hooks/stop-verify"
fx="scripts/fixtures/stop"
pass=0; miss=0
declare -a failures=()

# run <name> <expect: BLOCK|ALLOW> <transcript-or-path> [extra-input-jq-args...]
run() {
  local name="$1" expect="$2" tpath="$3"; shift 3
  local in out got
  in="$(jq -n --arg t "$tpath" --arg c "$root" "$@" \
        '{hook_event_name: "Stop", session_id: "test", transcript_path: $t, cwd: $c,
          stop_hook_active: ($ARGS.named.active // false),
          last_assistant_message: ($ARGS.named.final // null)}')"
  out="$(printf '%s' "$in" | bash "$hook" 2>/dev/null)"; local rc=$?
  got="ALLOW"
  [ "$(printf '%s' "$out" | jq -r 'try .decision catch ""' 2>/dev/null)" = "block" ] && got="BLOCK"
  # A non-zero exit from a Stop hook is itself a failure mode: exit 2 blocks with no reason,
  # and anything else surfaces as a hook error. The gate must always exit 0.
  if [ "$rc" -ne 0 ]; then
    miss=$((miss + 1)); failures+=("$name — exited $rc (must always exit 0)")
    printf '%-42s %-6s MISS exit %s\n' "$name" "$expect" "$rc"; return
  fi
  if [ "$got" = "$expect" ]; then
    pass=$((pass + 1)); printf '%-42s %-6s ok\n' "$name" "$expect"
  else
    miss=$((miss + 1)); failures+=("$name — expected $expect, got $got")
    printf '%-42s %-6s MISS got %s\n' "$name" "$expect" "$got"
  fi
}

printf '%-42s %-6s %s\n' "CASE" "EXPECT" "RESULT"
printf '%.0s-' {1..64}; printf '\n'

# The one failure the gate exists to catch.
run "claim + edits + no command"            BLOCK "$fx/block-claim-no-command.jsonl"
# Turn scoping: last turn's command does not pay for this turn's claim.
run "bash in a PREVIOUS turn only"          BLOCK "$fx/block-bash-in-previous-turn.jsonl"

# Convergence. The same blocking transcript must pass once the harness says it already
# blocked — this is what caps the gate at one block per turn so a session can always end.
run "stop_hook_active on a blocking turn"   ALLOW "$fx/block-claim-no-command.jsonl" --argjson active true
# The gate reads only `tail -n 500`, and fails OPEN when the turn boundary falls outside that
# window — a documented choice, not a bug ("if the turn boundary isn't inside the window we fail
# open instead of guessing at a narrower turn"). Every other fixture here is 4-8 lines, so nothing
# exercised the edge. This pins it: the same blocking turn, buried under 519 lines of chatter, is
# allowed. If a future edit changes the window or the fail direction, this case moves and says so.
run "turn start outside the 500-line window"  ALLOW "$fx/allow-turn-start-outside-tail-window.jsonl"

# The transcript is written asynchronously and may not yet hold the turn's final message at Stop
# time (hooks reference); the harness hands over the real final text as last_assistant_message.
# Each fixture's flushed tail says the opposite of the real final message, so the gate must judge
# the real one — in both directions.
run "final claim not yet in the transcript"   BLOCK "$fx/allow-no-claim.jsonl" --arg final "Done — added the retry wrapper."
run "final message is not the flushed claim"  ALLOW "$fx/block-claim-no-command.jsonl" --arg final "Added the wrapper; still working on the retry path."

# Everything the gate must NOT block.
run "a command actually ran"                ALLOW "$fx/allow-command-ran.jsonl"
# A prose-only turn has no command that could observe the change, so demanding one is a false
# block on the commonest Trivial-tier task. The mixed case is the guard on that guard: one code
# file among the docs and the gate must still fire, or "touch a README too" becomes the bypass.
run "docs-only edit + claim"                ALLOW "$fx/allow-docs-only.jsonl"
run "docs AND code edited + claim"          BLOCK "$fx/block-mixed-docs-and-code.jsonl"
# `echo ok` cleared this gate for its whole life — the forgeable-attestation class, committed by
# the gate itself. The two ALLOW rows are the guard on the fix: a real suite must still pass, and
# `ls` is a LEGITIMATE check for "was the file written", so the block list stays at the three
# commands that can never observe anything.
run "contentless command (echo ok)"        BLOCK "$fx/block-contentless-command.jsonl"
# Four forms that ALL satisfied this gate until the filter was fixed: `\b` after `:` requires an
# adjacent word character that never exists, and a trailing separator defeated the `[^&|;]*$` tail.
run "contentless bare colon"              BLOCK "$fx/block-contentless-colon.jsonl"
run "contentless echo, trailing ;"        BLOCK "$fx/block-contentless-trailing-semicolon.jsonl"
run "contentless true, trailing ;"        BLOCK "$fx/block-contentless-true-semicolon.jsonl"
run "contentless echo, backgrounded"      BLOCK "$fx/block-contentless-background.jsonl"
run "a real test command"                  ALLOW "$fx/allow-real-command.jsonl"
run "ls as a genuine existence check"      ALLOW "$fx/allow-ls-is-a-real-check.jsonl"
run "\"still working on it\""               ALLOW "$fx/allow-still-working.jsonl"
run "russian \"not working yet\""            ALLOW "$fx/allow-ru-negation.jsonl"
run "suite, then a trailing edit"           ALLOW "$fx/allow-suite-then-trailing-edit.jsonl"
run "no edits in the turn"                  ALLOW "$fx/allow-no-edits.jsonl"
run "edits but no completion claim"         ALLOW "$fx/allow-no-claim.jsonl"
run "conditional \"done once you...\""      ALLOW "$fx/allow-conditional-claim.jsonl"

# Fail-open. A gate that crashes must let the turn end, never wedge it.
run "transcript path does not exist"        ALLOW "$fx/no-such-file.jsonl"

# The kill switch needs the env var, so it is run explicitly rather than through run().
if [ -n "$(COMPOUND_V_STOP_GATE=off bash "$hook" \
      < <(jq -n --arg t "$fx/block-claim-no-command.jsonl" \
          '{hook_event_name:"Stop",transcript_path:$t,stop_hook_active:false}') 2>/dev/null)" ]; then
  miss=$((miss + 1)); failures+=("kill switch — still emitted a decision")
  printf '%-42s %-6s MISS emitted a decision\n' "kill switch (env)" "ALLOW"
else
  pass=$((pass + 1)); printf '%-42s %-6s ok\n' "kill switch (env)" "ALLOW"
fi

# Malformed stdin must not produce a block or a non-zero exit.
out="$(printf 'not json at all' | bash "$hook" 2>/dev/null)"; rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
  pass=$((pass + 1)); printf '%-42s %-6s ok\n' "malformed stdin" "ALLOW"
else
  miss=$((miss + 1)); failures+=("malformed stdin — exit $rc, output '$out'")
  printf '%-42s %-6s MISS exit %s\n' "malformed stdin" "ALLOW" "$rc"
fi

# The block must name a command to run, or it is a wall rather than a gate.
reason="$(jq -n --arg t "$fx/block-claim-no-command.jsonl" --arg c "$root" \
          '{hook_event_name:"Stop",transcript_path:$t,cwd:$c,stop_hook_active:false}' \
          | bash "$hook" 2>/dev/null | jq -r 'try .reason catch ""')"
case "$reason" in
  *'bash scripts/check.sh'*) pass=$((pass + 1)); printf '%-42s %-6s ok\n' "block names a concrete command" "REASON" ;;
  *) miss=$((miss + 1)); failures+=("block reason did not name this repo's command: '$reason'")
     printf '%-42s %-6s MISS\n' "block names a concrete command" "REASON" ;;
esac

# The manifest is what actually wires the gate up; a valid-JSON check is not enough.
keys="$(jq -r '.hooks | keys_unsorted | join(",")' hooks/hooks.json 2>/dev/null)"
if [ "$(jq -r '.hooks.Stop[0].hooks[0].command' hooks/hooks.json 2>/dev/null)" = '"${CLAUDE_PLUGIN_ROOT}/hooks/stop-verify"' ]; then
  pass=$((pass + 1)); printf '%-42s %-6s ok  (%s)\n' "hooks.json registers Stop" "WIRED" "$keys"
else
  miss=$((miss + 1)); failures+=("hooks.json does not register hooks/stop-verify under Stop")
  printf '%-42s %-6s MISS (%s)\n' "hooks.json registers Stop" "WIRED" "$keys"
fi
if [ "$(jq -r '[.hooks.Stop[0].hooks[].command] | map(select(test("stop-ledger"))) | length' hooks/hooks.json 2>/dev/null)" = "1" ]; then
  pass=$((pass + 1)); printf '%-42s %-6s ok\n' "hooks.json registers stop-ledger" "WIRED"
else
  miss=$((miss + 1)); failures+=("hooks.json does not register hooks/stop-ledger under Stop")
  printf '%-42s %-6s MISS\n' "hooks.json registers stop-ledger" "WIRED"
fi

# ---- the ledger gate + scripts/ledger.sh -----------------------------------------------
# Rewritten after an adversarial recheck found the previous suite 39/39 green with eight live
# defects, the worst of which reproduced the exact failure the gate exists to prevent: one
# typo'd status made a row invisible to BOTH halves, so the hook stayed silent and ledger.sh
# printed 93% and exited 0 on unfinished work. The invariant below is the fix for the suite,
# not just for the code.
lg_dir="$(mktemp -d)"; mkdir -p "$lg_dir/.claude"
trap 'rm -rf "$lg_dir"' EXIT

# THE COHERENCE INVARIANT, asserted on every fixture: the two halves must never both wave a run
# through. ledger.sh exit 0 is permitted ONLY when the hook is silent, and a non-zero ledger.sh
# must be matched by the hook either blocking or saying not-done out loud.
# expect: BLOCK (refuses the stop) | NOTDONE (allows, but says so) | ALLOW (genuinely finished)
lg() { # lg <name> <expect> <ledger-json|-> [active]
  local name="$1" expect="$2" body="$3" active="${4:-false}" out d m got rc lrc
  [ "$body" = "-" ] || printf '%s' "$body" > "$lg_dir/.claude/slices.json"
  out="$(printf '{"hook_event_name":"Stop","cwd":"%s","stop_hook_active":%s}' "$lg_dir" "$active" \
        | bash hooks/stop-ledger 2>/dev/null)"; rc=$?
  d="$(printf '%s' "$out" | jq -r 'try .decision catch ""' 2>/dev/null)"
  m="$(printf '%s' "$out" | jq -r 'try .systemMessage catch ""' 2>/dev/null)"
  if   [ "$d" = "block" ]; then got=BLOCK
  elif [ -n "$m" ];        then got=NOTDONE
  else                          got=ALLOW; fi
  if [ "$rc" -ne 0 ]; then
    miss=$((miss + 1)); failures+=("$name — hook exited $rc (a Stop hook must always exit 0)")
    printf '%-46s %-8s MISS exit %s\n' "$name" "$expect" "$rc"; return
  fi
  if [ "$got" != "$expect" ]; then
    miss=$((miss + 1)); failures+=("$name — expected $expect, got $got")
    printf '%-46s %-8s MISS got %s\n' "$name" "$expect" "$got"; return
  fi
  # Coherence, on the same bytes the hook just judged. Exempt only stop_hook_active: there the
  # hook is ABSTAINING so the turn can end (the harness's convergence guard), not certifying the
  # run — there is no judgment to compare against. Any other silent ALLOW must mean done.
  if [ "$body" != "-" ] && [ "$active" != "true" ]; then
    bash scripts/ledger.sh --path "$lg_dir/.claude/slices.json" >/dev/null 2>&1; lrc=$?
    if [ "$lrc" -eq 0 ] && [ "$got" != "ALLOW" ]; then
      miss=$((miss + 1)); failures+=("$name — INCOHERENT: ledger.sh exit 0 while the hook said $got")
      printf '%-46s %-8s MISS incoherent\n' "$name" "$expect"; return
    fi
    if [ "$lrc" -ne 0 ] && [ "$got" = "ALLOW" ]; then
      miss=$((miss + 1)); failures+=("$name — INCOHERENT: ledger.sh exit $lrc while the hook waved it through silently")
      printf '%-46s %-8s MISS incoherent\n' "$name" "$expect"; return
    fi
  fi
  pass=$((pass + 1)); printf '%-46s %-8s ok\n' "$name" "$expect"
}
OPEN='[{"id":"s1","rows":[{"id":"r1","does":"login works","status":"todo"}]}]'
DONE='[{"id":"s1","rows":[{"id":"r1","status":"passed"},{"id":"r2","status":"dropped","dropped_by":"x","dropped_why":"y"}]}]'

lg "no ledger at all"                        ALLOW   -
lg "a row still todo"                        BLOCK   "$OPEN"
lg "same, stop_hook_active"                  ALLOW   "$OPEN" true
lg "every row genuinely closed"              ALLOW   "$DONE"
lg "flat row array (hand-written)"           BLOCK   '[{"id":"r1","status":"todo"}]'
lg "12+ open rows (truncated list)"          BLOCK   "$(jq -nc '[{id:"s",rows:[range(0;15)|{id:("r"+(.|tostring)),status:"todo"}]}]')"
# --- the scope-loss channel: an unknown status must be OPEN, never invisible -----------------
lg "status typo: done"                       BLOCK   '[{"id":"s1","rows":[{"id":"a","status":"passed"},{"id":"b","status":"done"}]}]'
lg "status typo: in_progress"                BLOCK   '[{"id":"s1","rows":[{"id":"r1","status":"in_progress"}]}]'
lg "status capitalised: Passed"              BLOCK   '[{"id":"s1","rows":[{"id":"r1","status":"Passed"}]}]'
lg "status padded: \" todo \""                BLOCK   '[{"id":"s1","rows":[{"id":"r1","status":" todo "}]}]'
lg "status null"                             BLOCK   '[{"id":"s1","rows":[{"id":"r1","status":null}]}]'
lg "status numeric"                          BLOCK   '[{"id":"s1","rows":[{"id":"r1","status":7}]}]'
lg "status is an array"                      BLOCK   '[{"id":"s1","rows":[{"id":"r1","status":["todo"]}]}]'
lg "non-object element beside real rows"     BLOCK   '[{"id":"s1","rows":["a note",{"id":"r2","status":"todo"}]}]'
lg "duplicate row ids"                       BLOCK   '[{"id":"s1","rows":[{"id":"r1","status":"passed"},{"id":"r1","status":"passed"},{"id":"r9","status":"todo"}]}]'
lg "nested slice -> sub-slice -> rows"       BLOCK   '[{"id":"s1","rows":[{"id":"sub","rows":[{"id":"r1","status":"todo"}]}]}]'
lg "malformed ledger (not json)"             BLOCK   'not json'
lg "slices present but no rows"              BLOCK   '[{"id":"s1","capability":"x"}]'
# --- nothing open, still not done: must speak rather than wave through -----------------------
lg "only a blocked row left"                 NOTDONE '[{"id":"s1","rows":[{"id":"r1","status":"blocked"}]}]'
lg "dropped with no attribution"             NOTDONE '[{"id":"s1","rows":[{"id":"r1","status":"dropped"}]}]'
lg "dropped, who but no why"                 NOTDONE '[{"id":"s1","rows":[{"id":"r1","status":"dropped","dropped_by":"x"}]}]'
# --- a realistic multi-turn sequence ---------------------------------------------------------
lg "turn 1: 3 open"                          BLOCK   '[{"id":"s1","rows":[{"id":"a","status":"todo"},{"id":"b","status":"todo"},{"id":"c","status":"todo"}]}]'
lg "turn 2: closed one, discovered one"      BLOCK   '[{"id":"s1","rows":[{"id":"a","status":"passed"},{"id":"b","status":"todo"},{"id":"c","status":"todo"},{"id":"d","status":"todo","from":"discovered"}]}]'
lg "turn 3: regression, passed -> todo"      BLOCK   '[{"id":"s1","rows":[{"id":"a","status":"todo"},{"id":"b","status":"todo"},{"id":"c","status":"todo"},{"id":"d","status":"todo","from":"discovered"}]}]'
lg "turn 4: all closed, one blocked"         NOTDONE '[{"id":"s1","rows":[{"id":"a","status":"passed"},{"id":"b","status":"passed"},{"id":"c","status":"blocked"},{"id":"d","status":"passed"}]}]'
lg "turn 5: the blocker cleared"             ALLOW   '[{"id":"s1","rows":[{"id":"a","status":"passed"},{"id":"b","status":"passed"},{"id":"c","status":"passed"},{"id":"d","status":"passed"}]}]'

# The documented shape: slices carry their OWN status alongside their rows. A recursive
# extractor counts those containers as rows and inflates the denominator by one per slice —
# 18 rows read as 23 on the first real ledger this was pointed at. Regression, not hypothesis.
DOCSHAPE='[{"id":"s1","capability":"c1","status":"todo","rows":[{"id":"a","status":"passed"},{"id":"b","status":"passed"}]},{"id":"s2","capability":"c2","status":"todo","rows":[{"id":"c","status":"passed"}]}]'
got_rows="$(printf '%s' "$DOCSHAPE" > "$lg_dir/probe.json"; bash scripts/ledger.sh --path "$lg_dir/probe.json" 2>&1 | grep -F 'declared ')"
if printf '%s' "$got_rows" | grep -qF 'declared 3'; then
  pass=$((pass + 1)); printf '%-46s %-8s ok\n' "slice-with-status is not a row" "3 rows"
else
  miss=$((miss + 1)); failures+=("slice-with-status counted as a row — got: $got_rows")
  printf '%-46s %-8s MISS\n' "slice-with-status is not a row" "3 rows"
fi

# Both Stop hooks are registered on the same event and share one stop_hook_active budget.
# Neither may exit non-zero, and neither may emit anything but a single JSON object.
sv_out="$(printf '{"hook_event_name":"Stop","cwd":"%s","stop_hook_active":false}' "$lg_dir" | bash hooks/stop-verify 2>/dev/null)"; sv_rc=$?
sl_out="$(printf '{"hook_event_name":"Stop","cwd":"%s","stop_hook_active":false}' "$lg_dir" | bash hooks/stop-ledger 2>/dev/null)"; sl_rc=$?
both_ok=1
[ "$sv_rc" -eq 0 ] && [ "$sl_rc" -eq 0 ] || both_ok=0
for o in "$sv_out" "$sl_out"; do
  [ -z "$o" ] && continue
  printf '%s' "$o" | jq -e . >/dev/null 2>&1 || both_ok=0
done
if [ "$both_ok" -eq 1 ]; then
  pass=$((pass + 1)); printf '%-46s %-8s ok\n' "both Stop hooks on one payload" "exit0+json"
else
  miss=$((miss + 1)); failures+=("two Stop hooks on one payload: rc=$sv_rc/$sl_rc, output not both valid JSON")
  printf '%-46s %-8s MISS\n' "both Stop hooks on one payload" "exit0+json"
fi

printf '%s' "$OPEN" > "$lg_dir/.claude/slices.json"
out="$(printf '{"hook_event_name":"Stop","cwd":"%s","stop_hook_active":false}' "$lg_dir" \
      | COMPOUND_V_LEDGER_GATE=off bash hooks/stop-ledger 2>/dev/null)"
if [ -z "$out" ]; then pass=$((pass + 1)); printf '%-46s %-8s ok\n' "kill switch (env)" "ALLOW"
else miss=$((miss + 1)); failures+=("COMPOUND_V_LEDGER_GATE=off did not disable the gate")
     printf '%-46s %-8s MISS\n' "kill switch (env)" "ALLOW"; fi


# Paused is not stopped: a subagent still in flight wakes the session when it lands, so the gate
# abstains, as /goal does. A backgrounded shell must NOT disarm it: a dev server or a log tail
# never lands, so abstaining on one would disarm the gate for the rest of the run.
printf '%s' "$OPEN" > "$lg_dir/.claude/slices.json"
bt() { # bt <name> <expect: BLOCK|ALLOW> <background task type>
  local out d
  out="$(jq -nc --arg c "$lg_dir" --arg ty "$3" \
         '{hook_event_name:"Stop",cwd:$c,stop_hook_active:false,
           background_tasks:[{id:"t1",type:$ty,status:"running",description:"x"}]}' \
         | bash hooks/stop-ledger 2>/dev/null)"
  d="$(printf '%s' "$out" | jq -r 'try .decision catch ""' 2>/dev/null)"
  if { [ "$2" = BLOCK ] && [ "$d" = block ]; } || { [ "$2" = ALLOW ] && [ "$d" != block ]; }; then
    pass=$((pass + 1)); printf '%-46s %-8s ok\n' "$1" "$2"
  else
    miss=$((miss + 1)); failures+=("$1 — expected $2, got decision $d")
    printf '%-46s %-8s MISS\n' "$1" "$2"
  fi
}
bt "open rows, a subagent still in flight"     ALLOW subagent
bt "open rows, only a dev server in flight"    BLOCK shell

# --- ledger.sh: exit codes AND the line it prints, which nothing used to assert ---------------
led() { # led <name> <expect-exit> <ledger-json> [substring-that-must-appear]
  local name="$1" want="$2" f="$lg_dir/probe.json" o rc
  printf '%s' "$3" > "$f"; o="$(bash scripts/ledger.sh --path "$f" 2>&1)"; rc=$?
  if [ "$rc" != "$want" ]; then
    miss=$((miss + 1)); failures+=("$name — ledger.sh exited $rc, expected $want")
    printf '%-46s %-8s MISS exit %s\n' "$name" "exit$want" "$rc"; return
  fi
  if [ -n "${4:-}" ] && ! printf '%s' "$o" | grep -qF -e "$4"; then
    miss=$((miss + 1)); failures+=("$name — output missing '$4' (got: $(printf '%s' "$o" | head -1))")
    printf '%-46s %-8s MISS output\n' "$name" "exit$want"; return
  fi
  pass=$((pass + 1)); printf '%-46s %-8s ok\n' "$name" "exit$want"
}
led "ledger.sh: open rows -> nonzero"        1 "$OPEN"                     "open 1"
led "ledger.sh: all closed -> zero"          0 "$DONE"                     "100%"
led "ledger.sh: blocked is not success"      1 '[{"id":"s1","rows":[{"id":"r1","status":"blocked"}]}]' "blocked is not success"
led "ledger.sh: dropped needs attribution"   1 '[{"id":"s1","rows":[{"id":"r1","status":"dropped"}]}]' "without attribution"
led "ledger.sh: no rows -> cannot tell"      2 '[{"id":"s1","capability":"x"}]'                        "no rows found"
led "ledger.sh: bad status -> cannot tell"   2 '[{"id":"s1","rows":[{"id":"r1","status":"done"}]}]'    "outside"
led "ledger.sh: never prints a blank field"  1 '[{"id":"s1","rows":[{"id":"r1","status":"todo"}]}]'    "discovered +0"
# --- the per-capability floor -----------------------------------------------------------------
# A field run reported 89% with one of four capabilities at zero passed rows. Rows are not spread
# evenly across capabilities, so the aggregate structurally cannot see it.
DEAD='{"slices":[{"id":"A","capability":"works","rows":[{"id":"a1","status":"passed"}]},{"id":"B","capability":"never shipped","rows":[{"id":"b1","status":"todo"},{"id":"b2","status":"todo"}]}]}'
lg "capability with 0 passed + open rows"     BLOCK   "$DEAD"
lg "…all rows dropped is CUT, not dead"       ALLOW   '{"slices":[{"id":"A","capability":"x","rows":[{"id":"a1","status":"passed"}]},{"id":"B","capability":"cut","rows":[{"id":"b1","status":"dropped","dropped_by":"me","dropped_why":"gone","dropped_kind":"void"}]}]}'
lg "…only blocked must not wedge the run"     NOTDONE '{"slices":[{"id":"A","capability":"x","rows":[{"id":"a1","status":"passed"}]},{"id":"B","capability":"stuck","rows":[{"id":"b1","status":"blocked"}]}]}'
# (A slice-level `status: dropped` exemption was written and cut: it lets a run dodge every row in a
# capability with one edit, and nothing in the field data used it. An all-dropped slice covers the
# legitimate case, and each of those drops carries its own attribution.)
led "ledger.sh names the dead capability"     1 "$DEAD" "did not ship, whatever the percentage says"
led "ledger.sh prints a line per capability"  1 "$DEAD" "B  0/2 passed"

# --- typed drops: a requirement that MOVED owes a successor, one that is VOID does not ----------
led "moved drop with no successor"            2 '{"slices":[{"id":"A","capability":"x","rows":[{"id":"a1","status":"passed"},{"id":"a2","status":"dropped","dropped_by":"m","dropped_why":"moved to DM","dropped_kind":"moved"}]}]}' "naming no successor"
led "moved drop naming a stranger"            2 '{"slices":[{"id":"A","capability":"x","rows":[{"id":"a1","status":"passed"},{"id":"a2","status":"dropped","dropped_by":"m","dropped_why":"w","dropped_kind":"moved","replaced_by":["nope"]}]}]}' "naming no successor"
led "moved drop with a real successor"        0 '{"slices":[{"id":"A","capability":"x","rows":[{"id":"a1","status":"passed"},{"id":"a2","status":"dropped","dropped_by":"m","dropped_why":"w","dropped_kind":"moved","replaced_by":["a1"]}]}]}' "100%"
led "void drop owes nothing"                  0 '{"slices":[{"id":"A","capability":"x","rows":[{"id":"a1","status":"passed"},{"id":"a2","status":"dropped","dropped_by":"m","dropped_why":"no such field","dropped_kind":"void"}]}]}' "100%"
led "untyped drop warns, never blocks"        0 '{"slices":[{"id":"A","capability":"x","rows":[{"id":"a1","status":"passed"},{"id":"a2","status":"dropped","dropped_by":"m","dropped_why":"w"}]}]}' "untyped drop"

# --- the delta must read the shape the field actually writes ------------------------------------
led "discovered: true is counted"             1 '{"slices":[{"id":"A","capability":"x","rows":[{"id":"a1","status":"passed"},{"id":"a2","status":"todo","discovered":true}]}]}' "discovered +1"
led "from: discovered still counted"          1 '{"slices":[{"id":"A","capability":"x","rows":[{"id":"a1","status":"passed"},{"id":"a2","status":"todo","from":"discovered"}]}]}' "discovered +1"
led "--open shows the owning slice"           1 "$DEAD" ""

# --discharge: the landing gate. A passed row may only stop existing once it names something that
# outlives the file. The partial-form cases matter most — half a target is no target.
dis() { # dis <name> <expect-exit> <ledger-json>
  local name="$1" want="$2" f="$lg_dir/dis.json" rc
  printf '%s' "$3" > "$f"; bash scripts/ledger.sh --path "$f" --discharge >/dev/null 2>&1; rc=$?
  if [ "$rc" = "$want" ]; then pass=$((pass + 1)); printf '%-46s %-8s ok\n' "$name" "exit$want"
  else miss=$((miss + 1)); failures+=("$name — --discharge exited $rc, expected $want")
       printf '%-46s %-8s MISS exit %s\n' "$name" "exit$want" "$rc"; fi
}
dis "discharge: passed row, no target"       1 '[{"id":"s","rows":[{"id":"a","status":"passed"}]}]'
dis "discharge: rerun command"               0 '[{"id":"s","rows":[{"id":"a","is_check":true,"status":"passed","discharge":{"rerun":"npm test"}}]}]'
dis "discharge: observable + query"          0 '[{"id":"s","rows":[{"id":"a","is_check":true,"status":"passed","discharge":{"observable":"login rate","query":"sum(x)"}}]}]'
dis "discharge: named owner + check"         0 '[{"id":"s","rows":[{"id":"a","is_check":true,"status":"passed","discharge":{"owner":"slava","check":"eyeball the invoice"}}]}]'
dis "discharge: observable with no query"    1 '[{"id":"s","rows":[{"id":"a","status":"passed","discharge":{"observable":"login rate"}}]}]'
dis "discharge: owner with no check"         1 '[{"id":"s","rows":[{"id":"a","status":"passed","discharge":{"owner":"slava"}}]}]'
dis "discharge: run not finished"            1 '[{"id":"s","rows":[{"id":"a","status":"passed","discharge":{"rerun":"x"}},{"id":"b","status":"todo"}]}]'
dis "discharge: blocked blocks the landing"  1 '[{"id":"s","rows":[{"id":"a","status":"passed","discharge":{"rerun":"x"}},{"id":"b","status":"blocked"}]}]'
dis "discharge: dropped needs no target"     0 '[{"id":"s","rows":[{"id":"a","is_check":true,"status":"passed","discharge":{"rerun":"x"}},{"id":"b","status":"dropped","dropped_by":"s","dropped_why":"cut"}]}]'

# The slice's own check must be a row. 135 rows passed and every page wrong, because the goal was
# "make B like A" and no row compared B to A — every row was a true statement about B.
dis "discharge: slice check never a row"     1 '{"slices":[{"id":"S1","capability":"B matches A","check":"side by side","rows":[{"id":"a","status":"passed","does":"header renders","discharge":{"rerun":"x"}}]}]}'
dis "discharge: slice check IS a row"        0 '{"slices":[{"id":"S1","capability":"B matches A","check":"side by side","rows":[{"id":"a","is_check":true,"status":"passed","does":"B/pricing renders identically to A/pricing","discharge":{"rerun":"x"}}]}]}'
led "check-row void-dropped is refused"      2 '{"slices":[{"id":"S1","capability":"x","rows":[{"id":"a","status":"passed"},{"id":"b","is_check":true,"status":"dropped","dropped_by":"m","dropped_why":"w","dropped_kind":"void"}]}]}' "unbuilt, not satisfied"
led "check-row moved-with-successor is fine" 1 '{"slices":[{"id":"S1","capability":"x","rows":[{"id":"a","status":"todo"},{"id":"b","is_check":true,"status":"dropped","dropped_by":"m","dropped_why":"reframed","dropped_kind":"moved","replaced_by":["a"]}]}]}' "declared"
led "no check-row warns, never blocks"       1 '{"slices":[{"id":"S1","capability":"x","check":"c","rows":[{"id":"a","status":"todo"}]}]}' "not carried by any row"

if timeout 5 bash scripts/ledger.sh --path >/dev/null 2>&1; then :; fi
if [ "$?" -ne 124 ]; then pass=$((pass + 1)); printf '%-46s %-8s ok\n' "ledger.sh: --path with no value" "exit2"
else miss=$((miss + 1)); failures+=("ledger.sh --path with no value hangs")
     printf '%-46s %-8s MISS hangs\n' "ledger.sh: --path with no value" "exit2"; fi

printf '\n%s/%s cases behaved\n' "$pass" "$((pass + miss))"
if [ "${#failures[@]}" -gt 0 ]; then
  printf '\nMisses:\n'; printf '  %s\n' "${failures[@]}"
fi
[ "$miss" -eq 0 ]
