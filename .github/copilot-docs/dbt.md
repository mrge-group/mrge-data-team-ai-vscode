# dbt — Data Build Tool

The dbt projects are located in `data-platform-etl/dags/dbt/` and build transformation models on **Databricks** (main project) and **Redshift** (legacy projects). The projects are orchestrated via **Apache Airflow (MWAA)**.

## ⚠️ Prerequisites for Running dbt Commands

**The workspace is pre-configured to use the Poetry virtual environment at `<workspace-root>/.venv/`.**

> **Note:** `<workspace-root>` refers to the `mrge-data-team-ai-vscode/` directory (the top-level workspace folder containing `pyproject.toml`, `data-platform-etl/`, `data-platform-dagster-group/`, etc.).

### Option 1: Run from Terminal (Recommended)

**If you've activated the Poetry shell:**

```bash
# One-time: Activate the Poetry-managed virtual environment from workspace root
cd <workspace-root>
poetry shell

# Navigate to dbt project
cd data-platform-etl/dags/dbt/data_platform_dbt/

# Run dbt commands directly
dbt debug
dbt run --select my_model --target dev
dbt test
```

**If you haven't activated the Poetry shell:**

```bash
# From workspace root, run with poetry run
cd <workspace-root>
poetry run dbt run --select my_model --target dev --project-dir data-platform-etl/dags/dbt/data_platform_dbt --profiles-dir data-platform-etl/dags/dbt/data_platform_dbt
```

### Option 2: Run via Makefile (from workspace root)

The workspace provides Makefile shortcuts that automatically use the correct virtual environment:

```bash
# From workspace root
make dbt-run MODEL=my_model TARGET=dev
make dbt-test TARGET=dev
make dbt-compile TARGET=dev
```

**Key Points:**

- The workspace uses **Poetry** to manage Python dependencies, including dbt
- The workspace Python interpreter is configured to use `.venv/bin/python` by default
- All dbt projects are under the base path `data-platform-etl/dags/dbt/`
- All dbt commands must run for `data_platform_dbt` (the main dbt project directory) unless explicitly asked to run from a different dbt project
- Other dbt projects (DigiDip, Click Valuation) have separate directories documented at the end of this file

## ⚠️ Important dbt Command Rules

### Always Add a `--target` Flag

Always specify the target environment for clarity:
```bash
dbt run --select my_model --target dev    # Development
dbt run --select my_model --target prod   # Production
```

### Always Ask Before Production Commands

**Before running any mutating dbt command on production (`--target prod`), you MUST ask for confirmation:**

```bash
# These commands require confirmation when target=prod:
dbt build --target prod
dbt run --target prod
dbt snapshot --target prod
dbt seed --target prod
```

This prevents accidental overwrites or data loss in production.

## dbt Projects Overview

| Project | Path | Database | Purpose |
|---------|------|----------|---------|
| **data_platform_dbt** | `dags/dbt/data_platform_dbt/` | Databricks (Unity Catalog) | Main multi-source data warehouse |
| digidip_data_warehouse | `dags/dbt/digidip_data_warehouse/` | Redshift | DigiDip-specific warehouse (legacy) |
| click_valuation | `dags/dbt/click_valuation/` | Redshift | Click valuation models (legacy) |

**This document focuses on the main `data_platform_dbt` project.**

## Tech Stack (data_platform_dbt)

- **dbt Core:** Version 1.10.6
- **Adapter:** `dbt-databricks` (version 1.10.6+)
- **Data Warehouse:** Databricks SQL Warehouse (Unity Catalog)
- **Orchestration:** Apache Airflow (MWAA) via **astronomer-cosmos** (version 1.11.0+)
- **Package Manager:** Poetry
- **dbt Packages:** `dbt_utils` (version 1.3.0)

## Project Structure (data_platform_dbt)

