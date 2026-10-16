#!/usr/bin/env bash
# PreToolUse hook for Bash: refuse `git commit` and `git push` that would land
# on the default branch (main or master).
# Reads the hook payload on stdin. Exit 2 blocks the call and feeds stderr
# back to the agent; exit 0 lets it through.
# A guardrail against accidents, not a sandbox: it matches generously and
# fails closed when it can't read the payload.

payload=$(cat)

# Print the string at a dotted path in the payload, or nothing.
json_get() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$payload" | jq -r --arg p "$1" 'getpath($p | split(".")) // empty | strings' 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$payload" | python3 -c 'import json, sys
try:
    d = json.load(sys.stdin)
    for k in sys.argv[1].split("."):
        d = d.get(k, "") if isinstance(d, dict) else ""
    print(d if isinstance(d, str) else "")
except Exception:
    pass' "$1" 2>/dev/null
  fi
}

# block <what> <default branch>
block() {
  echo "Blocked: git commit/push $1. Create a feature branch first: git fetch && git switch -c <type>/<issue>-<slug> origin/$2" >&2
  exit 2
}

command=$(json_get tool_input.command)
cwd=$(json_get cwd)
# Unreadable payload: match against the raw text instead of letting it through.
[ -n "$command" ] || command=$payload
cwd=${cwd:-.}

# `git commit` / `git push`, allowing global options in between (`git -C dir
# commit`), anywhere in a compound command, including inside `$(...)`,
# backticks, quotes (`sh -c "git commit"`), and via a path (`/usr/bin/git`).
git_re='(^|[^[:alnum:]_.-])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+'
end_re='([^[:alnum:]_-]|$)'

if ! printf '%s' "$command" | grep -Eq "${git_re}(commit|push)${end_re}"; then
  exit 0
fi

# A push whose refspec targets main/master (`HEAD:main`, `origin master`), or
# that pushes every branch, lands there whatever is checked out.
if printf '%s' "$command" | grep -Eq "${git_re}push([[:space:]][^;&|]*)?([[:space:]:+](refs/heads/)?(main|master)([[:space:]\"')]|$)|[[:space:]]--(all|mirror)${end_re})"; then
  block "targeting main/master" main
fi

# Check the branch everywhere the command may run: the hook's cwd, plus any
# `git -C <dir>` or `cd <dir>` target.
dirs=("$cwd")
while IFS= read -r d; do
  d=${d//\"/}
  d=${d//\'/}
  d=${d/#\~/$HOME}
  case "$d" in
    /*) ;;
    *) d="$cwd/$d" ;;
  esac
  dirs+=("$d")
done < <(printf '%s' "$command" | grep -oE '(^|[^[:alnum:]_-])(-C|cd)[[:space:]]+[^[:space:];&|)`]+' | sed -E 's/^.*(-C|cd)[[:space:]]+//')

for d in "${dirs[@]}"; do
  branch=$(git -C "$d" branch --show-current 2>/dev/null)
  case "$branch" in
    main|master) block "on '$branch'" "$branch" ;;
  esac
done

exit 0
