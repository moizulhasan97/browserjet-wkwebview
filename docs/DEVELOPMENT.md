# Development and validation

## Active project

Open `BrowserJet.xcodeproj`; target and shared scheme are `BrowserJet`. `Debug` maps to Development.xcconfig and `Release` to Production.xcconfig. The shared scheme archives Release. “Production configuration” in the release guide means the Release build using Production settings.

New Swift files may require explicit target membership/project entries: inspect the existing PBX project conventions and verify membership rather than assuming files on disk are built. Do not edit the older project as a substitute.

## Commands from repository root

Resolve packages when required:

```sh
xcodebuild -project BrowserJet.xcodeproj -scheme BrowserJet -resolvePackageDependencies
```

Build without signing, using disposable build products:

```sh
xcodebuild -project BrowserJet.xcodeproj -scheme BrowserJet -configuration Debug -destination 'platform=macOS' -derivedDataPath /tmp/browserjet-derived-data build CODE_SIGNING_ALLOWED=NO
```

Lint:

```sh
swiftlint lint --no-cache --config .swiftlint.yml
```

Use Release build validation when changing environment-specific code or packaging. Release includes a Crashlytics script, so build scripts and environment prerequisites can affect that check. Do not archive, sign, notarize, publish an appcast or tag merely to validate a routine code change.

## Verification policy

- Inspect `.github/workflows/ci.yml` and `.swiftlint.yml` for current checks. CI resolves packages, builds Debug and runs lint only when installed. A skipped lint step is not a lint pass.
- No automated test target was found in the inspected PBX project/shared scheme. Choose meaningful focused tests for behavioral work; include target/project setup when adding a suite. Do not add tests that only mirror trivial implementation.
- Use relevant manual flows from the domain references for WebKit/window/entitlement behavior. Validate light/dark appearance and keyboard/focus behavior for UI changes.
- Record failures accurately, including toolchain, network or sandbox blockers. Report whether compilation actually began before attributing a failure to source code.
- For documentation-only work, check links, paths, command accuracy and diff whitespace. An app rebuild is not required merely because Markdown changed.

## Shipping

`CONTRIBUTING.md` is authoritative for branch bases, PR targets, versioning, Developer ID distribution, notarization and Sparkle appcast publishing. Use `.github/pull_request_template.md` for the PR body, including actual validation in Notes. Never commit signing secrets or private update keys.
