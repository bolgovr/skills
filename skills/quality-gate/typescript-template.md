# TypeScript quality gate

Detect the package manager from the lockfile before running anything: `package-lock.json` → npm, `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `bun.lockb` → bun.

Run in order. Each check must exit 0 to pass.

1. **Typecheck**: run the `typecheck` script if `package.json` defines one, otherwise `npx tsc --noEmit`.
2. **Lint**: run the `lint` script if `package.json` defines one, otherwise skip. No configured script, no lint step.
3. **Tests**: run the `test` script if `package.json` defines one, otherwise skip. No configured script, no test step.
4. **Coverage**: only if step 3 ran. Run the `coverage` script if `package.json` defines one, otherwise the test runner's own coverage flag, matched to the runner the `test` script calls: `npx vitest run --coverage` or `npx jest --coverage` (or the detected package manager's equivalent). If the runner's coverage provider isn't installed (e.g. `@vitest/coverage-v8`), report that rather than adding it. Read the per-file report for each changed non-test `.ts`/`.tsx` file: every new or changed line is covered, or the report names it with the reason it can't be: a platform call with no fake, or an accepted gap the repo documents.
