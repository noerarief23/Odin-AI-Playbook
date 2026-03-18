# GitHub Copilot Repository Instructions

## General Principles

- Make **incremental edits** only; never produce duplicate backup files (`*_backup`, `*_fixed`, `*_old`, etc.).
- **Never commit secrets**, credentials, API keys, tokens, or environment-specific values — use environment variables or secret managers.
- Follow the **existing conventions** already in this repository (naming, formatting, folder layout).
- Prefer editing the existing file over creating a new one when the purpose is the same.

## Multi-Stack Guidance

### Node / TypeScript
- Use `strict` TypeScript config; avoid `any` unless unavoidable.
- Prefer `async/await` over raw Promises or callbacks.
- Use named exports; avoid default exports except for framework entry points.
- Test with Jest or Vitest; keep unit tests co-located (`*.test.ts`).

### Python
- Target Python 3.10+ unless the project specifies otherwise.
- Use type hints on all public functions and classes.
- Format with `black` and lint with `ruff`; follow PEP 8.
- Tests live in `tests/` and use `pytest`.

### Go
- Follow `gofmt` style; use `golangci-lint` for static analysis.
- Return explicit errors; do not `panic` in library code.
- Keep packages small and focused; avoid circular imports.
- Tests are in the same package with `_test.go` suffix.

### .NET (C#)
- Use nullable reference types and latest language features for the target framework.
- Follow Microsoft's naming conventions (PascalCase for types/members, camelCase for locals).
- Use `xunit` for tests; place them in a `*.Tests` project.
- Prefer dependency injection; avoid static state.

## Output Expectations

When responding to a code-change request, always provide:

1. **Plan** — a short bullet-point plan of what will change and why.
2. **Changed files** — list every file that will be created or modified.
3. **Patch / code** — the actual changes in diff or full-file form.
4. **How to test** — concrete steps (commands, test names, manual steps) to verify correctness.
