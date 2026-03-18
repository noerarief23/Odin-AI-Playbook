# odin-ai-playbook

Reusable playbook for:
- GitHub Copilot repository instructions (`.github/`)
- AWS Kiro steering + settings (`.kiro/`)
- Reusable skills library (`.ai/skills/`)

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