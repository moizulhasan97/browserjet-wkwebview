# BrowserJet project instructions

BrowserJet is a native macOS browser using **WKWebView**, SwiftUI, and AppKit. It is no longer CEF based.

## Engineering judgment

- Work as a senior macOS architect: evaluate suggestions against the code and explain a better approach when evidence supports it. Do not agree reflexively or argue for its own sake.
- Prefer focused, maintainable changes within the existing feature/view-model/service architecture. Avoid speculative abstractions, placeholder implementations, unrelated cleanup, or new dependencies without a concrete need.
- Read the affected implementation before proposing changes. Distinguish verified behavior, intended behavior, and assumptions. Ask only questions that materially affect the outcome.
- `CEF_M1` is reference-only if present. Do not inspect it unless the user explicitly requests it; never change it.
- Preserve user changes. Inspect Git status before editing. Follow `CONTRIBUTING.md` for branch and PR rules; do not commit directly to `main` or `develop`. If branching is blocked, explain the limitation and leave changes uncommitted for review.

## Architecture guardrails

- Use `BrowserJet.xcodeproj`, target/scheme `BrowserJet`. Do not edit the older `browserjet-wkwebview.xcodeproj` unless the task requires it.
- Feature UI belongs in `BrowserJet/Features`; shared services in `AppFoundation`; shared UI in `Views`; theme/style primitives in `DesignSystem`. Extend existing owners instead of adding parallel state.
- Keep UI/window/WebKit state on `@MainActor` where existing owners require it. Keep async work cancellable and respect delegate, observer, task, and window lifetimes.
- Preserve session-slot accounting, per-tab/per-window store isolation, proxy authentication, trial/license restrictions, and update gates.
- A proxy burn replaces the data store and WKWebView. Preserve delegate rebinding, `webViewID`, and deferred `pendingURL` loading after attachment.
- “VPN” is the product name for browser proxy routing here; do not assume a device-wide VPN tunnel.
- Reuse semantic `appTheme`, `designSystem`, `DesignMetrics`, and existing components. Add useful previews for new or substantially changed UI using local fixtures, without production network calls.
- Use `AppLogger`, not `print()`. Do not add logs containing passwords, license keys, proxy credentials, sensitive URLs, or decrypted payloads. Existing logging is not a security precedent.
- Never hard-code operational credentials or bypass certificate validation, licensing, update enforcement, or proxy requirements to make a task pass.

## Context to read as needed

- Start with `docs/PROJECT_CONTEXT.md` for the source map and observed behavior.
- Read `docs/reference/BROWSING_AND_PROXIES.md` for tabs, WebKit, navigation, routing, or burn work.
- Read `docs/reference/LICENSING_CONFIG_UPDATES.md` for activation, account state, Remote Config, telemetry, or updates.
- Read `docs/DEVELOPMENT.md` before validation, project-file changes, or release work.
- Read `CONTRIBUTING.md` and `.github/pull_request_template.md` before branch/PR/release work.
- Read `docs/AI_WORKFLOW.md` for skill usage and handoffs. Read only relevant references; do not preload every file.

## Validation and completion

- Run checks proportionate to the change; report exact checks and outcomes. Never claim a build, test, or UI flow passed without running it.
- There is currently no configured automated test target. Do not invent an `xcodebuild test` success. Add focused tests when behavior/risk warrants them and account for target setup.
- Document behavioral changes and durable decisions alongside code. Use `docs/tasks/TEMPLATE.md` for substantial tasks; avoid one ever-growing global plan.
- End with what changed, why, validation, and any remaining limitation. Do not push, merge, tag, publish, or change external systems unless the user requested that action.
