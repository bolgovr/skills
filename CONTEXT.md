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
A failing test, with concrete inputs and the expected result taken from the spec, proving the code breaks its spec.
_Avoid_: finding, bug report

## Relationships

- An **Issue tracker** holds many **Issues**
- An **Adversary** proves each break of a change with a **Counterexample**; a suspicion it can't prove is not a **Counterexample**

## Flagged ambiguities

- "backlog" was previously used to mean both the *tool* hosting issues and the *body of work* inside it. Resolved: the tool is the **Issue tracker**; "backlog" is no longer used as a domain term.
- "backlog backend" / "backlog manager". Resolved: collapsed into **Issue tracker**.
