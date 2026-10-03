#!/usr/bin/env bash
# stack.sh — detect THIS project's stack at its INSTALLED versions, and print where the
# canonical pattern for it actually lives.
#
# Why a script and not a table: a table of "for stack X read Y" is an index over a moving
# target, and this kit already shipped one that rotted — searching-patterns claimed a
# reference had "70 perf rules" when the installed copy has 64. A script reads the lockfile
# in front of it, so it is correct by construction and costs no context until it is run.
# Output is what enters the window; the source never does.
#
#   bash scripts/stack.sh [dir]     default: cwd
set -uo pipefail
root="${1:-.}"
cd "$root" 2>/dev/null || { echo "no such dir: $root" >&2; exit 2; }

say() { printf '%s\n' "$*"; }
hr()  { printf '\n%s\n' "── $* ──────────────────────────────────"; }

# Resolve an installed version rather than the declared range: the range is what someone
# asked for, the lockfile is what is on disk, and only the second one can be wrong in a way
# the docs will not tell you about.
ver_node() { node -p "require('./node_modules/$1/package.json').version" 2>/dev/null; }
# Resolve the interpreter that actually owns this project's packages BEFORE querying it. Asking
# the system python about a project whose deps live in .venv reports every dependency as absent
# and tells you to go install what is already installed — a confidently wrong reading, which is
# worse than no reading. Print which interpreter answered so a wrong one is visible.
PYBIN=""
pick_py() {
  for c in "${VIRTUAL_ENV:+$VIRTUAL_ENV/bin/python}" ./.venv/bin/python ./venv/bin/python ./env/bin/python; do
    [ -n "$c" ] && [ -x "$c" ] && { PYBIN="$c"; return; }
  done
  if [ -f uv.lock ] && command -v uv >/dev/null 2>&1; then PYBIN="uv run --no-sync python"; return; fi
  command -v python3 >/dev/null 2>&1 && PYBIN="python3"
}
ver_py()   { [ -n "$PYBIN" ] || return 1; $PYBIN -c "import importlib.metadata as m;print(m.version('$1'))" 2>/dev/null; }

declare -a FOUND=()
note_dep() { FOUND+=("$1|$2|$3"); }   # name | installed version | where to read it

hr "PROJECT"
say "path: $(pwd)"
# `-d .git` is false in a worktree or submodule (there .git is a FILE), which silently dropped
# branch+commit from the one output whose whole job is pinning what you read.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 && say "git:  $(git rev-parse --abbrev-ref HEAD 2>/dev/null) @ $(git rev-parse --short HEAD 2>/dev/null)"

