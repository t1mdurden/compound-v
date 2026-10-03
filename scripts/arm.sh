#!/usr/bin/env bash
# arm.sh — prove the CONTROL ARM before a measurement run spends anything.
#
# Every number this kit prints about itself comes from a run in a room, and the room is never
# empty. This script names what else is in it, builds an arm that excludes the part it can, and
# refuses to let a paid run start until it has SEEN the treatment activate — because a plugin
# directory that loads nothing produces a well-formed, entirely fake data point that looks
# exactly like a real one.
#
#   bash scripts/arm.sh                # report: what is ambient here, and what each arm loads
#   bash scripts/arm.sh --probe        # spend one turn per arm and diff what they actually saw
#   . scripts/arm.sh                   # sourced: arm_flags[] arm_label arm_banner arm_probe
#
#   (paths in the banner are printed relative to \$HOME: this script's own output is read back
#    into reports, and an absolute /Users/... path is a publish-blocking pattern in check.sh.)
#   ARM=isolated (default) | ambient          COMPOUND_V_PLUGIN_DIR=<path>  overrides the arm's dir
#
# Exit 0 = an arm was built (and with --probe, activation was observed in both).
# Exit 2 = the arm could not be built, or activation could not be confirmed. Do NOT spend.
#
# WHY THIS FILE EXISTS. scripts/trigger-eval.sh is the instrument behind every "this skill fires /
# this one over-fires" claim about the kit, and until this script it ran in whatever room the author
# happened to be standing in. The ambient room holds several times the kit's own skills, all
# competing for one listing budget, and the harness answers an overflow by DROPPING descriptions —
# so a fixture miss gets written up as a wording problem when it is a budget problem. The measured
# per-arm figures and that argument live in references/skill-listing-budget.md; regenerate them here
# with `--probe` rather than trusting a stored copy. The contaminated number is not obviously
# wrong — that is the whole difficulty.
#
# Honest limits, so nobody over-reads this:
#   - It isolates SETTINGS-sourced layers: user-level skills, agents, hooks, globally-enabled
#     plugins, and MCP servers. It does not isolate what the HOST injects — built-in skills, the
#     model, the client's own connectors. The isolated floor above is 51 skills, not zero, and
#     saying so is the point: this is a cleaner room, never a clean one.
#   - It cannot isolate the kit from ITSELF. compound-v's SessionStart hook injects the whole
#     router into every arm, and the router names every skill and its trigger phrases. A
#     trigger-eval number is therefore "router + description", never the description alone. The
#     third arm that would separate them is deliberately not built here, because the hook is how
#     the discipline is delivered — persistence and measurability are in direct tension and this
#     script buys only one of them.
#   - An arm LABEL is not a control. Two arms are comparable only when every other input is
#     byte-identical, the prompt included. If you add a flag to one arm, add it to both.

set -uo pipefail
rel_home_str() { printf '%s' "${1//$HOME/\$HOME}"; }
rel_home() { case "$1" in "$HOME"/*) printf '$HOME/%s' "${1#"$HOME"/}";; *) printf '%s' "$1";; esac; }
_arm_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ARM="${ARM:-isolated}"
case "$ARM" in
  isolated|ambient) ;;
  *) printf 'ARM must be "isolated" or "ambient" (got "%s")\n' "$ARM" >&2; exit 2 ;;
esac

# --- resolve the plugin dir portably ---------------------------------------------------------
# An env override, else this checkout, else the newest installed copy, else exit loudly. A
# hardcoded absolute path would make every published arm unreproducible off one machine, and a
# silent fallback to "no plugin" is the failure this whole script exists to prevent.
arm_plugin_dir() {
  local d
  if [ -n "${COMPOUND_V_PLUGIN_DIR:-}" ]; then
    d="$COMPOUND_V_PLUGIN_DIR"
  elif [ -f "$_arm_root/.claude-plugin/plugin.json" ]; then
    d="$_arm_root"
  else
    d="$(ls -dt "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"/plugins/cache/*/compound-v 2>/dev/null | head -1)"
  fi
  if [ -z "${d:-}" ] || [ ! -f "$d/.claude-plugin/plugin.json" ]; then
    printf 'ARM: no plugin manifest found (looked at COMPOUND_V_PLUGIN_DIR, %s, and the plugin cache).\n' "$(rel_home "$_arm_root")" >&2
    printf 'ARM: refusing to build an arm that would load nothing — an unactivated arm scores like a real one.\n' >&2
    return 2
  fi
  printf '%s' "$d"
}