```
data-platform-etl/
├── dags/
│   ├── dbt/
│   │   └── data_platform_dbt/          # Main dbt project (run all dbt commands from here)
│   │       ├── dbt_project.yml         # Project configuration
│   │       ├── profiles.yml            # Databricks connection profiles
│   │       ├── packages.yml            # dbt package dependencies (dbt_utils)
│   │       ├── models/                 # Transformation models
│   │       │   ├── staging/            # Source data → schema: staging
│   │       │   │   ├── dd/            # DigiDip staging (tag: dd)
│   │       │   │   ├── mb/            # MaxBo staging (tag: mb)
│   │       │   │   ├── one_cpa/       # OneCPA staging (tag: one_cpa)
│   │       │   │   ├── billing/       # Billing staging (tag: one_cpa)
│   │       │   │   ├── clickout/      # Clickout staging (tag: one_cpa)
│   │       │   │   ├── s24_legacy/    # Shopping24 legacy (tag: s24_legacy)
│   │       │   │   ├── sk/            # Source Knowledge (tag: sk)
│   │       │   │   ├── yk/            # YieldKit (tag: yk)
│   │       │   │   └── lookup/        # Lookup tables (tag: lookup)
│   │       │   ├── intermediate/       # Business logic (tables) → schema: business
│   │       │   │   ├── dd/
│   │       │   │   ├── mb/
│   │       │   │   ├── one_cpa/
│   │       │   │   ├── s24_legacy/
│   │       │   │   ├── sk/
│   │       │   │   └── yk/
│   │       │   ├── reporting/          # Analytics layer (tables) → schema: reporting
│   │       │   │   ├── dim_tables/    # Dimension tables (tag: dims)
│   │       │   │   ├── fact_tables/   # Fact tables (tag: facts)
│   │       │   │   │   ├── dd/
│   │       │   │   │   ├── mb/
│   │       │   │   │   ├── one_cpa/
│   │       │   │   │   ├── s24/
│   │       │   │   │   ├── s24_legacy/
│   │       │   │   │   ├── sk/
│   │       │   │   │   └── yk/
│   │       │   │   └── derived_fact_tables/  # Derived facts (tag: derived_facts)
│   │       │   │       ├── dd/
│   │       │   │       ├── mb/
│   │       │   │       ├── one_cpa/
│   │       │   │       ├── s24/
│   │       │   │       ├── s24_legacy/
│   │       │   │       ├── sk/
│   │       │   │       └── yk/
│   │       │   ├── reverse-etl/        # Reverse ETL models
│   │       │   └── macro_tests/        # Macro tests
│   │       ├── macros/                 # Custom Jinja macros
│   │       ├── analyses/               # Ad-hoc queries (not materialized)
│   │       ├── tests/                  # Data tests
│   │       └── snapshots/              # Type-2 SCDs
│   ├── load_mrge_lakehouse_dbt.py      # Airflow DAG for dbt runs
│   └── ...
├── pyproject.toml                      # Poetry dependencies
├── README.md                           # Setup instructions
└── Makefile
```

## dbt Project Configuration

### Profiles

Two profiles available in `profiles.yml`:

#### 1. `databricks-prod` (local development / production)

| Output | Catalog | Auth Method | Use Case |
|--------|---------|-------------|----------|
| **dev** (default) | `datalake_dev` | OAuth (Databricks CLI) | Local development |
| **prod** | `datalake_production` | HTTP token | Production (Airflow/CI) |

#### 2. `airflow-sp` (Airflow service principal)

Used by Airflow for orchestrated runs. Service principal authentication.

### Unity Catalog Structure

Dynamic catalog/schema based on environment:

| Environment | Catalog | Schema |
|-------------|---------|--------|
| **dev** | `datalake_dev` | `dev_<schema_prefix>` |
| **prod** | `datalake_production` | `prod_<schema_prefix>` |

Schema prefix controlled by `DBT_SCHEMA_PREFIX` environment variable.

### Materialization Strategy

| Layer | Materialization | Schema | Description |
|-------|----------------|--------|-------------|
| **staging** | Default (view) | `staging` | Raw source data, no transformations |
| **intermediate** | `table` | `business` | Business logic, joins, aggregations |
| **reporting** | `table` | `reporting` | Final dimensional model for BI |

### Tags

Models are tagged by source/domain for selective execution:

| Tag | Domain |
|-----|--------|
| `dd` | DigiDip |
| `mb` | MaxBounty |
| `one_cpa` | OneCPA (including billing, clickout) |
| `s24_legacy` | Shopping24 legacy |
| `s24` | Shopping24 (new) |
| `sk` | Source Knowledge |
| `yk` | YieldKit |
| `lookup` | Lookup/reference tables |
| `staging` | All staging models |
| `intermediate` | All intermediate models |
| `reporting` | All reporting models |
| `dims` | Dimension tables |
| `facts` | Fact tables |
| `derived_facts` | Derived fact tables |

### Variables

Important dbt variables (set via `--vars` or in `dbt_project.yml`):

