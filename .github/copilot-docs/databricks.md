# Databricks Querying & Unity Catalog

Tables are managed in **Databricks Unity Catalog** and queryable via **Databricks SQL Warehouse**. All transformation models are built using **dbt** (see [dbt.md](dbt.md) for development workflow).

## Unity Catalog Structure

### Catalogs

| Environment | Catalog | Purpose |
|-------------|---------|---------|
| **Production** | `datalake_production` | Production data warehouse |
| **Development** | `datalake_dev` | Development environment for testing |

### Schemas (Layered Architecture)

All schemas are prefixed based on environment:

| Layer | Schema | Materialization | Description |
|-------|--------|----------------|-------------|
| **Staging** | `prod_staging` / `dev_staging` | Views | Raw source data from ingestion; no transformations |
| **Business** | `prod_business` / `dev_business` | Tables | Business logic, joins, aggregations (intermediate layer) |
| **Reporting** | `prod_reporting` / `dev_reporting` | Tables | Final dimensional model (facts & dimensions) for analytics/BI |

**Schema prefix** is controlled by `DBT_SCHEMA_PREFIX` environment variable (defaults to `prod` in production, `dev` in development).

### Data Sources

Models are organized by source domain/company:

| Tag | Domain | Description |
|-----|--------|-------------|
| `dd` | DigiDip | DigiDip affiliate network |
| `mb` | MaxBounty | MaxBounty affiliate network |
| `one_cpa` | OneCPA | OneCPA (includes billing, clickout) |
| `s24_legacy` | Shopping24 Legacy | Legacy Shopping24 data |
| `s24` | Shopping24 | New Shopping24 platform |
| `sk` | Source Knowledge | Source Knowledge (SoKno) |
| `yk` | YieldKit | YieldKit affiliate network |
| `lookup` | Reference Data | Lookup tables (currencies, FX rates, etc.) |

## Fully-Qualified Table Names

Always use three-part naming in queries:

```sql
<catalog>.<schema>.<table>
```

**Examples:**
- `datalake_production.prod_staging.stg_yk_clicks` — Production staging table for YieldKit clicks
- `datalake_production.prod_reporting.fact_yk_clicks` — Production reporting fact table
- `datalake_dev.dev_staging.stg_mb_summary` — Dev staging table for MaxBounty summary

## ⚠️ Finding Tables

### 1. Browse Unity Catalog via Databricks UI

**Databricks UI → Data → Catalogs**
- Navigate: `datalake_production` → schema → table
- View schema, sample data, lineage, permissions

### 2. Query Information Schema

```sql
-- List all tables in a schema
SELECT table_catalog, table_schema, table_name, table_type
FROM datalake_production.information_schema.tables
WHERE table_schema = 'prod_reporting'
ORDER BY table_name;

-- Search for tables by pattern
SELECT table_catalog, table_schema, table_name
FROM datalake_production.information_schema.tables
WHERE table_name LIKE '%clicks%'
ORDER BY table_schema, table_name;
```

### 3. Check dbt Models

All models are defined in:
```
data-platform-etl/dags/dbt/data_platform_dbt/models/
├── staging/       # Source data views
├── intermediate/  # Business logic tables
└── reporting/     # Fact and dimension tables
```

See [dbt.md](dbt.md) for the complete dbt project structure.

## Table Layers Guide

### Staging Layer (`prod_staging` / `dev_staging`)

**Materialization:** Views
**Purpose:** Raw source data with minimal transformations
**Naming:** `stg_<source>_<entity>`

**Examples:**
- `stg_yk_clicks` — YieldKit clicks from ingestion
- `stg_mb_summary` — MaxBounty summary data
- `stg_dd_transactions` — DigiDip transactions
- `stg_lookup_currencies` — Currency reference data

**When to use:**
- Initial data exploration
- Verifying source data quality
- Building new transformations

**⚠️ Note:** Staging views query the underlying raw data sources. Performance may vary.

### Intermediate Layer (`prod_business` / `dev_business`)

**Materialization:** Tables
**Purpose:** Business logic, joins, type casting, cleaning
**Naming:** `int_<source>_<entity>`

**Examples:**
- `int_yk_advertisers` — YieldKit advertiser dimension with business logic
- `int_yk_networks` — YieldKit network mappings
- `int_mb_programs` — MaxBounty program transformations

**When to use:**
- Building on cleaned/typed data
- Accessing denormalized business entities
- Complex transformations that aren't in reporting layer

**⚠️ Note:** Intermediate tables may be updated by incremental dbt runs.

### Reporting Layer (`prod_reporting` / `dev_reporting`)

**Materialization:** Tables
**Purpose:** Final dimensional model for BI/analytics
**Naming:**
- `dim_<entity>` — Dimension tables
- `fact_<source>_<entity>` — Fact tables
- `fact_<source>_<entity>_derived` — Derived fact tables

