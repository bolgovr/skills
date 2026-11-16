# Unit seams

Read after `tdd.md`, for a seam whose kind is `unit`. Everything in `tdd.md` applies; this adds what is specific to unit tests.

## Unit tests

- **Isolated.** No network, filesystem, or database. Inject the I/O boundaries and fake them (see Mocking).
- **Fast.** Milliseconds per test, so the suite can run on every save. If a `unit` seam can only be tested against real I/O, its kind is wrong or a fake adapter is missing: stop and report `needs-decision`.
- **Test the edges, not just the happy path.** Within this seam's behavior, cover empty, null/none, boundaries, max sizes, invalid input, and error paths. Dynamic languages need explicit type-misuse cases here; static ones get those from the compiler.
- **Property-based tests for invariants** (idempotence, round-trips, commutativity), only if the project already has a library for them; otherwise report `needs-decision` rather than adding the dependency.

## Mocking

In unit tests, mock at the Frameworks and Drivers boundary: the concrete "detail" behind an interface a Use Case or Entity owns, never the business rule itself.
- External APIs (payment, email, etc.)
- Databases
- File system (sometimes)

Fake external services, not your own collaborators: over-mocking couples tests to structure and hides real bugs. Clocks, IDs, and randomness are injected as dependencies, not mocked globally.

Never mock a Use Case, an Entity, or the Interface Adapter between them (Controller, Presenter, Use Case Output): those are the layers the test exists to verify.
