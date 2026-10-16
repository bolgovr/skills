# Lenses

Briefs for the `smartass` sub-agents, and the report template. Each lens reads **Shared rules** and its own section.

## Shared rules

- **Read-only.** Never edit, create, or delete files, never commit, never install anything.
- **Allowed commands** are ones that change nothing: `git log`, `git blame`, `git shortlog`, dependency listings, outdated and audit checks, LOC and file counts. Building or running tests only when the brief says timing runs are allowed.
- **Evidence or nothing.** Every finding names paths, numbers, or command output. Drop anything you can't back.
- **No loyalty to the status quo.** "It works" and "everyone uses it" are not arguments. "It costs X, measured like this" is.
- **Score against** maintainability first, development speed second, runtime speed third.
- **Report** at most 8 findings, under 500 words, each as:
  - **Title**
  - **Evidence**: paths, numbers, quotes.
  - **Gain**: effect on each of the three criteria, and the tradeoff if a lower one wins.
  - **Cost**: S, M, L, or XL. **Risk**: low, medium, or high.
  - **First step**: the smallest concrete move.

## Architecture & code

Call the Skill tool with "architecture-principles" first.

Look for: module boundaries and dependency direction, coupling hotspots, duplicated logic, god modules, abstractions with a single implementation, dead code, and code that fights or reimplements its framework (a hand-rolled router, cache, ORM, or state store). Evidence: paths, import relationships, file and function sizes.

Leave docs, tooling, and checks to Dev loop, and dependency resolution to Stack fit.

## Stack fit

Inventory the language and runtime versions, frameworks, and major dependencies. For each major piece:

- What it was designed for, against how this repo uses it: using a sliver of it, fighting it, or reimplementing parts of it.
- Version lag behind current, and its maintenance status.
- The leading alternatives, if it is a poor fit.

Then the language itself: does the codebase's dominant pain, as shown by evidence, match a class of problem another language removes (memory or concurrency bugs, loose typing, startup time, deployment footprint, a slow build)? Any language is a candidate, Rust included; none is a default. A language change is only worth reporting when the evidence for it is strong.

Use web search for the current status of every tool you recommend adopting or dropping, and of each current major dependency. Cite the links.

You own dependency resolution: what the repo relies on and whether it is declared. Leave docs and checks to Dev loop.

## Dev loop

- **Clone to green**: the steps from a fresh clone to passing tests, and whether the docs describe them accurately.
- **Build and test tooling**: tools in use, scripts, missing gates (lint, typecheck, format).
- **CI**: configured jobs, caching, duration where history or config shows it, signs of flakiness (retries, skipped tests).
- **Feedback speed**: how long a developer waits for a change to be checked locally.
- **Docs and onboarding**: README accuracy, stale or contradictory docs.

Time a clean build and the test suite only if the brief allows it.

You own stale or inaccurate docs and every missing automated check. Leave script and hook internals to Correctness & security.

## History

From git, over the last 12 months (or the whole history, if shorter):

- **Churn hotspots**: most-changed files (`git log --since=12.months --format= --name-only | sort | uniq -c | sort -rn | head -20`).
- **Bug-fix clusters**: files most touched by commits whose message matches fix, bug, hotfix, or regression.
- **Revert rate**: reverts as a share of commits.
- **Hidden coupling**: files in different modules that keep changing in the same commits.
- **Bus factor**: areas where one author made most of the changes (`git shortlog -sn -- <path>`).
- **Frozen areas**: code nobody has touched for a long time while its surroundings churn.

Report numbers, not impressions. Report what history shows (churn, fixes, coupling); leave the content of stale files to Dev loop.

## Correctness & security

- **Test gaps**: important or complex code without tests, and the ratio of test files to source files per area.
- **Risky patterns**: unvalidated input, string-built queries, secrets in the repo, unsafe deserialization, swallowed errors.
- **Supply chain**: lockfile present and committed, version pinning, audit command output, abandoned dependencies.

Also list the **migration constraints**: behaviour any rewrite or framework swap must preserve but nothing currently protects (untested behaviour, implicit contracts, data formats). The orchestrator vetoes any proposal whose migration path doesn't preserve one. These go after your findings and don't count toward the 8.

You own script and hook internals. Leave missing checks and stale docs to Dev loop.

## Devil's advocate

You defend the status quo. For each proposal you are given:

- Make the strongest case for keeping things as they are, or for fixing them in place.
- Name the migration costs the proposal underestimates: retraining, the period of running two systems, lost ecosystem features, data migration.
- Point out what the evidence doesn't show, and check its web claims.

Give each proposal a verdict, **holds**, **weakened**, or **beaten**, with the single strongest counterargument. Under 400 words.

## Report template

```markdown
# smartass report: <repo> (<YYYY-MM-DD>)

Scope: <whole repo | path | topic>. Previous report: <date | none>.

## The bet

<The one change, why it wins on the criteria, and its first step.>

## Quick wins

### 1. <Title> [new | still open since <date>]

- **Evidence**: ...
- **Gain**: maintainability ..., dev speed ..., runtime ... (tradeoff, if any)
- **Cost**: S | M | L | XL. **Risk**: low | medium | high.
- **First step**: ...

## Structural

<Same shape as Quick wins.>

## Burn it down

<Same shape, plus:>

- **Migration path**: ...
- **Why not fix in place**: ...
- **Sources**: <links>

## Fixed since last report

- <Title>

## Considered and rejected

- <Proposal>: <why it lost>, rejected by <correctness gate | devil's advocate>.

## Also noticed

- <One line each.>

## Process

<Only after the process interview. Same finding shape.>
```
