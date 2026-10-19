#!/usr/bin/env bash
set -uo pipefail

# Test for scripts/link-skills.sh. Runs it against a throwaway HOME and checks
# that it links every skill, leaves foreign entries alone, and replaces them
# only with --force.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
LINK="$REPO/scripts/link-skills.sh"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

failures=0
fail() {
  echo "FAIL: $*"
  failures=$((failures + 1))
}

# link <expected exit> [args]
link() {
  local expected=$1
  shift
  HOME="$tmp/home" bash "$LINK" "$@" >/dev/null 2>&1
  local actual=$?
  [ "$actual" = "$expected" ] || fail "link-skills.sh $* exited $actual, want $expected"
}

skills_dir="$tmp/home/.claude/skills"
mkdir -p "$skills_dir/grilling" "$tmp/other-repo/code-review"
echo keep >"$skills_dir/grilling/SKILL.md"
ln -s "$tmp/other-repo/code-review" "$skills_dir/code-review"
ln -s "$REPO/skills/retro-old" "$skills_dir/retro"

# Without --force: links the rest, skips both foreign entries, exits 1.
link 1
[ "$(cat "$skills_dir/grilling/SKILL.md" 2>/dev/null)" = keep ] || fail "a real directory was replaced without --force"
[ "$(readlink "$skills_dir/code-review")" = "$tmp/other-repo/code-review" ] || fail "a symlink into another repo was replaced without --force"
[ "$(readlink "$skills_dir/retro")" = "$REPO/skills/retro" ] || fail "a stale symlink into this repo was not refreshed"
for md in "$REPO"/skills/*/SKILL.md; do
  name=$(basename "$(dirname "$md")")
  case "$name" in grilling | code-review) continue ;; esac
  for dest in .claude/skills .agents/skills; do
    [ "$(readlink "$tmp/home/$dest/$name")" = "$REPO/skills/$name" ] || fail "$dest/$name is not linked"
  done
done

# With --force: replaces both and exits 0.
link 0 --force
[ "$(readlink "$skills_dir/grilling")" = "$REPO/skills/grilling" ] || fail "--force did not replace a real directory"
[ "$(readlink "$skills_dir/code-review")" = "$REPO/skills/code-review" ] || fail "--force did not replace a foreign symlink"

# Unknown argument.
link 1 --frce

if [ "$failures" -gt 0 ]; then
  echo "$failures case(s) failed"
  exit 1
fi
echo "all cases passed"
