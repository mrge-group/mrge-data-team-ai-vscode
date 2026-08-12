# mrge data team workspace

This workspace is a shell around several git submodules. Work happens in the submodules, not at the root.

## Retired — reference only

**ClickHouse, `data-platform-dagster-group` and `bi-airflow-dags` are retired.**

Read them only to recover business logic that still needs migrating. Never treat them as evidence of current architecture, and never cite them when describing how the platform works today. If a question is "how does X work now", these are not the answer.

This matters because the code is still present and still looks plausible. Anything found there needs corroboration from an active repo before it is stated as fact:

| Retired | What it still contains | Why it misleads |
|---|---|---|
| **ClickHouse** | `data-platform-infra/clickhouse/` Terraform provisioning a ClickHouse Cloud service, `data-platform-dagster-group/clickhouse/migrations/`, assets tagged `team: DataPlatform`, a `ch_to_databricks_loader_notebook.py` in the ETL repo | The Terraform reads as live infrastructure and the assets carry a current-looking owner tag |
| **`data-platform-dagster-group`** | Dagster assets, ClickPipes ingestion, ClickHouse table definitions | Recent-looking commits and real asset definitions |
| **`bi-airflow-dags`** | Legacy BI DAGs and DDL | Same table and column names as the live estate |

ClickHouse is **not** part of the technology stack. Do not put it in an architecture document, diagram, or recommendation.

## Active repositories

| Repo | Role |
|---|---|
| `data-platform-etl` | Airflow DAGs, dbt models, Databricks notebooks. The main working repo |
| `data-platform-infra` | Terraform for the AWS and Databricks estate (excluding the retired `clickhouse/` module) |
| `data-platform` | Platform services and deployment configuration |
| `data-platform-bi` | BI models and reporting |

## Working rules

- **Verify before asserting.** When stating what the platform does today, cite a file in an active repo. If the only evidence is in a retired repo, say so explicitly rather than presenting it as current.
- **Prefer the ETL repo** as the source of truth for pipelines and data flow.
- Architecture decisions live in `docs/adr/`. ADR-0001 covers the NEXUS platform.