# ---------- JavaScript / TypeScript ----------
if [ -f package.json ]; then
  hr "NODE / TYPESCRIPT"
  # Both the dependency list and every version below are resolved by running `node`. With node off
  # PATH each one silently returns empty and a fully-installed project reads as "nothing installed"
  # at exit 0 — telling you to install what is already there. The Python lane already refuses to
  # answer without an interpreter; this lane must too.
  if ! command -v node >/dev/null 2>&1; then
    NO_INTERP=1
    say "interpreter: none found — \`node\` is not on PATH, so no version below can be trusted."
    say "  Install node or run this from the environment that owns the project."
  else
  pm="npm"
  [ -f pnpm-lock.yaml ] && pm="pnpm"; [ -f yarn.lock ] && pm="yarn"; [ -f bun.lockb ] && pm="bun"
  say "package manager: $pm   (lockfile is the authority, not package.json ranges)"
  deps="$(node -p "Object.keys({...(require('./package.json').dependencies||{}),...(require('./package.json').devDependencies||{})}).join('\n')" 2>/dev/null)"
  while read -r d; do
    [ -n "$d" ] || continue
    v="$(ver_node "$d")"; [ -n "$v" ] || continue
    case "$d" in
      next)                 note_dep "$d" "$v" "nextjs.org/docs — pin the major; App Router vs Pages changes every answer" ;;
      react|react-dom)      note_dep "$d" "$v" "react.dev/reference/react" ;;
      @trpc/*)              note_dep "$d" "$v" "trpc.io/docs — v10 and v11 differ in router/procedure shape" ;;
      @tanstack/react-query) note_dep "$d" "$v" "tanstack.com/query/latest — v4→v5 renamed cacheTime→gcTime and dropped callbacks" ;;
      @tanstack/react-table|@tanstack/react-router|@tanstack/react-form|@tanstack/*) \
                            note_dep "$d" "$v" "tanstack.com/$(printf '%s' "${d#@tanstack/react-}")/latest" ;;
      prisma|@prisma/client) note_dep "$d" "$v" "prisma.io/docs" ;;
      drizzle-orm)          note_dep "$d" "$v" "orm.drizzle.team/docs" ;;
      zod)                  note_dep "$d" "$v" "zod.dev — v3 vs v4 changed error and .parse surfaces" ;;
      tailwindcss)          note_dep "$d" "$v" "tailwindcss.com/docs — v3→v4 moved config into CSS" ;;
      vite)                 note_dep "$d" "$v" "vite.dev/config" ;;
      typescript)           note_dep "$d" "$v" "typescriptlang.org/tsconfig" ;;
      vitest|jest)          note_dep "$d" "$v" "$( [ "$d" = vitest ] && echo vitest.dev/api || echo jestjs.io/docs )" ;;
      @testing-library/*)   note_dep "$d" "$v" "testing-library.com/docs — query priority is the whole API" ;;
      hono|express|fastify) note_dep "$d" "$v" "the framework's own docs; check the middleware signature for this major" ;;
      better-auth|next-auth|@auth/*) note_dep "$d" "$v" "AUTH SURFACE — read the installed .d.ts, not a blog" ;;
      stripe)               note_dep "$d" "$v" "MONEY SURFACE — docs.stripe.com/api pinned to the API version in code" ;;
    esac
  done <<< "$deps"
  fi
fi

# ---------- Python ----------
if [ -f pyproject.toml ] || [ -f requirements.txt ] || [ -f uv.lock ]; then
  hr "PYTHON"
  pick_py
  [ -f uv.lock ] && say "lock: uv.lock"
  if [ -n "$PYBIN" ]; then
    say "interpreter: $PYBIN   (versions below come from THIS interpreter)"
  else
    NO_INTERP=1
    say "interpreter: none found — no version below can be trusted; activate the project env first"
  fi
  for p in fastapi django flask pydantic sqlalchemy httpx celery pytest langchain openai anthropic; do
    v="$(ver_py "$p")"; [ -n "$v" ] || continue
    case "$p" in
      fastapi)    note_dep "$p" "$v" "fastapi.tiangolo.com — the docs ARE the reference, examples included" ;;
      pydantic)   note_dep "$p" "$v" "docs.pydantic.dev — v1→v2 is a rewrite; validators renamed" ;;
      sqlalchemy) note_dep "$p" "$v" "docs.sqlalchemy.org — 1.4 vs 2.0 changed the query API entirely" ;;
      *)          note_dep "$p" "$v" "the package's own docs at this exact version" ;;
    esac
  done
fi

# ---------- Rust / Go ----------
[ -f Cargo.toml ] && { hr "RUST"; say "docs.rs at the locked version; \`cargo tree\` for the real graph"; grep -E '^\[dependencies' -A15 Cargo.toml 2>/dev/null | head -16; }
[ -f go.mod ]     && { hr "GO"; say "pkg.go.dev at the locked version"; head -12 go.mod; }

# ---------- The report ----------
hr "STACK DETECTED (installed versions — NOT the declared ranges)"
if [ ${#FOUND[@]} -eq 0 ]; then
  # Which of the two things this silence means depends on whether an interpreter answered at
  # all. Printed unconditionally it contradicted the "interpreter: none found" line in the same
  # output — two opposite readings of one silence. NO_INTERP is set by whichever lane could not
  # resolve its interpreter, so this stays correct for Python as well as Node.
  if [ "${NO_INTERP:-0}" = "1" ]; then
    say "No dependency could be READ — the interpreter that owns this project was not found."
    say "This is not evidence that nothing is installed. Re-run from the environment that owns"
    say "the project (nvm/volta shell, or the activated venv) before concluding anything."
  else
    say "No recognised dependency resolved to an installed version."
  say "That is a finding, not an empty result: either nothing is installed yet (run the"
  say "install first — an uninstalled dep cannot be read and the docs will not tell you"
  say "which version you'd get), or this stack has no row here, in which case the general"
  say "rule applies — read the installed copy, then the maintainer's docs, never a blog."
  fi
else
  printf '%-28s %-12s %s\n' "DEPENDENCY" "INSTALLED" "CANONICAL SOURCE"
  for row in "${FOUND[@]}"; do
    IFS='|' read -r n v w <<< "$row"
    printf '%-28s %-12s %s\n' "$n" "$v" "$w"
  done
fi

hr "READ IN THIS ORDER (cheapest rung that answers the question wins)"
cat <<'EOT'
1. THE COPY YOU INSTALLED — node_modules/<pkg> and its .d.ts, site-packages/<pkg>, vendored
   source. Version-exact by construction, one grep, no network, and the only rung that
   survives a sandboxed run. Answers: a signature, a parameter, an enum, an error class,
   a default. Does NOT answer: why, or how the pieces compose.
2. THE REPO'S OWN CONVENTION — a house wrapper, an AGENTS.md/CLAUDE.md rule, the shape in
   neighbouring files, `git log -S<term>` for the last time someone solved this. A local
   convention OVERRIDES the external canonical one; do not import a clashing "correct" pattern.
3. THE MAINTAINER'S DOCS, PINNED TO THE VERSION ABOVE — the default docs render the current
   major, which is often not yours. If the docs version and the installed version differ,
   that mismatch is itself the finding.
4. THE UPSTREAM REPO AT YOUR TAG — `gh api repos/<o>/<r>/contents/<path>?ref=<tag>` and
   `bash scripts/exemplar.sh grep <owner/repo> <subtree> "<pattern>"` to see how the library uses its own thing. Default branch is HEAD, not you.
5. A LARGE REAL CODEBASE USING IT IN ANGER — only when the question is "what shape should this
   be", never for a signature.

STOP when you can name the pattern AND its anti-pattern, or when two independent primary
sources converge. Everything past that is restatement.
EOT
