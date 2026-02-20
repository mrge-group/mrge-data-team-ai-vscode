# Copilot Context: de-ai-workspace (Multi-Repo Workspace)

## ⚠️ Non-Negotiables (Read First)

This workspace powers production ETL. Incorrect assumptions can cause bad data, broken pipelines, or expensive queries.

### Accuracy Rules

- **Be 100% correct or explicitly uncertain.** If something isn't verified, say so and gather evidence.
- **Never fabricate** table/column names, S3 paths, config values, function signatures, or technical behavior.
- **Never guess** how code works. Read the source first.
- **When uncertain, ask** the user for context, or request an Athena query / specific file path.

### Shell Command Hygiene

- **Avoid HEREDOCs as much as possible. Prefer short commands; if multi-line input is needed, write to a temporary file and delete it afterwards.**

### Safety: Read-only by Default

- Default to **read-only** actions when interacting with external systems (AWS, databases, Git, CI/CD, etc.).
- If an action is **mutating/destructive** (create/update/delete, writes, submissions, deployments, force-pushes, backfills, etc.), you must stop and ask for confirmation first.
- The confirmation request must be written in **BOLD LETTERS**.

### AWS CLI & Profiles

- AWS CLI usage patterns, profile selection helpers, and reliability guidance live in `.github/copilot-docs/aws-cli.md`.

### Evidence-First Workflow

- Before suggesting changes: **read the relevant Python + YAML** and confirm actual parameters/paths.
- For data issues: prefer **Athena inspection** over assumptions about contents.
- For cost/perf: **check `partition_cols`** in the entity YAML before recommending filters. Filtering on non-partition columns does not reduce S3 scan.

### PySpark Caching Pitfall

- **`.persist()` / `.cache()` are lazy** — they only mark a DataFrame for caching; the data is not materialized until an **action** (e.g., `.count()`) is triggered.
- When using `.persist()` before passing a DataFrame to a `ThreadPool` or any concurrent processing, **always force materialization** immediately after (e.g., `df.count()`) to guarantee the data is cached before threads start. Otherwise each thread may independently recompute the full pipeline.
- Always assign the result back: `df = df.persist()` for clarity and safety.

### Updating These Files

You may update instruction files when useful information emerges during a session, but only if:
- You get **user confirmation** before adding new content
- Additions are **already in the repo** or **explicitly confirmed by the user**
- Additions are **generic** enough to apply across use-cases

## What This Repo Is

A **multi-repo workspace** for production **data engineering ETL** on **AWS EMR Serverless** (**PySpark 3.3 + Delta Lake 2.1**). Processes multiple sources (Codility monolith, Salesforce, Gainsight, etc.) via a layered architecture and produces dimensional models for analytics.

The workspace contains **linked repositories** at the root level:
- `de-etl-jobs/` — main ETL repository (EMR jobs, Delta utils, Terraform, CI/CD)
- `airflow/` — DAGs & job configs
- `codility/` — monolith source code
- `solution-similarity/` — similarity inference API + Lambda
- `infra-core/` — Terraform IaC (all Codility infrastructure, deployed via Atlantis)

## Tech Stack

- **Compute:** AWS EMR Serverless (PySpark 3.3, Delta Lake 2.1)
- **Storage:** S3 (raw JSON, Parquet, Delta tables)
- **Orchestration:** Apache Airflow (DAGs: `airflow/airflow-dags/`, job configs: `airflow/job-config/`) — in the `airflow/` repo at workspace root
- **Infrastructure:** Terraform (in `de-etl-jobs/deploy/`), Docker (EMR venvs, Glue local dev)
- **CI/CD:** GitLab CI (`de-etl-jobs/.gitlab-ci.yml`)
- **Local Dev:** AWS Glue 4.0 Docker image for Jupyter notebooks (`make docker-glue-build && make docker-glue-run` from `de-etl-jobs/`)
- **AWS CLI:** SSO profile varies per user — **list available `codility-data` profiles from `~/.aws/config` and let the user choose** before running commands (typically L2+). Region `eu-central-1`. Always `export AWS_PROFILE="<confirmed-profile>"` before running commands. See `.github/copilot-docs/aws-cli.md` for details.

