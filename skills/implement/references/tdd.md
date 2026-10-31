# Implementing a seam test-first

Reference for the sub-agent that implements one confirmed seam. Every section applies on every cycle: consult them before and during the loop, not after.

Read `CONTEXT.md` (if it exists) so test names and interface vocabulary match the project's domain language, and respect ADRs in the area you're touching.

Follow SOLID for every class or interface you write or touch: single responsibility, open for extension, substitutable subtypes, segregated interfaces, dependency on abstractions. Check new code against it before moving to the next cycle, not as a pass at the end.

## Two kinds of test

Tests verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't. A good test reads like a specification: "user can checkout with valid cart" tells you exactly what capability exists, and it survives refactors because it doesn't care about internal structure.

Every seam is exactly one of two kinds, named in your brief:

- A **unit test** checks the behavior of one code unit: a module with a public interface (a function, a class, a package). The unit's own collaborators stay real; only the Frameworks and Drivers details are faked, so it runs entirely in memory.
- An **integration test** enters the system as high on the abstraction layers as it can and runs down through the real stack to real infrastructure.

## Unit tests

These principles hold in any language:

- **Test behavior, not implementation.** Assert on inputs → outputs and observable effects through the public interface, not on private methods, call counts or order, or internal state. Don't verify through a side channel (querying the database instead of using the interface). Refactors shouldn't break tests.
- **One reason to fail per test.** Each test checks one behavior, and its name states WHAT that behavior is, not HOW it's achieved (`returns_empty_when_no_items`). Multiple asserts are fine if they describe one outcome.
- **Deterministic and isolated.** No shared mutable state, no wall-clock time, no randomness, no network, filesystem, or database. Inject clocks, IDs, and I/O boundaries.
- **Fast.** Milliseconds per test, so the suite can run on every save. If a `unit` seam can only be tested against real I/O, its kind is wrong or a fake adapter is missing: stop and report `needs-decision`.
- **Arrange, Act, Assert.** Setup, one action, assertions. No logic (loops, conditionals) in the test body.
- **Test the edges, not just the happy path.** Within this seam's behavior, cover empty, null/none, boundaries, max sizes, invalid input, and error paths. Dynamic languages need explicit type-misuse cases here; static ones get those from the compiler.
- **Readable over DRY.** Duplication in tests is acceptable; a test should be understood without jumping around. Use builders and fixtures for setup, not for assertions.
- **Failure messages should diagnose.** Use the assertion library's semantic matchers so a failure shows expected vs. actual, not just `false`.
- **Tests are first-class code.** They're held to the same standard as production code. Refactoring them and deleting obsolete ones belongs to the review stage; in the loop, touch only the tests you are writing.
- **Property-based and table-driven where it fits.** Parameterize over cases with the framework's own feature (`it.each`, `@pytest.mark.parametrize`, Go subtests) instead of copy-pasting or looping in the test body. A table-driven test is one behavior, and each new row is its own red-green cycle. Use property-based tests for invariants (idempotence, round-trips, commutativity) only if the project already has a library for them; otherwise report `needs-decision` rather than adding the dependency.
- **Coverage is a smell detector, not a goal.** Low coverage flags untested areas; high coverage proves nothing about assertion quality. Aim for every behavior of the seam, including its edges, to have a test, not for a percentage.

## Mocking

In unit tests, mock at the Frameworks and Drivers boundary: the concrete "detail" behind an interface a Use Case or Entity owns, never the business rule itself.
- External APIs (payment, email, etc.)
- Databases
- File system (sometimes)

Fake external services, not your own collaborators: over-mocking couples tests to structure and hides real bugs. Clocks, IDs, and randomness are injected as dependencies, not mocked globally.

Never mock a Use Case, an Entity, or the Interface Adapter between them (Controller, Presenter, Use Case Output): those are the layers the test exists to verify.

## Integration tests

An integration test proves the layers agree with each other and with the infrastructure under them.

- **Enter at the top.** Drive the outermost entry point the feature has: the HTTP endpoint, CLI command, message handler, or Controller. If the top can't be driven in a test (no test client for the framework, say), enter one layer lower and say why in the test.
- **Everything you own is real.** Wiring, Use Cases, Entities, and adapters all run for real, against real infrastructure that can run locally (a database, a temp directory). Only third-party services that can't run locally are replaced, with a local stub.
- **Cover the critical paths, not the edges.** The feature's happy path plus the failures that cross layers: a validation rejection, a not-found, an infrastructure failure mapped to an API error. Don't repeat edge cases the unit tests already pin down. If an adapter behavior can't be reached from the top, report `needs-decision`; don't invent another kind of test.
- **Slower, still isolated and deterministic.** Seconds per test are fine. Each test owns its data (a temp directory, a transaction rolled back, a unique schema), so no test sees another's leftovers. Clocks, IDs, and randomness are still injected.
- **Keep the kinds apart.** Separate integration tests from unit tests the way the project already does (directory, file suffix, tag, or run command). If it has no convention, report `needs-decision` with a proposal.
- **Missing infrastructure is a blocker.** If what the test needs isn't available (no database, no container runtime), report `blocked` naming what's missing. Never fall back to fakes: that tests nothing about the integration.

Every unit test principle not overridden here still applies.

## Seams: where tests go

A **seam** is the public boundary you test at: the interface where you observe behavior without reaching inside. Tests live at seams, never against internals.

**Test only at the seam named in your brief, with the kind named there.** Both were confirmed with the user. If the work shows the seam is wrong, or a test needs a seam that wasn't agreed, stop and report `needs-decision`; don't invent a new one.

A `unit` seam commonly falls at a layer boundary: Controller → Use Case, Use Case → Use Case Output, Use Case → Entity. See Mocking above for what to fake at those boundaries. An `integration` seam sits at the outermost entry point the feature has.

## Anti-patterns

- **Implementation-coupled**: mocks internal collaborators, tests private methods, or verifies through a side channel (querying the database instead of using the interface). The tell: the test breaks when you refactor but behavior hasn't changed.
- **Tautological**: the assertion recomputes the expected value the way the code does (`expect(add(a, b)).toBe(a + b)`, a snapshot derived by hand the same way, a constant asserted equal to itself), so it passes by construction and can never disagree with the code. Expected values must come from an independent source of truth: a known-good literal, a worked example, the spec.
- **Horizontal slicing**: writing all tests first, then all implementation. Bulk tests verify _imagined_ behavior: you test the _shape_ of things rather than user-facing behavior, the tests go insensitive to real changes, and you commit to test structure before understanding the implementation. Work in **vertical slices** instead: one test → one implementation → repeat, each test a **tracer bullet** that responds to what the last cycle taught you.

## Rules of the loop

- **Red before green.** Write the failing test first, then only enough code to pass it. Don't anticipate future tests or add speculative features.
- **One slice at a time.** One test, one minimal implementation per cycle.
- **Refactoring is not part of the loop.** It belongs to the review stage (see the `code-review` skill), not the implementation cycle.

Run typechecking and only the test files in scope (the ones you touch, unit or integration) regularly. The quality gate runs later in its own stage, and the full test suite runs exactly once, right before the PR opens, so don't run either here.

Don't end your turn to wait on a background command: as a sub-agent, ending your turn is returning your report. Run long commands (a build, a large test file) in the foreground with a timeout that fits, and keep only the lines you need from their output.
