# My Agentic Army

Custom development subagents for both [Claude Code](https://code.claude.com/docs/en/sub-agents) and [Codex](https://developers.openai.com/codex/). The same roster is provided in each tool's native format: Markdown for Claude Code and TOML for Codex.

## Install

Claude Code:

```bash
./install.sh
```

Codex:

```bash
./install-codex.sh
```

Both installers use symlinks, so **editing an existing agent file in this repo takes effect immediately** in new sessions. Re-run the relevant installer after adding, renaming, or deleting an agent.

Claude sources live in [`agents/`](./agents) and are linked into `~/.claude/agents`. Codex sources live in [`codex-agents/`](./codex-agents) and are linked into `$CODEX_HOME/agents` (default: `~/.codex/agents`), where current Codex versions auto-discover TOML role definitions.

The `chief` needs to spawn its own specialist agents. For Codex, allow one nested level in `~/.codex/config.toml`:

```toml
[agents]
max_depth = 2
```

The Codex installer checks this setting and prints a reminder, but does not rewrite your existing config.

## The roster

| Agent | Job | Touches code? |
|---|---|---|
| [chief](agents/chief.md) | Orchestrates the roster for multi-step work; returns one synthesized report | No — coordinates + verifies |
| [code-reviewer](agents/code-reviewer.md) | Reviews diffs for bugs, edge cases, maintainability | No — reports only |
| [debugger](agents/debugger.md) | Reproduces bugs, finds root cause with evidence, applies minimal fix | Yes |
| [test-writer](agents/test-writer.md) | Writes behavior-focused tests in the project's existing framework, runs them | Yes |
| [docs-writer](agents/docs-writer.md) | READMEs, API docs, runbooks — grounded in the actual code | Docs only |
| [security-auditor](agents/security-auditor.md) | Defensive vulnerability audit with severity + remediation | No — reports only |
| [architect](agents/architect.md) | Designs features before coding: approaches, trade-offs, step-by-step plan | No — plan is the deliverable |

The read-only split is deliberate: reviewers and auditors that can't edit can't "helpfully" change the thing they're judging.

## How invocation works

Two ways to use a subagent:

1. **Automatic delegation.** Claude Code and Codex read each agent's `description` and can delegate when a task matches. Saying "review my changes" or "this test is failing, find out why" can route to code-reviewer / debugger.
2. **Explicit request.** Name the agent when you want to force it:
   > Use the **security-auditor** subagent on the upload endpoint.
   > Have the **architect** subagent plan the invoice-numbering change before we touch code.

Each subagent runs in its **own context window**. Give it a self-contained brief; a huge debugging session then stays out of the main context.

## When to reach for which agent

**A normal feature, start to finish:**

```
1. architect        → "Plan how to add recurring invoices to invoice_generator"
2. (you + the main agent implement the plan in the main conversation)
3. test-writer      → "Write tests for the recurrence logic"
4. code-reviewer    → "Review my diff before I commit"
5. docs-writer      → "Update the README for the new flag"
```

**Something's broken:** go straight to **debugger**. Give it the exact error output and how to reproduce. It's built to reproduce first and refuse to guess.

**Before a release / after touching auth, uploads, SQL, or secrets:** run **security-auditor** over the changed area. Also worth one full pass on any project going public.

**Whole pipelines: send the chief.** For work spanning several specialties, delegate once instead of driving each stage yourself:

> Use the **chief** subagent: add CSV export to the order-system reports page — plan it, implement, test, review, and update the docs.

The chief scouts the repo, briefs each specialist with self-contained instructions, runs independent stages in parallel (review ∥ security ∥ docs), routes findings back for fixes, verifies with fresh test runs, and returns a single synthesized report. Claude Code requires version ≥ 2.1.172 for subagent nesting; Codex requires `agents.max_depth = 2` or greater.

On Claude Code, the chief runs on Fable and assigns Claude models per dispatch. On Codex, the role inherits your active Codex model and reasoning settings; the library does not force a model choice.

Chief vs. driving agents yourself: the chief keeps your main conversation clean (one report instead of six), but you give up mid-pipeline steering. Use the chief for well-understood work you'd happily review at the end; drive agents individually when you expect to make judgment calls between stages.

**Rules of thumb**

- Use **architect** whenever a change spans more than one module or you're choosing between approaches. Skip it for one-liners.
- Use **code-reviewer** before committing anything you'd hesitate to push directly to main.
- Don't chain agents for trivial tasks — a typo fix doesn't need a plan, tests, review, and docs. The agents are leverage for meaningful work, not ceremony.

### Overlap with built-ins

Claude Code ships built-in capabilities that overlap: `/code-review` (diff review), `/security-review`, the Plan/Explore agents, and (if installed) the superpowers plugin's process skills. The custom agents differ in being **yours** — tune a prompt when a review misses something you care about, add stack-specific rules (e.g. .NET or Docker checks), and the change applies everywhere. Use whichever fits; they don't conflict.

## Anatomy of an agent

Claude Code agents are Markdown files with YAML frontmatter:

```markdown
---
name: kebab-case-id
description: What it does + WHEN to use it. This is what triggers
  automatic delegation — write it like a matching rule, not a slogan.
tools: Read, Grep, Glob, Bash        # omit to inherit all tools
---

The system prompt. The subagent sees ONLY this + the task it's given,
so include process, rules, and output format explicitly.
```

Tips learned the hard way:

- **`description` decides auto-delegation.** Include trigger phrases ("Use PROACTIVELY after…", "Use when…"). Vague descriptions never get picked.
- **Restrict `tools` to the minimum.** Read-only agents give more honest reports.
- **Demand an output format.** Otherwise reports come back in a different shape every time.
- **Tell the agent what NOT to do** (don't pad findings, don't refactor while fixing, don't invent style rules). Prohibitions carry most of the quality.

Codex agents are TOML role files:

```toml
name = "code-reviewer"
description = "What it does and when Codex should use it."
sandbox_mode = "read-only"

developer_instructions = '''
The agent's complete role prompt, process, rules, and output format.
'''
```

Codex uses `sandbox_mode = "read-only"` for reviewers and planners that must not edit, and `workspace-write` for agents that implement changes. Tool allowlists do not map one-to-one between Claude Code and Codex, so the Codex definitions use sandbox enforcement plus explicit role instructions.

## Adding a new agent

1. Create `agents/<name>.md` and `codex-agents/<name>.toml` in the native formats above.
2. Run `./install.sh` and `./install-codex.sh`.
3. Test it explicitly in both tools: "Use the <name> subagent to …" and iterate on the prompts until the output is right.
4. Commit both definitions together.

Ideas for later: a `refactorer` (behavior-preserving cleanup), a `dotnet-specialist` or `docker-specialist` with stack-specific checklists, a `pr-describer` that writes PR descriptions from diffs.
