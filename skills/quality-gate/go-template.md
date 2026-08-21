# Go quality gate

Run in order. Each check must exit 0 (or produce no output, where noted) to pass.

1. **Build**: `go build ./...`
2. **Vet**: `go vet ./...`
3. **Format**: `gofmt -l .` passes only if it prints nothing. Files it lists are unformatted; fix with `gofmt -w <files>` and re-run.
4. **Lint**: only if `.golangci.yml` or `.golangci.yaml` exists, `golangci-lint run`. No config, no lint step.
5. **Tests**: `go test ./...`
