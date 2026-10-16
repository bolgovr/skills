#!/usr/bin/env bash
# shellcheck disable=SC2016 # commands are literal payloads, never expanded
set -uo pipefail

# Table-driven test for skills/implement/scripts/block-commit-on-main.sh.
# Builds two throwaway repos (one on main, one on a feature branch), feeds the
# hook PreToolUse payloads, and checks its exit code (2 blocks, 0 allows).

REPO="$(cd "$(dirname "$0")/.." && pwd)"

# Inside a git hook, GIT_DIR and friends point at the repo being committed to.
# Clear them so the throwaway repos below are separate repos, not a re-init of
# that one (which would flip its core.bare to true).
while IFS= read -r var; do unset "$var"; done < <(git rev-parse --local-env-vars)
HOOK="$REPO/skills/implement/scripts/block-commit-on-main.sh"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

git init -q -b main "$tmp/on-main"
git init -q -b feat/x "$tmp/on-feat"
MAIN="$tmp/on-main"
FEAT="$tmp/on-feat"

# A PATH with the tools the hook needs but no JSON parser.
mkdir "$tmp/bin"
for tool in git grep sed cat; do ln -s "$(command -v "$tool")" "$tmp/bin/$tool"; done

json_escape() {
  local s=${1//\\/\\\\}
  printf '%s' "${s//\"/\\\"}"
}

failures=0

# run <expected exit> <cwd> <command> [raw payload] [PATH]
run() {
  local expected=$1 cwd=$2 cmd=$3 payload=${4:-} path=${5:-$PATH}
  [ -n "$payload" ] || payload="{\"cwd\":\"$(json_escape "$cwd")\",\"tool_input\":{\"command\":\"$(json_escape "$cmd")\"}}"
  local actual
  (cd "$cwd" && printf '%s' "$payload" | PATH=$path "$BASH" "$HOOK" 2>/dev/null)
  actual=$?
  if [ "$actual" != "$expected" ]; then
    echo "FAIL (want $expected, got $actual) [$(basename "$cwd")]: $cmd"
    failures=$((failures + 1))
  fi
}

# Allowed.
run 0 "$MAIN" 'git status'
run 0 "$MAIN" 'git log --grep commit'
run 0 "$MAIN" 'gitk --all'
run 0 "$FEAT" 'git commit -m x'
run 0 "$FEAT" 'git push -u origin feat/x'
run 0 "$FEAT" 'git push origin feat/main-thing'
run 0 "$MAIN" 'not json, no git here' 'not json, no git here'

# Blocked on a main checkout, however the command is spelled.
run 2 "$MAIN" 'git commit -m x'
run 2 "$MAIN" 'git push'
run 2 "$MAIN" 'git -c user.name=x commit -m x'
run 2 "$MAIN" 'git --no-pager push'
run 2 "$MAIN" 'npm test && git commit -am x'
run 2 "$MAIN" '/usr/bin/git commit -m x'
run 2 "$MAIN" 'echo $(git commit -m x)'
run 2 "$MAIN" '(git commit -m x)'
run 2 "$MAIN" 'echo `git commit -m x`'
run 2 "$MAIN" 'sh -c "git commit -m x"'
run 2 "$MAIN" $'git add .\ngit commit -m x'

# Blocked from a feature checkout when the commit or push lands on main.
run 2 "$FEAT" 'git push origin HEAD:main'
run 2 "$FEAT" 'git push origin feat/x:refs/heads/master'
run 2 "$FEAT" 'git push origin master'
run 2 "$FEAT" 'git push --all origin'
run 2 "$FEAT" "git -C $MAIN commit -m x"
run 2 "$FEAT" "cd $MAIN && git commit -m x"
run 2 "$FEAT" 'cd ../on-main && git commit -m x'

# Fails closed when the payload can't be parsed.
run 2 "$MAIN" 'git commit -m x' 'garbage git commit -m x'
run 2 "$MAIN" 'git commit -m x' '' "$tmp/bin"

if [ "$failures" -gt 0 ]; then
  echo "$failures case(s) failed"
  exit 1
fi
echo "all cases passed"
