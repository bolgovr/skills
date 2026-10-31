# An independent adversary proves breaks with failing tests, as its own skill

Line coverage ([ADR 0003](0003-coverage-is-a-blocking-line-level-gate.md)) proves a changed line ran, not that it's right, and it can't see an implicit `else` or the outcomes of `&&` and `||` operands. So the quality gate ends with an adversary: an agent whose only job is to prove the change doesn't implement its spec, or that some input breaks it. Issue #20 records the decision.

## Decision

- **Adversarial, last, only on green.** The adversary is `quality-gate`'s last step and runs only once build, lint, tests, coverage, and the Dependency Rule all pass. In `implement` it is its own flow step between Quality gate and Review.
- **Executable proof only.** A blocking result is a counterexample: a failing test with concrete inputs, the expected result quoted from the spec, and the actual result from the code. A suspicion it can't turn into a failing test is reported and never blocks. Property-based search is used only if the repo already has the library; the adversary never adds one.
- **Independence.** The adversary runs as a fresh sub-agent and sees only the spec, the diff, and the existing tests. It never sees the implementer's plan rationale, seam reports, or the caller's reasoning, so `implement` gives it its own brief with no plan-file line. It writes tests only, never production code: someone else fixes what it breaks.
- **Bounded.** One pass per run over a fixed attack list: boundaries, empty and invalid input, error paths, each acceptance criterion, and (mandatory) each implicit `else` and each `&&`/`||` operand both true and false. A confirming rerun stops after the first round with no new counterexample; `implement` allows at most 3 fix-and-confirm rounds.
- **Spec source.** The caller names it; standalone, the adversary looks for an issue reference in the branch, commits, or PR, then asks the user. With no spec it attacks the code's own contracts and reports spec conformance as "not checked", not as a failure.

## Why a separate skill

The adversary could have been a file inside `quality-gate`. It is its own model-invoked skill because two callers dispatch it: `quality-gate` and `implement`'s orchestrator. Claude Code sub-agents can't dispatch sub-agents, and `implement` runs the gate as a sub-agent, so that gate can't spawn an independent adversary. There the gate reports `adversary: not run (caller dispatches it)`, and the orchestrator dispatches the adversary itself. Both callers drive the same skill through their brief.

Where a harness has no sub-agent tool at all, the adversary runs inline and its verdict is flagged **not independent** rather than skipped.

## Invariants this creates

- Nobody deletes or weakens a counterexample test to make it pass. A counterexample built on one reading of an ambiguous spec becomes a `needs-decision` quoting the spec line, and stays failing until the human decides.
- Fixes for counterexamples touch production code only, never the counterexample tests.
- Counterexamples stay uncommitted in a standalone gate run (it usually runs on uncommitted work) and are committed in `implement`, where they stay in the suite as regression tests. The caller's brief decides which.
- Coverage-only mode, and the gate reruns in `implement`'s review-fix and sync, skip the adversary.
