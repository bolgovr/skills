# Swift quality gate

Run in order. Each check must exit 0 to pass.

1. **Build**:
   - SwiftPM (`Package.swift` present): `swift build`
   - Xcode project (`.xcodeproj`/`.xcworkspace` present): find the scheme with `xcodebuild -list`, then `xcodebuild build -scheme <scheme> -destination 'generic/platform=iOS Simulator'`, swapping the destination for whatever platform the project actually targets
2. **Tests**: `swift test --enable-code-coverage` (SwiftPM) or `xcodebuild test -scheme <scheme> ... -enableCodeCoverage YES -resultBundlePath <path>.xcresult` (Xcode), mirroring whichever build path applied.
3. **Coverage**: read the report from step 2.
   - SwiftPM: `swift test --show-codecov-path` prints the path of the exported coverage JSON; read the entries for each changed source file.
   - Xcode: `xcrun xccov view --report <path>.xcresult` for the per-file summary, then `xcrun xccov view --archive --file <changed file> <path>.xcresult` for its line counts.

   Every new or changed line is covered, or the report names it with the reason it can't be: a platform call with no fake, or an accepted gap the repo documents.
4. **Lint**: only if `.swiftlint.yml` exists, `swiftlint`. No config, no lint step.
5. **Format**: only if `.swiftformat` exists, `swiftformat --lint .`. No config, no format step.
