---
name: data-sql-migration-review
description: Review SQL queries, schema changes, data migrations, and rollback plans for correctness, performance, safety, and reversibility before they run in production.
tags: [database, sql, migration, schema, indexing, query-optimisation, rollback]
version: 1.0.0
---

# Data & SQL Migration Review

## When to use
- Reviewing a PR that contains new or modified SQL queries.
- Auditing a schema migration (DDL: `ALTER TABLE`, `CREATE INDEX`, `DROP COLUMN`) before production deployment.
- Validating a data migration script that transforms or moves existing data.
- Checking a new ORM model or query builder output for performance issues.
- Planning a zero-downtime migration strategy for a high-traffic table.

## Inputs

| Parameter | Required | Description |
|---|---|---|
| `sql` or `migration` | ✅ | SQL queries, migration files, or ORM model changes to review |
| `schema` | optional | Current table schema (DDL) for the tables involved |
| `context` | optional | Database engine (PostgreSQL, MySQL, SQLite, SQL Server), table sizes, expected load |
| `focus` | optional | Specific concern: `performance`, `safety`, `rollback`, `locking`, `correctness` |

## Procedure

1. **Understand the intent** — Summarise what the migration or query is trying to achieve (add column, backfill data, create index, change type, etc.).
2. **Review correctness** — Check for:
   - Correct `WHERE` clause (avoid unintentional full-table updates/deletes).
   - Correct JOIN type (INNER vs. LEFT can silently drop rows).
   - Type mismatch or implicit casting in predicates.
   - Missing `NOT NULL` constraint with no default on a non-empty table.
3. **Review performance** — Check for:
   - Missing index on columns used in `WHERE`, `JOIN ON`, `ORDER BY`, or `GROUP BY`.
   - Full table scans on large tables.
   - N+1 query patterns in ORM-generated SQL.
   - `SELECT *` where a column list should be specified.
   - Subqueries that could be replaced with JOINs or CTEs for readability and performance.
4. **Review locking and downtime risk** — Check for DDL that acquires an `ACCESS EXCLUSIVE` lock on PostgreSQL (blocks all reads and writes):
   - `ADD COLUMN` with a volatile `DEFAULT` or `NOT NULL` without a default (PostgreSQL < 11).
   - `ADD COLUMN NOT NULL` on a large table (PostgreSQL 11+ is safe for constant defaults).
   - `ALTER COLUMN TYPE` — always requires a table rewrite.
   - `CREATE INDEX` without `CONCURRENTLY`.
   - Recommend zero-downtime alternatives for each locking operation.
5. **Review rollback plan** — Every destructive migration (`DROP`, `TRUNCATE`, `DELETE`, `ALTER … DROP COLUMN`) must have a documented rollback:
   - Can the operation be reversed? (DROP is irreversible without a backup.)
   - Is there a down migration script?
   - Has a backup been taken immediately before running the migration?
6. **Review data migration safety** — For scripts that transform or move data:
   - Does it run in a transaction? (Can it be rolled back atomically?)
   - Does it handle large tables in batches to avoid long-running transactions and lock contention?
   - Does it validate row counts before and after?
   - Is it idempotent (safe to re-run)?
7. **Review indexes** — Confirm that new indexes are created `CONCURRENTLY` in PostgreSQL, that composite index column order matches query patterns, and that redundant or duplicate indexes are flagged.
8. **Review constraints** — Check that foreign keys, unique constraints, and check constraints are present where business rules require them.
9. **Assign severity** to each finding: `critical` (data loss or production outage risk), `high` (significant performance regression or locking), `medium`, `low`.
10. **Produce the report** in the output format below.

## Output format

```
## Migration summary
- **Operation type**: DDL / DML / data migration
- **Tables affected**: <list>
- **Estimated rows affected**: <n> (if determinable)
- **Database engine**: <engine + version>

## Findings

### Critical
- **[File:line or query]** <Issue>. **Remediation**: <concrete fix>.

### High
- **[File:line or query]** <Issue>. **Remediation**: <concrete fix>.

### Medium / Low
- **[File:line or query]** <Issue>. **Recommendation**: <suggestion>.

## Locking analysis
| Operation | Lock type | Estimated duration | Zero-downtime alternative |
|---|---|---|---|

## Rollback plan
- **Reversible**: yes / no / partial
- **Down migration**: <present / missing / needed>
- **Backup required before running**: yes / no
- **Rollback procedure**: <steps>

## Recommended execution plan
```sql
-- Safe migration steps in order
<steps>
```
```

## Common pitfalls
- `ALTER TABLE … ADD COLUMN … DEFAULT <non-constant>` rewrites the entire table on PostgreSQL < 11 — always check the engine version.
- `CREATE INDEX` without `CONCURRENTLY` blocks writes for the duration of the build on PostgreSQL.
- Long-running transactions during a data migration hold row locks and can cause deadlocks; always batch in chunks of 1 000–10 000 rows.
- `DELETE FROM large_table` without a `LIMIT` and `WHERE` clause will lock the table and fill the WAL/binlog.
- Dropping a column that is still referenced in application code causes a runtime error even after migration — coordinate with the deployment order (code deploy before schema drop).
- `NOT NULL` constraints added without a default on a non-empty table will fail immediately on most databases.
- Always test migrations on a production-sized data copy before applying to production.

## Examples

### Example 1 — Missing CONCURRENTLY on index creation

**Input**:
```sql
CREATE INDEX idx_orders_user_id ON orders (user_id);
```

**Output**:
```
### High
- **migration_042.sql:3** `CREATE INDEX` without `CONCURRENTLY` will acquire an `ACCESS EXCLUSIVE` lock on `orders`, blocking all reads and writes for the duration of the index build.
  On a large table this can take minutes and cause a production outage.
  **Remediation**:
  ```sql
  CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders (user_id);
  ```
  Note: `CONCURRENTLY` cannot run inside a transaction block; remove `BEGIN`/`COMMIT` wrappers if present.
```

### Example 2 — Unbatched backfill data migration

**Input**:
```sql
UPDATE orders SET status = 'legacy' WHERE created_at < '2022-01-01';
```
Table `orders` has 50 million rows.

**Output**:
```
### Critical
- **backfill.sql:1** Single `UPDATE` on 50M rows will hold row locks for an extended period, fill the transaction log, and risk a production timeout or deadlock.
  **Remediation**: Run in batches of 10 000 rows with a short sleep between batches:
  ```sql
  DO $$
  DECLARE
    updated INT;
  BEGIN
    LOOP
      UPDATE orders SET status = 'legacy'
      WHERE id IN (
        SELECT id FROM orders
        WHERE created_at < '2022-01-01' AND status IS DISTINCT FROM 'legacy'
        LIMIT 10000
      );
      GET DIAGNOSTICS updated = ROW_COUNT;
      EXIT WHEN updated = 0;
      PERFORM pg_sleep(0.1);
    END LOOP;
  END $$;
  ```
```
