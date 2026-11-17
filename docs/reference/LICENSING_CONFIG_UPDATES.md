# Licensing, remote configuration and updates

## Licensing

Read `LicenseActivationCoordinator`, `LicenseService`, `LicenseStore`, `LicenseAccountStore`, `UserSession`, `VerifyKeyResponse` and `PersistedLicense` together before changing entitlement behavior. API endpoint construction belongs in the existing endpoint/service layers, not directly in a view.

The coordinator verifies keys, persists response/account fields, synchronizes telemetry identity and makes a backend key update when needed. Outcomes include success, shift-required, trial-expired and license-expired. Root and activation views coordinate UI transitions with `WindowManager`. A stored key is verified at startup; do not assume it guarantees offline access.

Key changes clear premium proxy state when the key changes and reset the backend-update marker. Full invalidation of all old-license-associated data has a TODO in the activation coordinator; do not assume it is complete. Key change has a relaunch expectation.

`BrowserLicenseBackgroundMonitor` polls eligible licenses, handles cancellation, refreshes persisted account state, and can show a grace-shutdown alert before quitting on rejection/expiry. Transient transport errors are logged and the loop continues. Preserve distinctions between entitlement rejection, expiry, and transport failure.

## Networking and configuration

`APIClient` uses URLSession and async/await with typed, text and raw-data request methods. `EndpointProtocol` and endpoint types construct requests; service types hold operations. Current status classification includes HTTP 401...500 as unauthorized and 501...599 as server errors. This is an observed implementation detail, not a recommended generic classification.

`AppEnvironment` selects development/production from build conditions. Debug uses Development.xcconfig and the development Firebase plist; Release uses Production.xcconfig and the production plist. `APIEnvironment` currently uses the same service base URL for both. Never infer backend isolation from the Firebase environment.

`RemoteConfigManager` supplies decoded defaults/resolved models for keys in `RemoteConfigKey`: force_update_enabled, menu_config, app_update_config, feature_flags_config, endpoints_config, builtin_vpn_config. Built-in pool configuration is sensitive and excluded from value logging. Unsupported or malformed built-in pool schemas leave pools unavailable; do not guess credentials or silently route direct.

## Updates and observability

`BrowserJet.swift` starts Sparkle and registers `ForceUpdateGate` and `SparkleUpdateCoordinator`. After Remote Config fetch, `AppUpdatePolicy.evaluateBuild()` supplies policy results. Read policy evaluation, coordinator, updater delegate and blocking UI together before changing enforcement. Manual-download fallback and the Sparkle feed are separate concerns.

Use `AnalyticsManager`/event definitions and `CrashReportingManager` rather than calling vendor SDKs throughout features. Remote flags control reporting. Preserve identity handling; never expose raw license keys or proxy credentials in telemetry.

The repository explicitly documents Sparkle appcast publishing in `CONTRIBUTING.md`. Older conversational assumptions that updates only use website/GitHub downloads must not override the current code. No feed availability or deployed release was verified during this documentation pass.

## Focused manual checks

Cover first activation, stored-key bootstrap, invalid key, transfer/shift, trial and paid expiry, recovery, key replacement and relaunch, unavailable network, and relevant license-monitor cancellation/shutdown behavior. For configuration/update changes, cover absent/malformed/unsupported values, offline fallback, optional update and blocking update behavior. Use fixtures or an authorized non-production setup for destructive entitlement/update scenarios.
