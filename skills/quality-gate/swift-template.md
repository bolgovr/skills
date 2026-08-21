# Swift quality gate

Run in order. Each check must exit 0 to pass.

1. **Build**:
   - SwiftPM (`Package.swift` present): `swift build`
   - Xcode project (`.xcodeproj`/`.xcworkspace` present): find the scheme with `xcodebuild -list`, then `xcodebuild build -scheme <scheme> -destination 'generic/platform=iOS Simulator'`, swapping the destination for whatever platform the project actually targets
2. **Tests**: `swift test` (SwiftPM) or `xcodebuild test -scheme <scheme> ...` (Xcode), mirroring whichever build path applied.
3. **Lint**: only if `.swiftlint.yml` exists, `swiftlint`. No config, no lint step.
4. **Format**: only if `.swiftformat` exists, `swiftformat --lint .`. No config, no format step.
