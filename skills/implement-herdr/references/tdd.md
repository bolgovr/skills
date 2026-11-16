# Implementing a seam test-first

Reference for the sub-agent that implements one confirmed seam. Every section applies on every cycle: consult them before and during the loop, not after.

This file holds what every seam shares. Your brief names your seam's kind and mode; read the matching file next to this one as well, and only that one:

- `unit` seam: `unit.md` (isolation, edges, mocking).
- `integration` seam: `integration.md`.
- `characterize` mode, either kind: `characterization.md` too.

Read `CONTEXT.md` (if it exists) so test names and interface vocabulary match the project's domain language, and respect ADRs in the area you're touching.

Follow SOLID for every class or interface you write or touch: single responsibility, open for extension, substitutable subtypes, segregated interfaces, dependency on abstractions. Check new code against it before moving to the next cycle, not as a pass at the end.

## Two kinds of test

Tests verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't. A good test reads like a specification: "user can checkout with valid cart" tells you exactly what capability exists, and it survives refactors because it doesn't care about internal structure.

Every seam is exactly one of two kinds, named in your brief:

- A **unit test** checks the behavior of one code unit: a module with a public interface (a function, a class, a package). The unit's own collaborators stay real; only the Frameworks and Drivers details are faked, so it runs entirely in memory.
- An **integration test** enters the system as high on the abstraction layers as it can and runs down through the real stack to real infrastructure.

## Principles for every test

These hold for both kinds, in any language:

- **Test behavior, not implementation.** Assert on inputs → outputs and observable effects through the public interface, not on private methods, call counts or order, or internal state. Don't verify through a side channel (querying the database instead of using the interface). Refactors shouldn't break tests.
- **One reason to fail per test.** Each test checks one behavior, and its name states WHAT that behavior is, not HOW it's achieved (`returns_empty_when_no_items`). Multiple asserts are fine if they describe one outcome.
- **Deterministic.** No wall-clock time, no randomness, no shared mutable state. Inject clocks, IDs, and randomness as dependencies; don't mock them globally.
- **Arrange, Act, Assert.** Setup, one action, assertions. No logic (loops, conditionals) in the test body.
- **Every branch has a test, not just every line.** Line coverage can't see an `if` with no `else`, a `switch` with no default, or which operand of an `&&`/`||` decided the outcome. For each one your seam adds, write the case where the condition is false and the case for each operand. These are the first inputs the adversary tries later, so a gap here costs a whole fix round.
- **Readable over DRY.** Duplication in tests is acceptable; a test should be understood without jumping around. Use builders and fixtures for setup, not for assertions.
- **Failure messages should diagnose.** Use the assertion library's semantic matchers so a failure shows expected vs. actual, not just `false`.
- **Tests are first-class code.** They're held to the same standard as production code. Refactoring them and deleting obsolete ones belongs to the review stage; in the loop, touch only the tests you are writing and the existing tests the plan assigns to your seam.
- **Table-driven where it fits.** Parameterize over cases with the framework's own feature (`it.each`, `@pytest.mark.parametrize`, Go subtests) instead of copy-pasting or looping in the test body. A table-driven test is one behavior, and each new row is its own red-green cycle.
- **Every changed line is covered, with no percentage target.** High coverage proves nothing about assertion quality, so aim for every behavior of the seam, including its edges, to have a test. But an uncovered new or changed line means a red-green cycle slipped, and the quality gate blocks on it. Unit and integration tests both count. A line may stay uncovered only through an exclusion written in the code, with a reason, in the syntax the gate names for the language; a platform call with no fake isn't a reason, it's a missing fake adapter (`needs-decision`).

## Seams: where tests go

A **seam** is the public boundary you test at: the interface where you observe behavior without reaching inside. Tests live at seams, never against internals.

**Test only at the seam named in your brief, with the kind named there.** Both were confirmed with the user. If the work shows the seam is wrong, or a test needs a seam that wasn't agreed, stop and report `needs-decision`; don't invent a new one.

A `unit` seam commonly falls at a layer boundary: Controller → Use Case, Use Case → Use Case Output, Use Case → Entity. What to fake at those boundaries is in `unit.md`. An `integration` seam sits at the outermost entry point the feature has.

## Anti-patterns

- **Implementation-coupled**: mocks internal collaborators, tests private methods, or verifies through a side channel (querying the database instead of using the interface). The tell: the test breaks when you refactor but behavior hasn't changed.
- **Tautological**: the assertion recomputes the expected value the way the code does (`expect(add(a, b)).toBe(a + b)`, a snapshot derived by hand the same way, a constant asserted equal to itself), so it passes by construction and can never disagree with the code. Expected values must come from an independent source of truth: a known-good literal, a worked example, the spec.
- **Horizontal slicing**: writing all tests first, then all implementation. Bulk tests verify _imagined_ behavior: you test the _shape_ of things rather than user-facing behavior, the tests go insensitive to real changes, and you commit to test structure before understanding the implementation. Work in **vertical slices** instead: one test → one implementation → repeat, each test a **tracer bullet** that responds to what the last cycle taught you.

## Rules of the loop

- **Red before green.** Write the failing test first, then only enough code to pass it. Don't anticipate future tests or add speculative features. The one exception is a seam in `characterize` mode (see `characterization.md`).
- **One slice at a time.** One test, one minimal implementation per cycle.
- **Refactoring is not part of the loop.** It belongs to the review stage (see the `code-review` skill), not the implementation cycle. When your seam comes from a refactoring plan, the restructuring the plan describes is the seam's implementation, not an extra; anything beyond it still waits for review.

Run typechecking and only the test files in scope (the ones you touch, unit or integration) regularly, with the commands the plan's Commands section lists. The full quality gate and the full test suite run later in their own stages, so don't run either here.

Your last step before reporting `done`: call the Skill tool with "quality-gate" in coverage-only mode on your seam's files (source and tests). It runs only the coverage check, scoped to those files. Close each uncovered line it lists with a red-green cycle (a characterization test, in `characterize` mode) or, where no test can reach the line, an in-code exclusion with a reason. Rerun coverage-only mode until it passes.

Don't end your turn to wait on a background command: as a sub-agent, ending your turn is returning your report. Run long commands (a build, a large test file) in the foreground with a timeout that fits, and keep only the lines you need from their output.
