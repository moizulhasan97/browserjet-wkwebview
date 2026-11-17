---
name: browserjet-review
description: Review BrowserJet changes for correctness, regressions, WebKit lifecycle, proxy isolation, licensing and validation gaps; use before a PR or when reviewing a diff.
---

# browserjet-review

Read CLAUDE.md, docs/PROJECT_CONTEXT.md, relevant domain references and CONTRIBUTING.md when reviewing a PR.

1. Establish the requested comparison/base and inspect Git status. Review the actual diff and surrounding implementation; if the base is unclear, state the selected scope or ask when material.
2. Trace changed paths through callers, state owners, delegates and cleanup. Prioritize concrete regressions over style preferences.
3. Check slot acquisition/release, data-store isolation, proxy failure/fallback, burn attachment/rebinding, navigation failure state, popup handling, main-actor boundaries and cancellation when affected.
4. Check license transitions, license-scoped cache invalidation, Remote Config defaults/schema compatibility, update enforcement and credential redaction when affected.
5. Inspect validation evidence; run appropriate read-only checks when practical. Distinguish missing coverage from a proven bug.
6. Report actionable findings ordered by severity, with file/line evidence, triggering conditions and impact. State uncertainty; do not present hypothetical concerns as confirmed defects. If none, say so and name unverified areas.
7. Do not modify files or submit comments to external services unless the user asked for those actions.