## Workspace Structure

```
de-ai-workspace/                        # Workspace root
├── .github/                            # Workspace-level config
│   ├── copilot-instructions.md         # This file (always loaded)
│   └── copilot-docs/                   # Detailed reference docs (read on demand)
│       ├── athena.md                   # Athena querying, table layers, cost guidelines
│       ├── airflow.md                  # Airflow integration, DAG schedules, MWAA API
│       ├── atlassian.md                # Jira + Confluence MCP usage
│       ├── aws-cli.md                  # AWS CLI usage, authentication, key resource IDs
│       ├── backfill.md                 # Manual backfill / ad-hoc job run procedures
│       ├── coralogix.md                # Coralogix MCP: app names, subsystems, query tips
│       ├── emr-jobs.md                 # EMR job patterns, key classes, Delta operations
│       ├── gitlab.md                   # GitLab MCP: code, MRs, issues, project reference
│       ├── infra-core.md               # infra-core repo: Terraform, Atlantis, data infra
│       └── merge-requests.md           # MR description template and conventions
├── de-etl-jobs/                        # Main ETL repository
│   ├── jobs/emr/data_models/           # All EMR Spark jobs
│   │   ├── deltalake_utils/            # Shared modules (PYTHONPATH on EMR)
│   │   ├── business_layer/             # Business entity jobs + similarity model + recommendation model
│   │   ├── domain_curated_layer/       # Raw → curated handlers + 140+ YAML entity configs
│   │   ├── reporting_layer/            # Dimensional model (dim_*.py, fact_*.py)
│   │   └── deltalake_processes/        # Delta maintenance scripts
│   ├── deploy/                         # Terraform IaC
│   ├── jupyter_workspace/              # Jupyter notebooks for exploration
│   ├── util_scripts/                   # Ad-hoc utility scripts
│   ├── Makefile                        # Build, sync, deploy commands
│   └── .gitlab-ci.yml                  # CI/CD pipeline
├── airflow/                            # Linked repo — DAGs, job configs, utilities
├── codility/                           # Linked repo — monolith source code
├── solution-similarity/                # Linked repo — similarity inference (Flask API + Lambda)
└── infra-core/                         # Linked repo — Terraform IaC (Atlantis-deployed)
```

### Where to Find Things

| Looking for... | Go to... |
|---|---|
| Shared Spark utilities, UDFs, configs | `de-etl-jobs/jobs/emr/data_models/deltalake_utils/` |
| A specific entity's ETL logic | `de-etl-jobs/jobs/emr/data_models/business_layer/` (custom jobs) or `business_layer/single_source_entity/` (YAML-driven) |
| Raw-to-curated YAML config for an entity | `de-etl-jobs/jobs/emr/data_models/domain_curated_layer/single_source_entity/` (140+ YAML files) |
| Reporting dim/fact tables | `de-etl-jobs/jobs/emr/data_models/reporting_layer/` |
| Similarity model pipeline | `de-etl-jobs/jobs/emr/data_models/business_layer/similarity_model/` |
| Airflow DAGs and job configs | `airflow/airflow-dags/` and `airflow/job-config/` |
| Lambda / API code | `solution-similarity/` |
| Data infra (EMR, Airflow, S3, Redshift) | `infra-core/infrastructure/codility-data/` |
| Coralogix alerts (data team) | `infra-core/infrastructure/codility-shared-services/global/coralogix/alerts/codility/data/` |

## Data Architecture (Layered)

```
External Sources (Monolith, Salesforce, Gainsight, etc.)
        │
        ▼
    Raw Layer (S3: JSON / Parquet snapshots from CDC, DMS, APIs)
        │
        ▼
    Domain Curated Layer (Delta tables — YAML-driven, generic handlers)
        │
        ▼
    Business Layer (Delta tables — custom ETL per entity)
        │
        ▼
    Reporting Layer (Delta tables — dim_* / fact_* dimensional model)
        │
        ▼
    Redshift (reporting tables synced for BI / analytics)
```

### Layer Details

