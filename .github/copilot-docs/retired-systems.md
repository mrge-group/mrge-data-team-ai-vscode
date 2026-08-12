# Retired Systems — Reference Only

**ClickHouse, `data-platform-dagster-group` and `bi-airflow-dags` are retired.**

Read them only to recover business logic that still needs migrating. Never treat them as evidence of how the platform works today, and never cite them when describing current architecture, writing an ADR, or producing a diagram.

**ClickHouse is not part of the technology stack.** It must not appear in an architecture document, diagram, or recommendation.

## Why this needs saying

The retired code is still checked out and still looks live. Every signal you would normally trust points the wrong way:

| Artefact | Why it reads as current |
|---|---|
| `data-platform-infra/clickhouse/main.tf` | Provisions a real ClickHouse **Cloud** service — organization id, service id, API key and secret. Reads as live infrastructure |
| `data-platform-dagster-group/clickhouse/migrations/` | Numbered, sequential migrations that look actively maintained |
| Dagster ClickPipes assets | Tagged `team: DataPlatform` with a named owner |
| `data-platform-etl/databricks/notebooks/ch_to_databricks_loader_notebook.py` | Sits in an **active** repo, which makes ClickHouse look like a current dependency |
| `bi-airflow-dags/dags/` | Same table and column names as the live estate |

This is not hypothetical. During ADR-0001 work, this evidence was read as current estate and ClickHouse was written into the architecture as the landing place for real-time click data. It had to be corrected twice.

## Rule

When stating what the platform does today, cite a file in an **active** repo:

| Repo | Role |
|---|---|
| `data-platform-etl` | Airflow DAGs, dbt models, Databricks notebooks. The main working repo |
| `data-platform-infra` | Terraform for the AWS and Databricks estate — **excluding** the retired `clickhouse/` module |
| `data-platform` | Platform services and deployment configuration |
| `data-platform-bi` | Omni BI models and reporting |

If the only evidence for a claim sits in a retired repo, say so explicitly instead of presenting it as fact. This follows the workspace accuracy rule: be 100% correct or explicitly uncertain.

## Migration reference

Using these repos to port old logic is the one supported use. When you do:

1. Read the retired implementation for **intent** — the business rule, the edge cases, the column semantics.
2. Rebuild it against the active stack (Databricks, dbt, MWAA). Do not copy Dagster or ClickHouse idioms across.
3. Verify the result against production data rather than trusting the old logic to have been correct.
