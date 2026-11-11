---
name: implement
description: "Implement a piece of work based on a spec or set of tickets, using clean architecture and SOLID principles."
compatibility: "Requires git, jq or python3 for the commit guard hook, and gh or glab for the issue tracker."
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

1. **Work in a git worktree.** Every implement or fix session gets its own worktree, so parallel sessions never share a checkout. If the session is already in a linked worktree (`git rev-parse --git-dir` differs from `git rev-parse --git-common-dir`), stay there. Otherwise, in Claude Code, call the EnterWorktree tool; where that tool isn't available, stop and tell the user to relaunch with `claude --worktree`. Sub-agents work in this same worktree, one writer at a time. Only a sub-agent that writes in parallel with another writer gets its own (`isolation: "worktree"` on the Agent tool).
2. **Branch off a fresh `origin/main`.** Run `git fetch && git switch -c <type>/<issue>-<slug> origin/main`, where `<type>` is the change kind (`feat`, `fix`, `refactor`, `chore`, `docs`, `test`), `<issue>` is the ticket number, and `<slug>` is a few kebab-case words from its title. If the repo's default branch isn't `main`, use `origin/<default>` instead (`git symbolic-ref --short refs/remotes/origin/HEAD`).
3. **Create the plan file.** Write `.implement/plan.md` (see below). Then run `git rev-parse --git-path info/exclude` and, with the Edit tool, add `.implement/` to the file it prints, unless it's already listed. That keeps the plan out of every commit without touching the repo's `.gitignore`.

Never commit or push on `main` or `master`. While this skill is active, a PreToolUse hook (`scripts/block-commit-on-main.sh`) blocks `git commit` and `git push` on either branch in your session, and any push that targets one. Sub-agents may not inherit that hook, so the brief also has them check the branch before every commit.

## Shell commands in a worktree

A worktree session refuses any shell command it can't verify stays inside the worktree, and each refusal costs a turn and the output that went into it. Chaining with `&&` or `;` and piping into a filter are fine. What gets refused: heredocs, command substitution (`$(...)` or backticks), shell variables, and loops or conditionals. So create and edit files with the Write and Edit tools, never `cat <<EOF` or an inline script, and when one command needs another's output, run them as two calls. This holds for you and for every sub-agent, so both briefs state it.

## The plan file

`.implement/plan.md` is the session's durable state and the brief every sub-agent reads first. Every later agent pays to read every line of it, so it holds what a later agent needs and nothing else:

- **Spec**: the tickets or spec path, one line each.
- **Commands**: the exact commands this repo uses, one line each, found once by the explore agent so nobody rediscovers them: tests for a given file, typecheck and lint, the full suite, and what they need to run (a container, an env file). Also what CI pins that a local run could get wrong, such as a formatter or SDK version. An agent that finds a line wrong corrects it.
- **Map**: at most 10 lines of paths: the files the spec touches and the existing code to imitate (a similar module, a test in the right style, a fixture).
- **Seams**: one line per confirmed seam, in implementation order, with its kind (`unit` or `integration`), its mode if it has one (`characterize`), its assigned tests if any, and its status (`todo`, `in progress`, `partial`, `done`, `blocked`). A `partial` line also says what is left.
- **Decisions**: one line each, 200 characters at most. The user's answers, your assumptions (marked `assumed`), and only those sub-agent choices a later agent must honour: a public name, an error contract, where something lives. How the code works belongs in the code and the commit message, not here.

The agent working a seam sets its status. You add the user's answers and your assumptions. If Decisions has grown past what the next agent needs, trim it before you dispatch. After a context compaction, re-read the plan instead of re-asking anyone.

## Flow

After dispatching a sub-agent, end your turn; its completion notification re-invokes you.

