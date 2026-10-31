---
name: quality-gate
description: Run the language-appropriate quality gate (build, lint, typecheck, tests) before implementation work is considered done, and check the change against clean architecture and SOLID. Use once a change is functionally complete and before committing or handing it off, or when the user asks to run the quality gate.
---

# Quality Gate

Gate a change on language-specific checks before it's done. Scope to what changed, not the whole repo, unless nothing has changed yet.
Coverage is part of the gate, at line level: every new or changed line is covered by at least one test, and unit and integration tests both count. There is no percentage target. An uncovered line passes only with an exclusion written in the code, with a reason, so it shows in the diff and in review; each template's Coverage step names its exclusion syntax. Go and Swift have no native pragma, so the gate defines one: `// coverage-exclude: <reason>`, at the end of the uncovered line or alone on the line above it. The tool still reports that line; the gate honours the comment when reading the report. An exclusion with no reason doesn't count, in any language. Code left untested because a platform call has no fake doesn't qualify: that's a missing fake adapter, not a reason to exclude.
Test files are never subject to coverage, and files with no executable lines (docs, config) need none. For a matched language, coverage not measured fails the gate: no coverage provider, an unknown test runner, or no test script, and the gate names what's missing (for example the exact command to install the provider). It never installs anything itself. Coverage is measured through the templates' Coverage steps only. A changed production file in a language with no template can't be measured, so it doesn't block: the verdict reports it as `coverage: no template for <language>`.

## 1. Scope the change

Diff the working tree against the last commit (or the branch's merge-base with its default branch, whichever better isolates the current work) to get the changed file paths. If there's no usable diff (fresh repo, nothing changed yet), scope to the whole repo instead.

## 2. Match language templates

For each language below, match if either its marker file exists at the repo root (or an ancestor of a changed file) or a changed file has one of its extensions:

- **Dart / Flutter**: `pubspec.yaml`, `*.dart` → [dart-template.md](./dart-template.md)
- **Go**: `go.mod`, `*.go` → [go-template.md](./go-template.md)
- **Swift**: `Package.swift`, `*.xcodeproj`, `*.xcworkspace`, `*.swift` → [swift-template.md](./swift-template.md)
- **TypeScript**: `tsconfig.json`, `*.ts`, `*.tsx` → [typescript-template.md](./typescript-template.md)

A change can match more than one template (e.g. a Go backend with a TypeScript frontend); run every template that matches. If nothing matches, say so, skip step 3 (don't improvise checks for a language with no template), and go straight to step 4: the architecture and SOLID check is language-agnostic and still applies. A changed production file no template matches follows the no-template rule above.

## 3. Run each matched template

Read the matched template(s) and run every check they list, in order, against the scoped change. Record each check's pass/fail.

## 4. Check architecture and SOLID

Call the Skill tool with "architecture-principles" for the clean architecture and SOLID reference, then check the scoped change against it, grading by its rule: A Dependency Rule violation (an inner layer naming an outer-layer type, such as a Use Case or Entity importing a framework, UI, or database type) is a hard violation; a SOLID finding is a judgement call.

Here a hard violation fails the gate like any other check, and a judgement call is reported but doesn't block the gate on its own.

## 5. Verdict

The gate passes only when every check in every matched template passed and no Dependency Rule violation was found. A step a template skips for lack of config (no lint or format config) isn't a failure; name it in the verdict. Coverage is never skipped for a matched language (not measured fails, as above), and each no-template line is listed without blocking. On any failure: don't call the work done. Show the failing command's output or the violation, fix it (or ask, if the fix isn't yours to make), and re-run that check. List any SOLID judgement calls separately; they're for the user to weigh, not a blocker.

## Coverage-only mode

When the caller asks for coverage only (an implement seam agent does, before reporting `done`), run a narrower gate on the files the caller names:

1. Scope to those files instead of the diff. Their new or changed lines are those changed since the branch's merge-base with its default branch (the base step 1 uses); a file new on the branch is wholly changed.
2. Match templates as in step 2.
3. From each matched template run only its Tests and Coverage steps, scoped to those files: pass only the tests for them as targets where the runner takes targets, and skip any full-suite run the Tests step adds.

Skip the other template steps and step 4. The verdict passes only when the coverage rule above holds for every named production file in a matched language (a no-template file is reported, not failed, per the rule above); otherwise list each uncovered line by file and line number. This mode is the single source of truth for coverage commands: callers run it rather than a coverage command of their own.
