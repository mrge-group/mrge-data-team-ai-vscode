# AI VS Code Workspace

Shared VS Code workspace for the Data Engineering team with pre-configured AI assistant instructions, MCP integrations, and linked repositories.

## Quick Setup

### 1. Clone the workspace

```bash
git clone --recurse-submodules git@gitlab.codility.net:data-engineering-team/ai-vscode-workspace.git
cd ai-vscode-workspace
```

If you already cloned without `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

### 2. Open in VS Code

```bash
code .
```

### 3. Install recommended extensions

When VS Code opens, install these extensions if you don't have them already:

- **GitHub Copilot** (`GitHub.copilot`)
- **GitHub Copilot Chat** (`GitHub.copilot-chat`)

### 4. MCP servers (auto-configured)

The workspace comes with pre-configured MCP servers in `.vscode/mcp.json`:

| Server | What it does | Auth |
|---|---|---|
| **Atlassian** | Jira + Confluence access | Browser OAuth (auto-prompt) |
| **Coralogix** | Logs, metrics, traces, alerts | API key (prompted on first use) |

No manual config needed — VS Code will prompt for credentials when you first use each server.

### 5. Start using

Open **Copilot Chat** (⌘⇧I on macOS) and ask questions about the codebase. The AI agent has context about:
- ETL job structure and patterns
- Data architecture (layers, tables, configs)
- Airflow DAGs and schedules
- Coralogix observability (app names, subsystems)
- Jira/Confluence integration
- Infrastructure (Terraform, Atlantis)

## Updating

Pull the latest workspace config and submodule changes:

```bash
# Update workspace config
git pull

# Update all submodules to their latest branch tips
make update

# Or both in one go
git pull && make update
```

## What's Included

```
.github/
├── copilot-instructions.md     # Core AI instructions (always loaded)
└── copilot-docs/               # Detailed docs (loaded on demand by AI)
    ├── athena.md               # Athena querying & cost guidelines
    ├── emr-jobs.md             # EMR Spark job patterns
    ├── airflow.md              # DAG schedules & orchestration
    ├── backfill.md             # Manual backfill procedures
    ├── merge-requests.md       # MR description conventions
    ├── coralogix.md            # Coralogix app names & query tips
    ├── atlassian.md            # Jira & Confluence usage
    └── infra-core.md           # Terraform & infrastructure

.vscode/
└── mcp.json                    # MCP server configs (Atlassian, Coralogix)

Submodules:
├── de-etl-jobs/                # Main ETL repository
├── airflow/                    # DAGs & job configs
├── codility/                   # Monolith source code
├── solution-similarity/        # Similarity inference API
└── infra-core/                 # Terraform IaC
```

## Contributing

To update AI instructions or workspace config:

1. Create a branch: `git checkout -b update-instructions`
2. Edit files in `.github/` or `.vscode/`
3. Commit, push, and create an MR
4. After merge, teammates run `git pull` to get the updates
