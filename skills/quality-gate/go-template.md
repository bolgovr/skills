# Go quality gate

Run in order. Each check must exit 0 (or produce no output, where noted) to pass.

1. **Build**: `go build ./...`
2. **Vet**: `go vet ./...`
3. **Format**: `gofmt -l .` passes only if it prints nothing. Files it lists are unformatted; fix with `gofmt -w <files>` and re-run.
4. **Lint**: only if `.golangci.yml` or `.golangci.yaml` exists, `golangci-lint run`. No config, no lint step.
5. **Tests**: `go test -coverprofile=coverage.out ./...`
6. **Coverage**: read `coverage.out` from step 5: for each changed non-test `.go` file, list its uncovered blocks (records ending in a count of `0`). If `coverage.out` is missing, coverage is not measured and the step fails. Every new or changed line is covered, or excluded in the code with the gate's `// coverage-exclude: <reason>` (defined in SKILL.md). Delete `coverage.out` afterwards.
