#!/usr/bin/env bash
set -uo pipefail

# Test for skills/quality-gate's line-coverage rule. Checks the invariants a
# grep can pin down: each template's Coverage step names its in-code exclusion
# syntax, no dropped exclusion reason survives, the Swift test binary path is
# current, and the skill documents a coverage-only mode and the non-blocking
# verdict line for a production file no template matches. The rule's wording is
# verified by review, not here.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
GATE="$REPO/skills/quality-gate"

failures=0
fail() {
  echo "FAIL: $*"
  failures=$((failures + 1))
}

# coverage_step <template>: the template's Coverage step, up to the next
# numbered step or the end of the file.
coverage_step() {
  awk '/^[0-9]+\. \*\*Coverage\*\*/ { on = 1; print; next }
       on && /^[0-9]+\. \*\*/ { exit }
       on { print }' "$GATE/$1"
}

# names <template> <syntax>: the template's Coverage step names <syntax>.
names() {
  coverage_step "$1" | grep -qF -- "$2" || fail "$1 Coverage step does not name \`$2\`"
}

names dart-template.md 'coverage:ignore-line'
names typescript-template.md 'v8 ignore next'
names typescript-template.md 'istanbul ignore next'
names go-template.md 'coverage-exclude:'
names swift-template.md 'coverage-exclude:'

if grep -rqiF 'platform call with no fake' "$GATE"; then
  fail "\"a platform call with no fake\" is still offered as a reason"
fi

grep -qF 'PackageTests' "$GATE/swift-template.md" && fail "swift-template.md still names the <Package>PackageTests binary"
grep -qF '.build/debug/<TestTarget>.xctest/Contents/MacOS/<TestTarget>' "$GATE/swift-template.md" ||
  fail "swift-template.md does not name the <TestTarget> binary path"

grep -qi 'coverage-only mode' "$GATE/SKILL.md" || fail "SKILL.md does not document a coverage-only mode"
grep -qF 'coverage: no template for <language>' "$GATE/SKILL.md" ||
  fail "SKILL.md does not name the \`coverage: no template for <language>\` verdict line"

if [ "$failures" -gt 0 ]; then
  echo "$failures case(s) failed"
  exit 1
fi
echo "all cases passed"