| Variable | Default | Purpose |
|----------|---------|---------|
| `interval_start_date` | `null` | Start date for incremental backfills |
| `interval_end_date` | `null` | End date for incremental backfills |
| `backfill_col` | `""` | Column name for backfill filtering |
| `catalog` | Dynamic | Unity Catalog name (dev/prod) |
| `schema` | Dynamic | Schema name (dev_*/prod_*) |

## Environment Setup

### Required Environment Variables

Set these in your shell for **local development**:

```bash
# Databricks connection (required)
export HOST_NAME=dbc-3ccb0e4a-5869.cloud.databricks.com
export HTTP_PATH=/sql/1.0/warehouses/daf3d9187b0c6491

# dbt configuration (optional, defaults shown)
export DBT_TARGET=dev                    # or "prod"
export DBT_SCHEMA_PREFIX=dev             # or "prod" or custom like "dev_yourname"

# Production only (token-based auth)
export DATABRICKS_TOKEN=<your_token>     # Only needed for prod target

# Optional: For timestamping runs
export RUN_TS=$(date +%Y-%m-%dT%H:%M:%S)
```

**Apply changes:**
```bash
source ~/.zshrc  # or ~/.bashrc
```

**Verify:**
```bash
echo $HOST_NAME
echo $HTTP_PATH
```

### Authentication Setup

#### For Local Development (OAuth via Databricks CLI)

**One-time setup:**

```bash
# Install Databricks CLI if not already installed
brew tap databricks/tap
brew install databricks

# Login with OAuth (credentials stored securely)
export DATABRICKS_HOST="https://accounts.cloud.databricks.com/"
export DATABRICKS_ACCOUNT="5dd9f32d-08c0-4c94-a0cd-258361b39070"
databricks auth login --host "$DATABRICKS_HOST" --account-id "$DATABRICKS_ACCOUNT"
```

This authenticates you via browser OAuth and stores credentials locally. No need to manage tokens manually.

#### For Production (HTTP Token)

Airflow uses service principal tokens via `DATABRICKS_TOKEN` environment variable. You typically don't need this for local development.

## Running dbt Locally

### Step 1: Activate the Workspace Virtual Environment

**⚠️ CRITICAL: Before running any dbt commands, you must activate the workspace virtual environment.**

The workspace uses Poetry to manage dependencies, including dbt. You have two options:

#### Option A: Use Poetry Shell (Recommended)

```bash
# From the workspace root
cd /Users/ovedsablan/git_repos/mrge/mrge-data-team-ai-vscode
poetry shell
```

This activates the virtual environment in your current shell session. You'll see the venv name in your prompt (e.g., `(mrge-data-team-workspace-py3.11)`).

#### Option B: Activate the Virtual Environment Directly

```bash
# Navigate to workspace root first
cd <workspace-root>
source $(poetry env info --path)/bin/activate
```

**Verify activation:** Once activated, verify dbt is available:

```bash
which dbt          # Should show path to venv dbt
dbt --version      # Should show dbt 1.10.6
```

### Step 2: Navigate to the dbt Project Directory

**⚠️ IMPORTANT: All dbt commands must be run from the default dbt project directory:**

```bash
cd data-platform-etl/dags/dbt/data_platform_dbt/
```

**Do not run commands from the workspace root or any other directory.** The dbt project configuration (`dbt_project.yml`, `profiles.yml`, `models/`, etc.) is located in `data_platform_dbt/`.

### Step 3: Run dbt Commands

Now you can run any dbt command directly without the `poetry run` prefix:

**Quick Start Workflow:**
```bash
# 1. Activate venv (from workspace root)
cd <workspace-root>  # Navigate to mrge-data-team-ai-vscode/
poetry shell

# 2. Navigate to dbt project
cd data-platform-etl/dags/dbt/data_platform_dbt/

# 3. Run dbt commands normally
dbt compile --select my_model
dbt run --select my_model
```

### Common Commands

All commands below assume you've already activated the virtual environment and navigated to `data-platform-etl/dags/dbt/data_platform_dbt/`.

