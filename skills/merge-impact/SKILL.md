---
name: merge-impact
description: "Work out what merging a pull request would actually do, and write it into the PR description, ideally before the PR is opened so it opens with the report in it: the blast radius (which entry points, flows, data, and consumers the change reaches), the business rules and flows it changes (before and after, announced or not), a verdict for the reviewer (Merge, Skim, or Review carefully) with the exact spots worth their eyes and the things it could not verify, and questions for the author. Use when the user asks what a PR or diff affects, what could break, how risky a change is, whether a PR is safe to merge or needs a careful review, where to focus a review, or wants a PR description that lowers the reviewer's mental load, even if they never say \"blast radius\" or \"impact\"."
compatibility: "Requires git, plus gh (or glab on GitLab) to read and update the pull request."
---

A reviewer opening a PR has to answer three questions before reading a single line carefully: what does this touch, what does it change about how the product behaves, and how hard do I need to look? This skill answers those from the diff and the code around it, and puts the answers in the PR description, where the reviewer already is.

This is not a code review. It does not judge style, standards, or whether the code matches its spec (the `code-review` skill does that). It tells the reviewer where their attention pays off. If you trip over an outright bug while tracing, list it among the review spots, but do not go hunting for them.

## Process

### 1. Pin the change

The user names a PR (number or URL), or means the PR of the current branch, or a branch that has no PR yet. Resolve it with `gh pr view <n> --json number,title,body,url,baseRefName,headRefName,headRefOid,author` and take the diff from `gh pr diff <n>`. Read the title, the existing description, and any linked issue: they are what the author has *announced*, and step 4 compares the code against them.

Tracing needs the code at the PR's head, not only the diff. If the local checkout is not at the head commit, fetch it (`git fetch origin pull/<n>/head`) and read through `git grep <pattern> FETCH_HEAD` and `git show FETCH_HEAD:<path>`, so the user's working tree is left alone.

**A branch that is about to become a PR.** The best time to run this is before the PR is opened, so the PR opens with the report already in its description and no reviewer ever sees it without one. Do the same analysis against `git diff <base>...HEAD`, where `<base>` is the branch the PR will target. What is announced is the draft description, if the caller names a file holding one, plus the commit messages and any linked issue. Then go to step 8's draft path.

If there is no PR and none is being opened (a pasted diff, a branch the user only wants weighed), do the same analysis and go to step 8's no-PR path.

### 2. Separate behaviour from noise

Sort each hunk into one of two piles:

- **Mechanical**: renames, moves, formatting, comments, generated files, lockfiles, pure test additions. Confirm a hunk is mechanical before calling it so: a "rename" that also flips a condition is the classic place a behaviour change hides.
- **Behavioural**: anything that changes what the system does for some input, including config values, defaults, migrations, dependency upgrades, and deleted code.

Everything after this step is about the behavioural pile. The mechanical pile gets one line in the report, so the reviewer knows they can scroll past it. Line count says nothing about risk: a 900-line move can be a merge, and a one-character change to a fee threshold cannot.

### 3. Trace the blast radius

For each behavioural change, walk outward from the changed symbol until you reach something a person or another system touches. Search for callers; do not infer them from file names.

- **Entry points**: the HTTP routes, jobs, CLI commands, queue consumers, and webhooks that reach the changed code. A reviewer cannot weigh "changed `price_for()`"; they can weigh "every checkout, plus the nightly invoice job".
- **Shared surface**: database schema and migrations, config and environment variables, feature flags, public API shapes, emitted events, and shared helpers with many callers. These reach past what the diff shows.
- **Who feels it**: which users, tenants, or downstream systems, and whether all of them or a subset.
- **Reversibility**: can a revert undo it? Data migrations, deleted data, sent messages, and calls to external systems cannot be taken back by reverting the commit, and that changes the verdict more than anything else.
- **Test cover**: whether the changed behaviour is exercised by a test in the diff or already in the repo. Name the behaviour that is not.

State the radius as flows and entry points, with `file:line` anchors so the reviewer can jump there. A list of touched files adds nothing: the diff view already shows it.

### 4. Name the rule changes

For each behavioural change, write one before-and-after sentence in the product's language, not the code's. Use the repo's `CONTEXT.md` vocabulary if it has one.

> Before: a Member with any overdue Loan could not borrow. After: only Loans overdue by more than 7 days block borrowing.