| Layer | Storage | Glue DB | Description |
|-------|---------|---------|-------------|
| **Raw** | S3 (JSON, Parquet) | N/A | Raw CDC snapshots, DMS exports, API dumps. Not queryable via Athena. |
| **Domain** | Delta Lake on S3 | `domain_entities` | First Delta layer. Some entities skip curated and land here directly (check `skip_curated_layer` in YAML). |
| **Domain Curated** | Delta Lake on S3 | `curated_entities` | Cleaned, typed, deduplicated. Driven by YAML configs in `de-etl-jobs/jobs/emr/data_models/domain_curated_layer/single_source_entity/`. |
| **Business** | Delta Lake on S3 | `business_entities` | Business logic applied. Custom Python jobs per entity. |
| **Reporting** | Delta Lake on S3 | `reporting_entities` | Dimensional model (`dim_*`, `fact_*`). Synced to Redshift for BI/analytics. |

## Conventions

- **Entity YAML configs** define source-to-target mappings. Located in `single_source_entity/` under each layer in `de-etl-jobs/jobs/emr/data_models/`.
- **`op_db_prefix`** parameter: Used for stress testing. Prefixes table/path names (e.g., `"stress"` → reads from `stress_*`).
- **`table_version`** parameter: Suffix for versioned tables (e.g., `v3`).
- **ArgParser pattern:** Each job defines its own `ArgParser` class with `parse_args()`.
- **Logging:** Use `logger` from `business_commons` (or `global_commons`).
- **Tests:** `pytest` with PySpark local sessions (`SparkSession.builder.master("local[2]")`).

## Local Development

All `make` commands run from the `de-etl-jobs/` directory:

```bash
cd de-etl-jobs/
make docker-glue-build    # Build Glue 4.0 Docker image for local Jupyter
make docker-glue-run      # Run Jupyter Lab (accessible at localhost:8888)
make test-all             # Run tests
make sync-jobs            # Sync jobs to S3 (deploy)
```

`deltalake_utils/` is mounted on PYTHONPATH in the Glue Docker container, enabling `from business_commons import ...` without relative paths.

## Deployment

All deployment commands run from the `de-etl-jobs/` directory:

- **EMR jobs:** `make sync-jobs` syncs `jobs/` to S3
- **Shared utils:** `make push-emr-serverless-commons` zips and uploads `deltalake_utils/` to S3
- **EMR venv:** `make push-emr-serverless-venv-arm-prod` builds Docker, extracts venv tarball, uploads to S3
- **CI/CD:** GitLab CI triggers on `master` push with path-based rules (configured in `de-etl-jobs/.gitlab-ci.yml`)

## MCP Servers

External tools are available via MCP (Model Context Protocol) servers configured in `.vscode/mcp.json`. Read the relevant doc before using each server.

## On-Demand Reference Docs

The following detailed docs are in `.github/copilot-docs/`. **Read them only when the task requires it** — don't load all of them for every request.

| Doc | Read when... |
|-----|-------------|
| `.github/copilot-docs/aws-cli.md` | Running AWS CLI commands (EMR, S3, Athena), authentication, key resource IDs |
| `.github/copilot-docs/athena.md` | Writing Athena queries, checking table layers, optimizing query cost |
| `.github/copilot-docs/emr-jobs.md` | Working with EMR Spark jobs, understanding key classes, Delta read/write patterns |
| `.github/copilot-docs/airflow.md` | Working with DAGs, checking schedules, understanding job orchestration, querying Airflow via MWAA API |
| `.github/copilot-docs/backfill.md` | Running manual backfills, generating boto3 EMR scripts |
| `.github/copilot-docs/merge-requests.md` | User asks for an MR/merge request description |
| `.github/copilot-docs/coralogix.md` | Investigating logs, traces, metrics, incidents, or alerts via Coralogix MCP |
| `.github/copilot-docs/atlassian.md` | Looking up Jira tickets, Confluence docs, or managing tasks via Atlassian MCP |
| `.github/copilot-docs/gitlab.md` | Working with GitLab MRs, branches, issues, code, or looking up project IDs via GitLab MCP |
| `.github/copilot-docs/infra-core.md` | Working with Terraform/infra-core, data infra components, Coralogix alerts, Atlantis deployment |
