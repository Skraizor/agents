# Development Agents

Custom development agents for [Claude Code](https://code.claude.com/docs/en/sub-agents), [Codex](https://developers.openai.com/codex/), [Cursor](https://cursor.com/docs/subagents), and [OpenCode](https://opencode.ai/docs/agents/). The same roster is provided in each tool's native format: Markdown for Claude Code, Cursor, and OpenCode, and TOML for Codex.

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

OpenCode:

```bash
./install-opencode.sh
```

All installers use symlinks, so **editing an existing agent file in this repo takes effect immediately** in new sessions. Re-run the relevant installer after adding, renaming, or deleting an agent.

Claude sources live in [`agents/`](./agents) and are linked into `~/.claude/agents`. Codex sources live in [`codex-agents/`](./codex-agents) and are linked into `$CODEX_HOME/agents` (default: `~/.codex/agents`). Cursor sources live in [`cursor-agents/`](./cursor-agents) and are linked into `~/.cursor/agents`. OpenCode sources live in [`opencode-agents/`](./opencode-agents) and are linked into `~/.config/opencode/agents` (or `$XDG_CONFIG_HOME/opencode/agents`).

On Claude Code, Codex, and Cursor, the `chief` is itself a subagent and must be able to launch specialists. Use a current host version and a mode that exposes subagent spawning. Cursor supports this two-level tree in version 2.5 and later when the current mode exposes the Task tool. Current Codex releases enable subagents by default. On OpenCode, `chief` is a **primary** agent: Tab to it as the session harness, then it delegates to the specialist subagents.

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

Codex additionally includes [explorer](codex-agents/explorer.toml) for repository reconnaissance, [mechanical-worker](codex-agents/mechanical-worker.toml) for low-judgment repetitive edits, and [critical-architect](codex-agents/critical-architect.toml) for rare consequential cross-system decisions. Its [test-writer](codex-agents/test-writer.toml) also acts as an independent coverage reviewer and risk-based test designer.

For Codex, the roster is grouped by intended frequency:

- **Core delivery:** `chief`, `explorer`, `architect`, `implementer`, `debugger`, `test-writer`, `code-reviewer`
- **Conditional specialists:** `mechanical-worker`, `security-auditor`
- **Documentation specialist:** `docs-writer`
- **Rare escalation:** `critical-architect`

| Codex agent | Model | Reasoning |
|---|---|---|
| `chief` | `gpt-5.6-sol` | Medium |
| `explorer` | `gpt-5.6-terra` | Low |
| `architect` | `gpt-5.6-sol` | High |
| `implementer` | `gpt-5.6-sol` | Medium |
| `debugger` | `gpt-5.6-sol` | High |
| `test-writer` | `gpt-5.6-terra` | Medium |
| `code-reviewer` | `gpt-5.6-sol` | High |
| `mechanical-worker` | `gpt-5.6-luna` | Low |
| `security-auditor` | `gpt-5.6-sol` | High |
| `docs-writer` | `gpt-5.6-terra` | Medium |
| `critical-architect` | `gpt-6-astra` | Medium |

The read-only split is deliberate: reviewers and auditors that can't edit can't "helpfully" change the thing they're judging.

## How invocation works

See [Example agent prompts](PROMPTS.md) for copy-ready briefs covering individual specialists, critical architecture, and full-team workflows.

Invocation differs slightly by host:

1. **Claude Code and Cursor can delegate automatically.** Their parent agents use the task, current context, and each custom agent's `description` to choose a specialist. Specific descriptions and phrases such as "use proactively" make matching more reliable.
2. **Ask Codex to delegate.** Current local Codex releases launch subagents after a direct request or an applicable `AGENTS.md` or skill instruction. A custom agent's `description` guides role selection once delegation is in scope; it does not by itself guarantee proactive delegation.
3. **OpenCode uses `chief` as the primary session agent.** Tab to `chief`, then it delegates to specialist subagents from their `description`. You can also `@mention` a specialist directly, for example `@debugger investigate this failing test`.
4. **Name an agent for deterministic routing:**
   > Use the **security-auditor** subagent on the upload endpoint.
   > Have the **architect** subagent plan the invoice-numbering change before we touch code.

   Cursor also supports slash invocation, such as `/debugger investigate this failing test`.

Each subagent runs in its **own context window**. Give it a self-contained brief; a huge debugging session then stays out of the main context.

## When to reach for which agent

**A normal feature, start to finish:**

```
1. architect        → only if the change has unresolved design decisions
2. implementer      → implement the agreed behavior in an explicit file scope
3. test-writer      → independently review coverage, then add contract-based tests where authorized
4. code-reviewer ∥ security-auditor → independent read-only review as risk warrants
5. implementer      → remediate confirmed findings, then re-run verification
6. docs-writer      → update docs after behavior is stable
```

**Something's broken:** go straight to **debugger**. Give it the exact error output and how to reproduce. It's built to reproduce first and refuse to guess.

**Before a release / after touching auth, uploads, SQL, or secrets:** run **security-auditor** over the changed area. Also worth one full pass on any project going public.

**Whole pipelines: send the chief.** For work spanning several specialties, delegate once instead of driving each stage yourself:

> Use the **chief** subagent: add CSV export to the order-system reports page — plan it, implement, test, review, and update the docs.
>
> On OpenCode, Tab to **chief** and give it the same request.

The chief scouts the repo, turns the request into acceptance criteria, assigns non-overlapping file ownership, runs independent read-only reviews in parallel, routes confirmed findings back for fixes, verifies the final state, updates docs last, and returns a single synthesized report.

All Codex roles pin a model and reasoning effort. Coordination, implementation, debugging, review, security, and architecture use `gpt-5.6-sol`; exploration, test engineering, and documentation use `gpt-5.6-terra`; repetitive mechanical work uses `gpt-5.6-luna`; and rare critical architecture uses `gpt-6-astra`. Claude and Cursor definitions continue to inherit their host model by default.

Chief vs. driving agents yourself: the chief keeps your main conversation clean (one report instead of six), but you give up mid-pipeline steering. Use the chief for well-understood work you'd happily review at the end; drive agents individually when you expect to make judgment calls between stages.

**Rules of thumb**

- Use **architect** when a material design decision remains. A multi-file but already-scoped change can go directly to **implementer**.
- Give every writable agent an explicit file scope, especially when other agents or the user already have changes in the working tree.
- Use **code-reviewer** before committing anything you'd hesitate to push directly to main.
- Don't chain agents for trivial tasks — a typo fix doesn't need a plan, tests, review, and docs. The agents are leverage for meaningful work, not ceremony.

### Overlap with built-ins

Claude Code ships built-in capabilities that overlap: `/code-review` (diff review), `/security-review`, the Plan/Explore agents, and (if installed) the superpowers plugin's process skills. Cursor also includes built-in Explore, Bash, and Browser subagents. OpenCode ships built-in Build, Plan, General, Explore, and Scout agents. The custom agents differ in being **yours** — tune a prompt when a review misses something you care about, add stack-specific rules (e.g. .NET or Docker checks), and the change applies everywhere. Use whichever fits; they don't conflict.

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

- **`description` is routing metadata.** Make it a concrete matching rule with positive and negative scope. Claude Code, Cursor, and OpenCode use it for automatic delegation; Codex uses it as role guidance when spawning.
- **Restrict permissions and tools.** Claude read-only roles use `permissionMode: plan`; Codex uses `sandbox_mode = "read-only"`; Cursor uses `readonly: true`; OpenCode uses `permission` allow/ask/deny rules (`edit: deny`, `task: deny`, `git push *` denials). Tool allowlists narrow each role further. A more-permissive live parent/session override can take precedence in some hosts, so keep the prompt-level no-edit rule too.
- **Define ownership and evidence.** Writable roles need a file boundary and preservation rule; reviewers need a reproducible failure scenario and validation gaps.
- **Use a stable output contract.** This makes handoffs and final synthesis reliable.
- **Keep prompts focused.** Add a prohibition only when it prevents a concrete failure mode; duplicated or generic instructions dilute the role.

Codex agents are TOML role files:

```toml
name = "code-reviewer"
description = "What it does and when Codex should use it."
model = "gpt-5.6-sol"
model_reasoning_effort = "high"
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

OpenCode agents are Markdown files with YAML frontmatter. The filename (minus `.md`) is the agent id. `permission` uses OpenCode's current allow/ask/deny rules; `mode` is `primary` for the session harness and `subagent` for specialists:

```markdown
---
description: What it does and when OpenCode should use it.
mode: subagent
model: ollama/devstral:24b
permission:
  edit: allow
  bash:
    "*": allow
    "git push": deny
    "git push *": deny
  task: deny
---

The agent's complete role prompt.
```

Use `mode: primary` only for `chief`. Specialists stay `mode: subagent` so they cannot become a competing session harness. Prefer `permission` over the deprecated `tools` boolean map. This repo installs OpenCode definitions globally in `~/.config/opencode/agents/`; OpenCode also discovers project-local files in `.opencode/agents/`.

## OpenCode

OpenCode is intended as the main agent harness for a hybrid cloud/local setup. The behavioral prompts match the rest of the roster; the OpenCode port adds per-agent model routing and least-privilege permissions.

```
User
  │
  ▼
chief / frontier model
  │
  ├── architect / frontier
  ├── implementer / local
  ├── debugger / local
  ├── test-writer / local
  ├── docs-writer / local
  ├── code-reviewer / frontier
  └── security-auditor / frontier
```

The intent is to use **local compute** for high-volume repository reading, implementation, tests, and debugging, and **frontier models** for orchestration, architecture, review, and high-value judgment.

| Agent | Mode | Model | Edits? |
|---|---|---|---|
| [chief](opencode-agents/chief.md) | primary | `openai/gpt-5.6-sol` | No — coordinates + verifies |
| [architect](opencode-agents/architect.md) | subagent | `openai/gpt-5.6-sol` | No — plan only |
| [implementer](opencode-agents/implementer.md) | subagent | `ollama/devstral:24b` | Yes |
| [debugger](opencode-agents/debugger.md) | subagent | `ollama/devstral:24b` | Yes |
| [test-writer](opencode-agents/test-writer.md) | subagent | `ollama/devstral:24b` | Tests only |
| [docs-writer](opencode-agents/docs-writer.md) | subagent | `ollama/devstral:24b` | Docs only |
| [code-reviewer](opencode-agents/code-reviewer.md) | subagent | `openai/gpt-5.6-sol` | No — reports only |
| [security-auditor](opencode-agents/security-auditor.md) | subagent | `openai/gpt-5.6-sol` | No — reports only |

Install:

```bash
./install-opencode.sh
```

That symlinks [`opencode-agents/*.md`](./opencode-agents) into `~/.config/opencode/agents/` (or `$XDG_CONFIG_HOME/opencode/agents` if set). The installer is idempotent, will not overwrite a real (non-symlink) file, and only removes dangling symlinks that pointed back into this repository.

### Models and providers

This repo does **not** ship API keys or an `opencode.json`. Configure providers in OpenCode as you normally would:

- **Frontier model** `openai/gpt-5.6-sol` requires your usual OpenCode OpenAI (or compatible) provider configuration. Change the `model:` frontmatter if your provider exposes a different id.
- **Local model** `ollama/devstral:24b` expects [Ollama](https://ollama.com) at the normal local endpoint (`http://localhost:11434`). Pull and serve `devstral:24b` before using the local roles.

OpenCode also ships a built-in read-only `explore` subagent. This roster does not replace it; `chief` may invoke it for scouting. To run `explore` on the local model as well, pin it in your own OpenCode config rather than adding a duplicate agent here.

## Adding a new agent

1. Create `agents/<name>.md`, `codex-agents/<name>.toml`, `cursor-agents/<name>.md`, and `opencode-agents/<name>.md` in the native formats above.
2. Run `./install.sh`, `./install-codex.sh`, `./install-cursor.sh`, and `./install-opencode.sh`.
3. Test it explicitly in each tool: "Use the <name> subagent to …" (on OpenCode, Tab to `chief` or `@name`) and iterate on the prompts until the output is right.
4. Commit all four definitions together.

Ideas for later: a `refactorer` (behavior-preserving cleanup), a `dotnet-specialist` or `docker-specialist` with stack-specific checklists, a `pr-describer` that writes PR descriptions from diffs.
