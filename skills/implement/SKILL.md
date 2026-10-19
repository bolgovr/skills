---
name: implement
description: "Implement a piece of work based on a spec or set of tickets, using clean architecture and SOLID principles."
disable-model-invocation: true
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          # CLAUDE_SKILL_DIR is not exported to hook processes, so probe each install location, user-level before project-level.
          # If the guard script can't be found, fail closed: block anything that looks like a commit or push.
          command: 'for d in "$CLAUDE_SKILL_DIR" "$CLAUDE_PLUGIN_ROOT/skills/implement" "$HOME/.claude/skills/implement" "$HOME/.agents/skills/implement" "$CLAUDE_PROJECT_DIR/.claude/skills/implement"; do [ -n "$d" ] && [ -x "$d/scripts/block-commit-on-main.sh" ] && exec "$d/scripts/block-commit-on-main.sh"; done; if grep -Eq "git.*(commit|push)"; then echo "implement: block-commit-on-main.sh not found, so git commit/push is blocked until the guard is restored" >&2; exit 2; fi'
---

Implement the work described by the user in the spec or tickets.

You are the **orchestrator**. You plan, talk to the user, dispatch sub-agents, and read their reports. You never edit source files or run tests yourself: anything that reads widely or produces long output (exploring, the test loop, builds, the quality gate) runs in a sub-agent, so your context stays small for the whole session.

## Before you start

1. **Work in a git worktree.** Every implement or fix session gets its own worktree, so parallel sessions never share a checkout. If the session is already in a linked worktree (`git rev-parse --git-dir` differs from `git rev-parse --git-common-dir`), stay there. Otherwise, in Claude Code, call the EnterWorktree tool; where that tool isn't available, stop and tell the user to relaunch with `claude --worktree`. Sub-agents work in this same worktree, one at a time. Only a sub-agent that runs in parallel with another writer gets its own (`isolation: "worktree"` on the Agent tool).
2. **Branch off a fresh `origin/main`.** Run `git fetch && git switch -c <type>/<issue>-<slug> origin/main`, where `<type>` is the change kind (`feat`, `fix`, `refactor`, `chore`, `docs`, `test`), `<issue>` is the ticket number, and `<slug>` is a few kebab-case words from its title. If the repo's default branch isn't `main`, use `origin/<default>` instead (`git symbolic-ref --short refs/remotes/origin/HEAD`).
3. **Create the plan file.** Write `.implement/plan.md` (see below) and add `.implement/` to the file `git rev-parse --git-path info/exclude` prints, unless it's already listed. That keeps the plan out of every commit without touching the repo's `.gitignore`.

Never commit or push on `main` or `master`. While this skill is active, a PreToolUse hook (`scripts/block-commit-on-main.sh`) blocks `git commit` and `git push` on either branch in your session, and any push that targets one. Sub-agents may not inherit that hook, so the brief also has them check the branch before every commit.

## The plan file

`.implement/plan.md` is the session's durable state and the brief every sub-agent reads first. Keep it short:

- **Spec**: the tickets or spec path, one line each.
- **Seams**: one line per confirmed seam, in implementation order, with its status (`todo`, `in progress`, `done`, `blocked`).
- **Decisions**: the user's answers and the sub-agents' local choices, one line each.

Update it after every report. After a context compaction, re-read it instead of re-asking anyone.

## Flow

After dispatching a sub-agent, end your turn; its completion notification re-invokes you.