Look past the headline change for the quiet ones: a changed default, a loosened or tightened validation, a moved boundary (`<` to `<=`), different rounding, a new ordering, an error that is now swallowed or newly raised, a permission check added or dropped, a retry or timeout change.

Then mark each rule change **announced** (the title, description, or linked issue says so) or **unannounced**. An unannounced behaviour change is the single most valuable thing this report can surface: it is either an accident, or an intention the reviewer was never told about, and they need to know either way.

### 5. Say what you could not verify

Every claim in the report is either traced in the code or it is not. Where the trail goes cold, say so and say why, instead of guessing in either direction: dynamic dispatch or reflection, consumers in another repo, configuration that lives outside the repo, behaviour that depends on production data, a caller search that may be incomplete.

A reviewer can check three named unknowns in a few minutes. An unknown hidden behind a confident sentence costs them the whole review, because once they find one they stop trusting the rest.

### 6. Reach a verdict

Pick one, and lead the report with it:

- **Merge**: nothing behavioural, or a behavioural change that is contained, announced, covered by tests, and undone by a revert. The reviewer can approve on the strength of the report.
- **Skim**: mostly safe, with a small number of named spots that deserve a human read. Name them; the rest can be skipped.
- **Review carefully**: any of: an unannounced rule change; money, authentication, authorization, or personal data; a migration or anything a revert cannot undo; a shared surface with wide reach; or an unknown from step 5 that sits on something important.

Give the reason in one sentence. Then list the review spots in the order the reviewer should read them, each with a `file:line` and the specific question to answer there ("does the nightly job still get a non-null `tenant_id` here?"), not a vague "check this".

Be willing to say Merge. A report that hedges every PR up to "Review carefully" teaches the reviewer to ignore it, and then it protects nothing. Equally, do not talk a risky change down because the diff is small or the author is senior.

### 7. Ask the author what only they know

Some of the reviewer's load can only be lifted by the author. List the specific questions whose answers belong in the description and are not there yet, for example: why this approach; whether an unannounced change from step 4 is intended; how it was tested beyond the automated suite; the rollout and rollback plan for anything irreversible; what was deliberately left out. Ask only what this PR raises: a generic checklist is noise. If the description already covers everything, omit the section.

### 8. Write it into the PR description

The report lives in the PR body, below whatever the author wrote. Keep the author's text exactly as it is, and wrap the report in markers so a rerun replaces the old report instead of stacking a second one:

```markdown
<!-- merge-impact:start -->
## Merge impact

**Verdict: Skim.** One sentence of reason.

### Review these spots
1. `path/to/file.py:42`: the question to answer here.

### Blast radius
- **Entry points**: ...
- **Shared surface**: ...
- **Who feels it**: ...
- **Reversibility**: ...
- **Not covered by tests**: ...

### Rule changes
| | Before | After | Announced |
|---|---|---|---|
| Short name | ... | ... | yes / no |

### Not verified
- What, and why the trail went cold.

### Questions for the author
- ...

Mechanical, safe to scroll past: one line naming the files or kinds of change.

<sub>Generated by merge-impact at `<short head sha>`.</sub>
<!-- merge-impact:end -->
```

Drop any section that has nothing in it (a Merge verdict often has no review spots and no rule changes) and keep every entry to a line or two. The report exists to save reading time, so one that is longer than the diff has failed. The head SHA in the footer tells a later reader whether the report is stale.

**The PR is open.** Write the new body to a temporary file and apply it with `gh pr edit <n> --body-file <file>`. Never pass the body on the command line: it is Markdown, and the shell would run its backticks. Then tell the user the verdict, its one-line reason, and the PR URL; do not repeat the whole report in chat.

**The PR is not open yet (the draft path).** The report goes into the description file the PR will be opened with. If the caller named a draft file, add the report to it under the same rules: the text already there stays exactly as it is, and the markers replace an older report. Otherwise write the report to a new file, with a short summary of the change above it as the author's part. Then open the PR with that file as its body (`gh pr create --body-file <file>`), unless the caller opens it or the user only asked for the description; in that case say where the file is. Tell the user the verdict and its one-line reason. Commits pushed after this point make the report stale, so run the skill again on the open PR if the head moves.

**No PR, or the edit is refused** (no permission on someone else's PR): print the report in chat as a ready-to-paste block and say plainly that nothing was posted. Do not fall back to posting a comment unless the user asks for one.
