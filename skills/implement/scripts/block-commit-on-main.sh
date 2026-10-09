#!/usr/bin/env bash
# PreToolUse hook for Bash: refuse `git commit` and `git push` while the
# working tree is on the default branch (main or master).
# Reads the hook payload on stdin. Exit 2 blocks the call and feeds stderr
# back to the agent; exit 0 lets it through.

payload=$(cat)

command=$(printf '%s' "$payload" | python3 -c 'import json, sys
try:
    print(json.load(sys.stdin).get("tool_input", {}).get("command", ""))
except Exception:
    pass' 2>/dev/null)

# Match `git commit` / `git push`, allowing global options in between
# (e.g. `git -C dir commit`), anywhere in a compound command.
if ! printf '%s' "$command" | grep -Eq '(^|[;&|[:space:]])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+(commit|push)([[:space:]]|$)'; then
  exit 0
fi

cwd=$(printf '%s' "$payload" | python3 -c 'import json, sys
try:
    print(json.load(sys.stdin).get("cwd", ""))
except Exception:
    pass' 2>/dev/null)

branch=$(git -C "${cwd:-.}" branch --show-current 2>/dev/null)

case "$branch" in
  main|master)
    echo "Blocked: git commit/push on '$branch'. Create a feature branch first: git fetch && git switch -c <type>/<issue>-<slug> origin/$branch" >&2
    exit 2
    ;;
esac

exit 0
