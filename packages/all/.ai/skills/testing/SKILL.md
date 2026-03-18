---
name: testing
description: Design and generate a comprehensive test suite (unit, integration, and E2E) for a given piece of code, ensuring high coverage of happy paths, error paths, and edge cases.
tags: [testing, quality, coverage, tdd]
version: 1.0.0
---

# Testing

## When to use
- Adding tests to a new feature before or after implementation.
- Improving test coverage for an under-tested module.
- Reviewing an existing test suite for gaps.
- Setting up testing infrastructure for a new service.

## Inputs

| Parameter | Required | Description |
|---|---|---|
| `code` | ✅ | Function, class, module, or service to test |
| `language` | ✅ | Runtime/language (e.g. TypeScript/Jest, Python/pytest, Go/testing, .NET/xunit) |
| `test_type` | optional | `unit`, `integration`, `e2e`, or `all` (default: `unit`) |
| `existing_tests` | optional | Current test file(s) to extend rather than replace |

## Procedure

1. **Identify public surface** — List all public functions, methods, endpoints, or components to test.
2. **Map test cases** — For each item in the surface, enumerate:
   - Happy path (valid input → expected output).
   - Error paths (invalid input, missing fields, wrong types).
   - Boundary values (empty string, zero, max int, null, very large input).
   - Concurrent/async cases (if applicable).
3. **Select test type** — Choose unit, integration, or E2E based on what is asked, defaulting to unit.
4. **Write test file** — Generate tests using the project's existing framework (detect from `package.json`, `pyproject.toml`, `go.mod`, `*.csproj`).
   - Name tests descriptively: `should <do X> when <condition>`.
   - Use `Arrange / Act / Assert` structure.
   - Mock/stub external I/O (DB, HTTP, filesystem) for unit tests.
5. **Calculate expected coverage** — Estimate branch coverage; flag any branches not covered and explain why.
6. **Add missing test utilities** — If fixtures, factories, or helpers are needed, generate them.
7. **Provide run command** — State the exact command to run the new tests.

## Output format

```
## Test plan
<Bullet list of test cases organised by function/method>

## Test file
```<language>
<complete test file or additions to existing file>
```

## Coverage estimate
<Estimated line/branch coverage and any uncovered branches>

## Run command
```bash
<command to run the tests>
```
```

## Common pitfalls
- Do not test implementation details (private methods, internal state); test observable behaviour.
- Do not write tests that always pass (tautologies like `assert result == result`).
- For async code, ensure tests await properly; do not fire-and-forget.
- Avoid shared mutable state between tests; each test should be independent.
- Integration tests should use a test database/container, never production data.

## Examples

### Example 1 — Python unit test (pytest)

**Input**: `def divide(a: float, b: float) -> float` in `math_utils.py`

**Output**:
```python
# tests/test_math_utils.py
import pytest
from math_utils import divide

def test_divide_returns_quotient():
    assert divide(10, 2) == 5.0

def test_divide_raises_on_zero_divisor():
    with pytest.raises(ZeroDivisionError):
        divide(10, 0)

def test_divide_negative_numbers():
    assert divide(-6, 2) == -3.0

def test_divide_float_inputs():
    assert divide(1, 3) == pytest.approx(0.333, rel=1e-2)
```

Run: `pytest tests/test_math_utils.py -v`

### Example 2 — TypeScript unit test (Jest)

**Input**: `async function fetchUser(id: string): Promise<User>` in `userService.ts`

**Output**:
```typescript
// src/userService.test.ts
import { fetchUser } from './userService';
import { db } from './db';

jest.mock('./db');

describe('fetchUser', () => {
  it('should return user when found', async () => {
    (db.findById as jest.Mock).mockResolvedValue({ id: '1', name: 'Alice' });
    const user = await fetchUser('1');
    expect(user).toEqual({ id: '1', name: 'Alice' });
  });

  it('should throw NotFoundError when user does not exist', async () => {
    (db.findById as jest.Mock).mockResolvedValue(null);
    await expect(fetchUser('999')).rejects.toThrow('User not found');
  });
});
```

Run: `npx jest src/userService.test.ts`