```bash
# Install packages (dbt_utils)
dbt deps

# Test connection and configuration
dbt debug

# Compile models without running (good for testing Jinja)
dbt compile --select <model_or_selector>

# Run all models
dbt run

# Run models by tag
dbt run --select tag:dd              # DigiDip only
dbt run --select tag:staging         # All staging
dbt run --select tag:intermediate    # All intermediate
dbt run --select tag:reporting       # All reporting
dbt run --select tag:dims            # Dimension tables only
dbt run --select tag:facts           # Fact tables only

# Run models by layer
dbt run --select staging.*
dbt run --select intermediate.*
dbt run --select reporting.*

# Run specific source
dbt run --select staging.dd.*        # DigiDip staging
dbt run --select intermediate.mb.*   # MaxBo intermediate

# Run specific model and downstream dependencies
dbt run --select my_model+

# Run specific model and upstream dependencies
dbt run --select +my_model

# Test all models
dbt test

# Test specific model
dbt test --select my_model

# Generate and serve documentation
dbt docs generate
dbt docs serve                       # Opens browser at http://localhost:8080

# Run a single model
dbt run --select my_model

# Full refresh (rebuild incremental models from scratch)
dbt run --full-refresh

# Compile and show compiled SQL for a model
dbt compile --select my_model
# Then check target/compiled/data_platform_etl/models/.../my_model.sql
```

### Backfill Pattern (Incremental Models)

For incremental models that support backfill variables:

```bash
dbt run --select my_incremental_model \
  --vars '{interval_start_date: "2024-01-01", interval_end_date: "2024-01-31", backfill_col: "transaction_date"}'
```

### Selector Syntax

- `model_name` — Run specific model
- `tag:tag_name` — Run models with tag
- `path/to/models.*` — Run all models in path
- `model_name+` — Run model + downstream
- `+model_name` — Run model + upstream
- `+model_name+` — Run model + upstream + downstream
- `@model_name` — Run model + its children (direct descendants only)

## Airflow Orchestration

dbt models are orchestrated via **Apache Airflow (MWAA)** using the **Astronomer Cosmos** library, which automatically generates Airflow tasks from dbt models/tests.

### Main DAG

**DAG file:** `dags/load_mrge_lakehouse_dbt.py`

This DAG:
- Runs dbt models on schedule
- Uses service principal authentication (`airflow-sp` profile)
- Integrates with Databricks SQL Warehouse
- Provides task-level lineage and monitoring

### Running Airflow Locally (MWAA Local)

```bash
cd data-platform-etl/

# Start local MWAA environment
./mwaa-local-env start

# Access Airflow UI at http://localhost:8080
# Username: admin
# Password: test

# Import variables (first time only)
# Admin > Variables > Import variables.json
```

### Cosmos Integration Benefits

- **Task-per-model:** Each dbt model = separate Airflow task
- **Lineage:** Visual DAG graph matches dbt model dependencies
- **Selective re-runs:** Re-run specific models without full dbt run
- **Monitoring:** Task-level logs, retries, alerting
- **Testing integration:** dbt tests run as separate Airflow tasks

## Key Conventions

- **Schema prefix:** Use `dev_<yourname>` for personal development schemas (e.g., `dev_john`). Production uses `prod_reporting`.
- **Unity Catalog:** Always specify catalog in queries: `catalog.schema.table`
- **Documentation:** Document models and columns in `schema.yml` files within each model directory
- **Macros:** Check `macros/` for existing macros before writing custom SQL
- **Tests:** Define tests in `schema.yml` (generic tests) or `tests/` (custom tests)
- **Snapshots:** Use for tracking historical changes (type-2 SCDs)
- **Reverse ETL:** Export models live in `models/reverse-etl/`

## Dependencies

From `pyproject.toml`:
- `dbt-core = "==1.10.6"` — Core dbt framework
- `dbt-databricks = "^1.10.6"` — Databricks adapter
- `astronomer-cosmos = "^1.11.0"` — Airflow-dbt integration
- `databricks-sdk = ">=0.47,<0.48.0"` — Databricks Python SDK
- `apache-airflow = "2.10.3"` — Airflow orchestration

From `packages.yml`:
- `dbt-labs/dbt_utils @ 1.3.0` — Standard dbt macros (`surrogate_key`, `star`, `pivot`, etc.)

## Configuration Highlights

From `dbt_project.yml`:

```yaml
flags:
  use_materialization_v2: true              # Use dbt's v2 materialization logic
  require_generic_test_arguments_property: true  # Enforce test argument standards
```

These flags enable modern dbt features and enforce best practices.

## Troubleshooting

**⚠️ Reminder: Activate the virtual environment first, then run all commands from `data-platform-etl/dags/dbt/data_platform_dbt/`**

### dbt Command Not Found

If you see `dbt: command not found` or `pyenv: dbt: command not found`:

1. **Check if virtual environment is activated:**
   ```bash
   which dbt          # Should show path to venv, not "dbt not found"
   dbt --version      # Should show 1.10.6
   ```

