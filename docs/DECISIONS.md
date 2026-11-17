# Architecture decisions

Record new accepted decisions here, or link to a separate ADR when substantial. Include date, problem, options, chosen approach, consequences and source/validation. Do not turn inferred intent into an accepted decision.

## Established constraints

- BrowserJet's current macOS implementation uses WKWebView, SwiftUI and AppKit. CEF_M1 is reference-only, with inspection allowed only on explicit request.
- Keep implementation consistent with existing ownership and architecture; introduce abstractions when a concrete task justifies them.
- CONTRIBUTING.md defines the team's Git and distribution workflow.

These constraints come from user instructions and the current repository, not newly invented architecture decisions. See PROJECT_CONTEXT.md for observed implementation details and unresolved concerns.
