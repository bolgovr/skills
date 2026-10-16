---
name: claude-handoff
description: Hand the current conversation off to a fresh background agent that picks up the work immediately.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Write a handoff summary of the current conversation so a fresh agent can continue the work. Instead of saving it, launch a background agent seeded with the summary as its prompt.

Never paste the summary into the command line. It is Markdown, and inside double quotes the shell runs every backtick span and `$()` in it. Write it to a new file in a temporary directory (the session scratchpad, if there is one) with the file-writing tool, not with `echo` or a heredoc, then launch:

```bash
claude --bg --name "<descriptive name>" "$(cat <summary file>)"
```

Command substitution inserts the file's text as is, so the agent receives it as written. The agent starts in the current working directory and returns immediately; the user manages it with `claude agents`.

Always pass `-n`/`--name` with a descriptive name in plain words, without quotes, backticks, or `$` (e.g. `--name "Fix login bug"`); it sets the display name shown in the job list, session picker, and terminal title.

Include a "suggested skills" section in the summary, naming which skills the next agent should call the Skill tool for.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information, since the summary becomes the agent's prompt.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the summary accordingly.