arm_label="$ARM"
arm_flags=()
if [ "$ARM" = "isolated" ]; then
  _arm_dir="$(arm_plugin_dir)" || exit 2
  # --setting-sources drops the user layer (their skills, agents, hooks, enabled plugins);
  # --plugin-dir puts back exactly one treatment, from a path we name;
  # --strict-mcp-config with no --mcp-config drops every MCP server, whose tools also steer routing.
  arm_flags=(--setting-sources project,local --plugin-dir "$_arm_dir" --strict-mcp-config)
  arm_label="isolated (plugin-dir $(rel_home "$_arm_dir"))"
fi

# --- what is in the room ----------------------------------------------------------------------
# Dependency-free by design: this has to run before anything is installed or authenticated,
# because "I could not check" and "there is nothing to find" must never print the same.
arm_banner() {
  local cfg="${CLAUDE_CONFIG_DIR:-$HOME/.claude}" n
  printf 'ARM: %s\n' "$arm_label"
  printf 'flags: %s\n' "$(rel_home_str "${arm_flags[*]:-<none — the ambient arm passes no flags, which is the point>}")"
  printf 'ambient layers that reach an UNISOLATED run from %s:\n' "$(rel_home "$cfg")"
  n="$(find "$cfg/skills" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
  printf '  user skills           %s (they share the listing budget with this kit)\n' "${n:-0}"
  n="$(find "$cfg/agents" -maxdepth 1 -mindepth 1 2>/dev/null | wc -l | tr -d ' ')"
  printf '  user agents           %s\n' "${n:-0}"
  n="$(grep -coE '"[A-Za-z0-9@._-]+@[A-Za-z0-9._-]+" *: *true' "$cfg/settings.json" 2>/dev/null)"
  printf '  enabled plugins       %s\n' "${n:-0}"
  n="$(grep -ohE '"(PreToolUse|PostToolUse|PostToolUseFailure|SessionStart|SessionEnd|UserPromptSubmit|Stop|SubagentStart|SubagentStop|PermissionRequest|Notification|PreCompact|TaskCreated|TaskCompleted)" *:' \
        "$cfg/settings.json" "$cfg/settings.local.json" 2>/dev/null | sort -u | tr -d '":' | tr '\n' ' ')"
  printf '  user hook events      %s\n' "${n:-<none>}"
  if [ -r "$cfg/CLAUDE.md" ]; then
    printf '  user CLAUDE.md        %s bytes (loads in every session AND every subagent)\n' "$(wc -c < "$cfg/CLAUDE.md" | tr -d ' ')"
  fi
  n="$(env | grep -cE '^(ANTHROPIC|CLAUDE)_' 2>/dev/null)"
  printf '  ANTHROPIC_/CLAUDE_ env %s var(s) inherited from this shell\n' "${n:-0}"
  printf 'the kit re-injects itself in EVERY arm (this is not isolated, by choice):\n'
  printf '  %s\n' "$(grep -oE '"(SessionStart|UserPromptSubmit|Stop|SubagentStart)"' "$_arm_root/hooks/hooks.json" 2>/dev/null | tr -d '"' | sort -u | tr '\n' ' ')"
}

