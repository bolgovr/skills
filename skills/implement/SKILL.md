---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or tickets.

Make sure all code paths are covered with unit tests.

Structure new code per [clean-architecture.md](./clean-architecture.md): keep business rules (Entities, Use Cases) free of framework, UI, and database code, and make dependencies point inward per The Dependency Rule. Put new logic in the layer it belongs to rather than reaching for whatever file is already open.

Follow [solid.md](./solid.md) for every class or interface you write or touch: single responsibility, open for extension, substitutable subtypes, segregated interfaces, dependency on abstractions. Check new code against it before moving to the next slice, not as a pass at the end.


## Testing
This section is reference that makes that loop produce tests worth keeping: what a good test is, where tests go, the anti-patterns, and the rules of the loop. Every section applies on every cycle: consult them before and during the loop, not after.

When exploring the codebase, read `CONTEXT.md` (if it exists) so test names and interface vocabulary match the project's domain language, and respect ADRs in the area you're touching.

### What a good test is

Tests verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't. A good test reads like a specification: "user can checkout with valid cart" tells you exactly what capability exists, and it survives refactors because it doesn't care about internal structure.
Characteristics:

- Tests behavior users/callers care about
- Uses public API only
- Survives internal refactors
- Describes WHAT, not HOW
- One logical assertion per test

Red flags:
- Mocking internal collaborators
- Testing private methods
- Asserting on call counts/order
- Test breaks when refactoring without behavior change
- Test name describes HOW not WHAT
- Verifying through external means instead of interface

### Mocking
Mock at the **Frameworks and Drivers** boundary from [clean-architecture.md](./clean-architecture.md#frameworks-and-drivers): the concrete "detail" behind an interface a Use Case or Entity owns, never the business rule itself.
- External APIs (payment, email, etc.)
- Databases
- Time/randomness
- File system (sometimes)

Never mock a Use Case, an Entity, or the Interface Adapter between them (Controller, Presenter, [Use Case Output](./clean-architecture.md#use-case-output)) — those are the layers the test exists to verify.



## Seams: where tests go

A **seam** is the public boundary you test at: the interface where you observe behavior without reaching inside. Tests live at seams, never against internals.

**Test only at pre-agreed seams.** Before writing any test, write down the seams under test and confirm them with the user. No test is written at an unconfirmed seam. You can't test everything, so agreeing the seams up front is how testing effort lands on the critical paths and complex logic instead of every edge case.

Ask: "What's the public interface, and which seams should we test?"

When the shape of that interface is itself in question (how deep the module is, where the seam belongs, what the interface should expose), call the Skill tool with "codebase-design" for the vocabulary. It is the shared source of the module, interface, depth, seam, adapter, leverage and locality terms, and it is a reference to consult, not a session to run.

A seam commonly falls at a layer boundary from [clean-architecture.md](./clean-architecture.md): Controller → Use Case, Use Case → Use Case Output, Use Case → Entity. See Mocking above for what to fake at those boundaries.

## Anti-patterns

- **Implementation-coupled**: mocks internal collaborators, tests private methods, or verifies through a side channel (querying the database instead of using the interface). The tell: the test breaks when you refactor but behavior hasn't changed.
- **Tautological**: the assertion recomputes the expected value the way the code does (`expect(add(a, b)).toBe(a + b)`, a snapshot derived by hand the same way, a constant asserted equal to itself), so it passes by construction and can never disagree with the code. Expected values must come from an independent source of truth: a known-good literal, a worked example, the spec.
- **Horizontal slicing**: writing all tests first, then all implementation. Bulk tests verify _imagined_ behavior: you test the _shape_ of things rather than user-facing behavior, the tests go insensitive to real changes, and you commit to test structure before understanding the implementation. Work in **vertical slices** instead: one test → one implementation → repeat, each test a **tracer bullet** that responds to what the last cycle taught you.


## Rules of the loop

- **Red before green.** Write the failing test first, then only enough code to pass it. Don't anticipate future tests or add speculative features.
- **One slice at a time.** One seam, one test, one minimal implementation per cycle.
- **Refactoring is not part of the loop.** It belongs to the review stage (see the `code-review` skill), not the implementation cycle.


Run typechecking regularly, single test files regularly, and the full test suite + /quality-gate once at the end.

Once done, use /code-review to review the work.

Commit your work to the current branch.
