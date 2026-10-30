# Implementing a seam test-first

Reference for the sub-agent that implements one confirmed seam. Every section applies on every cycle: consult them before and during the loop, not after.

Read `CONTEXT.md` (if it exists) so test names and interface vocabulary match the project's domain language, and respect ADRs in the area you're touching.

Make sure all code paths are covered with unit tests.

Follow SOLID for every class or interface you write or touch: single responsibility, open for extension, substitutable subtypes, segregated interfaces, dependency on abstractions. Check new code against it before moving to the next cycle, not as a pass at the end.

## What a good test is

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

## Mocking
Mock at the Frameworks and Drivers boundary (see architecture-principles): the concrete "detail" behind an interface a Use Case or Entity owns, never the business rule itself.
- External APIs (payment, email, etc.)
- Databases
- Time/randomness
- File system (sometimes)

Never mock a Use Case, an Entity, or the Interface Adapter between them (Controller, Presenter, Use Case Output): those are the layers the test exists to verify.

## Seams: where tests go

A **seam** is the public boundary you test at: the interface where you observe behavior without reaching inside. Tests live at seams, never against internals.

**Test only at the seam named in your brief.** It was confirmed with the user. If the work shows the seam is wrong, or a test needs a seam that wasn't agreed, stop and report `needs-decision`; don't invent a new one.

A seam commonly falls at a layer boundary (see architecture-principles): Controller → Use Case, Use Case → Use Case Output, Use Case → Entity. See Mocking above for what to fake at those boundaries.

## Anti-patterns

- **Implementation-coupled**: mocks internal collaborators, tests private methods, or verifies through a side channel (querying the database instead of using the interface). The tell: the test breaks when you refactor but behavior hasn't changed.
- **Tautological**: the assertion recomputes the expected value the way the code does (`expect(add(a, b)).toBe(a + b)`, a snapshot derived by hand the same way, a constant asserted equal to itself), so it passes by construction and can never disagree with the code. Expected values must come from an independent source of truth: a known-good literal, a worked example, the spec.
- **Horizontal slicing**: writing all tests first, then all implementation. Bulk tests verify _imagined_ behavior: you test the _shape_ of things rather than user-facing behavior, the tests go insensitive to real changes, and you commit to test structure before understanding the implementation. Work in **vertical slices** instead: one test → one implementation → repeat, each test a **tracer bullet** that responds to what the last cycle taught you.

## Rules of the loop

- **Red before green.** Write the failing test first, then only enough code to pass it. Don't anticipate future tests or add speculative features.
- **One slice at a time.** One test, one minimal implementation per cycle.
- **Refactoring is not part of the loop.** It belongs to the review stage (see the `code-review` skill), not the implementation cycle.

Run typechecking and only the test files in scope (the ones you touch) regularly. The quality gate runs later in its own stage, and the full test suite runs exactly once, right before the PR opens, so don't run either here.

Don't end your turn to wait on a background command: as a sub-agent, ending your turn is returning your report. Run long commands (a build, a large test file) in the foreground with a timeout that fits, and keep only the lines you need from their output.
