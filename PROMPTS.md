# Example agent prompts

These examples explicitly name an agent so Codex can route the task predictably. Replace bracketed placeholders with concrete repository details, constraints, and acceptance criteria.

## Whole-team workflow

Use the `chief` when a task benefits from several specialties and you want one final report instead of managing each handoff yourself.

> Use the `chief` subagent to coordinate the full specialist roster on this task: **[describe the objective]**.
>
> Acceptance criteria: **[list the required outcomes]**.
>
> Explicitly use the full roster wherever applicable: have `explorer` map the current implementation; `critical-architect` assess consequential cross-system risks; `architect` produce the implementation plan; `mechanical-worker` handle clearly bounded repetitive edits; `implementer` own production changes; `debugger` investigate any reproducible failures; `test-writer` independently review coverage and add risk-based tests; `code-reviewer` perform correctness and regression review; `security-auditor` perform a focused security review; and `docs-writer` update documentation after behavior stabilizes.
>
> Assign non-overlapping writable scopes, preserve existing workspace changes, remediate confirmed findings, and rerun relevant verification. If a role is genuinely inapplicable, mark it skipped and explain why instead of inventing work. Return one synthesized final report with changes, verification evidence, remediated findings, and remaining risks.

For a normal feature where every role is unlikely to add value, use a shorter brief and let the chief right-size the workflow:

> Use the `chief` subagent to implement **[feature]**. The acceptance criteria are **[criteria]**. Coordinate only the specialists that materially improve the result, preserve existing changes, verify the final behavior, and return one synthesized report.

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

> Use the `code-reviewer` subagent to review **[working-tree diff, branch, commit, or PR]** against **[base or acceptance criteria]**. Trace affected execution paths and report only verified introduced defects, ranked P0–P3, with concrete evidence and suggested fixes. Do not edit files.

## Conditional specialists

### Mechanical worker

> Use the `mechanical-worker` subagent to **[rename, extract, format, or repeat a defined update]** within **[explicit file scope]**. Preserve behavior, find every affected occurrence, follow the established pattern, verify no stale references remain, and stop if the task exposes a design decision.

### Security auditor

> Use the `security-auditor` subagent to audit **[change or subsystem]**. Assume **[attacker capabilities]** and focus on **[authentication, authorization, secrets, injection, uploads, dependencies, or exposure]**. Trace untrusted inputs to sensitive operations, report only verified vulnerabilities with severity and remediation, and do not edit files.

## Documentation specialist

### Docs writer

> Use the `docs-writer` subagent to update **[README, API reference, runbook, onboarding guide, or release notes]** for **[stable behavior]**. Verify every command, configuration key, default, and referenced path against the code. Edit documentation sources only and report any code/docs contradiction rather than changing product behavior.

## Critical architect

Use `critical-architect` when a decision crosses major system boundaries, has a large blast radius, or would be difficult to reverse. It should be unusual for an ordinary feature to need this role.

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
