# TypeScript quality gate

Detect the package manager from the lockfile before running anything: `package-lock.json` → npm, `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `bun.lockb` → bun.

Run in order. Each check must exit 0 to pass.

1. **Typecheck**: run the `typecheck` script if `package.json` defines one, otherwise `npx tsc --noEmit`.
2. **Lint**: run the `lint` script if `package.json` defines one, otherwise skip. No configured script, no lint step.
3. **Tests**: run the `test` script if `package.json` defines one. Without one there is nothing to run here, and step 4 fails.
4. **Coverage**: never skipped. If step 3 didn't run, coverage is not measured and the step fails.
   - Command: the `coverage` script if `package.json` defines one, otherwise the coverage flag of the runner the `test` script calls: `npx vitest run --coverage` or `npx jest --coverage` (or the detected package manager's equivalent). Any other runner and no `coverage` script: coverage is not measured, so fail and name the runner. Don't improvise a command.
   - Missing provider: if the runner's coverage provider isn't installed, fail and name the exact install command with the detected package manager (e.g. `npm install -D @vitest/coverage-v8`). Never install it yourself.
   - Read: the text reporter's `Uncovered Line #s` column (or the equivalent in the repo's configured reporter) for each changed non-test source file (`.ts`, `.tsx`, `.js`, `.jsx`, `.mjs`, `.cjs`; tool config such as `vitest.config.ts` aside). A changed source file absent from the report (no test imports it, e.g. jest without `collectCoverageFrom`) counts as wholly uncovered.

   Every new or changed line is covered, or excluded in the code with the configured provider's pragma: `/* v8 ignore next -- @preserve <reason> */` for v8 (vitest's default; without `@preserve`, esbuild strips the comment from TypeScript), `/* istanbul ignore next -- <reason> */` for istanbul (jest's default, `coverageProvider: 'babel'`). Each provider ignores the other's pragma, so use the one matching the provider in the vitest or jest config.
