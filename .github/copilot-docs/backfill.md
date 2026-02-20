# Manual Backfill / Ad-hoc Job Runs

When backfilling or running a job manually outside Airflow:

## 1. Ask for Required Information

- EMR Application ID (playground: `00fntrvkvuemgj15`, or check `airflow/airflow-dags/dag_utils/utils.py` in the `airflow/` repo for production app IDs)
- Job script path (e.g., `business_layer/gitlab_events.py`)
- Job arguments (target_entity, config_path, execution_time, is_first_run, etc.)
- Any custom Spark configs needed (e.g., increased memory)

## 2. Generate a boto3 Run Script

- Use `get_emr_spark_configs()` pattern from `airflow/airflow-dags/dag_utils/utils.py` (in the `airflow/` repo)
- Entry point: `s3://codility-data-artifacts-eu-central-1/etl-jobs/jobs/emr/data_models/<script_path>`
- Execution role: `arn:aws:iam::589722663725:role/emr-source-service`
- Save the script in `de-etl-jobs/emr_backfill/` folder with a descriptive name (e.g., `backfill_gitlab_events.py`)
- Print the job run ID and an `aws emr-serverless get-job-run` command at the end for status checking

## 3. Key Parameters to Consider

- `--execution_time`: The reference timestamp for the job
- `--is_first_run`: Set to `True` only for initial full load
- `--load_start_timestamp` / `--load_end_timestamp`: For explicit time ranges (if supported by the job)
- `--is_backfill_run`: Some jobs have specific backfill modes

## 4. Before Running, Verify

- The job script is synced to S3 (`make sync-jobs`)
- The correct application ID for the environment
- Memory/executor configs if the job previously failed with OOM

## 5. Safety Checks

Before confirming the script is safe:

- App ID is playground (`00fntrvkvuemgj15`) unless production is explicitly requested
- `is_first_run` is `False` (merge/upsert) unless full reload is intended
- Spark configs match the failed job's config from `airflow/job-config/` (in the `airflow/` repo)
- No `--operational_db_prefix` means it **writes to production tables** — flag this to the user
