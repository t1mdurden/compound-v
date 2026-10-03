#!/usr/bin/env bash
# preflight.sh — what this kit needs on your machine, and whether you have it.
#
# Run it directly to get a checklist:      bash scripts/preflight.sh
# Sourced by the other scripts so a missing tool becomes a NAMED failure instead of an empty result.
#
# WHY THIS FILE EXISTS. Every source lane in this kit shells out to something: `gh` for the code
# lane, `yt-dlp` for the talk lane, `curl` for papers and blogs. Measured on a genuinely
# unauthenticated machine, `exemplar.sh ref trpc/trpc` printed one newline and exited **0** — so the
# repo lane returned an empty ref, `grep` and `read` silently ran against it, and nothing anywhere
# said "you are not logged in". That is precisely the failure this kit teaches people to hunt: a
# channel FAILURE and a channel ABSENCE must never look identical. It was shipped here first.
#
# Note on `gh`: it does NOT fall back to anonymous requests. With no credentials it refuses every
# call with "To get started with GitHub CLI, please run: gh auth login" — so `gh auth login` is a
# hard prerequisite for the code lane, not an optimisation. The README used to claim "no key, no
# login"; that was wrong, and this file is the check that keeps it honest.

set -uo pipefail

_pf_missing=0
_pf_say() { printf '%s\n' "$1" >&2; }

# need <binary> <what it is for> <install hint>
# Returns 0 if present. On absence, names the tool, the lane it disables, and how to install it —
# then returns 1 so the caller can stop instead of returning a confident empty answer.
need() {
  local bin="$1" purpose="${2:-}" hint="${3:-}"
  if command -v "$bin" >/dev/null 2>&1; then return 0; fi
  _pf_say "MISSING DEPENDENCY: $bin"
  [ -n "$purpose" ] && _pf_say "  needed for: $purpose"
  [ -n "$hint" ]    && _pf_say "  install:    $hint"
  _pf_say "  This is a TOOL failure, not an empty result — do not record it as 'nothing found'."
  _pf_missing=$((_pf_missing + 1))
  return 1
}

# gh_ready — `gh` present AND authenticated. Both halves matter: an installed-but-logged-out gh
# fails every API call, and the failure text does not mention rate limits or auth unless you look.
gh_ready() {
  need gh "the code lane (reading real repos at a pinned release)" \
          "brew install gh   |   https://cli.github.com" || return 1
  if ! gh auth status >/dev/null 2>&1; then
    _pf_say "gh IS INSTALLED BUT NOT LOGGED IN."
    _pf_say "  run:        gh auth login          (or set GH_TOKEN=<a personal access token>)"
    _pf_say "  why:        gh makes NO anonymous requests — every API call is refused without it,"
    _pf_say "              so the code lane returns nothing and looks like an empty result."
    _pf_missing=$((_pf_missing + 1))
    return 1
  fi
  return 0
}

# Standalone mode: print the whole checklist and exit non-zero if anything required is absent.
# `return` fails outside a function in a sourced file, so this only runs when executed directly.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  printf '\n  Compound V — dependency check\n'
  printf '  %s\n\n' "-------------------------------"

  ok() { printf '  [ok]      %-10s %s\n' "$1" "$2"; }
  no() { printf '  [MISSING] %-10s %s\n' "$1" "$2"; }

  # Required: without these the kit's own gates cannot run.
  for row in \
    "git|version control, and the code lane's sparse checkouts|https://git-scm.com" \
    "curl|papers (arXiv) and engineering blogs|preinstalled on macOS and most Linux" \
    "jq|the hooks and the ledger checks|brew install jq   |   apt install jq"
  do
    IFS='|' read -r b p h <<< "$row"
    if command -v "$b" >/dev/null 2>&1; then ok "$b" "$p"; else no "$b" "$p — install: $h"; _pf_missing=$((_pf_missing+1)); fi
  done

  # Lane-specific: the kit still runs without these, but the named lane goes dark.
  if command -v gh >/dev/null 2>&1; then
    if gh auth status >/dev/null 2>&1; then ok "gh" "code lane — authenticated"
    else no "gh auth" "gh is installed but LOGGED OUT — run: gh auth login"; _pf_missing=$((_pf_missing+1)); fi
  else
    no "gh" "code lane (exemplar.sh) — install: brew install gh"; _pf_missing=$((_pf_missing+1))
  fi

  if command -v yt-dlp >/dev/null 2>&1; then ok "yt-dlp" "talk lane (yt.sh) — verified channels"
  else no "yt-dlp" "talk lane (yt.sh) — install: brew install yt-dlp   |   pipx install yt-dlp"; _pf_missing=$((_pf_missing+1)); fi

  # Optional: only the stack lane uses these, and only for projects in that language.
  command -v python3 >/dev/null 2>&1 && ok "python3" "stack.sh Python lane (optional)" \
    || printf '  [absent]  %-10s %s\n' "python3" "stack.sh Python lane only — optional"
  command -v node >/dev/null 2>&1 && ok "node" "stack.sh Node lane (optional)" \
    || printf '  [absent]  %-10s %s\n' "node" "stack.sh Node lane only — optional"

  printf '\n'
  if [ "$_pf_missing" -gt 0 ]; then
    printf '  %s item(s) missing. Install them before relying on a source lane: an absent tool makes\n' "$_pf_missing"
    printf '  a lane return nothing, which reads exactly like "there is nothing to find".\n\n'
    exit 1
  fi
  printf '  All set — every source lane is reachable.\n\n'
fi
