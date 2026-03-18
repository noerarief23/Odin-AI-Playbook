---
name: debugging
description: Systematically diagnose the root cause of a bug, error, or unexpected behaviour and propose a minimal, verified fix.
tags: [debugging, root-cause, diagnosis]
version: 1.0.0
---

# Debugging

## When to use
- A test is failing and the cause is unclear.
- An exception, panic, or crash is reported in logs.
- A feature produces wrong output with no obvious cause.
- A performance regression needs diagnosis.

## Inputs

| Parameter | Required | Description |
|---|---|---|
| `symptom` | ✅ | Error message, stack trace, unexpected output, or test failure |
| `code` | ✅ | Relevant source file(s) or function(s) |
| `reproduction` | optional | Steps or command to reproduce the issue |
| `environment` | optional | Runtime version, OS, config flags |

## Procedure

1. **Restate the symptom** — Paraphrase the error/unexpected behaviour in plain language to confirm understanding.
2. **Identify the failure point** — Locate the exact line, function, or component where the failure originates (stack trace, log line, assertion).
3. **List hypotheses** — Generate 2–5 possible root causes ordered by likelihood. Consider: off-by-one, null/nil dereference, type mismatch, race condition, misconfiguration, wrong assumption about an API.
4. **Rule out hypotheses** — For each hypothesis, identify the evidence that confirms or refutes it (log output, variable value, test case). Start with the most likely.
5. **Identify root cause** — State the confirmed root cause in one sentence.
6. **Propose minimal fix** — Write the smallest code change that fixes the root cause without introducing new risks.
7. **Verify the fix** — Describe how to confirm the fix works (specific test command, log line to look for, or manual step).
8. **Identify regression test** — Suggest a test case that would have caught this bug and should be added.

## Output format

```
## Symptom
<Restatement of the error/unexpected behaviour>

## Root cause
<One-sentence description of the confirmed root cause>

## Fix
<Code snippet or diff for the minimal fix>

## Verification
<Command or step to verify the fix>

## Regression test
<Test case to add>
```

## Common pitfalls
- Do not propose a fix before confirming the root cause; guessing wastes time.
- Avoid masking errors (e.g. wrapping in try/catch without handling); fix the actual cause.
- If the stack trace points to a third-party library, check whether the bug is in *your* usage of that library before blaming the library.
- For intermittent bugs, suggest adding structured logging to capture state on next occurrence rather than guessing.

## Examples

### Example 1 — TypeError in Python

**Input**:
```
TypeError: 'NoneType' object is not subscriptable
  File "processor.py", line 42, in process
    return data["result"]["value"]
```

**Output**:
```
## Symptom
`process()` raises a TypeError when indexing `data["result"]`, meaning `data["result"]` is `None`.

## Root cause
The upstream API returns `{"result": null}` when the record is not found, but the code assumes `result` is always a dict.

## Fix
```python
result = data.get("result")
if result is None:
    return None
return result["value"]
```

## Verification
Run `pytest tests/test_processor.py -k "not_found"` — it should pass after the fix.

## Regression test
```python
def test_process_returns_none_when_result_is_null():
    assert process({"result": None}) is None
```
```

### Example 2 — Race condition (Go)

**Input**:
```
fatal error: concurrent map writes
goroutine 12 [running]: runtime.throw(...)
```

**Output**:
```
## Symptom
Concurrent goroutines writing to a shared map cause a runtime panic.

## Root cause
`cache` (a plain `map`) is accessed from multiple goroutines without synchronisation.

## Fix
Replace `map` with `sync.Map`, or protect access with a `sync.RWMutex`.

## Verification
Run the test with `-race` flag: `go test -race ./...` — the race detector should report no errors.

## Regression test
Add a test that spawns 50 goroutines concurrently reading and writing `cache` and asserts no panic.
```
