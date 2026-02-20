# Airflow Integration

## Overview

- **Job configs** are YAML files in `airflow/job-config/` (in the `airflow/` repo at workspace root) — define EMR jobs, dependencies, Spark configs.
- **DAG utils** in `airflow/airflow-dags/dag_utils/` — `get_emr_spark_configs()` builds EMR Serverless job configs.
- **EMR jobs** cannot return XCom values. Pattern: write metadata JSON to S3, read it in a lightweight Python Airflow task.
- **Artifacts bucket:** `codility-data-artifacts-eu-central-1`

## DAG Schedules

Use these schedules to choose lookback windows (incremental loads / failures):

| DAG | Schedule | Frequency |
|-----|----------|-----------|
| `emr_reporting_daily` | `0 3 * * *` | Daily at 03:00 UTC |
| `emr_reporting_6_hour_updater` | `30 */6 * * *` | Every 6 hours |
| `emr_domain_curated_updater` | `@hourly` | Hourly |
| `emr_domain_curated_updater_daily` | `15 2 * * *` | Daily at 02:15 UTC |
| `emr_similarity_daily_updater` | `0 2 * * *` | Daily at 02:00 UTC |
| `emr_similarity_hourly_updater` | `@hourly` | Hourly |
| `emr_churn_zero_loader_contact` | `30 */3 * * *` | Every 3 hours |
| `emr_churn_zero_loader_events` | `0 2 * * *` | Daily at 02:00 UTC |
| `gain_sight_loader` | `30 */3 * * *` | Every 3 hours |
| `evaluations_data_hourly_updater` | `@hourly` | Hourly |
| `deltalake_maintenance_vacuum` | `0 15 * * 6` | Weekly (Saturday 15:00 UTC) |
| `deltalake_maintenance_optimize` | `45 15 * * 0` | Weekly (Sunday 15:45 UTC) |

**Note:** For daily jobs, use a lookback window of **25+ hours** to ensure no data gaps. For 6-hour jobs, use **7+ hours**.

## MWAA API (Querying Airflow)

Use the **MWAA CLI Token API** to run **read-only** Airflow CLI commands from the terminal. This uses AWS SSO credentials — no extra Airflow auth is needed.

- **Environment name:** `codility-data-mwaa-eu-central-1-2`
- **Airflow version:** 2.10.3 (Python 3.11)
- **Auth:** `aws mwaa create-cli-token` → Bearer token for the MWAA CLI endpoint
- **Reference script:** `airflow/airflow_utils/run_airflow_cli_mwaa.py`

### ⚠️ Read-Only Only — NEVER Mutate

**NEVER** use commands that modify Airflow state. The following are **strictly forbidden**:

- `dags trigger` — triggers a DAG run
- `dags pause` / `dags unpause` — changes DAG scheduling
- `dags delete` — deletes a DAG
- `dags backfill` — creates backfill runs
- `variables set` / `variables delete` — modifies Airflow variables
- `connections add` / `connections delete` — modifies connections
- `tasks run` / `tasks test` — executes tasks
- `tasks clear` — clears task instances (causes reruns)

Only use the read-only commands listed below.

### Shell One-Liner Pattern

```bash
export AWS_PROFILE="<PROFILE>"  # Always ask user for profile first

MWAA=$(aws mwaa create-cli-token \
  --name "codility-data-mwaa-eu-central-1-2" \
  --region eu-central-1 --output json --no-cli-pager) \
&& curl -s POST \
  "https://$(echo $MWAA | jq -r '.WebServerHostname')/aws_mwaa/cli" \
  -H "Authorization: Bearer $(echo $MWAA | jq -r '.CliToken')" \
  -H "Content-Type: text/plain" \
  -d "<AIRFLOW_CLI_COMMAND>" \
  | jq -r '.stdout' | base64 -d
```

**Note:** The CLI token expires quickly (~60s). Generate a new one for each command.

### Allowed Read-Only Commands

| Command | Description | Example |
|---------|-------------|---------|
| `dags list -o json` | List all DAGs with status | `dags list -o json` |
| `dags state <dag_id> <execution_date>` | State of a specific DAG run | `dags state emr_reporting_daily 2026-02-15T03:00:00+00:00` |
| `dags next-execution <dag_id>` | Next scheduled execution time | `dags next-execution emr_reporting_daily` |
| `tasks list <dag_id>` | List tasks in a DAG | `tasks list emr_reporting_daily` |
| `variables list` | List all Airflow variable keys | `variables list` |
| `variables get <key>` | Get a variable value | `variables get emr_serverless_common` |
| `version` | Airflow version | `version` |

### Important Notes

- **`dags state` requires the exact execution date** matching the DAG schedule. For `emr_reporting_daily` (scheduled at `0 3 * * *`), use `2026-02-15T03:00:00+00:00`, not just `2026-02-15`.
- **Some commands are blocked by MWAA** (return 403 Forbidden): `dags report`, `dags show`, `dags details`, `tasks states-for-dag-run`. These are MWAA platform restrictions.
- **`dags list-runs`** is not supported (returns parsing error).
- **Output is base64-encoded.** Always pipe through `base64 -d` (or `base64 --decode`).
- **Noise lines** like `CloudWatch logging is disabled for SubprocessLogHandler` appear in stdout — filter them if needed.
- **REST API (`/api/v1/`)** is **not available** — the MWAA environment does not have `api.auth_backends` configured.
