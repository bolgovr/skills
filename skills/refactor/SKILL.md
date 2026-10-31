---
name: refactor
description: "Plan a refactor from a refactoring root the user names, examining every reachable module and its tests, and publish a refactoring plan that implement can run."
compatibility: "Requires gh or glab depending on the configured issue tracker; none for local files."
disable-model-invocation: true
---

Plan a refactor, starting from a code symbol the user names. The output is a **refactoring plan**: a spec published to the issue tracker that the user hands to `/implement` unchanged. This skill only reads code: it never edits source files, writes tests, or commits.

Read `CONTEXT.md` (if it exists) for the domain vocabulary, and respect the ADRs in the area. The issue tracker should have been provided to you. If not, tell the user to run `/setup-repo-skills`.

You are the **orchestrator**. You talk to the user, dispatch sub-agents, and read their reports. Anything that reads widely (mapping, analysis) runs in a sub-agent, so your context stays small. After dispatching sub-agents, end your turn; their completion notifications re-invoke you.

## Vocabulary

- **Refactoring root**: the symbol the refactor starts from: a function, class, module, file, or endpoint, at any layer.
- **Reachable set**: every in-repo module reachable from the root by following calls and imports, plus every test that exercises one of them.
- **Boundary**: an edge where the reachable set stops: third-party or framework code, generated code, or a module already visited. Record it; never read past it.
- **Characterization test**: a test that pins current behaviour so the refactor can prove it preserved it. It passes on first write and stays green through the whole refactor.

## Flow

1. **Agree on the root and goal.** Ask the user for the refactoring root and, optionally, a goal ("make X testable", "split Y", "prepare for feature Z"). Resolve the root to one concrete symbol before going on: if a name matches several, ask which.
2. **Map the reachable set.** Dispatch an `Explore` sub-agent with the map role below.
3. **Prune.** Show the user the module list with sizes and the boundaries. They may drop modules or whole subtrees; what's dropped goes to Out of scope. Don't start the analysis until they confirm the set.
4. **Analyse.** Split the pruned set into subtrees of roughly equal size, a few modules each, and dispatch one read-only `general-purpose` analysis sub-agent per subtree, all in one message so they run in parallel.
5. **Settle findings and target design.** Call the Skill tool twice, for "grilling" and "domain-modeling". Grill the user on which findings the plan takes on and what the interfaces look like afterwards; refactors often rename concepts, so update `CONTEXT.md` as names settle. Rejected findings go to Out of scope.
6. **Agree the seams.** Propose the seams and their order, and confirm them with the user (see Seams below).
7. **Publish.** Write the plan (see The plan below) and publish it to the issue tracker as one issue. Tell the user to run `/implement` with it, or `/to-tickets` for a wide refactor.

## Sub-agent briefs

Map role:

```
Map the reachable set of a refactor, read-only. Change nothing and don't commit.
Refactoring root: <symbol>.
Follow calls and imports from the root through in-repo code. Stop at a boundary:
third-party or framework code, generated code, or a module already visited.
Record each boundary, but never read past it. Then find every test that
exercises a module in the set, unit or integration.
Reply with at most 60 lines, never pasting code. The modules list takes priority:
if it won't fit, collapse a large subtree into one line (its directory, module
count, and total size) and shorten the tests list before the modules list.
modules: <path or module name> <size in lines> <what it does, a few words>, one per line
boundaries: <from module> -> <third-party, framework, or generated target>, one per line
tests: <test file> -> <modules it exercises>, one per line
```

Analysis role:

```
Analyse part of a refactor's reachable set, read-only. Change nothing and don't commit.
Refactoring root: <symbol>. Goal: <goal, or "none given">.
Your modules: <subtree>. The whole set, for context only: <module list>.
Before reading, call the Skill tool with "architecture-principles".
Find what makes this code hard to change or test: layering and Dependency Rule
violations, SOLID violations, shallow modules (an interface nearly as complex as
the implementation), and missing seams. Judge depth by how much behaviour a
caller gets per unit of interface it has to learn.
Then read the tests that exercise your modules: which behaviour they pin, which
behaviour no test pins, and which tests couple to internals a refactor would remove.
Reply with at most 30 lines, never pasting code:
findings: <module> <problem, in the vocabulary above> <why it matters for the goal>, one per line
covered: <behaviour> <test that pins it>, one per line
uncovered: <behaviour the refactor could move> <no test pins it>, one per line
coupled: <test> <internal it depends on>, one per line
```

## Seams

Call the Skill tool with "architecture-principles" if it isn't already loaded. The plan uses `implement`'s seam vocabulary, and `implement` runs its seams in order:

- Every seam is exactly one kind: `unit` (one module through its public interface, collaborators real, only Frameworks and Drivers details faked) or `integration` (entered at the outermost entry point, everything owned running for real).
- **Characterization seams come first.** For every behaviour the refactor could move that no test pins, propose a seam in `characterize` mode, at the public interface the behaviour is observable through. These seams pin what the code does today, including behaviour that looks wrong; fixing it is a separate, behaviour-changing seam the user must ask for explicitly.
- **Then the restructuring seams**, each one step toward the target design, ordered so every step lands green against the characterization tests. A restructuring seam is tested at the new interface it introduces.
- **Assign the affected tests.** Each test the analysis marked as coupled is kept, rewritten by a named seam, or deleted by a named seam. A deletion needs a characterization seam that covers the behaviour the test pinned.
- **Wide refactors.** If a step changes a symbol whose blast radius fans across the codebase, so no single seam can land green, order the steps as expand (add the new form beside the old), migrate (move call sites over in batches), then contract (delete the old form once nothing uses it). Then recommend `/to-tickets` on the published plan instead of `/implement`, so each batch becomes its own ticket.

## The plan

Name modules and symbols, never line numbers or code snippets: they go stale before implementation starts. Use the project's domain vocabulary throughout.

```
## Goal
<the user's goal, or "None given: driven by the findings below.">

## Refactoring root
<symbol>

## Reachable set
<module>: <what it does>, one per line
Boundaries: <from module> -> <target>, one per line

## Findings
<module>: <problem> <why it matters>, one per line, only the ones the user took on

## Target design
<the interfaces after the refactor: each module's responsibility and what it exposes>

## Seams
1. <name> (<unit | integration>, characterize): <behaviour it pins, at which interface>
2. <name> (<unit | integration>): <restructuring step, the interface it introduces>

## Affected tests
<test>: keep | rewrite in seam <n> | delete in seam <n>, covered by seam <m>

## Out of scope
<pruned modules and rejected findings, one per line with the reason>
```

Publish it as one issue titled `Refactor <root>: <goal or main finding>`. On a local-files tracker, write it as the spec of a feature directory, `.scratch/refactor-<slug>/spec.md`.

## Without a sub-agent tool

Where there is no tool for dispatching sub-agents, run the same flow inline, in the same order: treat each brief as your checklist for that step, and analyse the subtrees one after another.