1. **Explore.** Dispatch an `Explore` sub-agent to read `CONTEXT.md` and the ADRs in the area, find the code the spec touches, and propose candidate seams. It is read-only, so you write what it returns into the plan file: Commands, Map, and the seams. When the spec already lists seams (a refactoring plan does), copy them into the plan file with their kind, mode, and assigned tests, and have the explore agent check them against the code and report mismatches instead of proposing new ones.
2. **Confirm seams with the user.** This step stays with you; see Seams and Questions for the user below. Ask the open questions the explore agent found in this same round, so the seams are built on the right reading of the spec. No seam agent starts before its seam is confirmed.
3. **Implement one seam at a time.** For each confirmed seam, in plan order, dispatch a `general-purpose` seam agent. Seams run in sequence because later ones usually build on what earlier ones produced.
   - `partial`: the agent stopped at a green checkpoint to keep its context small. Dispatch a fresh seam agent for the same seam; the plan's seam line says what is left.
   - `needs-decision`: put the question to the user, record the answer under Decisions, then resume the same agent with SendMessage (or dispatch a fresh one if it's gone).
   - `blocked`: decide the next step with the user. Don't start the next seam on top of a broken one.
4. **Observability.** Dispatch a `general-purpose` observable agent.
5. **Quality gate.** Dispatch a `general-purpose` gate agent.
6. **Adversary.** Dispatch a `general-purpose` adversary agent with the Adversary brief below, not the standard one, so it sees only the spec, the diff, and the existing tests. Don't wait for it: start step 7 in the same turn. The adversary only adds tests and the reviewers only read, so the two run together and their results are fixed in one pass. It commits its counterexample tests, which stay in the suite as regression tests.
   - Counterexamples: they go to the review-fix agent in step 8. After it reports, dispatch the adversary once more to confirm, with the confirming variant of its brief. If that run reports counterexamples, fix and confirm again. Stop after at most 3 rounds; if counterexamples remain, decide the next step with the user, as for `blocked`. The user may rule one out of scope: then the adversary removes that test and it goes on the follow-up list.
   - `needs-decision` (a dispute, per the adversary skill's Disputes rule): put it to the user and record the answer under Decisions. Don't move past step 8 while a dispute is open. The answer either keeps the test (review-fix fixes the code) or has the adversary rewrite it to the agreed reading.
7. **Review.** Call the Skill tool with "code-review" yourself, with `origin/<default>` as the fixed point, while the adversary runs. It runs its own sub-agents. A reviewer may see a failing counterexample test land mid-review; that is expected.
8. **Fix.** Once the adversary and the review have both reported and no dispute is open, dispatch one `general-purpose` review-fix agent with all the counterexamples and review findings together. If neither produced anything, skip this step. It escalates the same way seam agents do. Then confirm with the adversary, as step 6 describes, if there were counterexamples.
9. **Sync with the default branch.** Run `git fetch` and `git log --oneline HEAD..origin/<default>`. If it lists nothing, move on. Otherwise run `git rebase origin/<default>` yourself. A clean rebase needs no agent: the next step verifies the result. On a conflict, run `git rebase --abort` and dispatch a `general-purpose` sync agent.
10. **Final gate.** Dispatch a `general-purpose` final agent. It runs the whole quality gate and the full test suite on the finished branch, the only time either runs after step 5 (see Running tests below).
11. **Merge impact.** Draft the Pull Request's description in `.implement/pr-body.md` with the Write tool: what the repo's PR conventions ask for, plus the Decisions marked `assumed` under "Assumptions", so the reviewer can overrule any of them. Then dispatch a `general-purpose` impact agent. It adds a merge impact report to that file, below your draft, so the PR opens already telling the reviewer what the change reaches and how hard to look. Tell the user its verdict. An unannounced rule change it reports is behaviour the spec never asked for: put it to the user with the follow-ups, as a bug to fix or an intention to record.
12. **Ship.** Check `git status` is clean and skim `git log --oneline origin/<default>..HEAD`. Then push the feature branch and open a Pull Request against the default branch, with `.implement/pr-body.md` as its body (`gh pr create --body-file .implement/pr-body.md`, or the tracker's equivalent).
13. **Watch CI.** Wait for the PR's checks to finish (in Claude Code, run `gh pr checks <number> --watch` as a background command, or the tracker's equivalent). If a check fails, dispatch a review-fix agent with the failing check's name and run id, then push its commit and watch again, at most 3 rounds. If the failure came from a local command that differs from CI's, have the agent correct the plan's Commands line too. A fix pushed here leaves the report in the description stale: once the checks are green, dispatch the impact agent again, on the PR this time, to replace it. A repo with no CI skips this step.
14. **Follow-ups.** List what the session deferred: review findings the user chose not to fix, the adversary's suspicions, counterexamples ruled out of scope, and bugs agents noticed outside the change. Ask the user once whether to file them as issues, and file the ones they pick.

## Running tests

During development, every agent runs only the tests in scope: the test files for the code it touched and the tests of the seam it's working on, unit or integration, plus typechecking. The whole quality gate runs twice: in step 5, so the adversary attacks a green change, and in step 10, on the finished branch. The full test suite runs exactly once, in step 10. Agents that change code in between (review-fix, sync) run the tests in scope plus lint and typecheck on the files they touched, and leave the rest to step 10. Every sub-agent follows this rule, so the brief states it; no role other than final runs the full suite.

## Seams

Before confirming seams with the user, read the "Seams: where tests go" section of `<skill dir>/references/tdd.md` (`<skill dir>` is the base directory the harness gave when this skill was invoked), which defines what a **seam** is and where one commonly falls, and the "Two kinds of test" section, which defines `unit` and `integration` seams.

**Test only at pre-agreed seams.** Before any seam agent starts, write down the seams under test and confirm them with the user. You can't test everything, so agreeing the seams up front is how testing effort lands on the critical paths and complex logic instead of every edge case.

Ask: "What's the public interface, which seams should we test, and is each a `unit` or an `integration` seam?" Every seam is exactly one kind. By default, propose one `integration` seam per user-facing entry point the spec touches, ordered after the `unit` seams it depends on; the user may drop or reorder it.

**A seam is also one agent's worth of work.** An agent's cost grows with the square of how long it runs, because every turn re-reads everything before it, and its judgement gets worse in a very long context. So size seams before confirming them: one that needs more than about ten red-green cycles, or rewrites more than a handful of files, is split along its interface (by operation, by entry point, by consumer batch). Two seams that touch the same small file and would take a few cycles each are merged, since every agent pays a fixed cost to start.

A refactoring plan (a spec that restructures code without changing its behaviour) also carries **characterization** seams: a `unit` or `integration` seam in `characterize` mode, which pins the current behaviour before anything moves. They come first in the plan, and `<skill dir>/references/characterization.md` defines them. When the spec assigns existing tests to a seam (to rewrite or delete), copy that assignment into the plan's seam line.

When the shape of that interface is itself in question (how deep the module is, where the seam belongs, what the interface should expose), argue it in these terms:

- **Module**: anything with an interface and an implementation, at any scale: a function, a class, a package.
- **Interface**: everything a caller must know to use the module correctly: types, but also invariants, ordering, error modes, and required configuration.
- **Depth**: how much behaviour a caller or test can exercise per unit of interface it has to learn. Prefer deep modules (a lot behind a small interface) over shallow ones (an interface nearly as complex as the implementation).
- **Adapter**: a concrete thing that fills an interface at a seam, such as the real database repo or an in-memory fake.
- **Leverage** is what callers get from depth, and **locality** is what maintainers get: change and bugs concentrate in one place instead of spreading across callers.

## Questions for the user

Every question stops the session until the user is back, and one that arrives mid-seam stops an agent with it. So ask early, ask together, and ask only what is theirs to decide:

- **Theirs**: the seams, scope, a public interface, a new dependency, and a spec line whose readings give the user different behaviour. Collect these before the first seam starts (the explore agent lists the ones it can see) and ask them in one round.
- **Yours**: everything else, including a choice you would only present with one sensible option. Take that option, record it under Decisions marked `assumed`, and carry on. The PR lists every assumption, so the user can still overrule it at review, when it costs them a comment instead of a wait.

When a question is about the environment and not this ticket (a tool version CI pins, a service that has to be running), suggest the user record the answer in the repo's agent instructions, so the next session doesn't ask again.

## Sub-agent brief

Build every brief except the adversary's (see Adversary brief) from this template. Fill the placeholders and swap in the role line for the agent you're dispatching:

```
You are the <role> sub-agent of an implement session.
Worktree: <absolute path>. Branch: <branch>. Stay on this branch.
Read .implement/plan.md first. Use its Commands and Map instead of rediscovering them.

<role line>

Escalate, don't decide: if the work would change a confirmed seam or a public
interface, or add a dependency, stop and report needs-decision with the question.
Make local implementation choices yourself. Add one to the plan's Decisions, in
one line, only if a later agent has to honour it.

Shell: this worktree session refuses heredocs, $(...) and backticks, shell
variables, and loops. Create and edit files with the Write and Edit tools, and
split anything else into plain commands. && and pipes are fine.

Run only the tests in scope for your change (the test files for the code you
touched) plus typechecking. Never run the full test suite unless your role says so.

Commit to the current branch once your work is green, after confirming
`git branch --show-current` is neither main nor master. Never push.

Reply with this report and nothing else, at most 15 lines. Never paste logs or diffs.
status: done | partial | blocked | needs-decision
files: <changed paths>
tests: <names of tests added>
result: <one line: tests and typecheck>
notes: <only what the orchestrator must act on or tell the user: questions,
  surprises, things deferred. What you built is in the commit message.>
```

Role lines (`<skill dir>` is the base directory the harness gave when this skill was invoked):

- **explore**: Read `CONTEXT.md` and the ADRs in the area, find the code the spec touches, and propose candidate seams (the public interface, what sits behind it, its kind, where its tests go), including one `integration` seam per user-facing entry point the spec touches. Propose a split for any seam that looks like more than about ten red-green cycles. Change nothing and don't commit. Instead of the standard report, reply in at most 35 lines with four lists, one line per item: `commands` (the exact commands for the tests of one file, typecheck, lint, and the full suite, what they need to run, and any tool version CI pins; read the CI workflow and the repo's agent instructions for these), `map` (the relevant files and the existing code to imitate), `seams`, and `questions` (each spec line that can be read two ways, or that the code contradicts, with the readings).
- **seam**: Implement `<kind>` seam `<name>` from the plan, mode `<characterize or none>`, test-first, and keep its status in the plan current. Before writing anything, call the Skill tool with "architecture-principles" and read `<skill dir>/references/tdd.md`, then the file it names for your seam's kind (`unit.md` or `integration.md`), and `characterization.md` too if the seam's mode is `characterize`; follow them on every cycle. Besides the tests you write, touch only the existing tests the plan assigns to this seam. If the seam is still unfinished after about 40 turns, stop at the next green cycle: commit, set the seam to `partial` in the plan with what is left, and report `partial`. A fresh agent finishes it for less than you would. Before reporting `done`, call the Skill tool with "quality-gate" in coverage-only mode on your seam's files and close what it finds, as `tdd.md` describes.
- **observable**: Call the Skill tool with "observable" and apply it to this branch's changes since `origin/<default>`.
- **gate**: Call the Skill tool with "quality-gate", scoped to this branch's changes since `origin/<default>`. Its adversary step reports `adversary: not run (caller dispatches it)`, which is expected: the adversary runs as its own flow step. Fix what fails and rerun, at most 3 rounds; if it's still red, report `blocked` with the remaining failures in one line each.
- **review-fix**: Apply these review findings, adversary counterexamples, or failing CI checks: `<findings, counterexamples, or checks>`. Fix each test-first. For a counterexample, name its root cause before you fix it, then look for other inputs that fail for the same cause, add a test for each you find, and fix the cause in production code, not the one input: a fix that only handles the reported input brings the adversary back with its neighbour. Never delete or weaken a counterexample test. Then run the tests in scope for the fixes, plus lint and typecheck on the files you touched, before you commit. Don't rerun the quality gate: the final step runs it on the finished branch.
- **sync**: Rebase this branch onto `origin/<default>`. Resolve conflicts so both sides' intent survives; a conflict that needs a design call is a `needs-decision`, so run `git rebase --abort` and report it. Once rebased, run the tests in scope for the files that conflicted, plus lint and typecheck on them, and commit any fixes. Don't rerun the quality gate: the final step does.
- **final**: Call the Skill tool with "quality-gate", scoped to this branch's changes since `origin/<default>`, skipping its adversary step, and make sure the full test suite runs exactly once along the way (run it yourself, with the plan's Commands, if the gate's own steps didn't). If anything fails, fix it and rerun only the failing checks and the tests in scope for your fix, not the whole suite, at most 3 rounds; if it's still red, report `blocked` with the remaining failures in one line each.
- **impact**: Call the Skill tool with "merge-impact" on this branch against `origin/<default>`. The PR is not open yet and you don't open it: its draft description is `.implement/pr-body.md`, and the report goes into that file. Change no other file and don't commit, and leave the text already in the draft as it is. On a rerun after a CI fix, the brief names PR `<number>` instead: then the PR description is the only thing you write. Instead of the standard report, reply in at most 8 lines: the verdict and its one-line reason, then one line for each unannounced rule change, unverified item, and question for the author.

