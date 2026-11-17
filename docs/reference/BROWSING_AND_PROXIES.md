# Browsing, isolation and proxy routing

## Ownership and entry points

- `Features/WindowController/WindowManager.swift`: launcher-to-browser transition and provider selection.
- `Features/Browser/State/BrowserWindowState.swift`: tab collection, selection, history stack, navigation actions, duplicate/reopen, zoom, proxy burn.
- `AppFoundation/Session/SessionManager.swift`: shared slot pool and active-session count. Acquisition must pair with release across close and window teardown paths.
- `AppFoundation/Networking/Proxy/Model/TabModel.swift`: tab identity, session slot, resolved proxy, WKWebView, observed navigation state and native navigation-failure lifecycle.
- `AppFoundation/Networking/Proxy/Model/TabNavigationDelegate.swift`: KVO, navigation callbacks, authentication, popup policy and web-process termination handling.
- `Features/Browser/Components/WebView/WebViewContainer.swift`: NSViewRepresentable attachment, WKUIDelegate, window.open routing and deferred initial/replacement loading.
- `Utils/Helpers/AddressBarURLResolver.swift`: address/search interpretation; reuse it rather than implementing another URL parser.

## Isolation and routing

`SessionIsolationMode` supports per-tab and per-window. Per-tab creates a fresh UUID-identified WKWebsiteDataStore for each tab; per-window shares one store and resolved proxy. These stores are not declared nonpersistent. Do not describe them as incognito or claim disk cleanup without verifying it.

`ProxyType` distinguishes local and proxied sources. Provider selection passes through `AuthProxyProviderFactory`; providers include static, list and templated authentication strategies. `ProxyPoolService` associates proxy assignments with session slots. `ProxyConfigurationFactory` builds an HTTP CONNECT Network proxy configuration and applies credentials to the website data store. `TabNavigationDelegate` also handles proxy authentication challenges.

The built-in VPN pool is supplied through Remote Config, not bundled credentials. Premium proxy loading uses `PremiumProxyRepository`, `ProxyService`, payload decryption and decoded proxy models. Read these implementations before changing license-scoped caching or pool refresh. The existence of a custom source model does not establish a complete user-facing proxy-management product.

## Proxy burn lifecycle to preserve

1. Require a proxied tab in per-tab mode.
2. Ask the pool for a replacement for the existing session slot; leave the current tab intact if unavailable.
3. Capture `currentURL`, which prefers a failed destination when a native error page is visible.
4. Create a new data store with the new proxy and update the tab's credential.
5. Replace the WKWebView and rebind the retained navigation delegate/KVO.
6. Set `pendingURL` and change `webViewID` so SwiftUI recreates the container.
7. Attach the replacement to its window, assign the UI delegate, then defer the load by a run-loop tick.

Changing only credentials or reloading the old web view is not equivalent to this operation. Validate visible rendering without requiring a tab switch.

## Navigation behavior to preserve

Native navigation failure state lives on `TabModel`; the committed page remains underneath, with media suspended. Reload retries the failing URL; Back can dismiss the error and reveal committed content; Forward is disabled while the error is shown. Tab title/favicon/currentURL reflect the visible error state. Review delegate cancellation and provisional navigation tracking before changing this behavior.

Popups normally route to a new tab. SeatGeek checkout URLs have a same-tab exception in the navigation and UI delegates. Verify both paths when changing popup behavior.

## Focused manual checks

Use only authorized test accounts and proxy pools. Check local/proxied launch, unavailable pools, cookie/login separation, new/popup/duplicate/reopened tabs, session cap, slot release after close/window teardown, navigation errors with back/retry, and burn with actual visible rendering and changed egress IP. Confirm any relevant per-window behavior separately. A successful IP-check page alone does not prove absence of leaks across every WebKit request type.
