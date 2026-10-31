# rb-skills

A collection of agent skills (slash commands and behaviors) loaded by Claude Code. Skills are consumed by per-repo configuration emitted by `/setup-repo-skills`.

## Language

**Issue tracker**:
The tool that hosts a repo's issues: GitHub Issues, Linear, a local `.scratch/` markdown convention, or similar. Skills like `to-tickets` read from and write to it.
_Avoid_: backlog manager, backlog backend, issue host

**Issue**:
A single tracked unit of work inside an **Issue tracker**: a bug, task, spec, or slice produced by `to-tickets`.
_Avoid_: ticket (use only when quoting external systems that call them tickets)

**Adversary**:
The independent agent that tries to break a change against its spec, seeing only the spec, the diff, and the existing tests.
_Avoid_: reviewer, tester

**Counterexample**:
A failing test, with concrete inputs, the expected result taken from the spec, and the actual result from the code, proving the code breaks its spec.
_Avoid_: finding, bug report

**Refactoring root**:
The symbol a refactor starts from, named by the user: a function, class, module, file, or endpoint. Unlike implement's user-facing entry point, it can sit at any layer.
_Avoid_: entry point (reserved for user-facing entry points such as an HTTP endpoint or CLI command)

**Reachable set**:
Every in-repo module reachable from a **Refactoring root** by following calls and imports, plus every test that exercises one of them. It stops at a **Boundary**.

**Boundary**:
An edge where the **Reachable set** stops: third-party or framework code, generated code, or a module already visited. Recorded, never read past.

**Characterization test**:
A test that pins the current behaviour of existing code so a refactor can prove it preserved it. It passes on first write and must stay green through the whole refactor.

**Refactoring plan**:
The spec a refactor session produces, published as an **Issue** and consumed by implement.

## Relationships

- An **Issue tracker** holds many **Issues**
- An **Adversary** proves each break of a change with a **Counterexample**; a suspicion it can't prove is not a **Counterexample**
- A **Refactoring plan** starts from exactly one **Refactoring root** and covers its **Reachable set**
- A **Refactoring plan** is one **Issue**

## Flagged ambiguities

- "backlog" was previously used to mean both the *tool* hosting issues and the *body of work* inside it. Resolved: the tool is the **Issue tracker**; "backlog" is no longer used as a domain term.
- "backlog backend" / "backlog manager". Resolved: collapsed into **Issue tracker**.
