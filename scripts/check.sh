#!/usr/bin/env bash
set -uo pipefail

# Repo checks: the rules from .claude/CLAUDE.md and .agents/invocation.md that
# a script can enforce, plus the script tests, shellcheck, and strict
# plugin validation. Runs as the pre-commit hook (.githooks/pre-commit).
# Checks the working tree, not only what is staged.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO" || exit 1

# Skills referenced here but not shipped, which resolve only when the plugin
# that ships them is installed alongside. Keep it empty: inline what a skill
# needs instead of depending on another plugin.
EXTERNAL_SKILLS=""
# Slash names that are Claude Code built-in commands, not skills.
BUILTIN_COMMANDS="plugin"

failures=0
fail() {
  echo "FAIL: $*"
  failures=$((failures + 1))
}
warn() { echo "WARN: $*"; }
# contains <space-separated list> <word>
contains() {
  case " $1 " in *" $2 "*) return 0 ;; esac
  return 1
}

# Print the given heading's section of README.md, up to the next heading.
readme_section() {
  awk -v heading="$1" '$0 == heading { inside = 1; next } /^#/ { inside = 0 } inside' README.md
}

# Skills: frontmatter name, invocation flags, README entry.
skills=""
user_invoked=""
for md in skills/*/SKILL.md; do
  dir=$(dirname "$md")
  name=$(basename "$dir")
  skills="$skills $name"
  frontmatter=$(awk 'NR == 1 && $0 == "---" { inside = 1; next } inside && $0 == "---" { exit } inside' "$md")

  fm_name=$(printf '%s\n' "$frontmatter" | sed -n 's/^name:[[:space:]]*//p' | tr -d "\"'")
  [ "$fm_name" = "$name" ] || fail "$md: frontmatter name '$fm_name' doesn't match its folder '$name'"

  disabled=no
  printf '%s\n' "$frontmatter" | grep -Eq '^disable-model-invocation:[[:space:]]*true' && disabled=yes
  implicit_off=no
  if [ -f "$dir/agents/openai.yaml" ]; then
    grep -Eq '^[[:space:]]+allow_implicit_invocation:[[:space:]]*false' "$dir/agents/openai.yaml" && implicit_off=yes
  else
    fail "$dir: missing agents/openai.yaml"
  fi
  if [ "$disabled" != "$implicit_off" ]; then
    fail "$name: 'disable-model-invocation: true' and 'allow_implicit_invocation: false' must be set together (see .agents/invocation.md)"
  fi

  if [ "$disabled" = yes ]; then
    user_invoked="$user_invoked $name"
    section="### User-invoked"
  else
    section="### Model-invoked"
  fi
  readme_section "$section" | grep -qF "[\`$name\`](./skills/$name/SKILL.md)" ||
    fail "README.md: no entry for $name under '$section' linking ./skills/$name/SKILL.md"
done

# README links to skills that don't exist.
for link in $(grep -oE '\(\./skills/[^)]+/SKILL\.md\)' README.md | tr -d '()'); do
  [ -f "$link" ] || fail "README.md links $link, which doesn't exist"
done

# Skill references in operative docs resolve. `Call the Skill tool with "x"`
# must name a model-invoked skill; `/x` must name a skill or a built-in.
docs=$(printf '%s\n' README.md .claude/CLAUDE.md; find skills -name '*.md' | sort)
while IFS=: read -r file line text; do
  for ref in $(printf '%s' "$text" | grep -oE "Skill tool (with|twice, for) [^.:;]*" | grep -oE "[\"\`][a-z0-9-]+[\"\`]" | tr -d "\"\`"); do
    if contains "$skills" "$ref"; then
      contains "$user_invoked" "$ref" && fail "$file:$line: calls user-invoked '$ref' through the Skill tool; tell the user to run /$ref instead"
    else
      contains "$EXTERNAL_SKILLS" "$ref" || fail "$file:$line: Skill tool reference to unknown skill '$ref'"
    fi
  done
done < <(printf '%s\n' "$docs" | xargs grep -nH "Skill tool")
# shellcheck disable=SC2016 # the backticks are literal Markdown
while IFS=: read -r file line ref; do
  ref=${ref#\`/}
  ref=${ref%\`}
  contains "$skills $EXTERNAL_SKILLS $BUILTIN_COMMANDS" "$ref" || fail "$file:$line: /$ref is not a skill in skills/ or a known external skill"
done < <(printf '%s\n' "$docs" | xargs grep -noHE '`/[a-z][a-z0-9-]*`')

# Tracked symlinks resolve (AGENTS.md -> .claude/CLAUDE.md).
while IFS= read -r link; do
  [ -e "$link" ] || fail "$link is a symlink to $(readlink "$link"), which doesn't exist"
done < <(git ls-files -s | awk -F '\t' '$1 ~ /^120000 / { print $2 }')

# No em-dashes anywhere (.claude/CLAUDE.md). Built from bytes so this file
# doesn't contain one.
emdash=$(printf '\342\200\224')
while IFS= read -r hit; do
  fail "em-dash: $hit"
done < <(git grep -nI -e "$emdash")

# Script tests.
for test in scripts/test-*.sh; do
  if ! out=$(bash "$test" 2>&1); then
    fail "$test:"
    printf '%s\n' "$out"
  fi
done

# Shell scripts.
if command -v shellcheck >/dev/null 2>&1; then
  if ! out=$(git ls-files -z '*.sh' .githooks | xargs -0 shellcheck 2>&1); then
    fail "shellcheck:"
    printf '%s\n' "$out"
  fi
else
  warn "shellcheck not installed, skipping"
fi

# Plugin manifests.
if command -v claude >/dev/null 2>&1; then
  for target in . .claude-plugin/plugin.json; do
    if ! out=$(claude plugin validate "$target" --strict 2>&1); then
      fail "claude plugin validate $target --strict:"
      printf '%s\n' "$out"
    fi
  done
else
  warn "claude CLI not installed, skipping plugin validation"
fi

if [ "$failures" -gt 0 ]; then
  echo "$failures check(s) failed"
  exit 1
fi
echo "all checks passed"
