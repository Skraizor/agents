# My Agentic Army

Custom [Claude Code subagents](https://code.claude.com/docs/en/sub-agents) for everyday development. Sources live in this repo; `install.sh` symlinks them into `~/.claude/agents` so they're available in every project on this machine.

## Install

```bash
./install.sh
```

Re-run after adding or renaming an agent. Because the install uses symlinks, **editing an agent file in this repo takes effect immediately** — no reinstall needed (new Claude Code sessions pick it up).

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

1. **Automatic delegation.** Claude Code reads each agent's `description` and delegates when a task matches. Saying "review my changes" or "this test is failing, find out why" will usually route to code-reviewer / debugger on its own.
2. **Explicit request.** Name the agent when you want to force it:
   > Use the **security-auditor** subagent on the upload endpoint.
   > Have the **architect** subagent plan the invoice-numbering change before we touch code.

Each subagent runs in its **own context window** — it doesn't see your conversation, and you get back only its final report. That's a feature: a huge debugging session doesn't pollute your main context.

## When to reach for which agent

**A normal feature, start to finish:**

```
1. architect        → "Plan how to add recurring invoices to invoice_generator"
2. (you + Claude implement the plan in the main conversation)
3. test-writer      → "Write tests for the recurrence logic"
4. code-reviewer    → "Review my diff before I commit"
5. docs-writer      → "Update the README for the new flag"
```

**Something's broken:** go straight to **debugger**. Give it the exact error output and how to reproduce. It's built to reproduce first and refuse to guess.

**Before a release / after touching auth, uploads, SQL, or secrets:** run **security-auditor** over the changed area. Also worth one full pass on any project going public.

**Whole pipelines: send the chief.** For work spanning several specialties, delegate once instead of driving each stage yourself:

> Use the **chief** subagent: add CSV export to the order-system reports page — plan it, implement, test, review, and update the docs.

The chief scouts the repo, briefs each specialist with self-contained instructions, runs independent stages in parallel (review ∥ security ∥ docs), routes findings back for fixes, verifies with fresh test runs, and returns a single synthesized report. Requires Claude Code ≥ 2.1.172 (subagent nesting; chief spawns the others up to 5 levels deep).

Chief vs. driving agents yourself: the chief keeps your main conversation clean (one report instead of six), but you give up mid-pipeline steering. Use the chief for well-understood work you'd happily review at the end; drive agents individually when you expect to make judgment calls between stages.

**Rules of thumb**

- Use **architect** whenever a change spans more than one module or you're choosing between approaches. Skip it for one-liners.
- Use **code-reviewer** before committing anything you'd hesitate to push directly to main.
- Don't chain agents for trivial tasks — a typo fix doesn't need a plan, tests, review, and docs. The agents are leverage for meaningful work, not ceremony.

### Overlap with built-ins

Claude Code ships built-in capabilities that overlap: `/code-review` (diff review), `/security-review`, the Plan/Explore agents, and (if installed) the superpowers plugin's process skills. The custom agents differ in being **yours** — tune a prompt when a review misses something you care about, add stack-specific rules (e.g. .NET or Docker checks), and the change applies everywhere. Use whichever fits; they don't conflict.

## Anatomy of an agent

Each agent is one markdown file:

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

## Adding a new agent

1. Create `agents/<name>.md` with the frontmatter above.
2. `./install.sh`
3. Test it explicitly: "Use the <name> subagent to …" and iterate on the prompt until the output is right.
4. Commit.

Ideas for later: a `refactorer` (behavior-preserving cleanup), a `dotnet-specialist` or `docker-specialist` with stack-specific checklists, a `pr-describer` that writes PR descriptions from diffs.
