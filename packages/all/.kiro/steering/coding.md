---
title: Coding Standards
---

# Coding Standards

These standards apply to all code in this repository. Kiro should follow them when generating or modifying code.

## General Rules

- **Incremental edits only** — modify existing files in place; never create `*_backup`, `*_old`, `*_fixed` copies.
- **No secrets in code** — use environment variables, AWS Secrets Manager, or a secrets vault.
- **Self-documenting code** — prefer clear naming over comments; add comments only when the *why* is non-obvious.
- **Small, focused functions** — each function/method does one thing and fits on a screen.
- **Fail fast** — validate inputs at the boundary; return/throw early rather than nesting conditions.

## Formatting & Linting

| Stack | Formatter | Linter |
|---|---|---|
| Node / TypeScript | Prettier | ESLint (typescript-eslint) |
| Python | black | ruff |
| Go | gofmt | golangci-lint |
| .NET | `dotnet format` | Roslyn analyzers |

Always run the project's formatter and linter before submitting changes.

## Testing

- Write tests for every new function or non-trivial change.
- Keep unit tests fast (< 100 ms each); use mocks/fakes for I/O.
- Name tests descriptively: `should <do something> when <condition>`.
- Minimum coverage target: **80 %** for new code.

## Error Handling

- **Never silently swallow errors.** Log or propagate them.
- Use structured logging (JSON lines) with `level`, `message`, and relevant context fields.
- Include correlation/request IDs in log entries when processing HTTP requests.

## Security

- Sanitize and validate all external inputs (HTTP, file, environment).
- Use parameterized queries; never interpolate user data into SQL or shell commands.
- Set least-privilege IAM roles / permissions for any cloud resources.
- Rotate secrets regularly; do not hard-code expiry dates.
