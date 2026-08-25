---
name: quality-gate
description: Run the language-appropriate quality gate (build, lint, typecheck, tests) before implementation work is considered done, and check the change against clean architecture and SOLID. Use once a change is functionally complete and before committing or handing it off, or when the user asks to run the quality gate.
---

# Quality Gate

Gate a change on language-specific checks before it's done. Scope to what changed, not the whole repo, unless nothing has changed yet.
always run test coverage check and make sure all new code is covered by tests. If the repo has a language-specific quality gate template, run it too.

## 1. Scope the change

Diff the working tree against the last commit (or the branch's merge-base with its default branch, whichever better isolates the current work) to get the changed file paths. If there's no usable diff (fresh repo, nothing changed yet), scope to the whole repo instead.

## 2. Match language templates

For each language below, match if either its marker file exists at the repo root (or an ancestor of a changed file) or a changed file has one of its extensions:

- **Go**: `go.mod`, `*.go` → [go-template.md](./go-template.md)
- **Swift**: `Package.swift`, `*.xcodeproj`, `*.xcworkspace`, `*.swift` → [swift-template.md](./swift-template.md)
- **TypeScript**: `tsconfig.json`, `*.ts`, `*.tsx` → [typescript-template.md](./typescript-template.md)

A change can match more than one template (e.g. a Go backend with a TypeScript frontend); run every template that matches. If nothing matches, say so, skip step 3 (don't improvise checks for a language with no template), and go straight to step 4: the architecture and SOLID check is language-agnostic and still applies.

## 3. Run each matched template

Read the matched template(s) and run every check they list, in order, against the scoped change. Record each check's pass/fail.

## 4. Check architecture and SOLID

Call the Skill tool with "architecture-principles" for the clean architecture and SOLID reference, then check the scoped change against it:

- **Dependency Rule violations** (an inner layer naming something from an outer layer, e.g. a Use Case or Entity importing a framework, UI, or database type) are hard failures, same as any other check in this gate.
- **SOLID findings** (a class doing more than one thing, a switch that should be polymorphism, a concrete dependency instead of an interface) are judgement calls: report them, but they don't block the gate on their own.

## 5. Verdict

The gate passes only when every check in every matched template passed and no Dependency Rule violation was found. On any failure: don't call the work done. Show the failing command's output or the violation, fix it (or ask, if the fix isn't yours to make), and re-run that check. List any SOLID judgement calls separately; they're for the user to weigh, not a blocker.
