# Refactors run through implement with characterization seams

The `refactor` skill produces a **Refactoring plan** that goes straight to `implement`. Implement's loop is red before green, but a refactor first needs **Characterization tests**: they pin current behaviour, so they pass on first write. We gave `implement` a `characterize` mode on a seam rather than a third seam kind. The seam stays `unit` or `integration`, so the rules for what to fake and where tests live still apply, and the mode only lifts red-before-green: the test is green on first write, takes its expected values from observed current behaviour, and never changes for the rest of the refactor. Characterization seams come first in the plan, and a seam may rewrite or delete the existing tests the plan assigns to it, but a deletion needs a named characterization seam that covers the behaviour.

## Considered Options

- **Leave `implement` unchanged** and express every refactor step as a new interface that goes red first. Rejected: current behaviour would have no test pinning it, so nothing would prove the refactor preserved it.
- **Have `refactor` write the characterization tests itself** before handing off. Rejected: the planner would stop being read-only, and test writing would be split across two skills with different rules.
- **A third seam kind, `characterization`**. Rejected: it hides whether the test runs in memory or through the real stack, which is exactly what the unit and integration rules key on.
