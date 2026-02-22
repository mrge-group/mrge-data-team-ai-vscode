# Copilot Context: MRGE Data Team Workspace

## ⚠️ Non-Negotiables (Read First)

This workspace powers production data pipelines and analytics. Incorrect assumptions can cause bad data, broken pipelines, or expensive queries.

### Accuracy Rules

- **Be 100% correct or explicitly uncertain.** If something isn't verified, say so and gather evidence.
- **Never fabricate** table/column names, S3 paths, config values, function signatures, or technical behavior.
- **Never guess** how code works. Read the source first.
- **When uncertain, ask** the user for context, or request a Databricks query / specific file path.

### Shell Command Hygiene

- **Avoid HEREDOCs as much as possible. Prefer short commands; if multi-line input is needed, write to a temporary file and delete it afterwards.**

### Safety: Read-only by Default

- Default to **read-only** actions when interacting with external systems (AWS, databases, Git, CI/CD, etc.).
- If an action is **mutating/destructive** (create/update/delete, writes, submissions, deployments, force-pushes, backfills, etc.), you must stop and ask for confirmation first.
- The confirmation request must be written in **BOLD LETTERS**.

### Poetry Virtual Environment

- This workspace uses **Poetry** for Python dependency management.
- Before running dbt or other Python commands, **activate the virtual environment**:
  ```bash
  cd <workspace-root>  # Navigate to mrge-data-team-ai-vscode/
  poetry shell
  ```
- See `.github/copilot-docs/dbt.md` for detailed setup instructions.

### Evidence-First Workflow

- Before suggesting changes: **read the relevant Python/SQL/YAML** and confirm actual parameters/paths.
- For data issues: prefer **Databricks inspection** over assumptions about contents.
- For dbt models: **check the compiled SQL** (`dbt compile`) before making changes.

### Updating These Files

You may update instruction files when useful information emerges during a session, but only if:
- You get **user confirmation** before adding new content
- Additions are **already in the repo** or **explicitly confirmed by the user**
- Additions are **generic** enough to apply across use-cases

## What This Workspace Is

A **unified development workspace** for **MRGE Data Team** managing:
- **Data transformations** (dbt on Databricks)
- **Orchestration** (Apache Airflow MWAA, Dagster Cloud)
- **Infrastructure** (Terraform, Kubernetes)
- **BI pipelines** (Tableau, reporting models)

Multiple affiliate networks (YieldKit, DigiDip, MaxBounty, OneCPA, Shopping24, Source Knowledge) are processed into a unified analytics data warehouse.

## Tech Stack

- **Data Warehouse:** Databricks Unity Catalog (Delta Lake)
- **Transformations:** dbt Core 1.10.6 + dbt-databricks
- **Orchestration:** Apache Airflow (MWAA) + Dagster Cloud
- **Infrastructure:** Terraform, Kubernetes (EKS), AWS
- **BI:** Tableau
- **Streaming:** Redpanda, Airbyte
- **Version Control:** GitHub
- **Python:** 3.11.14 (managed via Poetry)

## Workspace Structure

