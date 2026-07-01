# Contributing to BrowserJet

Welcome to the BrowserJet project!

This guide documents the branching strategy, Git workflow, pull request conventions, release process, and macOS distribution steps used throughout the project.

---

# Table of Contents

- [Branch Strategy](#branch-strategy)
- [Branch Naming](#branch-naming)
- [Feature Workflow](#feature-workflow)
- [Chore Workflow](#chore-workflow)
- [Development Fix Workflow](#development-fix-workflow)
- [Production Hotfix Workflow](#production-hotfix-workflow)
- [Release Workflow](#release-workflow)
- [Versioning](#versioning)
- [Protected Branch Rules](#protected-branch-rules)
- [Keeping Branches in Sync](#keeping-branches-in-sync)
- [Pull Request Guidelines](#pull-request-guidelines)
- [macOS Release Process](#macos-release-process)
- [Release Checklist](#release-checklist)
- [Golden Rules](#golden-rules)

---

# Branch Strategy

BrowserJet follows a simplified Git Flow workflow.

## `main`

The `main` branch always contains the latest stable production release.

Only the following branches may be merged into `main`:

- `release/*`
- `hotfix/*`

No feature development should occur directly on `main`.

---

## `develop`

The `develop` branch contains the latest development work for the next release.

All ongoing work should start from `develop`.

---

# Branch Naming

| Purpose | Branch |
|----------|--------|
| Feature | `feature/<feature-name>` |
| Chore | `chore/<task-name>` |
| Development Fix | `fix/<issue-name>` |
| Production Hotfix | `hotfix/<issue-name>` |
| Release | `release/vX.Y.Z` |
| Documentation | `docs/<document-name>` |
| Sync `main` → `develop` | `sync/main-to-develop` |

Examples:

```text
feature/launcher-menu
feature/remote-config

fix/browser-crash

chore/update-sparkle

hotfix/fix-forced-update-ui

release/v4.1.0

docs/add-contributing-guide

sync/main-to-develop
```

---

# Feature Workflow

Use for new functionality.

## Steps

1. Checkout `develop`
2. Pull latest changes
3. Create a feature branch
4. Implement the feature
5. Open PR into `develop`
6. Merge after approval

```text
develop
    ↓
feature/new-feature
    ↓
PR → develop
```

---

# Chore Workflow

Use for:

- Refactoring
- Cleanup
- Dependency updates
- Documentation
- Code improvements

## Steps

1. Checkout `develop`
2. Pull latest changes
3. Create a chore branch
4. Complete the work
5. Open PR into `develop`
6. Merge after approval

```text
develop
    ↓
chore/update-dependencies
    ↓
PR → develop
```

---

# Development Fix Workflow

Use when the bug has **not** been released to production.

## Steps

1. Checkout `develop`
2. Pull latest changes
3. Create a fix branch
4. Fix the issue
5. Open PR into `develop`
6. Merge after approval

```text
develop
    ↓
fix/tab-crash
    ↓
PR → develop
```

---

# Production Hotfix Workflow

Use when fixing an issue in the **live production application**.

## Steps

1. Checkout `main`
2. Pull latest changes
3. Create a hotfix branch
4. Apply **only** the production fix
5. Update the application version
6. Open PR into `main`
7. Merge after approval
8. Create release tag
9. Release production build
10. Open PR (`sync/main-to-develop`) to merge `main` back into `develop`

```text
main
    ↓
hotfix/fix-forced-update-ui
    ↓
PR → main
    ↓
Tag v4.0.1
    ↓
Release Production
    ↓
sync/main-to-develop → PR → develop
```

---

# Release Workflow

Use when preparing a new production release.

## Steps

1. Checkout `develop`
2. Pull latest changes
3. Create a release branch

```text
release/vX.Y.Z
```

4. Update version number
5. Perform QA testing
6. Apply release-only fixes if required
7. Open PR into `main`
8. Merge after approval
9. Create release tag
10. Publish release
11. Open PR (`sync/main-to-develop`) to merge `main` back into `develop`

```text
develop
    ↓
release/v4.1.0
    ↓
QA
    ↓
PR → main
    ↓
Tag v4.1.0
    ↓
Release
    ↓
sync/main-to-develop → PR → develop
```

---

# Versioning

BrowserJet follows Semantic Versioning.

```
MAJOR.MINOR.PATCH
```

Examples

```
4.0.0
4.0.1
4.1.0
5.0.0
```

## Major

Breaking changes or significant redesigns.

```
4.0.0 → 5.0.0
```

---

## Minor

New features.

```
4.0.0 → 4.1.0
```

---

## Patch

Bug fixes or production hotfixes.

```
4.0.0 → 4.0.1
```

---

## Build Number

Increment every App Store / production build.

Example

```
MARKETING_VERSION = 4.0.1
CURRENT_PROJECT_VERSION = 9
```

The Git tag should always match the marketing version.

```
v4.0.1
```

---

# Protected Branch Rules

Both branches are protected.

Never commit directly to:

- `main`
- `develop`

Always create a branch and open a Pull Request.

---

## Allowed Merge Targets

| Branch | Merge Into |
|----------|------------|
| feature/* | develop |
| fix/* | develop |
| chore/* | develop |
| docs/* | develop |
| hotfix/* | main |
| release/* | main |
| sync/* | develop |

---

# Keeping Branches in Sync

`main` and `develop` are both protected, so `main → develop` is never merged directly — it always goes through a `sync/main-to-develop` branch and Pull Request, same as any other change.

## After a Hotfix

After:

- merge hotfix → main
- release production
- create tag

Open a PR:

```text
sync/main-to-develop
    ↓
PR → develop
```

This ensures future releases include the production fix.

---

## After a Release

After:

```
release → main
```

Open a PR:

```text
sync/main-to-develop
    ↓
PR → develop
```

---

## Never

Do **not** merge:

```text
develop → main
```

The only way changes should reach production is through:

- Release branches
- Hotfix branches

---

# Pull Request Guidelines

## Title

Use Conventional Commit style: `type: description`.

| Type | Used for |
|------|----------|
| `feat` | `feature/*` branches |
| `fix` | `fix/*` and `hotfix/*` branches |
| `chore` | `chore/*` branches |
| `docs` | `docs/*` branches |
| `release` | `release/*` branches |

`fix` covers both development fixes and production hotfixes — the branch prefix (`fix/*` vs `hotfix/*`) is what distinguishes them, not the commit type.

Examples

```
feat: add launcher menu configuration

fix: resolve browser crash

fix: resolve forced update UI issue

chore: update Sparkle

docs: add contributing guide

release: prepare v4.1.0
```

---

## Description

Every Pull Request should follow this template.

````markdown
## Summary
Briefly describe the purpose of this PR.

### Included
* List the major changes.
* Keep items concise.
* Group related changes.

### Notes
* Mention anything reviewers should know.
* Include migration steps, release notes, deployment notes or feature flags if applicable.
````

Example

````markdown
## Summary
Resolve UI issues affecting the production release.

### Included
* Fixed the forced update dialog layout.
* Fixed UI inconsistencies in production.
* Updated version to 4.0.1 (Build 9).

### Notes
* Targets `main` as a production hotfix.
* Create release tag `v4.0.1` after merge.
* Merge `main` back into `develop` after releasing.
````

---

# macOS Release Process

## 1. Archive

Archive the application using the **Production** configuration.

Verify:

```
MARKETING_VERSION
CURRENT_PROJECT_VERSION
```

before archiving.

---

## 2. Export

Export the application using **Developer ID** distribution.

Example output

```text
Build/
└── BrowserJet.app
```

---

## 3. Create DMG

```bash
create-dmg \
  --volname "BrowserJet Installer" \
  --volicon "/path/to/BrowserJetAppIcon.icns" \
  --window-pos 200 120 \
  --window-size 820 420 \
  --icon-size 100 \
  --icon "BrowserJet.app" 220 200 \
  --hide-extension "BrowserJet.app" \
  --app-drop-link 600 200 \
  --codesign "Developer ID Application: Vozye SMC-PVT LTD (F7WH9VQS26)" \
  --notarize "browserjet-notary" \
  "/path/to/output/BrowserJet.dmg" \
  "/path/to/exported-app/"
```

---

## 4. Verify Notarization

Validate the application

```bash
spctl -a -vvv -t install "/path/to/BrowserJet.app"
```

Validate the DMG

```bash
xcrun stapler validate "/path/to/BrowserJet.dmg"
```

If necessary

```bash
xcrun stapler staple "/path/to/BrowserJet.dmg"
```

Validate again

```bash
xcrun stapler validate "/path/to/BrowserJet.dmg"
```

---

## 5. Create Release Tag

After merging into `main`, create a Git tag.

Example

```
v4.0.1
```

The tag should reference the exact commit that was released.

---

## 6. Publish the Sparkle Appcast

BrowserJet ships updates via [Sparkle](https://sparkle-project.org). Users will not receive the update until the appcast feed is published.

1. Generate the appcast item for the new DMG using Sparkle's `generate_appcast` tool (signs the update with the EdDSA private key).
2. Update `appcast.xml` with the generated item (version, build number, download URL, signature, release notes).
3. Push the updated `appcast.xml` to the `BrowserJet-Updates` feed repo (served from `https://moizulhasan97.github.io/BrowserJet-Updates/appcast.xml`, matching `SUFeedURL` in `Info.plist`).
4. Verify the feed is reachable and the new version appears in the XML.

---

## 7. Sync Branches

After releasing, open a `sync/main-to-develop` Pull Request:

```
sync/main-to-develop → PR → develop
```

---

# Release Checklist

Before publishing a release verify:

- [ ] Marketing version updated
- [ ] Build number updated
- [ ] Production configuration selected
- [ ] Archive completed successfully
- [ ] App exported successfully
- [ ] DMG generated successfully
- [ ] Gatekeeper validation passes
- [ ] DMG notarization validated
- [ ] Git tag created
- [ ] Sparkle appcast generated and signed
- [ ] Appcast published to the update feed
- [ ] Production release published
- [ ] `main` merged back into `develop`

---

# Golden Rules

- Start all new work from `develop`.
- Start production hotfixes from `main`.
- Never commit directly to `main` or `develop`.
- Never merge feature branches directly into `main`.
- Only release and hotfix branches may merge into `main`.
- Always create a Pull Request.
- Keep hotfixes focused on production issues only.
- Tag every production release.
- Publish the Sparkle appcast after every production release or hotfix.
- After every release or hotfix, merge `main` back into `develop` via a Pull Request.
- Keep Pull Requests small, focused, and easy to review.
