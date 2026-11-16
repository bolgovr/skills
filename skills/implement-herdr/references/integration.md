# Integration seams

Read after `tdd.md`, for a seam whose kind is `integration`. Everything in `tdd.md` applies; this adds what is specific to integration tests.

An integration test proves the layers agree with each other and with the infrastructure under them.

- **Enter at the top.** Drive the outermost entry point the feature has: the HTTP endpoint, CLI command, message handler, or Controller. If the top can't be driven in a test (no test client for the framework, say), enter one layer lower and say why in the test.
- **Everything you own is real.** Wiring, Use Cases, Entities, and adapters all run for real, against real infrastructure that can run locally (a database, a temp directory). Only third-party services that can't run locally are replaced, with a local stub.
- **Cover the critical paths, not the edges.** The feature's happy path plus the failures that cross layers: a validation rejection, a not-found, an infrastructure failure mapped to an API error. Don't repeat edge cases the unit tests already pin down. If an adapter behavior can't be reached from the top, report `needs-decision`; don't invent another kind of test.
- **Slower, still isolated and deterministic.** Seconds per test are fine. Each test owns its data (a temp directory, a transaction rolled back, a unique schema), so no test sees another's leftovers, in whatever order the suite runs them: a test that alters shared state (a schema, a fixture table) restores it exactly. Clocks, IDs, and randomness are still injected.
- **Keep the kinds apart.** Separate integration tests from unit tests the way the project already does (directory, file suffix, tag, or run command). If it has no convention, report `needs-decision` with a proposal.
- **Missing infrastructure is a blocker.** If what the test needs isn't available (no database, no container runtime), report `blocked` naming what's missing. Never fall back to fakes: that tests nothing about the integration.
