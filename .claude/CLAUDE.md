Skills are organized into folders under `skills/`:

Every skill must have a reference in the top-level `README.md`. The Claude Code plugin ships every skill folder under `skills/` (its default scan), so there is no manifest list to update.

Install commands are copied verbatim from [.agents/install-block.md](../.agents/install-block.md).

Each skill entry in the top-level `README.md` must link the skill name to its `SKILL.md`.

Every `SKILL.md` is either user-invoked (`disable-model-invocation: true` plus `policy.allow_implicit_invocation: false` in `agents/openai.yaml`, reachable only by the human) or model-invoked (model- or user-reachable). See [.agents/invocation.md](../.agents/invocation.md).

To (re)link every skill into the local harness skill directories (`~/.claude/skills`, `~/.agents/skills`), run `scripts/link-skills.sh`. Each entry is a symlink into this repo, so a `git pull` keeps installed skills current; re-run the script after adding, removing, or renaming a skill.

No em-dashes anywhere in this repo's prose (`SKILL.md` files, docs, `README.md`, `CHANGELOG.md`, ADRs, changesets, code comments). Where a sentence reaches for one, rewrite it instead with a comma, colon, period, parentheses, or a conjunction, whichever the sentence actually wants; never do a blind character substitution.

Run `scripts/check.sh` before committing. It enforces the rules above that a script can check (README entries, paired invocation flags, skill references, em-dashes), runs the commit-guard tests and shellcheck, and runs `claude plugin validate . --strict`. Enable it as a pre-commit hook once per clone with `git config core.hooksPath .githooks`. A skill referenced from upstream rather than shipped here goes in its `EXTERNAL_SKILLS` list.
