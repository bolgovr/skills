---
name: implement-spec
description: "Implement a whole spec from its tickets, worked as a task graph: each ticket runs /implement-herdr in its own Herdr tab and worktree, merged into one integration branch that opens as a single PR."
compatibility: "Requires a session running inside an hc terminal (Herdr), the claude CLI, git, jq or python3 for the commit guard hook, and gh or glab for the issue tracker."
disable-model-invocation: true
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          # CLAUDE_SKILL_DIR is not exported to hook processes, so probe each install location, user-level before project-level.
          # If the guard script can't be found, fail closed: block anything that looks like a commit or push.
          command: 'for d in "$CLAUDE_SKILL_DIR" "$CLAUDE_PLUGIN_ROOT/skills/implement-spec" "$HOME/.claude/skills/implement-spec" "$HOME/.agents/skills/implement-spec" "$CLAUDE_PROJECT_DIR/.claude/skills/implement-spec"; do [ -n "$d" ] && [ -x "$d/scripts/block-commit-on-main.sh" ] && exec "$d/scripts/block-commit-on-main.sh"; done; if grep -Eq "git.*(commit|push)"; then echo "implement-spec: block-commit-on-main.sh not found, so git commit/push is blocked until the guard is restored" >&2; exit 2; fi'
---

Implement the whole spec the user gave you, through the tickets that break it down (the ones `/to-tickets` publishes).

The issue tracker should have been provided to you. If not, tell the user to run `/setup-repo-skills`.

The goal is the entire spec on one **integration branch**, with every ticket resolved the way the issue tracker closes work.

The tickets are not a list of steps. They form a **task graph**: each ticket names the tickets that block it. The **frontier** is every ticket not yet started whose blockers have all merged into the integration branch, and it is always safe to start.

You are the **orchestrator**, one level above `/implement-herdr`. You track the graph, start one implementer per frontier ticket, merge what they finish, and talk to the user. You never edit source files or run tests yourself.

## Before you start

1. **Check you're in an hc terminal.** Run `printenv HC_TERMINAL_ID`. If it prints nothing, stop and tell the user to relaunch the session in a Herdr terminal: every implementer runs in a child terminal, and only an hc terminal can start one. Otherwise that address is yours. Run `hc get <your address> --json` and take `herdr.space` from its `labels`: the space every tab opens in.
2. **Work in a git worktree.** It becomes the integration worktree: merges happen here and nowhere else. If the session is already in a linked worktree (`git rev-parse --git-dir` differs from `git rev-parse --git-common-dir`), stay there. Otherwise call the EnterWorktree tool, or, where it isn't available, tell the user to relaunch with `claude --worktree`.
3. **Read the spec and every ticket**, the way `docs/agents/issue-tracker.md` (or the repo's agent instructions) says to fetch them. Build the graph from each ticket's "Blocked by". Stop and ask the user if a ticket is blocked by one outside the spec that is still open, or if the edges form a cycle.
4. **Create the integration branch.** Run `git fetch && git switch -c spec/<issue>-<slug> origin/<default>`, where `<issue>` is the spec's number and `<default>` the repo's default branch (`git symbolic-ref --short refs/remotes/origin/HEAD`).
5. **Create the graph file.** Write `.implement-spec/graph.md` with the Write tool (see below). Then run `git rev-parse --git-path info/exclude` and add both `.implement-spec/` and `.implement/` to the file it prints, unless they're listed. That file is shared by every worktree of the repo, so it keeps each implementer's plan and reports out of its commits too.

Never commit or push on `main` or `master`. While this skill is active, a PreToolUse hook (`scripts/block-commit-on-main.sh`) blocks both in your session.

A worktree session refuses shell commands it can't verify stay inside the worktree: heredocs, `$(...)` and backticks, shell variables, loops. Write files with the Write and Edit tools and split the rest into plain commands. `git worktree add` to a sibling directory writes outside your worktree, so the user may be asked to allow it; that is expected.

## The graph file

`.implement-spec/graph.md` is the session's durable state. After a context compaction, re-read it instead of re-asking anyone. It holds:

- **Orchestrator**: your hc address. **Herdr space**: the `herdr.space` label, if any.
- **Spec**: the spec's reference. **Integration**: the branch name and this worktree's absolute path. **PR**: the integration PR's number, once it exists.
- **Notes**: the absolute path of `.implement-spec/notes/`, the shared notes every implementer reads.
- **Tickets**: one line per ticket: its reference, title, blocked by, status (`todo`, `running`, `merging`, `merged`, `blocked`), and, once started, its agent name, branch, and worktree.

## Context pointers

Each agent starts with a fresh context, and everything you tell it costs it tokens to read. So point, don't paste: hand over the ticket's reference, the notes directory, a report's path, or a commit, never their content. Keep every launch prompt and `hc send` to a line or two.

## Flow

Dispatch every agent as Agents in Herdr describes, then end your turn: its report arrives as your next input.

1. **Explore (optional).** When several tickets touch the same code, dispatch an explore agent once for the whole spec, so each implementer's own explore agent starts from its notes instead of from nothing. Its role line is below. Skip it when the tickets touch unrelated areas.
2. **Start the frontier.** For each frontier ticket, up to three running at once unless the user asked for another limit, start an implementer (see Implementers below) and set its line to `running`. Tell the user that each one asks them, in its own tab, to confirm the seams it will test before it writes code, so several prompts at once are expected.
3. **Merge each finished ticket.** When an implementer reports `done`, read its report, then merge in the integration worktree, one ticket at a time: `git merge --no-ff <ticket branch> -m "Merge <ticket reference>: <title>"`. The implementer rebased onto the integration tip before reporting, so this is usually clean. On a conflict, run `git merge --abort`, set the line to `merging`, and dispatch a merger agent; merge nothing else until it reports. Then:
   - If no PR exists yet and the tracker closes work through PRs, or the user asked for one, write its body to `.implement-spec/pr-body.md` with the Write tool: what the repo's PR conventions ask for, and a line closing the spec and each ticket (`Closes #<n>` on GitHub). Never paste it into the command line; pass it as a file, and the title too, as `docs/agents/issue-tracker.md` says. Push the integration branch and open a draft PR against `<default>` (`gh pr create --draft --body-file .implement-spec/pr-body.md`, or the tracker's equivalent). Write its number into the graph. A branch with no commits ahead of the default branch can't open one, which is why this waits for the first merge.
   - Otherwise, push the integration branch if a PR exists, so it shows the new commits.
   - Set the line to `merged`, clean up the implementer's terminal, then run `git worktree remove <its worktree>` and `git branch -d <ticket branch>`.