Dispatch the gate and final agents on the cheapest model the dispatch tool offers (in Claude Code, `model: "haiku"`): most of their work is running commands and reading exit codes. Add this sentence to their role line: `Fix only what a formatter or a lint autofix repairs, and report anything else as blocked.` On `blocked`, dispatch the same role again on the session's model, without that sentence. Every other role runs on the session's model.

## Adversary brief

The adversary never sees the plan file, the seam reports, or your reasoning about the change, so it gets this brief instead of the template above:

```
You are the adversary sub-agent of an implement session.
Worktree: <absolute path>. Branch: <branch>. Stay on this branch.
Spec: <the originating issue and the plan's spec tickets>. Change: this branch's diff since origin/<default>.

Call the Skill tool with "adversary" and attack this change against the spec.
Work the whole attack list before you report, and report every counterexample
you can prove, not only the first: each one you leave for a later run costs a
whole fix-and-confirm round.
Commit your counterexample tests to the current branch, after confirming
`git branch --show-current` is neither main nor master. Never push.

Shell: this worktree session refuses heredocs, $(...) and backticks, shell
variables, and loops. Create and edit files with the Write and Edit tools, and
split anything else into plain commands. && and pipes are fine.
Run only the tests you write and the test files they sit in, never the full suite.

Reply with the adversary skill's report and nothing else, at most 25 lines.
```

For a run that confirms fixes, replace the "Call the Skill tool" paragraph with this one, filling in the commit the fixes started from and the earlier counterexample tests:

```
Call the Skill tool with "adversary". This is a confirming run: the change was
attacked once already, and the fixes are the commits since <sha>. Run the earlier
counterexample tests (<test names and files>) and confirm they pass. Then attack
only what the fixes changed, and inputs that fail for the same cause as an
earlier counterexample. Don't work the whole attack list against the rest of the
change again.
```

## Without a sub-agent tool

Where there is no tool for dispatching sub-agents, run the same flow inline, in the same order, with the same plan file. Treat each role line as your checklist for that step, and before the first seam, call the Skill tool with "architecture-principles" and read `<skill dir>/references/tdd.md` and the file it names for each seam's kind. Finish each seam by calling the Skill tool with "quality-gate" in coverage-only mode on the seam's files, as `tdd.md` describes, before starting the next. At the adversary step, call the Skill tool with "adversary" and run it inline against the spec, the diff, and the existing tests only, setting the plan aside, and flag its result **not independent** when you report it to the user. Inline, the adversary and the review can't run together, so run the review after the adversary and fix both in step 8. At the merge impact step, call the Skill tool with "merge-impact" yourself, on the branch and its draft description.
