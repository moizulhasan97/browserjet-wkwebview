# BrowserJet repository context

Verified from this checkout on 2026-11-17. This is a navigation aid, not a substitute for reading current source. Version numbers and external configuration can change. No live backend, Firebase console, or deployed update feed was inspected.

## Product and stack

BrowserJet is a licensed macOS browser with a launcher for selecting a starting URL, tab count, and local/built-in/premium proxy routing. The active engine is Apple's WKWebView. UI uses SwiftUI with AppKit window controllers and an NSViewRepresentable bridge to WebKit. State uses ObservableObject, @Published, Combine, and main-actor owners; this is not a reducer framework or a fully uniform MVVM architecture.

The declared baseline is macOS 14, Swift 5, and Xcode 16+. The installed Xcode inspected here is 16.3. Availability of individual WebKit/Network APIs still needs a build check. SPM requirements in the project are Firebase >=12.12.1 and Sparkle >=2.9.1 within their configured version ranges; these are requirements, not verified resolved versions. Firebase products: Core, Analytics, Crashlytics, Remote Config.

## Folder and responsibility map

| Location | Responsibility / starting point |
| --- | --- |
| `BrowserJet/App` | `BrowserJet.swift` entry, `Core/AppDelegate.swift`, Firebase resource files, configuration environment bridge |
| `BrowserJet/Features/Root` | Stored-key bootstrap, activation outcomes, force-update root gate |
| `BrowserJet/Features/Activation` | Activation UI and view model, messages, content sizing |
| `BrowserJet/Features/RecoverAccount`, `ShiftLicense` | Recovery and license transfer flows |
| `BrowserJet/Features/Launcher` | Settings, VPN/region options, presets, `LaunchRequest` construction |
| `BrowserJet/Features/WindowController` | `WindowManager`, native browser window controller, titlebar tab accessory |
| `BrowserJet/Features/Browser` | Browser chrome, toolbar, menus, commands, tab UI, `State/BrowserWindowState.swift`, WebKit bridge, native error UI, screenshots, about/change-key flows |
| `BrowserJet/Features/Settings` | Settings UI/model, start URL preferences, quit confirmation |
| `BrowserJet/Features/Update` | Sparkle coordination/delegate, optional and blocking update UI |
| `BrowserJet/AppFoundation` | Session slots, licensing, API endpoints/services, proxy/VPN providers, Remote Config, analytics/crash reporting, shortcuts |
| `BrowserJet/AppFoundation/Networking/Proxy/Model` | `TabModel` and `TabNavigationDelegate` live here despite being browser-state objects |
| `BrowserJet/DesignSystem` | Theme, metrics, typography, button/text-field providers, environment injection |
| `BrowserJet/Views` | Reusable UI components |
| `BrowserJet/Models` | App configuration, session and payment-alert models |
| `BrowserJet/Utils` | Proxy repositories/decryption, persistence helpers, URL resolution, update policy, logging and extensions |
| `BrowserJet/Configurations` | Base, Development and Production xcconfigs |
| `.github` | macOS build/lint workflow and PR template |

`BrowserJet.xcodeproj` is the active project. The older `browserjet-wkwebview.xcodeproj` directory contains a shared scheme; its role is not established. No `CEF_M1` folder was present at the repository root during inspection; its reference-only restriction still applies if added or mounted later.

## Runtime flow

1. `BrowserJet.swift` creates theme/session state and the Sparkle updater; configures Firebase, telemetry, and an asynchronous Remote Config fetch; then presents activation through `WindowManager`.
2. `BrowserJetRootView` chooses full activation or stored-key verification. `LicenseActivationCoordinator` verifies/persists license state and returns success, expired trial, expired license, or shift-required outcomes.
3. Successful entry transitions to the launcher. Expired access offers a payment flow through a restricted browser. Shift/recovery/key-change behavior has dedicated owners.
4. `LauncherViewModel` manages settings, trial filtering, regions and pool availability. `LauncherSettings.makeLaunchRequest` resolves the routing selection and isolation/user-agent configuration.
5. `WindowManager.showBrowser` creates the proxy provider and browser state/controller. It aborts a proxied launch when no provider exists.
6. `BrowserWindowState` creates tabs using session slots and data stores; each `TabModel` owns its WKWebView. The SwiftUI container attaches that view and supplies a UI delegate.
7. Remote Config policies feed telemetry flags, menus, endpoints, built-in pools and update behavior. License monitoring can terminate access after verification shows expiry or a machine mismatch.

## Observed defaults, not product promises

Both app configurations currently use per-tab isolation, a maximum of 20 tabs, enabled Safari-style custom user agent, an IP-check starting URL, and a single offered built-in tier (VPN 1). Regions are AU, CA, NL, NZ, UAE, UK, US. Trial-blocked tier sets are currently empty. Read `Models/AppConfiguration.swift` before relying on any default.

The development xcconfig currently declares 4.0.3-dev, production 4.0.3, build 11. This does not establish a published release. Both API environments currently point to the same service host, with endpoint behavior also influenced by Remote Config. Separate Firebase plists do not imply separate service backends.

## Follow-up concerns to verify when relevant

These are inspection findings, not confirmed defects or an authorization to change behavior:

- No test target/test suite was found; CI builds Debug and optionally runs SwiftLint.
- `APIClient` logs request headers/body/full URL and response body. Audit redaction before extending logging around credentials or account data.
- UUID-identified WKWebsiteDataStores are not equivalent to nonpersistent stores. Verify retention/removal behavior before promising ephemeral browsing or changing isolation.
- Provider validation at launch does not prove every later pool-exhaustion path fails closed; inspect tab creation and replacement paths for routing-sensitive work.
- Existing KVC `drawsBackground` use and SDK/API availability need consideration for WebKit compatibility tasks.
- Popup routing contains explicit SeatGeek checkout handling in both delegates; preserve or deliberately revise it with evidence.
- `CONTRIBUTING.md` calls archiving “Production”; the actual shared scheme archives `Release`, which uses Production.xcconfig.

## Durable context

User: Moiz Ul Hasan, experienced iOS/macOS engineer. Prefers evidence-based architecture discussion, constructive disagreement when an approach is weaker, maintainable code consistent with existing architecture, and focused changes. Uses Claude alongside ChatGPT. CEF knowledge from older conversations must not be treated as the current engine architecture.

For future sessions, read this file and `CLAUDE.md`, then recheck affected source. Record durable new decisions in `docs/DECISIONS.md`; keep task progress in individual task notes. These tracked files preserve shared context without relying on a particular assistant's private memory.