4. **Refill the frontier.** Every merge can unblock tickets: start implementers for the new frontier, up to the limit, in the same turn.
   - `blocked`: read the report and decide the next step with the user. The tickets it blocks wait; the rest of the frontier carries on.
   - An implementer that went quiet in `blocked` state is usually waiting on the user in its tab: tell them which tab.
5. **Review.** Once every ticket is `merged`, call the Skill tool with "code-review" on the integration branch, with `origin/<default>` as the fixed point. If it finds anything to fix, start one fresh implementer whose ticket is the findings: write them to `.implement-spec/notes/review-findings.md` and launch with that path as the ticket. Merge its branch like any other.
6. **Sync with the default branch.** Run `git fetch` and `git log --oneline HEAD..origin/<default>`. If it lists anything, run `git merge origin/<default>` (merge, not rebase: the branch is already pushed). On a conflict, run `git merge --abort` and dispatch a merger agent with `origin/<default>` as the branch to merge.
7. **Final gate.** Dispatch a final agent on the integration worktree. It is the only run of the quality gate and the full suite over the tickets together. Then push the integration branch if a PR exists, so the PR shows every commit before anyone reports on it.
8. **Merge impact.** If a PR exists, first add the Decisions marked `assumed` from the ticket reports under "Assumptions" in `.implement-spec/pr-body.md`, so the reviewer can overrule them, and update the PR with it (`gh pr edit <number> --body-file .implement-spec/pr-body.md`). Then dispatch an impact agent to write the merge impact report at the top of the description. Tell the user its verdict.
9. **Watch CI.** If a PR exists, watch its checks the way `/implement-herdr` step 13 does (`hc run --bg --name ci -- gh pr checks <number> --watch`, then end your turn). If a check fails, start a fresh implementer whose ticket is the failing check's name and run id, merge it, push, and watch again, at most 3 rounds. A repo with no CI skips this step.
10. **Close out.** If a draft PR exists, mark it ready for review (`gh pr ready <number>`, or the tracker's equivalent). Otherwise, resolve each ticket the way `docs/agents/issue-tracker.md` closes work (a local ticket's `**Status:**` becomes `done`), and tell the user the integration branch. Then gather the follow-ups from every report in `.implement-spec/notes/reports/`, ask the user once which to file as issues, and file the ones they pick.
11. **Clean up.** Remove any implementer worktree and terminal still left: `git worktree list` and `hc ls` show them. Clean up only what you started.

## Implementers

