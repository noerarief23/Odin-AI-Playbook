---
name: code-review
description: Review a pull request or code diff for correctness, security, test coverage, and maintainability; produce prioritised, actionable feedback with suggested patches.
tags: [review, quality, security, testing]
version: 1.0.0
---

# Code Review

## When to use
- Reviewing a pull request before merge.
- Auditing a diff or patch supplied directly.
- Running a pre-merge checklist on your own changes.

## Inputs

| Parameter | Required | Description |
|---|---|---|
| `diff` or `files` | ✅ | The code change to review (git diff, file paths, or raw code blocks) |
| `context` | optional | PR description, ticket link, or additional background |
| `focus` | optional | Specific concern to prioritise (e.g. `security`, `performance`) |

## Procedure

1. **Summarise the change** — In 2–4 sentences describe *what* changed and *why* (infer from code + context if no description provided).
2. **Correctness check** — Verify logic, boundary conditions, off-by-one errors, null/undefined handling, and error propagation.
3. **Security check** — Screen for: injection (SQL, command, XSS), secrets/credentials in code, insecure deserialization, broken auth/authz, SSRF, path traversal, and over-permissive IAM/RBAC.
4. **Test coverage check** — Confirm new/changed behaviour has tests. Flag missing edge cases, missing error-path tests, and tests that only assert happy paths.
5. **Maintainability check** — Look for: code duplication, overly large functions, unclear naming, missing error messages, and tight coupling.
6. **Performance check** (when relevant) — N+1 queries, unbounded loops over large data sets, missing pagination, missing caching headers.
7. **Assign severity** to each finding: `must-fix`, `should-fix`, or `nice-to-have`.
8. **Write suggested patches** for any `must-fix` item where the fix is small (≤ 20 lines).
9. **Produce the review** in the output format below.

## Output format

````
## Summary
<2–4 sentence summary of the change>

## Must-fix
- [ ] **[File:line]** <Finding>. <Suggested fix or code snippet if small.>

## Should-fix
- [ ] **[File:line]** <Finding>.

## Nice-to-have
- [ ] **[File:line]** <Suggestion>.

## Suggested patches
```diff
<patch for must-fix items>
```
````

If there are no findings in a category, omit that section.

## Common pitfalls
- Do not flag style nits as `must-fix`; use `nice-to-have` for purely cosmetic issues.
- When the diff is large (> 500 lines), focus on security and correctness first; note that a full review was not possible.
- Avoid suggesting rewrites of entire files; keep suggestions incremental.
- If context is missing, ask one clarifying question before proceeding.

## Examples

### Example 1 — SQL injection

**Input** (Python diff):
```diff
+def get_user(username):
+    query = f"SELECT * FROM users WHERE name = '{username}'"
+    return db.execute(query)
```

**Output**:
```
## Summary
Adds a `get_user` helper that queries the users table by name.

## Must-fix
- [ ] **db.py:3** SQL injection: `username` is interpolated directly into the query string.
  Use a parameterised query instead: `db.execute("SELECT * FROM users WHERE name = ?", (username,))`
```

### Example 2 — Missing error handling

**Input** (TypeScript diff):
```diff
+const data = await fetch(url).then(r => r.json());
```

**Output**:
```
## Must-fix
- [ ] **api.ts:12** No error handling: if `fetch` fails or the response is non-2xx, the error is swallowed.
  Wrap in try/catch and check `response.ok` before calling `.json()`.
```