**Dimension Tables** (`dim_*`):
- `dim_advertisers` — Advertiser dimension
- `dim_publishers` — Publisher dimension
- `dim_networks` — Network dimension
- `dim_projects` — Project dimension
- `dim_date` — Date dimension (if exists)

**Fact Tables** (`fact_*`):

By source:
- **YieldKit:** `fact_yk_clicks`, `fact_yk_transactions`
- **MaxBounty:** `fact_mb_clicks_agg`, `fact_mb_transactions`
- **DigiDip:** `fact_dd_clicks`, `fact_dd_transactions`
- **OneCPA:** `fact_one_cpa_clicks`, `fact_one_cpa_transactions`
- **Shopping24:** `fact_s24_clicks`, `fact_s24_transactions`
- **Source Knowledge:** `fact_sk_clicks`, `fact_sk_transactions`

**Derived Fact Tables** (aggregated/computed from fact tables):
- Located in `reporting/derived_fact_tables/<source>/`

**When to use:**
- **Default choice for analytics and reporting**
- BI tool connections (Tableau, Looker, etc.)
- Ad-hoc analysis requiring joins across multiple sources
- Stable schemas, tested, documented

## Query Examples

### Staging Query (Exploration)

```sql
-- Check raw YieldKit clicks
SELECT *
FROM datalake_production.prod_staging.stg_yk_clicks
WHERE click_date = '2026-02-20'
LIMIT 100;
```

### Reporting Query (Analytics)

```sql
-- YieldKit clicks and revenue by advertiser
SELECT
    click_date,
    advertiser_id,
    COUNT(*) AS total_clicks,
    COUNT(transaction_id) AS total_transactions,
    SUM(adjusted_commission_eur) AS total_commission_eur,
    SUM(adjusted_mrge_profit_eur) AS total_profit_eur
FROM datalake_production.prod_reporting.fact_yk_clicks
WHERE click_date >= '2026-02-01'
  AND click_date < '2026-03-01'
GROUP BY click_date, advertiser_id
ORDER BY total_profit_eur DESC;
```

### Cross-Source Query (Multi-network)

```sql
-- Compare performance across all affiliate networks
WITH all_clicks AS (
    SELECT 'YieldKit' AS source, click_date, adjusted_commission_eur, adjusted_mrge_profit_eur
    FROM datalake_production.prod_reporting.fact_yk_clicks
    WHERE click_date >= '2026-02-01'

    UNION ALL

    SELECT 'DigiDip' AS source, click_date, adjusted_commission_eur, adjusted_mrge_profit_eur
    FROM datalake_production.prod_reporting.fact_dd_clicks
    WHERE click_date >= '2026-02-01'

    UNION ALL

    SELECT 'MaxBounty' AS source, click_date, adjusted_commission_eur, adjusted_mrge_profit_eur
    FROM datalake_production.prod_reporting.fact_mb_clicks_agg
    WHERE click_date >= '2026-02-01'
)
SELECT
    source,
    SUM(adjusted_commission_eur) AS total_commission,
    SUM(adjusted_mrge_profit_eur) AS total_profit
FROM all_clicks
GROUP BY source
ORDER BY total_profit DESC;
```

### Join with Dimensions

```sql
-- YieldKit revenue with advertiser details
SELECT
    f.click_date,
    a.advertiser_name,
    a.advertiser_vertical,
    COUNT(*) AS clicks,
    SUM(f.adjusted_commission_eur) AS commission,
    SUM(f.adjusted_mrge_profit_eur) AS profit
FROM datalake_production.prod_reporting.fact_yk_clicks f
INNER JOIN datalake_production.prod_reporting.dim_advertisers a
    ON f.advertiser_id = a.advertiser_id
WHERE f.click_date >= '2026-02-01'
GROUP BY f.click_date, a.advertiser_name, a.advertiser_vertical
ORDER BY profit DESC;
```

## ⚠️ Performance & Cost Guidelines

Databricks SQL Warehouse costs are based on **DBUs consumed** (compute time).

### Best Practices

1. **Use the reporting layer by default** — pre-aggregated, optimized, tested
2. **Filter on date columns** — most fact tables are partitioned by date
3. **Avoid `SELECT *`** — specify only needed columns
4. **Use `LIMIT` during exploration** — especially on staging views
5. **Check table statistics** — Use `DESCRIBE EXTENDED <table>` to understand size
6. **Leverage incremental models** — dbt handles incremental updates efficiently
7. **Use Delta Lake features** — Z-ordering, file compaction (managed by dbt/Airflow)

### Query Optimization

**Bad:**
```sql
-- Full scan on staging view
SELECT *
FROM datalake_production.prod_staging.stg_yk_clicks;
```

**Better:**
```sql
-- Use reporting layer with filters
SELECT click_date, advertiser_id, adjusted_mrge_profit_eur
FROM datalake_production.prod_reporting.fact_yk_clicks
WHERE click_date >= '2026-02-01'
  AND click_date < '2026-03-01'
LIMIT 1000;
```

### Checking Table Size

