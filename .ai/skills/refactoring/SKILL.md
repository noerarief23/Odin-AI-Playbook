---
name: refactoring
description: Improve the internal structure of code — readability, modularity, duplication, and naming — without changing observable behaviour; validate each step with tests.
tags: [refactoring, clean-code, maintainability]
version: 1.0.0
---

# Refactoring

## When to use
- Code is hard to read or understand.
- Functions are too long (> 40 lines) or do more than one thing.
- Significant duplication exists across the codebase.
- Naming is unclear or misleading.
- A new feature would be easier to add after structural cleanup.

## Inputs

| Parameter | Required | Description |
|---|---|---|
| `code` | ✅ | File(s) or function(s) to refactor |
| `goal` | optional | Specific refactoring objective (e.g. `extract function`, `reduce duplication`, `rename`) |
| `tests` | optional | Existing test file(s) used to verify behaviour is preserved |

## Procedure

1. **Understand current behaviour** — Read the code; note what it does, its inputs, and its outputs.
2. **Run existing tests** — Confirm all tests pass *before* any change. If tests are missing, generate them first (use the `testing` skill).
3. **Identify refactoring targets** — List specific smells: long method, duplicate code, magic numbers, large class, data clumps, feature envy, etc.
4. **Choose refactoring type** — Pick the appropriate technique for each target:
   - *Extract Function/Method* — move a block into a named function.
   - *Rename* — give variables, functions, and classes clearer names.
   - *Inline Variable* — remove an unnecessary intermediate variable.
   - *Replace Magic Number with Named Constant*.
   - *Introduce Parameter Object* — group related parameters into a struct/object.
   - *Split Function* — break a function that does two things into two functions.
   - *Move Function* — relocate a function to the module that owns its data.
5. **Apply one refactoring at a time** — Make the smallest possible change, then verify tests pass before the next change.
6. **Preserve public API** — Do not change function signatures, exported names, or module paths unless explicitly asked.
7. **Update tests and docs** — If names changed, update all references including tests, README, and inline comments.
8. **Produce before/after diff** — Show what changed and why.

## Output format

```
## Targets identified
<Numbered list of code smells found>

## Refactored code
```diff
<before/after diff or complete refactored file>
```

## Changes explained
<Brief explanation of each change and the smell it fixes>

## Verification
<Test command to run to confirm behaviour is unchanged>
```

## Common pitfalls
- Never refactor and add a feature in the same commit/PR; keep them separate.
- If no tests exist, write them first — refactoring without tests risks silent breakage.
- Do not rename public API symbols without checking all callers across the entire repo.
- Avoid over-engineering: a simple function does not need to become a strategy pattern.

## Examples

### Example 1 — Extract Function (Python)

**Before**:
```python
def process_order(order):
    total = 0
    for item in order["items"]:
        if item["type"] == "discount":
            total -= item["amount"]
        else:
            total += item["amount"]
    tax = total * 0.1
    return total + tax
```

**After**:
```python
def _calculate_subtotal(items: list) -> float:
    return sum(-i["amount"] if i["type"] == "discount" else i["amount"] for i in items)

def process_order(order: dict) -> float:
    subtotal = _calculate_subtotal(order["items"])
    return subtotal * 1.1
```

**Explanation**: Extracted subtotal calculation into `_calculate_subtotal`; replaced magic number `0.1` with inline multiplication for clarity.

### Example 2 — Replace Magic Number (TypeScript)

**Before**:
```typescript
if (password.length < 8) throw new Error('Too short');
```

**After**:
```typescript
const MIN_PASSWORD_LENGTH = 8;
if (password.length < MIN_PASSWORD_LENGTH) throw new Error('Too short');
```
