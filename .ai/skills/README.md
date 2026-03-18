# Odin AI Skills Playbook

A curated library of reusable AI skills for GitHub Copilot agentic workflows and AWS Kiro, inspired by the [anthropics/skills](https://github.com/anthropics/skills) conventions and the [Open Agent Skills spec](https://openagentskills.dev).

---

## What Are Skills?

A **skill** is a self-contained, reusable instruction set that teaches an AI agent *how* to perform a specific, repeatable task. Rather than writing the same prompt every time, you drop a skill into your repo and invoke it by name.

Key properties:
- **Self-contained** — each skill lives in its own folder with a single `SKILL.md` entrypoint.
- **Composable** — skills can be chained or referenced from other skills.
- **Progressive disclosure** — a skill starts with a short `description` the agent uses to decide *whether* to invoke it, then expands to full procedure steps only when invoked.
- **Portable** — copy `.ai/skills/` into any repo; the skills work immediately.

### Progressive Disclosure Model

```
Agent sees trigger/request
    ↓
Reads skill description (frontmatter)   ← lightweight, always visible
    ↓
Decides to invoke skill
    ↓
Reads full SKILL.md procedure           ← detailed, loaded on demand
    ↓
Executes step-by-step
    ↓
Returns formatted output
```

---

## Available Skills

| Skill | Folder | Description |
|---|---|---|
| Code Review | [`code-review/`](code-review/SKILL.md) | Review PRs/diffs for correctness, security, tests, and maintainability |
| Debugging | [`debugging/`](debugging/SKILL.md) | Systematic root-cause analysis for bugs, errors, and unexpected behaviour |
| Testing | [`testing/`](testing/SKILL.md) | Design and generate test suites (unit, integration, E2E) |
| Refactoring | [`refactoring/`](refactoring/SKILL.md) | Improve code structure without changing observable behaviour |
| CI/CD Troubleshooting | [`cicd-troubleshooting/`](cicd-troubleshooting/SKILL.md) | Diagnose and fix broken CI/CD pipelines |
| Security Review | [`security-review/`](security-review/SKILL.md) | OWASP-aligned security audit of code and config |
| API Design | [`api-design/`](api-design/SKILL.md) | Design or review REST/GraphQL/gRPC APIs |
| Incident Response | [`incident-response/`](incident-response/SKILL.md) | Triage, contain, resolve, and document production incidents |
| Terraform IaC Review | [`terraform-iac-review/`](terraform-iac-review/SKILL.md) | Review Terraform modules for security, correctness, and best practices |
| Docker Container Hardening | [`docker-container-hardening/`](docker-container-hardening/SKILL.md) | Audit and harden Dockerfile and container runtime config |

---

## How to Author a Skill

### Naming conventions
- Folder name must match the `name` in YAML frontmatter.
- Use **kebab-case** (`api-design`, `cicd-troubleshooting`).
- Keep names short and action-oriented.

### Required file: `SKILL.md`

Every skill folder must contain a `SKILL.md` with YAML frontmatter at the top:

```markdown
---
name: my-skill
description: One or two sentences. Starts with a verb. Tells the agent WHEN to use this skill.
---

# My Skill

...body...
```

**Frontmatter fields:**

| Field | Required | Description |
|---|---|---|
| `name` | ✅ | Kebab-case; must match folder name |
| `description` | ✅ | 1–2 sentences; used by the agent to decide when to invoke |
| `version` | optional | Semver string e.g. `1.0.0` |
| `tags` | optional | Array of strings for discovery |

### Recommended body sections

```markdown
## When to use
(Triggers and conditions — keep brief)

## Inputs
(What the agent needs before starting)

## Procedure
(Numbered steps — the core of the skill)

## Output format
(What to return and how to structure it)

## Common pitfalls
(Mistakes to avoid)

## Examples
(1–3 concrete examples with input/output)
```

### Keep `SKILL.md` concise
- Aim for **100–300 lines** per skill.
- Use tables for structured data (inputs, output fields).
- Omit obvious steps; focus on *what is unique* about this skill.
- Prefer numbered lists for ordered steps, bullet lists for unordered items.

### Optional subfolders

```
my-skill/
  SKILL.md          ← required
  references/       ← links, checklists, external docs (Markdown)
  scripts/          ← helper scripts invoked by the skill
  assets/           ← diagrams, templates, sample files
```

---

## How to Validate a Skill

Before committing a new skill, run through this checklist manually or via CI:

1. **Frontmatter** — `name` field matches folder name exactly (kebab-case).
2. **Description** — present, starts with a verb, is ≤ 2 sentences.
3. **Procedure** — has at least 3 numbered steps.
4. **Examples** — at least 1 example with input and expected output.
5. **No secrets** — skill file contains no credentials, tokens, or real IPs.
6. **Idempotency** — following the procedure twice produces the same result.

If the repo has a validator script (`scripts/validate-skills.sh`), run it:

```bash
bash scripts/validate-skills.sh
```

No external dependencies are required for basic validation.

---

## Using Skills with GitHub Copilot Agentic Workflows

GitHub Copilot reads instructions from `.github/copilot-instructions.md`. To wire skills into agentic mode, add a reference block:

```markdown
## Skills
Skills for common engineering tasks live in `.ai/skills/`. Use the skill for
the relevant task type when one exists:
- Code review → `.ai/skills/code-review/SKILL.md`
- Debugging   → `.ai/skills/debugging/SKILL.md`
- Testing     → `.ai/skills/testing/SKILL.md`
(and so on for each skill in `.ai/skills/`)
```

You can also reference a skill explicitly in a Copilot chat prompt:

```
@workspace follow the procedure in .ai/skills/security-review/SKILL.md
and audit this file: src/auth/jwt.ts
```

---

## Using Skills with AWS Kiro Steering

Kiro reads steering documents from `.kiro/steering/`. Reference skills inside a steering document:

```markdown
---
title: Engineering Standards
inclusion: always
---

## Skills
Reusable task procedures are stored under `.ai/skills/`.
When performing a code review, follow `.ai/skills/code-review/SKILL.md`.
When debugging, follow `.ai/skills/debugging/SKILL.md`.
```

Or reference a skill inline in a Kiro prompt:

```
Follow the procedure in .ai/skills/api-design/SKILL.md
and review this OpenAPI spec: openapi.yaml
```

---

## Referencing Skills from AGENTS.md

If the repo uses an `AGENTS.md` file (per the [agents.md](https://agents.md) convention), add a skills section:

```markdown
## Skills
This repo uses AI skills stored in `.ai/skills/`. Each skill folder contains
a `SKILL.md` with frontmatter and a step-by-step procedure. Reference the
relevant skill when performing common tasks.
```

---

## Installing Skills into Another Repo

Copy the entire `.ai/skills/` folder:

```bash
cp -r /path/to/odin-ai-playbook/.ai/skills/ /path/to/target-repo/.ai/skills/
```

Or use the provided installer (from the repo root):

```bash
bash scripts/install.sh --package all --force
```

---

## References

- **anthropics/skills** — inspiration for the 1-folder-per-skill layout and `SKILL.md` frontmatter convention: <https://github.com/anthropics/skills>
- **Open Agent Skills spec** — community specification for portable AI skills: <https://openagentskills.dev>
- **agents.md** — convention for `AGENTS.md` files in repositories: <https://agents.md>
- **GitHub Copilot repository instructions** — how Copilot reads `.github/copilot-instructions.md`: <https://docs.github.com/en/copilot/customizing-copilot/adding-repository-instructions-for-github-copilot>
- **AWS Kiro steering** — how Kiro reads `.kiro/steering/*.md` files for project-level context
