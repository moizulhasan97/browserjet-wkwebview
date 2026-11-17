---
name: browserjet-release
description: Prepare or review BrowserJet release readiness, versions, branch targets, notarization and Sparkle appcast requirements without publishing automatically.
disable-model-invocation: true
---

# browserjet-release

Read CLAUDE.md, CONTRIBUTING.md, docs/DEVELOPMENT.md and docs/reference/LICENSING_CONFIG_UPDATES.md. Treat this as release preparation, not authorization for distribution.

1. Inspect branch/status and requested release scope. Verify the intended release/hotfix base and PR target from CONTRIBUTING.md.
2. Read current Development/Production xcconfigs, project settings, Info.plist and shared scheme. Validate marketing/build versions and Debug/Release environment mapping. Do not guess a new version when unspecified.
3. Check source/validation evidence and unresolved release blockers. Prepare a concrete checklist using the existing release checklist; mark unperformed checks honestly.
4. When explicitly requested, prepare scoped version/docs changes and a PR title/body following the repository template; include validation in Notes.
5. Identify remaining archive/export, Developer ID signing, DMG notarization, tag, signed Sparkle appcast publication and main-to-develop sync steps. Keep private keys and signing credentials out of files and logs.
6. Do not tag, push, upload, notarize, publish the appcast or release, merge, or change Remote Config unless the user explicitly requested that action. Report readiness and exact remaining steps.
