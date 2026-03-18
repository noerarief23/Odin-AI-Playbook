# odin-ai-playbook

Reusable playbook for:
- GitHub Copilot repository instructions (`.github/`)
- AWS Kiro steering + settings (`.kiro/`)
- Reusable skills library (`.ai/skills/`) — inspired by [anthropics/skills](https://github.com/anthropics/skills)

## Skills library

The skills library provides 10 production-ready AI skills for common engineering tasks. Each skill lives in `.ai/skills/<name>/SKILL.md` and follows the [Open Agent Skills](https://openagentskills.dev) convention.

| Skill | Description |
|---|---|
| `code-review` | Review PRs/diffs for correctness, security, tests, and maintainability |
| `debugging` | Systematic root-cause analysis for bugs and errors |
| `testing` | Design and generate test suites (unit, integration, E2E) |
| `refactoring` | Improve code structure without changing observable behaviour |
| `cicd-troubleshooting` | Diagnose and fix broken CI/CD pipelines |
| `security-review` | OWASP-aligned security audit of code and config |
| `api-design` | Design or review REST/GraphQL/gRPC APIs |
| `incident-response` | Triage, contain, resolve, and document production incidents |
| `terraform-iac-review` | Review Terraform modules for security and best practices |
| `docker-container-hardening` | Audit and harden Dockerfiles and container runtime config |

See [`.ai/skills/README.md`](.ai/skills/README.md) for the full authoring guide, usage instructions, and references.

## Install into a target repository (recommended)

### macOS / Linux (bash)
```bash
# from your target repo root
bash /path/to/odin-ai-playbook/scripts/install.sh --package all --force
```

### Windows (PowerShell)
```powershell
# from your target repo root
powershell -ExecutionPolicy Bypass -File C:\path\to\odin-ai-playbook\scripts\install.ps1 -Package all -Force
```

## What gets installed (package=all)
- `.github/copilot-instructions.md`
- `.kiro/steering/*.md`
- `.kiro/settings/mcp.json`
- `.ai/skills/*/SKILL.md`

## Notes
- Installer defaults to overwrite when `--force` / `-Force` is set.
- If you want profiles later (backend/frontend/infra), add more folders under `packages/`.