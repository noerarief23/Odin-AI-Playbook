---
name: security-review
description: Audit code, configuration, and dependencies for security vulnerabilities using an OWASP-aligned checklist; produce prioritised findings with remediation guidance.
tags: [security, owasp, audit, vulnerabilities]
version: 1.0.0
---

# Security Review

## When to use
- Before merging a PR that touches authentication, authorisation, or data handling.
- Auditing a new service or module for security weaknesses.
- Reviewing infrastructure config (Dockerfiles, IaC, CI/CD) for hardening gaps.
- Running a periodic security sweep on an existing codebase.

## Inputs

| Parameter | Required | Description |
|---|---|---|
| `code` | ✅ | Files, diff, or service to review |
| `context` | optional | Architecture notes, threat model, or data classification |
| `focus` | optional | Specific area (e.g. `auth`, `api`, `infra`, `dependencies`) |

## Procedure

1. **Map the attack surface** — Identify all entry points: HTTP endpoints, message queue consumers, CLI args, file uploads, webhooks, and admin interfaces.
2. **Check authentication & authorisation** — Verify tokens are validated on every request, sessions expire, roles/scopes are enforced, and privilege escalation is prevented.
3. **Check input validation & injection** — Screen for SQL injection, command injection, LDAP injection, XSS (reflected, stored, DOM), SSRF, and path traversal.
4. **Check secrets management** — Ensure no credentials, API keys, or tokens are hard-coded. Confirm secrets are loaded from environment variables or a secrets manager.
5. **Check dependency vulnerabilities** — Note any known-vulnerable versions (flag for scanning with `npm audit`, `pip-audit`, `govulncheck`, or `dotnet list package --vulnerable`).
6. **Check error handling & information leakage** — Ensure stack traces, DB errors, and internal paths are not exposed to end users.
7. **Check encryption & transport security** — Confirm TLS is enforced, certificates are validated, and sensitive data at rest is encrypted.
8. **Check logging & monitoring** — Confirm security events (failed logins, permission denials) are logged without including sensitive data (passwords, tokens).
9. **Check rate limiting & DoS protection** — Verify expensive endpoints have rate limits or authentication gates.
10. **Assign severity** — Use CVSS-inspired levels: `critical`, `high`, `medium`, `low`, `informational`.
11. **Produce the report** in the format below.

## Output format

````
## Attack surface
<Bullet list of entry points identified>

## Findings

### Critical
- **[File:line]** <Vulnerability>. **Remediation**: <specific fix>.

### High
- **[File:line]** <Vulnerability>. **Remediation**: <specific fix>.

### Medium / Low / Informational
- **[File:line]** <Issue>. **Remediation**: <guidance>.

## Dependency audit command
```bash
<command to run dependency vulnerability scan>
```
````

## Common pitfalls
- Do not mark all findings as `critical`; calibrate to actual exploitability and impact.
- Security review is not a substitute for automated SAST/DAST scanning; recommend both.
- For missing auth checks, always verify at the framework/middleware level, not just at the handler level.
- When secrets are found in code, treat it as a `critical` finding and recommend immediate rotation regardless of whether the code is public.

## Examples

### Example 1 — Hard-coded secret

**Input**:
```python
AWS_SECRET_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
```

**Output**:
```
### Critical
- **config.py:14** Hard-coded AWS secret key. This credential must be considered compromised.
  **Remediation**: Remove immediately, rotate the key in AWS IAM, and load from environment variable:
  `AWS_SECRET_KEY = os.environ["AWS_SECRET_KEY"]`
```

### Example 2 — Missing authorisation check

**Input** (Express route):
```typescript
router.delete('/users/:id', async (req, res) => {
  await db.users.delete(req.params.id);
  res.sendStatus(204);
});
```

**Output**:
```
### High
- **routes/users.ts:5** No authentication or authorisation on DELETE /users/:id. Any unauthenticated caller can delete any user.
  **Remediation**: Add auth middleware and verify the caller has admin role or owns the resource:
  `router.delete('/users/:id', requireAuth, requireRole('admin'), async (req, res) => { ... })`
```
