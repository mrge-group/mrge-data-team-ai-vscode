# Athena Querying & Table Layers

Delta tables are registered in the **AWS Glue Data Catalog** and queryable via **Amazon Athena**.

## Databases / layers

- Domain: `domain_entities.<table_name>` (used for entities that skip curated)
- Curated: `curated_entities.<table_name>`
- Business: `business_entities.<table_name>`
- Reporting: `reporting_entities.<table_name>`

Practical guidance (matches the internal playbook):

- `curated_entities`: production-mirror / schema discovery; columns are stored as **STRING** and schema may auto-evolve.
- `business_entities`: controlled analytical layer; types are defined by ETL.
- `reporting_entities`: BI/reporting layer (facts & dimensions); stable schemas; default choice for most ad-hoc analytics.

## Workgroups

Athena access/cost controls are managed via **Workgroups** (permissions, scan limits, output location, encryption).

- Always verify you’re in the correct Workgroup before running expensive queries.
- If a query fails with scan-limit / timeout errors, it may be enforced at the Workgroup level.

## ⚠️ Finding the correct layer

Before writing queries, verify which database the table lives in.

1. **Check the entity YAML** (domain/curated): `de-etl-jobs/jobs/emr/data_models/domain_curated_layer/single_source_entity/<entity>.yml`
   - If `skip_curated_layer: True` → table is in `domain_entities`
   - If `skip_domain_layer: True` → table skips domain and goes to `curated_entities`
   - Otherwise → table is in `curated_entities`

2. **Check the Python job read** (`db_name=...`) when relevant:
   - `db_name="domain"` → `domain_entities`
   - `db_name="curated"` → `curated_entities`
   - `db_name="business"` → `business_entities`
   - `db_name="reporting"` → `reporting_entities`

3. **When in doubt:**

```sql
SHOW TABLES IN <database> LIKE '<pattern>';
```

Never assume a table exists in a specific database without verifying.

## Curated layer type casting

Because curated tables store columns as STRING, cast explicitly and prefer `TRY_CAST` for exploration:

```sql
SELECT
  TRY_CAST(codility_account_id AS BIGINT) AS codility_account_id
FROM curated_entities.codility_accounts
LIMIT 10;
```

## ⚠️ Cost & performance guidelines

Athena cost is primarily based on **S3 data scanned**.

- **Filter on partition columns when available**. Do not guess partitions: check `partition_cols` in the entity YAML and/or use `SHOW PARTITIONS <table>`.
- **Avoid `SELECT *`**, especially on wide fact tables.
- **Use `LIMIT`** during exploration.
- **Prefer `reporting_entities`** for joins/aggregations when it covers your use-case.
- **Avoid large-scale casting on curated tables**; switch to business/reporting layers when possible.

Example — Bad (full scan):

```sql
SELECT *
FROM curated_entities.gitlab_events;
```

Example — Better (projection + limit; add partition filters if the table is partitioned):

```sql
SELECT col1, col2
FROM curated_entities.gitlab_events
LIMIT 100;
```
