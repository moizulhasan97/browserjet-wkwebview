---
name: browserjet-plan
description: Investigate and plan a BrowserJet feature or bug; use for ticket clarification, architecture discussion, acceptance criteria and task handoffs before implementation.
---

# browserjet-plan

Read CLAUDE.md, docs/PROJECT_CONTEXT.md and relevant domain references. Interpret the supplied task or ticket; do not assume access to external trackers.

1. Inspect Git status and affected source. Trace entry points, state owners and existing patterns; exclude CEF_M1 unless explicitly requested.
2. State the problem and current/expected behavior. Identify concrete constraints, regressions and missing requirements. Challenge a proposed approach with evidence when a better option exists.
3. Ask only material unresolved questions. Continue independent investigation while awaiting answers; do not invent product rules.
4. Propose the smallest architecture-consistent approach and validation. Include alternatives only for a meaningful tradeoff.
5. Create or update docs/tasks/<task-name>.md using docs/tasks/TEMPLATE.md. Mark unsettled assumptions and decisions explicitly.
6. Summarize the plan, affected owners, risks and next step. Do not implement application code or publish external changes during a planning request.