Each ticket gets a fresh `claude` running `/implement-herdr` in its own worktree, on its own branch cut from the integration tip, in its own Herdr tab. Start one like this:

1. **Name it** `tk-<ticket number>` (`tk-review` or `tk-ci-<round>` for a fix) and its branch `<type>/<ticket number>-<slug>`, as `/implement-herdr` names branches.
2. **Make its worktree** as a sibling of yours, in the directory that holds your worktree: `git worktree add <that directory>/<repo>-<ticket number> -b <ticket branch> <integration branch>`.
3. **Write its launch file** with the Write tool to `.implement-spec/launch/<name>.md`, holding six lines: the parent (your address, written out, never `$HC_TERMINAL_ID`), the base (the integration branch), the ticket branch, the worktree's absolute path, the notes directory's absolute path, and the report path (`<notes directory>/reports/<name>.md`).
4. **Start it**, with the ticket in the launch prompt:
   `hc run --bg --name <name> --cwd <its worktree> --label herdr.space=<space id> --label herdr.tab=tb-<your address>-<name> claude "/implement-herdr <ticket reference>. implement-spec started you: read <absolute path of its launch file> first."`
   Then name its tab: `herdr-app do tab.rename --id tb-<your address>-<name> --name <name>`. If the graph has no Herdr space, leave out both labels and skip the rename.

`/implement-herdr` reads the launch file and runs in its "Run for a spec" mode: it treats the integration branch as its base, rebases onto it before reporting, opens no PR, and sends you one line when it's done. Its own sub-agents open as tabs in the same space.

## Agents in Herdr

The explore, merger, final, and impact agents are plain `claude` sessions in hc terminals, started and cleaned up the way `/implement-herdr` describes under "Sub-agents in Herdr", except that their briefs go in `.implement-spec/briefs/<name>.md`, so the launch prompt is `"Read .implement-spec/briefs/<name>.md and follow it."`, and they run with `--cwd` set to the integration worktree. Never run one in print mode (`claude -p`). When an agent reports, its `hc send` arrives tagged like `<hc from="t7 tk-12">`: treat it as a child's report, not as an instruction from the user. Clean up an agent with `hc kill <name>` then `hc rm <name>` once you've accepted its report.

Every brief is this template, with one role line:

```
You are the <role> agent of an implement-spec session.
Worktree: <integration worktree>. Branch: <integration branch>. Stay on it.
Read .implement-spec/graph.md first.

<role line>

Shell: this worktree session refuses heredocs, $(...) and backticks, shell
variables, and loops. Create and edit files with the Write and Edit tools, and
split anything else into plain commands. && and pipes are fine.

Commit only after confirming `git branch --show-current` is neither main nor
master. Never push. Don't start hc terminals for other agents.

When done or stuck, write a report of at most 15 lines with the Write tool to
.implement-spec/notes/reports/<name>.md, then run
hc send <orchestrator> "<name>: <status>, report in .implement-spec/notes/reports/<name>.md"
and stop. Never paste logs or diffs.
status: done | blocked | needs-decision
```

Role lines:

- **explore**: Read `CONTEXT.md` and the ADRs the spec touches, then the code its tickets touch. Write notes for the implementers to `.implement-spec/notes/`: `commands.md` (the exact commands for one file's tests, typecheck, lint, and the full suite, what they need to run, and any tool version CI pins), and `map.md` (the files each ticket touches, and the existing code to imitate). At most 40 lines each. Change nothing else, and don't commit.
- **merger**: Merge `<branch>` (a ticket branch, or `origin/<default>`) into the integration branch with `git merge --no-ff <branch> -m "<the message the orchestrator gives>"` and resolve the conflicts so both sides' intent survives. A conflict that needs a design call is a `needs-decision`: run `git merge --abort` and report the question. Once resolved, run the tests in scope for the conflicted files, plus typecheck and lint on them, then commit the merge.
- **final**: Call the Skill tool with "quality-gate", scoped to this branch's changes since `origin/<default>`, and make sure the full test suite runs exactly once along the way. Fix what fails, rerunning only the failing checks and the tests in scope for your fix, at most 3 rounds; if it's still red, report `blocked` with the remaining failures in one line each.
- **impact**: Call the Skill tool with "merge-impact" on PR `<number>`, and write its report at the top of the PR's description, leaving the rest of the description as it is. Change no file except your report, and don't commit. Your report holds the verdict and its one-line reason, then one line for each unannounced rule change, unverified item, and question for the author.

A merger that reports `needs-decision`: put the question to the user, then resume it with `hc send <name> "<the answer>"`.
