# Code metrics

Two command-line tools score the change on things line coverage can't see: `crapper` (complexity weighed against coverage) and `dryer` (duplicated code). They support Clojure, Java, Go, TypeScript, JavaScript, Rust, and Python. They run only on changed files that a matched template covers, because `crapper` reuses its coverage command; any other changed file is out of scope for this step.

## Before you run them

- **Missing tool.** Check each with `command -v <tool>`. A tool that isn't installed, or that exits with an error of its own (not a finding), is reported as `metrics: <tool> not run (<reason>)` and doesn't block. Never install one.
- **Scope.** Pass the changed production files from step 1 as explicit paths. Don't use `--changed`: it reads `git status`, so it misses work already committed on the branch.
- **Output.** The tools write `.metrics/` at the project root. Keep them out of commits: run `git rev-parse --git-path info/exclude` and add `.metrics/` to the file it prints, unless it's already listed (or ignored).
- **Coverage.** `crapper` finds coverage on its own, and it can miss it without failing. Its discovery may also try to install a coverage package, which the gate doesn't allow. So give it the coverage command the matched template's Coverage step uses, with `--coverage-command "<command>"`, writing LCOV to the path the tool names in its output (for Python, `target/coverage/python/lcov.info`). If every function still shows `0.0%` coverage after the template's Coverage step passed, the tool didn't read the coverage, and its CRAP scores mean nothing; see the CRAP fallback below.

## 1. CRAP

Run `crapper --coverage-command "<command>" --threshold 10 <changed files>`. CRAP is `CC² × (1 − coverage)³ + CC`, so it is high for complex code with little test coverage. Exit 2 means some function scored above 10.

Every function in the change scoring above 10 fails: bring it to 10 or below by splitting it, by testing it, or both. A function whose complexity is a flat `switch` or `case` over independent branches is a judgement call: if splitting it would only scatter one decision across several places, keep it and report it with the SOLID judgement calls, with its score.

**Fallback.** When the tool can't read coverage, rerun with `--no-coverage` and fail only functions in the change with a cyclomatic complexity (`CC`) above 10. The coverage step already requires every changed line to be tested, and fully covered code scores CRAP equal to its CC. Report it as `crap: complexity only (coverage not read)`.

## 2. Duplication

Run `dryer --threshold 0.8` on the source roots the change lives in, not only the changed files, so that copies of existing code show up. Dryer exits 0 even when it finds duplicates, so read the report: each `DUPLICATE score=<n>` lists two or more locations.

A pair fails when at least one of its locations is in a changed line range. Pairs entirely in code the change didn't touch are outside the gate. Remove the duplication by extracting the shared shape into one function the copies call, so that one decision lives in one place. If two forms look alike but encode decisions that will change independently (two rules that just happen to match today), keep them and report the pair as a judgement call with its reason.

## Verdict lines

Report one line per tool: `crap: pass`, `crap: fail (<function> <score>, ...)`, `dry: pass`, `dry: fail (<file:lines> ~ <file:lines> <score>)`, or `<tool> not run (<reason>)`. Judgement calls go with the SOLID ones.
