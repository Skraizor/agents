# Development Agents

Custom development subagents for [Claude Code](https://code.claude.com/docs/en/sub-agents), [Codex](https://developers.openai.com/codex/), and [Cursor](https://cursor.com/docs/subagents). The same roster is provided in each tool's native format: Markdown for Claude Code and Cursor, and TOML for Codex.

## Install

Claude Code:

```bash
./install.sh
```

Codex:

```bash
./install-codex.sh
```

Cursor:

```bash
./install-cursor.sh
```

All installers use symlinks, so **editing an existing agent file in this repo takes effect immediately** in new sessions. Re-run the relevant installer after adding, renaming, or deleting an agent.

Claude sources live in [`agents/`](./agents) and are linked into `~/.claude/agents`. Codex sources live in [`codex-agents/`](./codex-agents) and are linked into `$CODEX_HOME/agents` (default: `~/.codex/agents`). Cursor sources live in [`cursor-agents/`](./cursor-agents) and are linked into `~/.cursor/agents`.

The `chief` is itself a subagent and must be able to launch specialists. Use a current host version and a mode that exposes subagent spawning. Cursor supports this two-level tree in version 2.5 and later when the current mode exposes the Task tool. Current Codex releases enable subagents by default.

## The roster

| Agent | Job | Touches code? |
|---|---|---|
| [chief](agents/chief.md) | Orchestrates the roster for multi-step work; returns one synthesized report | No — coordinates + verifies |
| [implementer](agents/implementer.md) | Implements a clear requirement or architecture plan within an assigned file scope | Yes |
| [code-reviewer](agents/code-reviewer.md) | Reviews diffs for bugs, edge cases, maintainability | No — reports only |
| [debugger](agents/debugger.md) | Reproduces bugs, finds root cause with evidence, applies minimal fix | Yes |
| [test-writer](agents/test-writer.md) | Writes behavior-focused tests in the project's existing framework, runs them | Yes |
| [docs-writer](agents/docs-writer.md) | READMEs, API docs, runbooks — grounded in the actual code | Docs only |
| [security-auditor](agents/security-auditor.md) | Defensive vulnerability audit with severity + remediation | No — reports only |
| [architect](agents/architect.md) | Designs features before coding: approaches, trade-offs, step-by-step plan | No — plan is the deliverable |

The read-only split is deliberate: reviewers and auditors that can't edit can't "helpfully" change the thing they're judging.

## How invocation works

Invocation differs slightly by host:

1. **Claude Code and Cursor can delegate automatically.** Their parent agents use the task, current context, and each custom agent's `description` to choose a specialist. Specific descriptions and phrases such as "use proactively" make matching more reliable.
2. **Ask Codex to delegate.** Current local Codex releases launch subagents after a direct request or an applicable `AGENTS.md` or skill instruction. A custom agent's `description` guides role selection once delegation is in scope; it does not by itself guarantee proactive delegation.
3. **Name an agent for deterministic routing:**
   > Use the **security-auditor** subagent on the upload endpoint.
   > Have the **architect** subagent plan the invoice-numbering change before we touch code.

   Cursor also supports slash invocation, such as `/debugger investigate this failing test`.

Each subagent runs in its **own context window**. Give it a self-contained brief; a huge debugging session then stays out of the main context.

## When to reach for which agent

**A normal feature, start to finish:**

```
1. architect        → only if the change has unresolved design decisions
2. implementer      → implement the agreed behavior in an explicit file scope
3. test-writer      → add contract-based coverage without changing production code
4. code-reviewer ∥ security-auditor → independent read-only review as risk warrants
5. implementer      → remediate confirmed findings, then re-run verification
6. docs-writer      → update docs after behavior is stable
```

**Something's broken:** go straight to **debugger**. Give it the exact error output and how to reproduce. It's built to reproduce first and refuse to guess.

**Before a release / after touching auth, uploads, SQL, or secrets:** run **security-auditor** over the changed area. Also worth one full pass on any project going public.

**Whole pipelines: send the chief.** For work spanning several specialties, delegate once instead of driving each stage yourself:

> Use the **chief** subagent: add CSV export to the order-system reports page — plan it, implement, test, review, and update the docs.

The chief scouts the repo, turns the request into acceptance criteria, assigns non-overlapping file ownership, runs independent read-only reviews in parallel, routes confirmed findings back for fixes, verifies the final state, updates docs last, and returns a single synthesized report.

All definitions inherit the parent model by default. This keeps the library portable across accounts and lets the host choose a suitable model/reasoning balance; pin models only after measuring a representative task suite.

Chief vs. driving agents yourself: the chief keeps your main conversation clean (one report instead of six), but you give up mid-pipeline steering. Use the chief for well-understood work you'd happily review at the end; drive agents individually when you expect to make judgment calls between stages.

**Rules of thumb**

- Use **architect** when a material design decision remains. A multi-file but already-scoped change can go directly to **implementer**.
- Give every writable agent an explicit file scope, especially when other agents or the user already have changes in the working tree.
- Use **code-reviewer** before committing anything you'd hesitate to push directly to main.
- Don't chain agents for trivial tasks — a typo fix doesn't need a plan, tests, review, and docs. The agents are leverage for meaningful work, not ceremony.

### Overlap with built-ins

Claude Code ships built-in capabilities that overlap: `/code-review` (diff review), `/security-review`, the Plan/Explore agents, and (if installed) the superpowers plugin's process skills. Cursor also includes built-in Explore, Bash, and Browser subagents. The custom agents differ in being **yours** — tune a prompt when a review misses something you care about, add stack-specific rules (e.g. .NET or Docker checks), and the change applies everywhere. Use whichever fits; they don't conflict.

## Anatomy of an agent

Claude Code agents are Markdown files with YAML frontmatter:

```markdown
---
name: kebab-case-id
description: What it does + WHEN to use it. This is what triggers
  automatic delegation — write it like a matching rule, not a slogan.
tools: Read, Grep, Glob, Bash        # omit to inherit all tools
permissionMode: plan                 # read-only exploration by default
---

The role's system prompt. A subagent does not inherit the full parent
conversation, so make the delegated task self-contained. Project instructions
and environment context may also be loaded by the host.
```

Tips learned the hard way:

- **`description` is routing metadata.** Make it a concrete matching rule with positive and negative scope. Claude Code and Cursor use it for automatic delegation; Codex uses it as role guidance when spawning.
- **Restrict permissions and tools.** Claude read-only roles use `permissionMode: plan`; Codex uses `sandbox_mode = "read-only"`; Cursor uses `readonly: true`. Tool allowlists narrow each role further. A more-permissive live parent/session override can take precedence in some hosts, so keep the prompt-level no-edit rule too.
- **Define ownership and evidence.** Writable roles need a file boundary and preservation rule; reviewers need a reproducible failure scenario and validation gaps.
- **Use a stable output contract.** This makes handoffs and final synthesis reliable.
- **Keep prompts focused.** Add a prohibition only when it prevents a concrete failure mode; duplicated or generic instructions dilute the role.

Codex agents are TOML role files:

```toml
name = "code-reviewer"
description = "What it does and when Codex should use it."
sandbox_mode = "read-only"

developer_instructions = '''
The agent's complete role prompt, process, rules, and output format.
'''
```

Codex uses `sandbox_mode = "read-only"` for reviewers, planners, and the chief, and `workspace-write` for agents that implement changes. Claude uses `permissionMode: plan` for the same read-only roles and explicitly resets writable roles to `permissionMode: default`, so a writable child does not inherit the chief's plan mode. The chief dispatches the explicitly writable `implementer` instead of relying on an inherited general-purpose role. Tool allowlists do not map one-to-one between the hosts, so each definition combines native permission enforcement with explicit role instructions.

Cursor agents are Markdown files with YAML frontmatter too, but permissions are expressed directly:

```markdown
---
name: code-reviewer
description: What it does and when Cursor should delegate to it.
model: inherit
readonly: true
---

The subagent's complete prompt.
```

Use `readonly: true` for reviewers and planners, and `readonly: false` for agents that edit code or documentation. Cursor supports project-local agents in `.cursor/agents/`; this repo installs the same definitions globally in `~/.cursor/agents/`.

## Adding a new agent

1. Create `agents/<name>.md`, `codex-agents/<name>.toml`, and `cursor-agents/<name>.md` in the native formats above.
2. Run `./install.sh`, `./install-codex.sh`, and `./install-cursor.sh`.
3. Test it explicitly in all three tools: "Use the <name> subagent to …" and iterate on the prompts until the output is right.
4. Commit all three definitions together.

Ideas for later: a `refactorer` (behavior-preserving cleanup), a `dotnet-specialist` or `docker-specialist` with stack-specific checklists, a `pr-describer` that writes PR descriptions from diffs.
