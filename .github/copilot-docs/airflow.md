# Airflow Integration

## Overview

- **DAGs** are defined in `data-platform-etl/dags/`
- **Artifacts bucket:** `mdp-artifacts-381491982671`

## MWAA API (Querying Airflow)

Use the **MWAA CLI Token API** to run **read-only** Airflow CLI commands from the terminal. This uses AWS SSO credentials — no extra Airflow auth is needed.

- **Environment name:** `data-platform-mwaa-eu-west-1-2`
- **Airflow version:** 2.10.3 (Python 3.11)
- **Auth:** `aws mwaa create-cli-token` → Bearer token for the MWAA CLI endpoint
- **Reference script:** `data-platform-etl/dags/` (check for CLI utility scripts)

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
  --name "data-platform-mwaa-eu-west-1-2" \
  --region eu-west-1 --output json --no-cli-pager) \
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
| `dags state <dag_id> <execution_date>` | State of a specific DAG run | `dags state <dag_id> 2026-02-15T03:00:00+00:00` |
| `dags next-execution <dag_id>` | Next scheduled execution time | `dags next-execution <dag_id>` |
| `tasks list <dag_id>` | List tasks in a DAG | `tasks list <dag_id>` |
| `variables list` | List all Airflow variable keys | `variables list` |
| `variables get <key>` | Get a variable value | `variables get <key>` |
| `version` | Airflow version | `version` |

### Important Notes

- **`dags state` requires the exact execution date** matching the DAG schedule. For a DAG scheduled at `0 3 * * *`, use `2026-02-15T03:00:00+00:00`, not just `2026-02-15`.
- **Some commands are blocked by MWAA** (return 403 Forbidden): `dags report`, `dags show`, `dags details`, `tasks states-for-dag-run`. These are MWAA platform restrictions.
- **`dags list-runs`** is not supported (returns parsing error).
- **Output is base64-encoded.** Always pipe through `base64 -d` (or `base64 --decode`).
- **Noise lines** like `CloudWatch logging is disabled for SubprocessLogHandler` appear in stdout — filter them if needed.
- **REST API (`/api/v1/`)** is **not available** — the MWAA environment does not have `api.auth_backends` configured.
