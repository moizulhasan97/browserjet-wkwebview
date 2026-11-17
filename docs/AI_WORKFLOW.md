# Working with Claude on BrowserJet

## Context layers

| File | Purpose |
| --- | --- |
| `CLAUDE.md` | Short always-loaded project instructions and reference index for Claude Code |
| `AGENTS.md` | Entry point directing other coding agents to the same shared instructions |
| `docs/PROJECT_CONTEXT.md` | Verified project map and durable onboarding context |
| `docs/reference/*.md` | On-demand domain details and focused validation cases |
| `docs/DEVELOPMENT.md` | Actual build, lint and validation conventions |
| `CONTRIBUTING.md` | Existing team Git, PR and distribution workflow |
| `.claude/skills/*/SKILL.md` | Reusable procedures for planning, implementation, review and release preparation |
| `docs/tasks/<task-name>.md` | A substantial task's current plan, evidence, progress and handoff |
| `docs/DECISIONS.md` | Accepted durable architecture decisions |

This setup targets Claude Code opened at this repository. A chat project's uploaded knowledge and instruction field are a separate surface: do not assume they automatically read local files or discover these commands. When using chat without repository access, attach current relevant files and describe the task. Keep instruction-field text short and point to the supplied project instructions; avoid maintaining a second copy of every rule.

## Commands

- `/browserjet-plan <problem or ticket>`: inspect and clarify requirements, then write a task-specific plan without implementing app code.
- `/browserjet-implement <task or plan path>`: implement within current architecture, validate, and update the handoff.
- `/browserjet-review <branch, diff or scope>`: review correctness and regressions with source evidence; do not change code unless asked.
- `/browserjet-release <version or scope>`: explicitly invoked release readiness review/preparation. It does not authorize publishing.

No model, effort level, permission bypass, connector, scheduled agent, or automatic ticket selection is configured. These skills are local procedures, not a background automation. Use the tools available in your Claude environment and report missing integrations honestly.

## Starting a task

Example:

> Read CLAUDE.md and docs/PROJECT_CONTEXT.md. Use /browserjet-plan to investigate <problem>. Trace the affected code and challenge my proposed approach if there is a stronger option. Ask only material questions. Write the agreed plan and acceptance criteria to docs/tasks/<name>.md. Do not implement yet.

Then:

> /browserjet-implement docs/tasks/<name>.md

For a small clear fix, invoke implementation directly; a separate planning ceremony is unnecessary.

## Continuing in another conversation or model

Before handing off, update the task file with the exact current state, checks already run, failures and next step. In the next session:

> Read CLAUDE.md, docs/PROJECT_CONTEXT.md and docs/tasks/<name>.md. Verify the working tree and relevant source, summarize remaining work briefly, then continue.

Keep stable facts in the project references and accepted choices in DECISIONS.md. Do not store passwords, raw license keys, proxy lists or production payloads. Recheck versions/configuration against source. These files are durable context, not a claim that ChatGPT's cross-conversation memory has been updated.

## Maintaining the setup

Correct the relevant reference after architectural/behavior changes rather than duplicating it across files. Keep CLAUDE.md short. Add another skill only for a repeated task with a distinct procedure. Do not create a generic skills.md catalog or giant plan.md merely for appearances.

Official references: https://code.claude.com/docs/en/memory and https://code.claude.com/docs/en/skills (consulted 2026-11-17). Confirm command availability in your installed Claude Code version.
