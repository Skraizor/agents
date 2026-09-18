# Example agent prompts

These examples explicitly name an agent so Codex can route the task predictably. Replace bracketed placeholders with concrete repository details, constraints, and acceptance criteria.

## Chief workflow

On OpenCode, Tab to the Sol `chief` primary agent. On Claude Code, launch `claude --agent chief` for the Sonnet chief session. On Codex or Cursor, delegate to `chief` with nested delegation available. See the [host limits](README.md#host-limits).

> Use the `chief` to implement **[outcome]**. Acceptance criteria: **[checkable criteria]**. Classify risk, delegate bounded work to the cheapest capable specialists, inspect the result and verification yourself, send a compact [review packet](REVIEW_PACKET.md) and final diff to a fresh routine reviewer, invoke `escalation-reviewer` only for a defined trigger, resolve findings, and report changed files, exact checks, skipped checks, and remaining uncertainty.

For a high-risk change or an explicit highest-quality review, the chief still runs deterministic checks and routine review before fresh escalation review (Opus in Claude, Astra in Codex/OpenCode, inherited model in Cursor). There is no need to summon every specialist for a small task.

## Core delivery agents

### Explorer

> Use the `explorer` subagent to trace how **[behavior or request]** flows through the repository. Identify entry points, callers, dependencies, tests, configuration, and the closest existing convention. Do not edit files. Return concise findings with `file:line` evidence and open questions for the implementer.

### Architect

> Use the `architect` subagent to design **[feature or change]**. Compare viable approaches only where a real decision exists, recommend the smallest codebase-consistent solution, and provide an implementation plan with exact files, verification, risks, migration, and rollback. Do not implement it.

### Implementer

> Use the `implementer` subagent to implement **[well-defined change]**. Own only **[files or module]**, preserve unrelated workspace changes, follow existing conventions, add focused coverage where appropriate, and run **[expected verification]**. Report changed files, results, and remaining risks.

### Debugger

> Use the `debugger` subagent to investigate **[error or failing test]**. Reproduce it first using **[command or steps]**, trace the root cause, add a regression test when practical, apply the smallest fix, and rerun the original reproduction plus the surrounding tests. Do not make speculative changes.

### Test writer and coverage reviewer

Review only:

> Use the `test-writer` subagent in coverage-review mode on **[diff, branch, or feature]**. Do not edit files. Map the behavioral contract to existing tests, identify concrete untested scenarios ranked by risk, design focused test cases, and run the smallest relevant existing tests. Report triggering state, expected result, and appropriate test level for each gap.

Review and add coverage:

> Use the `test-writer` subagent to review coverage for **[change]** and add the highest-value missing tests. Edit only **[test files or test directory]**, preserve unrelated changes, demonstrate that the most important test detects its target regression, and run the focused and surrounding suites.

### Code reviewer

> Use a fresh `code-reviewer` subagent to review **[final diff]** against the completed [review packet](REVIEW_PACKET.md). Include relevant source files and repository instructions. Trace affected paths; report only verified introduced defects, ranked P0–P3, with file:line evidence and suggested fixes. Do not edit files.

## Conditional specialists

### Mechanical worker

> Use the `mechanical-worker` subagent to **[rename, extract, format, or repeat a defined update]** within **[explicit file scope]**. Preserve behavior, find every affected occurrence, follow the established pattern, verify no stale references remain, and stop if the task exposes a design decision.

### Security auditor

> Use the `security-auditor` subagent to audit **[change or subsystem]**. Assume **[attacker capabilities]** and focus on **[authentication, authorization, secrets, injection, uploads, dependencies, or exposure]**. Trace untrusted inputs to sensitive operations, report only verified vulnerabilities with severity and remediation, and do not edit files.

## Documentation specialist

### Docs writer

> Use the `docs-writer` subagent to update **[README, API reference, runbook, onboarding guide, or release notes]** for **[stable behavior]**. Verify every command, configuration key, default, and referenced path against the code. Edit documentation sources only and report any code/docs contradiction rather than changing product behavior.

## Escalation review

> Use a fresh `escalation-reviewer` on **[high-risk trigger, unresolved uncertainty, disagreement, or explicit highest-quality request]**. Supply the same compact review packet, final diff, relevant sources, repository instructions, and routine findings. Return actionable findings and remaining uncertainty; do not edit.

## Critical architect

Use the Codex `critical-architect` (Sol) when a design decision crosses major system boundaries, has a large blast radius, or would be difficult to reverse. Its design work does not replace the post-implementation Astra escalation review when a trigger applies.

### Zero-downtime data migration

> Use the `critical-architect` subagent to assess migrating **[dataset or schema]** from **[current design]** to **[target design]** without downtime. Trace current readers and writers, identify compatibility and corruption risks, compare migration strategies, and recommend staged rollout, validation gates, observability, and rollback. Do not implement anything.

### Cross-service authorization redesign

> Use the `critical-architect` subagent to design **[tenant isolation or authorization change]** across **[services]**. Map trust and ownership boundaries, define security invariants, analyze partial deployment and backward compatibility, and recommend a phased design with auditability and recovery controls.

### Event-driven architecture

> Use the `critical-architect` subagent to assess replacing **[synchronous workflow]** with an event-driven design. Analyze ordering, duplication, idempotency, consistency, retries, poison messages, observability, and rollback. Compare serious alternatives and produce a decision-ready recommendation grounded in the repository.

### Foundational platform or vendor change

> Use the `critical-architect` subagent to evaluate replacing **[database, cloud service, identity provider, queue, or other foundational dependency]**. Identify coupling and operational constraints, compare migration options, quantify reversibility and vendor risk, and recommend validation experiments before any irreversible commitment.

### Multi-region resilience

> Use the `critical-architect` subagent to design multi-region resilience for **[system]** with **[RPO/RTO targets]**. Trace state ownership and failure domains, compare failover models, address consistency and split-brain risks, and provide rollout, testing, observability, and disaster-recovery procedures.

## Writing stronger briefs

Include these details whenever they matter:

- The concrete outcome and acceptance criteria
- Exact file or module ownership for writable agents
- Relevant commands, errors, logs, or reproduction steps
- Compatibility, performance, security, or migration constraints
- Existing workspace changes that must be preserved
- The required output: implementation, review findings, design, tests, or documentation
