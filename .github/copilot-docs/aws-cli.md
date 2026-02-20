# AWS CLI Usage

## Safety Policy (Read-only by Default)

- All AWS commands should be **read-only** by default (e.g., `list-*`, `get-*`, `describe-*`, `head-*`).
- If a command would **create/update/delete** resources or data (including writes to S3, EMR job submissions, Glue updates, IAM changes, Athena DDL/DML, etc.), you must stop and ask the user for confirmation first.
- The confirmation request must be written in **BOLD LETTERS** so it’s unmissable.

## Prerequisites

- AWS CLI v2 installed (`brew install awscli`)
- AWS SSO configured with the appropriate profile
- Active SSO session

## ⚠️ Always Ask Before Running AWS Commands

**Before running any AWS CLI command, confirm which AWS SSO profile to use.**

To avoid re-running long discovery snippets every time, use the repo helper which lists `codility-data` profiles, lets you pick one, and saves your preference locally (gitignored):

```bash
source scripts/aws_profile.sh
```

This typically ends up being an L2+ role/profile, but always confirm the right one for the task.

## AWS Profile Selection (Avoid Multi-line Shell Blocks)

- Avoid multi-line shell conditionals/blocks (e.g., `if ...; then ...; else ...; fi`) for profile discovery/selection.
  - They can leave the shell stuck in continuation prompts like `then>` / `else>`.
- Prefer the repo helpers:
  - `source scripts/aws_profile.sh` (interactive picker that persists to `.vscode/.aws_profile`)
  - `python3 scripts/aws_profile.py list`
  - `python3 scripts/aws_profile.py pick --save --print-export`

### Automation / Non-interactive selection

For automation/non-interactive usage, prefer:

```bash
python3 scripts/aws_profile.py pick --save --print-export --non-interactive
```

Auto-pick priority:

1) Saved profile in `.vscode/.aws_profile`
2) Existing `AWS_PROFILE` in the environment
3) Single matching profile
4) Single matching L2+ profile

Otherwise it fails and instructs to run the interactive picker.

## Authentication

All AWS commands must use the SSO profile. **Always export it first** in the terminal session:

```bash
export AWS_PROFILE="<PROFILE_NAME>"
```

Or set it per-command (less reliable with shell output capture):

```bash
AWS_PROFILE="<PROFILE_NAME>" aws <command>
```

Verify identity:
```bash
aws sts get-caller-identity --region eu-central-1 --output json --no-cli-pager
```

**If SSO session expired**, run:
```bash
aws sso login --profile "<PROFILE_NAME>"
```

## General Conventions

- **Region:** Always pass `--region eu-central-1` (all data infra is in eu-central-1)
- **Output:** Use `--output json --no-cli-pager` to get structured output without paging
- **Account:** `589722663725` (codility-data)

## AWS CLI Reliability (Throttling + Safe Parsing)

### Throttling (`TooManyRequestsException`)

Some AWS APIs (including EMR Serverless) may throttle.

- Prefer simple retries with short backoff (e.g., sleep 1s, 2s, 4s) rather than immediately failing.
- If throttling persists, widen the time window, reduce request frequency, or run once and inspect results.

### Safe JSON parsing

Avoid piping AWS CLI output straight into a JSON parser unless you’re sure the AWS CLI call succeeded.

- If the AWS CLI command fails, stdout may be empty and you’ll get a misleading `JSONDecodeError`.
- Safer pattern: run the AWS CLI command first, check exit code, then parse.

## EMR Serverless

### List Applications
```bash
aws emr-serverless list-applications --region eu-central-1 --output json --no-cli-pager
```

### Get Job Run Details
```bash
aws emr-serverless get-job-run \
  --application-id <APP_ID> \
  --job-run-id <JOB_RUN_ID> \
  --region eu-central-1 --output json --no-cli-pager
```

### List Job Runs (filter by state/time)
```bash
aws emr-serverless list-job-runs \
  --application-id <APP_ID> \
  --created-at-after <ISO8601> \
  --created-at-before <ISO8601> \
  --region eu-central-1 --output json --no-cli-pager
```

### Key Application IDs
| Application | ID | Purpose |
|---|---|---|
| `data_lake_similarity_hourly_updater_emr_application` | `00fns6ltgnmrk615` | Hourly CDC ETL jobs (similarity model, raw layer handlers) |

## S3

### List Objects (with size)
```bash
aws s3api list-objects-v2 \
  --bucket <BUCKET> \
  --prefix "<PREFIX>" \
  --output json --no-cli-pager
```

### Summarize (count + total size)
```bash
aws s3 ls s3://<BUCKET>/<PREFIX> --recursive --summarize
```

### Key Buckets
| Bucket | Purpose |
|---|---|
| `codility-data-datalake-raw-eu-central-1` | Raw CDC data (EU region) |
| `codility-data-datalake-raw-us-east-1` | Raw CDC data (US region) |
| `codility-data-delta-lake-silver-eu-central-1` | Delta Lake tables (domain, curated, business, reporting) |
| `codility-data-users-output-eu-central-1` | Athena query results |

## Athena Queries

Athena can be run directly via CLI. This is the preferred method for data inspection during investigations.

### Workgroup & Output Location

Use the `primary` workgroup with an explicit S3 output location:

```
s3://aws-athena-query-results-eu-central-1-589722663725/Unsaved/
```

### Running a Query (3-step process)

**Step 1: Start query execution**
```bash
aws athena start-query-execution \
  --query-string "<SQL>" \
  --work-group primary \
  --result-configuration "OutputLocation=s3://aws-athena-query-results-eu-central-1-589722663725/Unsaved/" \
  --region eu-central-1 --output json --no-cli-pager
```
Returns a `QueryExecutionId`.

**Step 2: Check execution status** (wait a few seconds first)
```bash
aws athena get-query-execution \
  --query-execution-id <QUERY_ID> \
  --region eu-central-1 --output json --no-cli-pager
```
Check `Status.State` — must be `SUCCEEDED` before fetching results. If `RUNNING`, wait and retry.

**Step 3: Get results**
```bash
aws athena get-query-results \
  --query-execution-id <QUERY_ID> \
  --region eu-central-1 --output json --no-cli-pager
```

### One-Liner Pattern (for simple queries)

```bash
QUERY_ID=$(aws athena start-query-execution \
  --query-string "SELECT COUNT(*) FROM curated_entities.codility_task_submits WHERE submit_date = '2025-01-15'" \
  --work-group primary \
  --result-configuration "OutputLocation=s3://aws-athena-query-results-eu-central-1-589722663725/Unsaved/" \
  --region eu-central-1 --output json --no-cli-pager | jq -r '.QueryExecutionId') \
&& sleep 5 \
&& aws athena get-query-results \
  --query-execution-id "$QUERY_ID" \
  --region eu-central-1 --output json --no-cli-pager
```

### Query Result Format

Results come as JSON with `Rows` array. First row is the header, subsequent rows are data:
```json
{
  "ResultSet": {
    "Rows": [
      { "Data": [{ "VarCharValue": "column_name" }] },
      { "Data": [{ "VarCharValue": "value" }] }
    ]
  }
}
```

### Cost Reminder

Follow the cost guidelines in `athena.md` — always use partition filters, LIMIT, and select only needed columns.
