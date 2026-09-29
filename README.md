# BrowserJet

BrowserJet is a macOS browser built using WKWebView with support for licensing, Sparkle updates, Firebase Remote Config, and a customizable launcher experience.

## Requirements

- macOS 14+
- Xcode 16+
- Swift 5
- SwiftLint

## Getting Started

1. Clone the repository.
2. Open `BrowserJet.xcodeproj` in Xcode. Swift Package dependencies (Firebase, Sparkle) resolve automatically.
3. Build and run.

> Debug builds use `GoogleService-Info-dev.plist` (dev Firebase project) and Release builds use `GoogleService-Info.plist` (production Firebase project). The correct file is copied in automatically by a build phase based on the active configuration — no manual setup required.

## Branches

- `main` — Stable production releases.
- `develop` — Active development.

## Documentation

See the following documentation:

- `CONTRIBUTING.md` — Git workflow, release process, branching strategy, pull request format, and distribution guide.