2. **If not activated, activate it:**
   ```bash
   # Navigate to workspace root first
   cd <workspace-root>  # The mrge-data-team-ai-vscode/ directory
   poetry shell

   # Then navigate to dbt project
   cd data-platform-etl/dags/dbt/data_platform_dbt/
   ```

3. **Verify Poetry environment exists:**
   ```bash
   # From workspace root
   cd <workspace-root>
   poetry env info      # Should show virtualenv path and Python version
   poetry install       # Run this if environment doesn't exist
   ```

### Connection Issues

```bash
# Make sure you're in the dbt project directory with venv activated
dbt debug
```

Check:
1. **Virtual environment is activated** (see above)
2. `HOST_NAME` and `HTTP_PATH` environment variables are set
3. Databricks CLI authentication is active (`databricks auth login`)
3. For prod target: `DATABRICKS_TOKEN` is set
4. SQL Warehouse is running (check Databricks UI)

### Authentication Expired

```bash
# Re-authenticate with Databricks CLI
databricks auth login --host "$DATABRICKS_HOST" --account-id "$DATABRICKS_ACCOUNT"
```

### Catalog/Schema Not Found

- Verify `DBT_TARGET` is set correctly (`dev` or `prod`)
- Check `DBT_SCHEMA_PREFIX` matches your intended schema
- Ensure catalog exists in Unity Catalog (Databricks UI → Data → Catalogs)
- For dev: need access to `datalake_dev` catalog
- For prod: need access to `datalake_production` catalog

### SQL Warehouse Not Available

- Check SQL Warehouse state in Databricks UI
- Verify `HTTP_PATH` points to correct warehouse
- Check warehouse auto-stop settings (may need to start manually)

### Package Installation

If `dbt deps` fails:
```bash
rm -rf dbt_packages/
dbt deps
```

### Compilation Errors

```bash
# Compile to see generated SQL
dbt compile --select problematic_model

# Check compiled output
cat target/compiled/data_platform_etl/models/.../problematic_model.sql
```

### Permission Errors

- Ensure you have SELECT grants on source tables in Unity Catalog
- Ensure you have CREATE/WRITE grants on target schemas
- Contact admin for Unity Catalog permissions

## Best Practices

1. **Always activate the virtual environment first** — Run `poetry shell` from workspace root before any dbt work
2. **Always run from the dbt project directory** — `cd data-platform-etl/dags/dbt/data_platform_dbt/` before running dbt commands
3. **Run `dbt debug` first** when troubleshooting connection issues
4. **Use tags for selective execution** during development (faster iteration)
5. **Test locally before pushing** to catch errors early
6. **Use schema prefixes** to isolate dev work: `DBT_SCHEMA_PREFIX=dev_yourname`
7. **Document models** in `schema.yml` for better collaboration
8. **Leverage `dbt_utils`** macros instead of reinventing the wheel
9. **Check compiled SQL** when debugging Jinja logic
10. **Use Unity Catalog fully-qualified names** in raw SQL: `catalog.schema.table`
11. **Keep models modular** — break complex logic into intermediate models
12. **Run tests regularly** — `dbt test` after model changes

## When to Use dbt vs. Other Tools

| Use Case | Tool |
|----------|------|
| SQL transformations on Databricks | dbt (this project) |
| Complex Python data processing | Airflow DAGs with custom operators |
| Real-time data ingestion | Streaming platform (Redpanda, Delta Live Tables) |
| CDC from source systems | Airflow DAGs with CDC logic |
| Data quality checks | Both (dbt tests + custom Airflow checks) |
| Scheduling and orchestration | Airflow (MWAA) |
| ML model training | Databricks notebooks / MLflow |
| Reverse ETL (warehouse → external systems) | dbt models in `reverse-etl/` + Airflow exports |

## Additional dbt Projects

### DigiDip Data Warehouse (Redshift)

**Path:** `dags/dbt/digidip_data_warehouse/`
**Profile:** `redshift_dd`
**Purpose:** DigiDip-specific analytics warehouse on Redshift
**Tags:** Various job-specific tags (check `dbt_project.yml`)

### Click Valuation (Redshift)

**Path:** `dags/dbt/click_valuation/`
**Profile:** `redshift_dd`
**Purpose:** Click valuation models for RTB eCPC calculations
**Tags:** `click_valuation`

Both legacy projects use Redshift and have separate profiles/configurations. Refer to their respective README files for details.
