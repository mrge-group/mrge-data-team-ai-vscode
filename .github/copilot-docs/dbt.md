# infra-core — Infrastructure as Code

The `infra-core/` repo contains all Codility infrastructure managed via **Terraform + Terragrunt**, deployed through **Atlantis** (GitOps).

## Directory Structure

| Directory | Description |
|---|---|
| `infrastructure/<account>/<region>/` | IaC for deployed infrastructure, split by AWS account and region |
| `services/<service-name>/<env>/<region>/` | Service-level infra, split by environment and region |
| `local-modules/` | Reusable Terraform modules by the Infra Team |
| `shared-modules/` | Reusable Terraform modules by Service Teams |
| `registry-modules/` | Modules published to the internal Terraform registry |
| `org/` | Organization-level settings (AWS SSO, accounts, policies) |
| `common_hcls/` | Global constants shared across projects |
| `global-deployments/` | Projects deployed to multiple accounts |

## Data Team Infrastructure

Data team infra lives in `infrastructure/codility-data/`:

| Path | Component |
|---|---|
| `eu-central-1/emr/` | EMR Serverless (applications, IAM, security groups) |
| `eu-central-1/airflow/` | MWAA Airflow environment |
| `eu-central-1/s3/` | S3 buckets (raw data, Delta Lake, artifacts) |
| `eu-central-1/redshift-dwh/` | Redshift cluster |
| `eu-central-1/redshift-dwh-config/` | Redshift configuration |
| `eu-central-1/athena/` | Athena workgroups |
| `eu-central-1/models-api/` | Models API (API Gateway) |
| `eu-central-1/similarity-inference-lambda/` | Similarity inference Lambda |
| `eu-central-1/similarity-service-inference-ecs/` | Similarity service ECS |
| `eu-central-1/ecs-load-balancers/` | ECS load balancers for data services |
| `eu-central-1/dwh-sql-exporter/` | DWH SQL exporter (monitoring) |
| `eu-central-1/dwh-metrics/` | DWH metrics |
| `eu-central-1/spoke/` | Spoke module (Coralogix firehose, log shippers) |
| `eu-central-1/vpc/` | VPC for data account |
| `us-east-1/` | US region resources (S3, ECR, CloudWatch, etc.) |

## Coralogix Alerts (Data Team)

Data team Coralogix alerts are defined in:
`infrastructure/codility-shared-services/global/coralogix/alerts/codility/data/`

| Alert Group | What It Monitors |
|---|---|
| `mwaa/` | Airflow task failures |
| `api-gateway/` | Models API 5xx errors |
| `similarity-service-sli/` | Similarity service latency and error SLIs |
| `similarity-service-inference/` | Inference endpoint health |
| `dwh-salesforce-freshness/` | Salesforce data freshness |
| `dwh_lambda/` | DWH Lambda errors |
| `external-data/` | External data source issues |

## Deployment Process (Atlantis)

1. Find the project directory you need to change
2. Make changes, push branch, create MR on GitLab
3. Atlantis posts `terragrunt plan` output as MR comment
4. Get review + approval (Infra team approval required)
5. Comment `atlantis apply` on the MR to apply changes
6. Merge after successful apply

**Do NOT run `terragrunt apply` locally** unless Atlantis is down (break-glass only).

## Running Locally (break-glass only)

```bash
cd infra-core/

# Install tools (macOS ARM)
make all-mac-arm64

# Navigate to the project
cd infrastructure/codility-data/eu-central-1/emr/

# Plan changes
terragrunt plan

# Apply (only in emergencies)
terragrunt apply
```

## When Data Team Might Need infra-core

- **EMR configs:** Change instance types, security groups, IAM roles → `infrastructure/codility-data/eu-central-1/emr/`
- **Airflow/MWAA:** Environment settings, worker configs → `infrastructure/codility-data/eu-central-1/airflow/`
- **S3 buckets:** New buckets, lifecycle policies, log shippers → `infrastructure/codility-data/eu-central-1/s3/`
- **Coralogix alerts:** Add/modify data team alerts → `infrastructure/codility-shared-services/global/coralogix/alerts/codility/data/`
- **Redshift:** Cluster changes, parameter groups → `infrastructure/codility-data/eu-central-1/redshift-dwh/`
- **API Gateway / Lambda:** Models API, similarity Lambda → respective directories
- **IAM / permissions:** Check roles and policies in the relevant project's `iam.tf`

## Tips for Working with infra-core

- Each project directory has a `terragrunt.hcl` that defines dependencies, inputs, and the Terraform source
- Variables are typically in `variables.tf`, actual values come from `terragrunt.hcl` inputs
- Shared constants live in `common_hcls/` — check there before hardcoding values
- Provider configs (AWS account, region, assume_role) are in `*-providers.tf` files at the account level
