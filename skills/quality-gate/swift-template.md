# Swift quality gate

Run in order. Each check must exit 0 to pass.

1. **Build**:
   - SwiftPM (`Package.swift` present): `swift build`
   - Xcode project (`.xcodeproj`/`.xcworkspace` present): find the scheme with `xcodebuild -list`, then `xcodebuild build -scheme <scheme> -destination 'generic/platform=iOS Simulator'`, swapping the destination for whatever platform the project actually targets
2. **Tests**: `swift test --enable-code-coverage` (SwiftPM) or `xcodebuild test -scheme <scheme> ... -enableCodeCoverage YES -resultBundlePath <path>.xcresult` (Xcode), mirroring whichever build path applied. `-resultBundlePath` fails if the bundle already exists: use a fresh temp path, or delete it first.
3. **Coverage**: read the report from step 2.
   - SwiftPM: `xcrun llvm-cov show <test binary> -instr-profile=.build/debug/codecov/default.profdata <changed source files>` (plain `llvm-cov` off macOS) prints each line with its execution count; lines with a count of `0` are uncovered. The test binary is `.build/debug/<TestTarget>.xctest/Contents/MacOS/<TestTarget>` on macOS (`.build/debug` is a symlink to `.build/out/Products/Debug`), `.build/debug/<TestTarget>.xctest` on Linux, where `<TestTarget>` is the test target's name in `Package.swift`. If the profdata isn't there, its directory is the one holding the JSON that `swift test --show-codecov-path` prints.
   - Xcode: `xcrun xccov view --report <path>.xcresult` for the per-file summary, then `xcrun xccov view --archive --file <source path> <path>.xcresult` for line counts (lines with a count of `0` are uncovered). `--file` needs the absolute source path as recorded at build time; `xcrun xccov view --archive --file-list <path>.xcresult` lists them. Delete the `.xcresult` bundle afterwards.

   If no profdata or `.xcresult` exists, coverage is not measured and the step fails. Every new or changed line is covered, or excluded in the code with `// coverage-exclude: <reason>`, at the end of the line or alone on the line above it. Swift has no native pragma: the tool still reports the line, and the gate honours the comment when reading the report. An exclusion with no reason doesn't count.
4. **Lint**: only if `.swiftlint.yml` exists, `swiftlint`. No config, no lint step.
5. **Format**: only if `.swiftformat` exists, `swiftformat --lint .`. No config, no format step.
