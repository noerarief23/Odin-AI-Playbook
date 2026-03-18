# example-skill

This skill demonstrates how to structure a reusable skill for Kiro or compatible AI assistants.

## What This Skill Does

Replace this section with a short description of what the skill does, when to invoke it, and what output to expect.

**Example**: "Given a Git diff, produce a conventional-commit message summarising the changes."

## Inputs

| Parameter | Type | Required | Description |
|---|---|---|---|
| `input` | string | yes | The primary input the skill operates on |
| `context` | string | no | Additional context to guide the skill |

## Output

Describe the expected output format.

**Example**:
```
feat(auth): add JWT refresh-token rotation

- Add /auth/refresh endpoint that issues a new access + refresh token pair
- Revoke the old refresh token on use (one-time use)
- Propagate REFRESH_TOKEN_SECRET through environment config
```

## Instructions

1. Read the input carefully.
2. Apply the skill's core logic (describe the steps here).
3. Return the result in the format described above.

## Examples

### Example 1

**Input**:
```
<paste sample input here>
```

**Output**:
```
<paste expected output here>
```

## Notes

- Add any edge cases, limitations, or caveats here.
- Link to related skills or documentation if applicable.