```
mrge-data-team-ai-vscode/               # Workspace root
├── .github/                            # Workspace-level config
│   ├── copilot-instructions.md         # This file (always loaded)
│   └── copilot-docs/                   # Detailed reference docs (read on demand)
│       ├── dbt.md                      # dbt development workflow, venv setup, commands
│       ├── databricks.md               # Databricks Unity Catalog, querying, table layers
│       ├── airflow.md                  # Airflow DAGs, MWAA, orchestration
│       ├── aws-cli.md                  # AWS CLI usage, authentication
│       ├── github.md                   # GitHub workflows, PRs, repository info
│       ├── atlassian.md                # Jira + Confluence MCP usage
│       └── pull-requests.md            # PR creation & description guidelines
├── pyproject.toml                      # Poetry dependencies (workspace-wide)
├── poetry.toml                         # Poetry configuration
├── bi-airflow-dags/                    # Legacy BI Airflow DAGs
│   ├── dags/                           # DAG definitions (by domain: digidip, maxbo, s24, etc.)
│   ├── utils/                          # Shared utilities
│   └── pyproject.toml                  # Separate Poetry config
├── data-platform/                      # Platform infrastructure
│   ├── apps-dev/                       # Dev environment apps (Grafana, etc.)
│   ├── apps-prod/                      # Production apps (Airbyte, Dagster, Redpanda)
│   ├── deployment/                     # Deployment configs
│   └── doc/                            # Architecture docs
├── data-platform-dagster-group/        # Dagster orchestration
│   ├── mrge_group/                     # Main Dagster code
│   │   ├── jobs.py                     # Dagster jobs
│   │   ├── schedules.py                # Dagster schedules
│   │   └── ...
│   ├── clickhouse/                     # ClickHouse migrations
│   ├── data_platform_dbt/              # dbt project (symlink to data-platform-etl)
│   └── pyproject.toml                  # Dagster dependencies
├── data-platform-etl/                  # **Main ETL repository**
│   ├── dags/                           # Airflow DAGs
│   │   ├── dbt/
│   │   │   └── data_platform_dbt/      # **Main dbt project** (Databricks)
│   │   │       ├── dbt_project.yml     # dbt configuration
│   │   │       ├── profiles.yml        # Databricks connection
│   │   │       ├── models/             # dbt models (staging, intermediate, reporting)
│   │   │       ├── macros/             # dbt macros
│   │   │       ├── tests/              # dbt tests
│   │   │       └── snapshots/          # dbt snapshots
│   │   └── ...                         # Other Airflow DAGs
│   ├── databricks/                     # Databricks notebooks
│   ├── docker/                         # Docker configs
│   ├── plugins/                        # Airflow plugins
│   ├── requirements/                   # Python requirements
│   └── Makefile                        # Build/deploy commands
├── data-platform-infra/                # Infrastructure as Code
│   ├── aws/                            # AWS Terraform
│   ├── databricks/                     # Databricks Terraform
│   ├── clickhouse/                     # ClickHouse configs
│   └── environments/                   # Environment-specific configs
└── tests/                              # Workspace-level tests
```

### Where to Find Things

| Looking for... | Go to... |
|---|---|
| **dbt models** (staging, intermediate, reporting) | `data-platform-etl/dags/dbt/data_platform_dbt/models/` |
| **dbt configuration** | `data-platform-etl/dags/dbt/data_platform_dbt/dbt_project.yml` |
| **dbt profiles** (Databricks connection) | `data-platform-etl/dags/dbt/data_platform_dbt/profiles.yml` |
| **Airflow DAGs** (MWAA) | `data-platform-etl/dags/` |
| **Legacy BI Airflow DAGs** | `bi-airflow-dags/dags/` (organized by source: dd, mb, s24, yk, etc.) |
| **Dagster jobs** | `data-platform-dagster-group/mrge_group/jobs.py` |
| **Dagster schedules** | `data-platform-dagster-group/mrge_group/schedules.py` |
| **Databricks notebooks** | `data-platform-etl/databricks/` |
| **Infrastructure (Terraform)** | `data-platform-infra/{aws,databricks,clickhouse}/` |
| **Platform deployment configs** | `data-platform/deployment/{airbyte,dagster,mwaa,redpanda-connect}/` |
| **ClickHouse migrations** | `data-platform-dagster-group/clickhouse/migrations/` |
| **Workspace Python dependencies** | `pyproject.toml` (workspace root) |

## Data Architecture (Layered)

```
External Sources (Affiliate Networks: YieldKit, DigiDip, MaxBounty, OneCPA, S24, SoKno)
        │
        ▼
    Raw Data (S3, Delta, APIs, CDC)
        │
        ▼
    Ingestion Layer (Airbyte, Custom connectors, Redpanda)
        │
        ▼
    Staging Layer (dbt views → Databricks Unity Catalog)
        │
        ▼
    Intermediate Layer (dbt tables → Business logic, joins, type casting)
        │
        ▼
    Reporting Layer (dbt tables → Dimensional model: dim_*, fact_*)
        │
        ▼
    BI Tools (Tableau) / Reverse ETL / Analytics
```

### Layer Details

| Layer | Storage | Schema | Materialization | Description |
|-------|---------|--------|----------------|-------------|
| **Raw** | S3, Delta | N/A | Files | Raw data from ingestion pipelines (Airbyte, custom connectors) |
| **Staging** | Databricks Unity Catalog | `prod_staging` / `dev_staging` | Views | Source data with minimal transformations; built with dbt |
| **Intermediate** | Databricks Unity Catalog | `prod_business` / `dev_business` | Tables | Business logic, joins, type casting, cleaning; built with dbt |
| **Reporting** | Databricks Unity Catalog | `prod_reporting` / `dev_reporting` | Tables | Dimensional model (`dim_*`, `fact_*`) for BI/analytics; built with dbt |

