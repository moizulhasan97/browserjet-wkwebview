---
name: browserjet-implement
description: Implement a BrowserJet feature or bug fix from a clear task or task plan; use for WKWebView, SwiftUI, AppKit and shared-service changes with focused validation.
---

# browserjet-implement

Read CLAUDE.md, the supplied task plan if present, docs/PROJECT_CONTEXT.md, docs/DEVELOPMENT.md and relevant domain references.

1. Inspect Git status, existing changes and branch. Follow CONTRIBUTING.md; never overwrite unrelated work. If Git metadata is blocked, state it and keep changes reviewable and uncommitted.
2. Confirm acceptance criteria from source and the request. For ambiguity that changes behavior, ask a focused question; do not invent requirements.
3. Trace the complete affected ownership path before editing. Preserve isolation, slot accounting, proxy/authentication, license and update contracts.
4. Make the smallest complete change within existing owners. Reuse the design system and API/service layers. Avoid unrelated cleanup and new dependencies without need.
5. Run proportional validation from docs/DEVELOPMENT.md. Add focused regression coverage when warranted; do not claim an absent test suite ran. Verify relevant native UI/WebKit flows where possible.
6. Review the diff for secrets, target membership, concurrency/lifetime mistakes and unintended behavior. Update relevant references and the task handoff.
7. Report changed behavior, checks/results and limitations. Do not push, merge, mark external tickets done or publish unless specifically requested.