1. **Explore.** Dispatch an `Explore` sub-agent to read `CONTEXT.md` and the ADRs in the area, find the code the spec touches, and propose candidate seams. It is read-only, so you write its findings into the plan file.
2. **Confirm seams with the user.** This step stays with you; see Seams below. No seam agent starts before its seam is confirmed.
3. **Implement one seam at a time.** For each confirmed seam, in plan order, dispatch a `general-purpose` seam agent, then mark the seam in the plan from its report. Seams run in sequence because later ones usually build on what earlier ones produced.
   - `needs-decision`: put the question to the user, record the answer under Decisions, then resume the same agent with SendMessage (or dispatch a fresh one if it's gone).
   - `blocked`: decide the next step with the user. Don't start the next seam on top of a broken one.
4. **Observability.** Dispatch a `general-purpose` observable agent.
5. **Quality gate.** Dispatch a `general-purpose` gate agent.
6. **Review.** Call the Skill tool with "code-review" yourself, with `origin/<default>` as the fixed point. It runs its own sub-agents.
7. **Fix review findings.** If the review found anything, dispatch one `general-purpose` review-fix agent with all the findings. It escalates the same way seam agents do and reruns the gate before it commits.
8. **Sync with the default branch.** Run `git fetch` and `git log --oneline HEAD..origin/<default>`. If it lists anything, others have landed work since you branched: dispatch a `general-purpose` sync agent to rebase onto it and rerun the gate. If it lists nothing, move on.
9. **Ship.** Check `git status` is clean and skim `git log --oneline origin/<default>..HEAD`. Then push the feature branch and open a Pull Request against the default branch.

## Seams

Before confirming seams with the user, read the "Seams: where tests go" section of `<skill dir>/references/tdd.md` (`<skill dir>` is the base directory the harness gave when this skill was invoked), which defines what a **seam** is and where one commonly falls.

**Test only at pre-agreed seams.** Before any seam agent starts, write down the seams under test and confirm them with the user. You can't test everything, so agreeing the seams up front is how testing effort lands on the critical paths and complex logic instead of every edge case.

Ask: "What's the public interface, and which seams should we test?"

When the shape of that interface is itself in question (how deep the module is, where the seam belongs, what the interface should expose), argue it in these terms:

- **Module**: anything with an interface and an implementation, at any scale: a function, a class, a package.
- **Interface**: everything a caller must know to use the module correctly: types, but also invariants, ordering, error modes, and required configuration.
- **Depth**: how much behaviour a caller or test can exercise per unit of interface it has to learn. Prefer deep modules (a lot behind a small interface) over shallow ones (an interface nearly as complex as the implementation).
- **Adapter**: a concrete thing that fills an interface at a seam, such as the real database repo or an in-memory fake.
- **Leverage** is what callers get from depth, and **locality** is what maintainers get: change and bugs concentrate in one place instead of spreading across callers.

## Sub-agent brief

Build every brief from this template. Fill the placeholders and swap in the role line for the agent you're dispatching:

```
You are the <role> sub-agent of an implement session.
Worktree: <absolute path>. Branch: <branch>. Stay on this branch.
Read .implement/plan.md first.

<role line>

Escalate, don't decide: if the work would change a confirmed seam or a public
interface, or add a dependency, stop and report needs-decision with the question.
Make local implementation choices yourself and add each to the plan's Decisions.

Commit to the current branch once your work is green, after confirming
`git branch --show-current` is neither main nor master. Never push.

Reply with this report and nothing else, at most 15 lines. Never paste logs or diffs.
status: done | blocked | needs-decision
files: <changed paths>
tests: <names of tests added>
result: <one line: tests and typecheck>
notes: <questions, surprises, decisions made>
```

Role lines (`<skill dir>` is the base directory the harness gave when this skill was invoked):

- **explore**: Read `CONTEXT.md` and the ADRs in the area, find the code the spec touches, and propose candidate seams (the public interface, what sits behind it, where its tests go). Change nothing and don't commit. Instead of the standard report, reply with the relevant files and the candidate seams, one line each, at most 25 lines.
- **seam**: Implement seam `<name>` from the plan, test-first. Before writing anything, call the Skill tool with "architecture-principles" and read `<skill dir>/references/tdd.md`; follow it on every cycle.
- **observable**: Call the Skill tool with "observable" and apply it to this branch's changes since `origin/<default>`.
- **gate**: Run the full test suite and call the Skill tool with "quality-gate". Fix what fails and rerun, at most 3 rounds; if it's still red, report `blocked` with the remaining failures in one line each.
- **review-fix**: Apply these review findings: `<findings>`. Then run the full test suite and the quality gate as the gate role does, before you commit.
- **sync**: Rebase this branch onto `origin/<default>`. Resolve conflicts so both sides' intent survives; a conflict that needs a design call is a `needs-decision`, so run `git rebase --abort` and report it. Once rebased, run the full test suite and the quality gate as the gate role does, and commit any fixes.

## Without a sub-agent tool

Where there is no tool for dispatching sub-agents, run the same flow inline, in the same order, with the same plan file. Treat each role line as your checklist for that step, and before the first seam, call the Skill tool with "architecture-principles" and read `<skill dir>/references/tdd.md`.
