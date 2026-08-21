---
name: quality-gate
description: Run the language-appropriate quality gate (build, lint, typecheck, tests) before implementation work is considered done. Use once a change is functionally complete and before committing or handing it off, or when the user asks to run the quality gate.
---

# Quality Gate

Gate a change on language-specific checks before it's done. Scope to what changed, not the whole repo, unless nothing has changed yet.

## 1. Scope the change

Diff the working tree against the last commit (or the branch's merge-base with its default branch, whichever better isolates the current work) to get the changed file paths. If there's no usable diff (fresh repo, nothing changed yet), scope to the whole repo instead.

## 2. Match language templates

For each language below, match if either its marker file exists at the repo root (or an ancestor of a changed file) or a changed file has one of its extensions:

- **Go**: `go.mod`, `*.go` → [go-template.md](./go-template.md)
- **Swift**: `Package.swift`, `*.xcodeproj`, `*.xcworkspace`, `*.swift` → [swift-template.md](./swift-template.md)
- **TypeScript**: `tsconfig.json`, `*.ts`, `*.tsx` → [typescript-template.md](./typescript-template.md)

A change can match more than one template (e.g. a Go backend with a TypeScript frontend); run every template that matches. If nothing matches, say so and stop: don't improvise checks for a language with no template.

## 3. Run each matched template

Read the matched template(s) and run every check they list, in order, against the scoped change. Record each check's pass/fail.

## 4. Verdict

The gate passes only when every check in every matched template passed. On any failure: don't call the work done. Show the failing command's output, fix it (or ask, if the fix isn't yours to make), and re-run that check.
