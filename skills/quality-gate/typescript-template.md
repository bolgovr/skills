# TypeScript quality gate

Detect the package manager from the lockfile before running anything: `package-lock.json` → npm, `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `bun.lockb` → bun.

Run in order. Each check must exit 0 to pass.

1. **Typecheck**: run the `typecheck` script if `package.json` defines one, otherwise `npx tsc --noEmit`.
2. **Lint**: run the `lint` script if `package.json` defines one, otherwise skip. No configured script, no lint step.
3. **Tests**: run the `test` script if `package.json` defines one, otherwise skip. No configured script, no test step.
4. **Coverage**: only if step 3 ran.
   - Command: the `coverage` script if `package.json` defines one, otherwise the coverage flag of the runner the `test` script calls: `npx vitest run --coverage` or `npx jest --coverage` (or the detected package manager's equivalent). Any other runner and no `coverage` script: skip, and report coverage as not measured. Don't improvise a command.
   - Missing provider: if the runner's coverage provider isn't installed (e.g. `@vitest/coverage-v8`), report coverage as not measured rather than adding it. That's a skip, like lint with no config, not a failure.
   - Read: the text reporter's `Uncovered Line #s` column (or the equivalent in the repo's configured reporter) for each changed non-test `.ts`/`.tsx` file. A changed source file absent from the report (no test imports it, e.g. jest without `collectCoverageFrom`) counts as wholly uncovered.

   Every new or changed line is covered, or the report names it with the reason it can't be: a platform call with no fake, or an accepted gap the repo documents.
