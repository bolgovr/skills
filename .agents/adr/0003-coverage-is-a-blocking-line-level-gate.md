# Coverage is a blocking line-level gate check, with exclusions only in code

`quality-gate` made coverage a pass condition while `implement`'s `tdd.md` called coverage "a smell detector, not a goal", so seam agents were told coverage didn't matter and then had the branch failed on it. Issue #19 first proposed resolving this by making coverage advisory. We went the other way: the user wants a code guarantee that every reachable line of a change is tested, and only a blocking check gives that.

## Decision

- Every new or changed production line is covered by at least one test. Unit and integration tests both count. There is no percentage target anywhere: a percentage says nothing about which lines of this change went untested.
- An uncovered line passes only with an exclusion written in the code, with a reason, so it shows in the diff and in review. Dart and TypeScript use their native pragmas (`coverage:ignore-line`, `v8 ignore next` or `istanbul ignore next`). Go and Swift have none, so the gate defines `// coverage-exclude: <reason>` and honours it when reading the report. "A platform call with no fake" is no longer a reason: it's a missing fake adapter, which `tdd.md` already treats as `needs-decision`.
- For a language with a template, coverage not measured fails the gate (no provider, an unknown runner, no test script), and the gate names what's missing. It never installs anything itself.
- A changed production file in a language with no template is reported as `coverage: no template for <language>` and doesn't block. This is a known limit: there is no measuring command to run, and failing every such change would block work the gate can't judge. A template for that language can come later.
- Seam agents run `quality-gate`'s coverage-only mode on their seam's files before reporting `done`, so gaps close inside the red-green loop rather than at the final gate.

Branch coverage was considered and rejected. No toolchain measures the outcomes of `&&` and `||` operands, Go reports no branch data, Swift's reports have no branch records, and Dart's branch data misses ternaries and implicit `else`. A branch rule would be enforceable in some languages and silently hollow in others. Branch thoroughness is delegated instead to the adversary ([ADR 0004](0004-an-independent-adversary-proves-breaks-with-failing-tests.md)), which reads the change for untested paths rather than counting them.

## Invariants this creates

- Test files are never subject to coverage; only production lines are.
- Coverage commands live only in `quality-gate`'s templates. Callers use coverage-only mode rather than a coverage command of their own.
- No exclusion lives in tool config or a gate-side list: if a line is excused, the reason is next to it in the code.