**Unity Catalog Hierarchy:**
- **Catalogs:** `datalake_production` (prod), `datalake_dev` (dev)
- **Schemas:** Prefixed by environment (e.g., `prod_staging`, `dev_reporting`)
- **Tables:** Three-part naming: `catalog.schema.table`

All transformations are managed by **dbt** and orchestrated by **Airflow (MWAA)** and **Dagster Cloud**.

See `.github/copilot-docs/dbt.md` and `.github/copilot-docs/databricks.md` for detailed documentation.

## Conventions

- **dbt models:** SQL-based transformations in `data-platform-etl/dags/dbt/data_platform_dbt/models/`
- **Model naming:**
  - Staging: `stg_<source>_<entity>` (e.g., `stg_yk_clicks`)
  - Intermediate: `int_<source>_<entity>` (e.g., `int_yk_advertisers`)
  - Reporting dimensions: `dim_<entity>` (e.g., `dim_advertisers`)
  - Reporting facts: `fact_<source>_<entity>` (e.g., `fact_yk_clicks`)
- **Tags:** Models are tagged by source domain (dd, mb, one_cpa, s24, sk, yk) for selective execution
- **Schema prefix:** Controlled by `DBT_SCHEMA_PREFIX` environment variable (prod/dev)
- **Unity Catalog:** Always use three-part naming: `catalog.schema.table`
- **Materialization:**
  - Staging = `view` (default)
  - Intermediate = `table`
  - Reporting = `table`
- **Documentation:** Document models and columns in `schema.yml` files
- **Tests:** Define dbt tests in `schema.yml` or `tests/` directory
- **Incremental models:** Use dbt's incremental materialization for large fact tables

## Local Development

### dbt Development

**Prerequisites:** Activate the Poetry virtual environment first.

```bash
# From workspace root
cd <workspace-root>
poetry shell

# Navigate to dbt project
cd data-platform-etl/dags/dbt/data_platform_dbt/

# Run dbt commands
dbt debug              # Test connection
dbt compile            # Compile models
dbt run                # Run models
dbt test               # Run tests
dbt docs generate      # Generate documentation
```

See `.github/copilot-docs/dbt.md` for complete development workflow.

### Dagster Development

```bash
cd data-platform-dagster-group/
poetry install
poetry run dagster dev  # Start local Dagster UI
```

## Deployment

- **dbt models:** Deployed via Airflow DAGs (orchestrated by MWAA)
- **Dagster jobs:** Deployed to Dagster Cloud
- **Infrastructure:** Terraform managed in `data-platform-infra/`
- **Platform apps:** Kubernetes deployments in `data-platform/deployment/`

## MCP Servers

External tools are available via MCP (Model Context Protocol) servers configured in `.vscode/mcp.json`. Read the relevant doc before using each server.

**Available MCP Servers:**

| Server | Purpose | Required Setup | Documentation |
|--------|---------|----------------|---------------|
| **Atlassian** | Jira + Confluence access | Browser OAuth (auto-prompt) | `.github/copilot-docs/atlassian.md` |
| **GitHub** | Repository operations, PRs, Issues | `MRGE_GITHUB_PERSONAL_ACCESS_TOKEN` env var | `.github/copilot-docs/github.md` |
| **Databricks** | SQL queries, Unity Catalog access | `HOST_NAME` + `DATABRICKS_TOKEN` env vars | `.github/copilot-docs/databricks.md` |

**Note:** The Databricks MCP server uses the same environment variables as dbt development. If you already have dbt set up, the MCP server will work automatically after reloading VS Code.

## On-Demand Reference Docs

The following detailed docs are in `.github/copilot-docs/`. **Read them only when the task requires it** — don't load all of them for every request.

| Doc | Read when... |
|-----|-------------|
| `.github/copilot-docs/dbt.md` | Working with dbt models, running dbt commands, understanding project structure, troubleshooting |
| `.github/copilot-docs/databricks.md` | Querying Databricks, Unity Catalog structure, table layers, writing SQL queries |
| `.github/copilot-docs/airflow.md` | Working with Airflow DAGs, MWAA orchestration, checking schedules |
| `.github/copilot-docs/aws-cli.md` | Running AWS CLI commands, authentication, accessing AWS resources |
| `.github/copilot-docs/github.md` | Working with GitHub PRs, branches, issues, repository management |
| `.github/copilot-docs/atlassian.md` | Looking up Jira tickets, Confluence docs, managing tasks via Atlassian MCP |
| `.github/copilot-docs/pull-requests.md` | User asks for a PR description or wants to create a GitHub Pull Request |
