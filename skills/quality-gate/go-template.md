# Go quality gate

Run in order. Each check must exit 0 (or produce no output, where noted) to pass.

1. **Build**: `go build ./...`
2. **Vet**: `go vet ./...`
3. **Format**: `gofmt -l .` passes only if it prints nothing. Files it lists are unformatted; fix with `gofmt -w <files>` and re-run.
4. **Lint**: only if `.golangci.yml` or `.golangci.yaml` exists, `golangci-lint run`. No config, no lint step.
5. **Tests**: `go test -coverprofile=coverage.out ./...`
6. **Coverage**: read `coverage.out` from step 5: for each changed non-test `.go` file, list its uncovered blocks (records ending in a count of `0`). If `coverage.out` is missing, coverage is not measured and the step fails. Every new or changed line is covered, or excluded in the code with `// coverage-exclude: <reason>`, at the end of the line or alone on the line above it. Go has no native pragma: the tool still reports the line, and the gate honours the comment when reading the report. An exclusion with no reason doesn't count. Delete `coverage.out` afterwards.
