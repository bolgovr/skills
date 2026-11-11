# Python quality gate

Throughout, "changed `.py` files" means the scoped change minus generated code and migrations the repo's own config already excludes (read `pyproject.toml`, `setup.cfg`, `.coveragerc`, and the CI workflow for the exclusions and flags, and use the same ones).

If the repo defines its own check entry points (Makefile targets such as `lint`/`test`/`coverage`, scripts, or commands named in `AGENTS.md`/`CLAUDE.md`), run those in place of the matching step below; they encode the repo's environment, exclusions, and flags. Otherwise run each tool through the project's environment: `uv run <tool>` with a `uv.lock`, `poetry run <tool>` with a `poetry.lock`, the repo's `.venv/bin/<tool>` if it exists, else `python -m <tool>`.

Run in order. Each check must exit 0 to pass.

1. **Format**: only if a formatter is configured (`[tool.ruff.format]` or `[tool.ruff]` in `pyproject.toml`, `ruff.toml`, or `[tool.black]`): `ruff format --check <changed .py files>` or `black --check <changed .py files>`. Only the changed files. No config, no format step.
2. **Lint**: only if a linter is configured (ruff or flake8): `ruff check <changed .py files>` or `flake8 <changed .py files>`. No config, no lint step.
3. **Typecheck**: only if a type checker is configured (`[tool.mypy]`, `mypy.ini`, `pyrightconfig.json`, or `[tool.pyright]`): run it the way CI does. A finding in a file this change didn't touch, already present on the base branch, is pre-existing; report it without counting it as a failure. No config, no typecheck step.
4. **Tests**: run the tests that reach each changed non-test `.py` file, plus the changed test files, under coverage (the command in step 5). The runner is `pytest` if the repo configures or depends on it, otherwise `python -m unittest`. If neither finds a test, there is nothing to run here, and step 5 fails.
5. **Coverage**: never skipped. If step 4 didn't run, coverage is not measured and the step fails.
   - Command: the repo's own coverage entry point if it has one. Otherwise, with `pytest-cov` installed, `pytest --cov --cov-report=term-missing <targets>`; with only `coverage` installed, `coverage run -m pytest <targets>` (or `coverage run -m unittest <targets>`), then `coverage report -m`. Don't improvise another command.
   - Missing provider: if neither `pytest-cov` nor `coverage` is installed, coverage is not measured: fail and name the exact install command for the project's environment (e.g. `uv add --dev pytest-cov`). Never install it yourself.
   - A coverage run that fails where the plain test run passes (an import that breaks under tracing, say) is still not measured: fail and show the error. Don't fall back to reading the code.
   - Read: the `Missing` column of the report for each changed non-test `.py` file. A changed file absent from the report (no test imports it, or the configured `source` leaves it out) counts as wholly uncovered.

   Every new or changed line is covered, or excluded in the code with `# pragma: no cover - <reason>` at the end of the line (on a `def`, `class`, or `if` line it excludes the whole block). A bare `# pragma: no cover` has no reason and doesn't count. Delete `.coverage` afterwards unless the repo tracks or ignores it already.
