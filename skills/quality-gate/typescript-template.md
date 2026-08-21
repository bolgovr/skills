# TypeScript quality gate

Detect the package manager from the lockfile before running anything: `package-lock.json` → npm, `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `bun.lockb` → bun.

Run in order. Each check must exit 0 to pass.

1. **Typecheck**: run the `typecheck` script if `package.json` defines one, otherwise `npx tsc --noEmit`.
2. **Lint**: run the `lint` script if `package.json` defines one, otherwise skip. No configured script, no lint step.
3. **Tests**: run the `test` script if `package.json` defines one, otherwise skip. No configured script, no test step.