# --- activation, observed rather than assumed ---------------------------------------------------
# Reads the init event the CLI emits before the model speaks. It names the plugins actually loaded,
# so this is a fact about the process, not a judgment about prose the model produced. Parsed with
# grep/sed on purpose: jq is not required to start a run, and a missing jq must not turn a hard gate
# into a skipped one.
# Echoes "<plugin-ok> <skills> <slash_commands> <agents> <plugins> <mcp>" on success.
arm_probe() {
  local want="${1:-compound-v}" line slice n_sk n_sc n_ag n_pl n_mcp
  command -v claude >/dev/null 2>&1 || { printf 'ARM: claude CLI not on PATH — cannot confirm activation.\n' >&2; return 2; }
  # head closes the pipe once the init event is through; claude dies of SIGPIPE instead of running
  # a full turn. rc is deliberately not judged — the verdict is the init line's CONTENT.
  line="$(timeout "${ARM_PROBE_TIMEOUT:-90}" claude -p ok \
            --output-format stream-json --verbose \
            ${arm_flags[@]+"${arm_flags[@]}"} \
            --disallowed-tools 'Bash Edit Write NotebookEdit Task Agent WebFetch WebSearch' \
            2>/dev/null | head -40 | grep -m1 '"subtype":"init"')"
  if [ -z "$line" ]; then
    printf 'ARM: no init event from the CLI — the run never started. Refusing to report an arm.\n' >&2
    return 2
  fi
  slice="$(printf '%s' "$line" | grep -oE '"plugins":\[[^]]*\]')"
  case "$slice" in
    *"\"name\":\"$want\""*) ;;
    *) printf 'ARM: %s did NOT activate in this arm (plugins: %s).\n' "$want" "${slice:-none}" >&2
       printf 'ARM: an unactivated arm produces numbers that look valid. Refusing to spend.\n' >&2
       return 2 ;;
  esac
  # Count members of one array in the init line. `head -1` takes the FIRST match on purpose:
  # "slash_commands" is a suffix of "terminal_slash_commands", so the naive pattern matches twice
  # and the second hit is a different, smaller list. A count that silently reads the wrong field
  # is the instrument bug this kit keeps finding in other people's harnesses.
  # String arrays are counted by separators + 1; an empty array has neither, so it stays 0.
  _arm_count() {
    local sl; sl="$(printf '%s' "$line" | grep -oE "\"$1\":\[[^]]*\]" | head -1)"
    case "$sl" in ''|*'[]') printf '0'; return ;; esac
    printf '%s' "$(( $(printf '%s' "$sl" | grep -o '","' | wc -l | tr -d ' ') + 1 ))"
  }
  # Object arrays ({"name":…},{"name":…}) have commas inside each member, so count the members.
  _arm_objs() {
    local sl; sl="$(printf '%s' "$line" | grep -oE "\"$1\":\[[^]]*\]" | head -1)"
    printf '%s' "$(printf '%s' "$sl" | grep -o '"name"' | wc -l | tr -d ' ')"
  }
  n_sk="$(_arm_count skills)";  n_sc="$(_arm_count slash_commands)"; n_ag="$(_arm_count agents)"
  n_pl="$(_arm_objs plugins)";  n_mcp="$(_arm_objs mcp_servers)"
  printf 'ok %s %s %s %s %s\n' "$n_sk" "$n_sc" "$n_ag" "$n_pl" "$n_mcp"
}

# --- standalone -------------------------------------------------------------------------------
# `return` fails outside a function in a sourced file, so this block only runs when executed.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  case "${1:-}" in
    --probe-one) arm_probe || exit 2; exit 0 ;;   # internal: one arm, one line, no banner
    --probe)
      arm_banner
      printf '\n%-9s %7s %15s %7s %8s %5s\n' ARM skills slash_cmds agents plugins mcp
      rc=0
      for a in isolated ambient; do
        out="$(ARM="$a" bash "${BASH_SOURCE[0]}" --probe-one 2>/dev/null)"
        if [ -z "$out" ]; then
          rc=2
          printf '%-9s %s\n' "$a" "PROBE FAILED — this arm is UNMEASURED, which is not a zero"
        else
          # shellcheck disable=SC2086
          set -- $out; shift; printf '%-9s %7s %15s %7s %8s %5s\n' "$a" "$1" "$2" "$3" "$4" "$5"
        fi
      done
      printf '\nThe gap between those rows is the size of the room the ambient arm was measured in.\n'
      exit "$rc" ;;
    '') arm_banner; exit 0 ;;
    *) printf 'unknown argument: %s (try --probe)\n' "${1}" >&2; exit 2 ;;
  esac
fi
