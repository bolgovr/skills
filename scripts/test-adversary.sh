#!/usr/bin/env bash
set -uo pipefail

# Test for the adversary gate (issue #20). Checks the invariants a grep can pin
# down, one block per skill that takes part: the adversary skill itself, and
# the skills that dispatch it. It pins structure, not wording; the wording is
# verified by review.

REPO="$(cd "$(dirname "$0")/.." && pwd)"

failures=0
fail() {
  echo "FAIL: $*"
  failures=$((failures + 1))
}

# expect <file> <fixed string> <what>: <file> contains <fixed string>,
# case-insensitively.
expect() {
  grep -qiF -- "$2" "$1" 2>/dev/null || fail "${1#"$REPO"/} does not $3"
}

# --- skills/adversary ---------------------------------------------------------

ADV="$REPO/skills/adversary"
ADV_MD="$ADV/SKILL.md"

# Registration: a model-invoked skill with Codex metadata and a README entry.
[ -f "$ADV_MD" ] || fail "skills/adversary/SKILL.md does not exist"
[ -f "$ADV/agents/openai.yaml" ] || fail "skills/adversary/agents/openai.yaml does not exist"
grep -qE '^disable-model-invocation:' "$ADV_MD" 2>/dev/null &&
  fail "skills/adversary/SKILL.md is not model-invoked"
grep -qF 'allow_implicit_invocation' "$ADV/agents/openai.yaml" 2>/dev/null &&
  fail "skills/adversary/agents/openai.yaml is not model-invoked"
awk '$0 == "### Model-invoked" { on = 1; next } /^#/ { on = 0 } on' "$REPO/README.md" |
  grep -qF "[\`adversary\`](./skills/adversary/SKILL.md)" ||
  fail "README.md has no Model-invoked entry linking ./skills/adversary/SKILL.md"

# Counterexample: a failing test with concrete inputs, expected from the spec,
# actual from the code.
expect "$ADV_MD" 'counterexample' "define a counterexample"
expect "$ADV_MD" 'concrete input' "require concrete inputs in a counterexample"
expect "$ADV_MD" 'expected result' "name the expected result of a counterexample"
expect "$ADV_MD" 'actual result' "name the actual result of a counterexample"
expect "$ADV_MD" 'non-blocking' "report an unproven suspicion as non-blocking"

# Attack list: the mandatory entries line coverage can't see.
expect "$ADV_MD" 'implicit else' "attack each implicit else"
expect "$ADV_MD" "\`&&\`" "attack each \`&&\` operand"
expect "$ADV_MD" "\`||\`" "attack each \`||\` operand"
expect "$ADV_MD" 'both true and false' "attack each operand both true and false"
expect "$ADV_MD" 'acceptance criterion' "attack each acceptance criterion"

# Spec source and its fallback.
expect "$ADV_MD" 'not checked' "report spec conformance as \"not checked\" with no spec"

# Independence: spec, diff, and existing tests only; writes tests only.
expect "$ADV_MD" 'never production code' "forbid writing production code"
expect "$ADV_MD" 'plan rationale' "keep the implementer's plan rationale out of view"

# Property-based search only with an existing library.
expect "$ADV_MD" 'property-based' "gate property-based search on an existing library"

# Budget.
expect "$ADV_MD" 'one pass' "limit itself to one pass"

# Disputes.
expect "$ADV_MD" 'needs-decision' "turn an ambiguous-spec counterexample into needs-decision"
expect "$ADV_MD" 'spec line' "quote the spec line in a dispute"
expect "$ADV_MD" 'weaken' "forbid weakening a counterexample test"

# ------------------------------------------------------------------------------

if [ "$failures" -gt 0 ]; then
  echo "$failures case(s) failed"
  exit 1
fi
echo "all cases passed"
