# Dart / Flutter quality gate

Use `flutter` when `pubspec.yaml` depends on `sdk: flutter`, otherwise `dart` (`dart analyze`, `dart test`). Throughout, "changed `.dart` files" means the scoped change minus generated code: `*.g.dart`, `*.freezed.dart`, `*.mocks.dart`, `lib/generated/**`, and generated packages. If the repo's CI excludes paths, exclude them too.

If the repo defines its own check entry points (Makefile targets such as `check`/`test`/`coverage`, scripts under `tool/`, or commands named in `AGENTS.md`/`CLAUDE.md`), run those in place of the matching step below; they encode the repo's exclusions and flags. Run the long steps (tests) as background commands and wait for the completion notification.

Run in order. Each check must exit 0 to pass.

1. **Format**: `dart format --output=none --set-exit-if-changed <changed .dart files>`. Only the changed files: an existing unformatted file elsewhere is not this change's failure.
2. **Analyze**: `flutter analyze` (or `dart analyze`), with the same flags CI passes (read the workflow file, e.g. `--no-fatal-infos`). A finding in a file this change didn't touch, already present on the base branch, is pre-existing; confirm it with `git stash`, then report it without counting it as a failure.
3. **Codegen fresh**: only if the change touches a file with a `part '*.g.dart'` directive, a `*.arb` file, or a codegen config.
   - Regenerate with the repo's own command (a Makefile target, `dart run build_runner build --delete-conflicting-outputs`, `dart run intl_utils:generate` / `flutter gen-l10n`). Never use `--build-filter`: a filtered build deletes the other outputs.
   - Then `git status`. It passes when every generated file the change needs is committed and nothing else moved.
4. **Tests**: `flutter test --coverage <targets>`, where the targets are the changed test files plus the test file mirroring each changed `lib/` file (`lib/a/b.dart` → `test/a/b_test.dart`). Then run the full suite once.
5. **Coverage**: read `coverage/lcov.info` from step 4. For each changed `lib/` file, list its uncovered lines (`DA:<line>,0` records). Every new or changed line is covered, or the report names it with the reason it can't be: a platform call with no fake, or an accepted gap the repo documents.
