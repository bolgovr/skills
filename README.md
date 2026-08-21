# rb-skills

Agent skills for Claude Code: grilling, domain modelling, implementation, and handoff workflows.

## Install

```bash
npx skills@latest add bolgovr/skills
```

Pick the skills you want, and which coding agents to install them on. The installer lets you choose which skills to take: make sure `setup-repo-skills` is one of them.

To install a single skill:

```bash
npx skills@latest add bolgovr/skills --skill=<name>
```

```bash
npx skills@latest update <name>
```

## Skills

### User-invoked

Reachable only by typing the skill's name.

- [`claude-handoff`](./skills/claude-handoff/SKILL.md): hand the current conversation off to a fresh background agent that picks up the work immediately.
- [`grill-with-docs`](./skills/grill-with-docs/SKILL.md): a relentless interview to sharpen a plan or design, which also creates docs (ADRs and glossary) as it goes.
- [`implement`](./skills/implement/SKILL.md): implement a piece of work based on a spec or set of tickets.
- [`loop-me`](./skills/loop-me/SKILL.md): grill the user about specs for the workflows they want to build, within this workspace.
- [`setup-repo-skills`](./skills/setup-repo-skills/SKILL.md): configure a repo for the engineering skills, its issue tracker, triage label vocabulary, and domain doc layout. Run once before first use of the other engineering skills.

### Model-invoked

Reachable by the model or the user.

- [`domain-modeling`](./skills/domain-modeling/SKILL.md): build and sharpen a project's domain model, writing or editing `CONTEXT.md` and ADRs.
- [`grilling`](./skills/grilling/SKILL.md): grill the user relentlessly about a plan, decision, or idea, stress-testing their thinking round by round.
- [`quality-gate`](./skills/quality-gate/SKILL.md): run the language-appropriate quality gate (build, lint, typecheck, tests) before implementation work is considered done.