```sql
-- Get table details including size
DESCRIBE EXTENDED datalake_production.prod_reporting.fact_yk_clicks;

-- Count rows
SELECT COUNT(*) FROM datalake_production.prod_reporting.fact_yk_clicks;
```

## Authentication & Access

### SQL Warehouse Connection

- **Host:** `dbc-3ccb0e4a-5869.cloud.databricks.com`
- **HTTP Path:** `/sql/1.0/warehouses/daf3d9187b0c6491`
- **Authentication:** OAuth (Databricks CLI) for local development, Service Principal for Airflow

See [dbt.md](dbt.md) for authentication setup.

### Permissions

Access is controlled via **Unity Catalog grants**:
- `SELECT` on tables/views
- `CREATE` on schemas (for dbt development)
- `USAGE` on catalogs and schemas

Contact the data team admin for Unity Catalog permissions.

## SQL Editor Access

### Databricks SQL Editor

1. Navigate to **Databricks UI → SQL**
2. Select SQL Warehouse
3. Create new query
4. Set catalog: `USE CATALOG datalake_production;`
5. Set schema: `USE SCHEMA prod_reporting;`
6. Run queries

### Local Development

Use dbt to query/test models locally (see [dbt.md](dbt.md)):

```bash
# From workspace root with venv activated
cd data-platform-etl/dags/dbt/data_platform_dbt/

# Compile to see generated SQL
dbt compile --select fact_yk_clicks

# Run model and check results
dbt run --select fact_yk_clicks
dbt test --select fact_yk_clicks
```

### MCP Server for AI Assistant

The workspace includes a **Databricks MCP server** (configured in `.vscode/mcp.json`) that enables GitHub Copilot to query Unity Catalog directly.

**Prerequisites:**
1. Set environment variables in your shell profile (`~/.zshrc` or `~/.bashrc`):
   ```bash
   export HOST_NAME="dbc-3ccb0e4a-5869.cloud.databricks.com"
   export DATABRICKS_TOKEN="dapi..."  # Get from Databricks UI → Settings → Developer → Access Tokens
   ```

2. Reload shell and VS Code:
   ```bash
   exec $SHELL
   ```
   Then reload VS Code: ⌘⇧P → "Developer: Reload Window"

**Usage:**
- Ask Copilot to query tables: "What are the top advertisers by profit this month?"
- Execute SQL queries through the AI assistant
- Explore table schemas and metadata

**Note:** The same `HOST_NAME` and `DATABRICKS_TOKEN` are used for dbt development (see [dbt.md](dbt.md#environment-setup)).

## Data Lineage

View lineage in:
1. **Databricks UI** → Data → Table → Lineage tab
2. **dbt docs** → Run `dbt docs generate && dbt docs serve` locally
3. **Airflow (Cosmos)** → DAG graph shows model dependencies

## Common Patterns

### Date Filtering (Most Common)

```sql
SELECT *
FROM datalake_production.prod_reporting.fact_yk_clicks
WHERE click_date >= '2026-02-01'
  AND click_date < CURRENT_DATE()
LIMIT 100;
```

### Aggregate by Time Period

```sql
SELECT
    DATE_TRUNC('month', click_date) AS month,
    COUNT(*) AS total_clicks,
    SUM(adjusted_mrge_profit_eur) AS profit
FROM datalake_production.prod_reporting.fact_yk_clicks
WHERE click_date >= '2026-01-01'
GROUP BY DATE_TRUNC('month', click_date)
ORDER BY month;
```

### Recent Data Check

```sql
-- Check most recent data in table
SELECT MAX(click_date) AS latest_date, COUNT(*) AS row_count
FROM datalake_production.prod_reporting.fact_yk_clicks;
```

## Troubleshooting

### Table Not Found

1. Verify catalog and schema names (case-sensitive)
2. Check if you have `SELECT` permissions
3. Confirm table exists: `SHOW TABLES IN datalake_production.prod_reporting;`
4. Verify dbt model has been deployed (check Airflow DAG runs)

### Slow Queries

1. Check if filtering on date columns
2. Reduce columns in `SELECT`
3. Use `LIMIT` for exploration
4. Check table statistics: `DESCRIBE EXTENDED <table>`
5. Consider using aggregated/derived fact tables if available

### Permission Denied

1. Verify Unity Catalog grants: contact data team admin
2. Check SQL Warehouse is running
3. Confirm authentication (OAuth token not expired)

## Workflow: From Source to Analytics

```
External Source (API, CDC, Salesforce)
        ↓
Raw Data (S3, Delta)
        ↓
Ingestion Pipeline (Airbyte, Custom)
        ↓
Staging Layer (dbt views) → prod_staging.*
        ↓
Intermediate Layer (dbt tables) → prod_business.*
        ↓
Reporting Layer (dbt tables) → prod_reporting.*
        ↓
BI Tools / Analytics / Reverse ETL
```

All transformations managed by **dbt** and orchestrated by **Airflow**. See [dbt.md](dbt.md) and [airflow.md](airflow.md) for details.
