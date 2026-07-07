# AI VS Code Workspace

Shared VS Code workspace for the Data Engineering team with pre-configured AI assistant instructions, MCP integrations, and linked repositories.

## Quick Setup

### Prerequisites

**Required Python version: 3.11.14**

Check your current version:
```bash
python --version
```

If you don't have Python 3.11.14, install it using pyenv:
```bash
# Install pyenv (if not already installed)
brew install pyenv

# Install Python 3.11.14
pyenv install 3.11.14

# If you get "already exists" - it's already installed, skip to next step

# Set it as the local version for this workspace
cd mrge-data-team-ai-vscode
pyenv local 3.11.14

# Verify
python --version  # Should show 3.11.14
```

**Important:** After setting `pyenv local`, restart your terminal or run:
```bash
# Reload shell configuration
exec $SHELL

# Verify again
python --version
```

**Already have 3.11.14 installed?** If `pyenv install 3.11.14` says "already exists", you just need to:
```bash
cd mrge-data-team-ai-vscode
pyenv local 3.11.14
exec $SHELL
python --version  # Verify it shows 3.11.14
```

### 1. Clone the workspace

```bash
git clone --recurse-submodules git@github.com:mrge-group/mrge-data-team-ai-vscode.git
cd mrge-data-team-ai-vscode
```

If you already cloned without `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

### 2. Set up Python environment (Poetry)

The workspace uses **Poetry** for unified dependency management across all data platform projects.

**Automated setup (recommended):**
```bash
# One command to set up everything
make setup
```

**Note:** The setup will automatically check your Python version. If you don't have 3.11.14, you'll get clear instructions on how to install it.

This will:
- ✅ Check Python version (3.11.14 required)
- ✅ Install Poetry (if not already installed)
- ✅ Create virtual environment
- ✅ Install all dependencies (including dev tools)
- ✅ Set up pre-commit hooks
- ✅ Run initial code quality checks

**Manual setup (if you prefer step-by-step):**
```bash
# Install Poetry (if not already installed)
make poetry-install-tool

# Create virtual environment and install all dependencies
make poetry-env-create

# Install pre-commit hooks
make pre-commit-install

# Activate the environment
poetry shell
```

**Verify setup:**
```bash
make poetry-env-info
```

### 3. Open in VS Code

```bash
code .
```

### 4. Install recommended extensions

When VS Code opens, install these extensions if you don't have them already:

- **GitHub Copilot** (`GitHub.copilot`)
- **GitHub Copilot Chat** (`GitHub.copilot-chat`)
- **dbt** (`dbtlabs.vscode-dbt`) - Official dbt extension for syntax highlighting and IntelliSense
- **dbt Power User** (`innoverio.vscode-dbt-power-user`) - dbt modeling, lineage, and documentation
- **Markdown Preview Enhanced** (`shd101wyy.markdown-preview-enhanced`) - Enhanced markdown preview

VS Code will automatically prompt you to install these when you open the workspace.

**VS Code Configuration:**

The workspace includes these pre-configured settings in `.vscode/settings.json`:

- **Autosave enabled:** Files save automatically 1 second after you stop typing
- **dbt syntax highlighting:** All `.sql` files in dbt projects use `jinja-sql` syntax
- **Python environment:** Points to the Poetry virtual environment at `.venv/bin/python`
- **dbt project paths:** Pre-configured for both `data-platform-etl` and `data-platform-dagster-group` dbt projects

### 5. MCP servers (auto-configured)

The workspace comes with pre-configured MCP servers in `.vscode/mcp.json`:

| Server | What it does | Auth | Setup Instructions |
|---|---|---|---|
| **Atlassian** | Jira + Confluence access | Browser OAuth (auto-prompt) | None - authenticates on first use |
| **GitHub** | Repository operations, PR/Issue management | Fine-grained PAT | See [GitHub MCP Setup](#github-mcp-setup) below |
| **Databricks** | SQL queries, Unity Catalog access | Token auth | See [Databricks MCP Setup](#databricks-mcp-setup) below |

#### GitHub MCP Setup

The GitHub MCP server requires a **Fine-grained Personal Access Token**:

1. **Create token:** Go to https://github.com/settings/personal-access-tokens/new
2. **Configure:**
   - **Token name:** "MRGE Data Team MCP" (or similar)
   - **Resource Owner:** "mrge-group"
   - **Expiration:** Choose your preference (90 days, 1 year, etc.)
   - **Repository access:** Select "All repositories"
   - **Repository permissions:**
     - **Read access to:** actions, attestations api, code, codespaces metadata, deployments, merge queues, metadata, pages, and repository hooks
     - **Read and Write access to:** commit statuses, discussions, and pull requests
3. **Generate token** and copy it
4. **Set environment variable:**
   ```bash
   # Add to your ~/.zshrc or ~/.bashrc
   export MRGE_GITHUB_PERSONAL_ACCESS_TOKEN="github_pat_..."
   ```
5. **Reload shell:**
   ```bash
   exec $SHELL
   ```
6. **Reload VS Code:** (⌘⇧P → "Developer: Reload Window") for the MCP server to connect.

**Note:** The MCP configuration directly uses `MRGE_GITHUB_PERSONAL_ACCESS_TOKEN` environment variable.

#### Databricks MCP Setup

The Databricks MCP server requires two environment variables:

```bash
# Add to your ~/.zshrc or ~/.bashrc
export HOST_NAME="dbc-3ccb0e4a-5869.cloud.databricks.com"
export DATABRICKS_TOKEN="dapi..."  # Get from Databricks Settings → Developer → Access Tokens
```

After adding these, reload your shell:
```bash
exec $SHELL
```

Then reload VS Code (⌘⇧P → "Developer: Reload Window") for the MCP server to connect.

**Note:** These are the same environment variables used for dbt development (see [dbt.md](.github/copilot-docs/dbt.md#environment-setup)).

### 6. Start using

Open **Copilot Chat** (⌘⇧I on macOS) and ask questions about the codebase. The AI agent has context about:
- ETL job structure and patterns
- Data architecture (layers, tables, configs)
- Airflow DAGs and schedules
- Coralogix observability (app names, subsystems)
- Jira/Confluence integration
- Infrastructure (Terraform, Atlantis)

## Claude Code

The workspace also ships configuration for **Claude Code** (CLI or VS Code extension), separate from the Copilot setup above:

- **`.mcp.json`** — project-scoped MCP servers for Claude Code. Includes `atlassian-mrge` (Jira + Confluence on `mrge.atlassian.net`).
- **`.claude/settings.json`** — shared permission rules. Blocks the personal claude.ai Atlassian connector (`mcp__claude_ai_Atlassian_Rovo__*`) so Claude can never read from or write to the wrong Jira site from this workspace.
- **`.claude/skills/`** — custom skills (slash commands), documented below.

**One-time Atlassian authentication:** the `atlassian-mrge` server config is shared via git, but each developer authenticates individually. In an interactive Claude Code session inside this workspace, run `/mcp`, select `atlassian-mrge`, and sign in with your **mrge work Atlassian account** (not a personal one), granting access to `mrge.atlassian.net`. The server name is intentionally distinct so its OAuth token is stored separately from any personal Atlassian login you may have elsewhere.

### Skill: `/jira-worklog` — auto-fill Jira worklogs

Fills your Jira worklogs for the current month: 8 hours per German working day (Mon–Fri excluding public holidays), spread across your assigned tickets and weighted by your PR activity on GitHub. Lives in `.claude/skills/jira-worklog/`.

> **Also works with GitHub Copilot:** Copilot supports the same [Agent Skills standard](https://github.blog/changelog/2025-12-18-github-copilot-now-supports-agent-skills/) and auto-discovers skills from `.claude/skills/`, so this skill is available in Copilot chat too (type `/skills` in VS Code to verify). **Caveat:** Copilot reaches Jira through the Atlassian server in `.vscode/mcp.json` — not the `atlassian-mrge` server — so the account-separation guard above doesn't apply there. Make sure you authorize Copilot's Atlassian MCP with your **mrge work account**, or the skill could write to the wrong Jira site.

**Prerequisites:**

- `atlassian-mrge` MCP server authenticated (see above)
- `gh` CLI authenticated (`gh auth status`) — used to weight hours by your PRs
- Python 3 — a helper script computes working days and German holidays. Bundesland-specific holidays require the [`holidays`](https://pypi.org/project/holidays/) package (included in the workspace Poetry env — run the script via `poetry run python3 ...`); without it the script falls back to nationwide holidays only and says so in its output

**Usage:** type `/jira-worklog` in Claude Code. The skill then:

1. Confirms which Jira site it's writing to and computes the month's working days through today (it asks for your Bundesland to get holidays right).
2. Asks about adjustments the data can't show: vacation/sick days, reduced hours, tickets you worked on but aren't assigned to anymore, etc.
3. Fetches your assigned tickets that have real activity this month, plus any worklogs already logged.
4. Distributes the remaining hours across tickets, weighted by PR evidence (count, size, date span), placing blocks within 09:00–19:00 Berlin time.
5. Presents the complete schedule as a table and **posts nothing until you explicitly approve it**.

**Safety guarantees built into the skill:**

- Only touches tickets **assigned to you**; never other people's tickets.
- **Gap-fill only:** existing worklogs (manual or from a previous run) are never edited, deleted, or duplicated — reruns only top up missing hours, so running it twice is safe.
- Total logged time is exactly `working days × 8h`, no overlapping blocks, max 8h per day.
- Explicit approval gate before any write to Jira.

## Updating

Pull the latest workspace config and submodule changes:

```bash
# Update workspace config
git pull

# Update all submodules to their latest branch tips
make update

# Update Python dependencies
make poetry-env-update

# Or all in one go
git pull && make update && make poetry-env-update
```

## Python Environment Management

The workspace provides a unified Poetry environment with all dependencies from `data-platform-etl` and other active projects.

### Common Commands

```bash
# View all available commands
make help

# Create environment (first time)
make poetry-env-create

# Install/sync dependencies (after git pull)
make poetry-install

# Update all dependencies to latest versions
make poetry-env-update

# Export requirements.txt (for Docker, MWAA, etc.)
make poetry-export

# Activate virtual environment
poetry shell

# Run commands without activating shell
poetry run <command>

# Show environment info
make poetry-env-info

# Clean and rebuild environment
make poetry-clean
make poetry-env-create
```

### Code Quality Tools

The environment includes pre-configured code quality tools:

```bash
# Format code
make format          # black + isort

# Lint code
make lint            # black, isort, flake8 (check only)

# Type check
make typecheck       # mypy

# Run tests
make test            # pytest

# Run all checks
make check-all       # lint + typecheck + test
```

### Development Tools

```bash
# Start Jupyter Lab
make jupyter

# Start IPython
make ipython
```

### Configuration

All tool configurations are in `pyproject.toml`:
- **black:** 120 char line length, Python 3.11 target
- **isort:** black-compatible profile
- **pytest:** Auto-coverage reporting
- **mypy:** Type checking with lenient settings

### Python Version

The workspace uses **Python 3.11.14** (specified in `.python-version`). Make sure you have this version installed:

```bash
# Check version
python --version

# Install with pyenv
pyenv install 3.11.14
pyenv local 3.11.14
```

## What's Included

```
.github/
├── copilot-instructions.md     # Core AI instructions (always loaded)
└── copilot-docs/               # Detailed docs (loaded on demand by AI)
    ├── dbt.md                  # dbt development workflow
    ├── databricks.md           # Databricks Unity Catalog & querying
    ├── airflow.md              # DAG schedules & orchestration
    ├── aws-cli.md              # AWS CLI usage & authentication
    ├── github.md               # GitHub workflows, PRs, repository info
    ├── atlassian.md            # Jira + Confluence MCP usage
    └── pull-requests.md        # PR creation & description guidelines

.vscode/
└── mcp.json                    # MCP server configs for Copilot (Atlassian, GitHub, Databricks)

.mcp.json                       # MCP server configs for Claude Code (atlassian-mrge)
.claude/
├── settings.json               # Shared Claude Code permissions (blocks personal Atlassian connector)
└── skills/
    └── jira-worklog/           # /jira-worklog skill: auto-fill monthly Jira worklogs
        ├── SKILL.md            # Skill definition & workflow
        └── scripts/            # German working-days/holidays helper

Submodules:
├── data-platform-etl/           # Main ETL repository
├── data-platform/               # Platform infrastructure & deployment
├── data-platform-dagster-group/ # Dagster orchestration
├── data-platform-infra/         # Infrastructure as Code (Terraform)
└── bi-airflow-dags/             # Legacy BI Airflow DAGs
```

## Contributing

**⚠️ Branch Protection:** All repositories enforce branch protection on `main`. Direct pushes to `main` are **blocked**.

To update AI instructions or workspace config:

1. **Create a feature branch:** `git checkout -b feat/update-instructions`
2. Edit files in `.github/` or `.vscode/`
3. Commit and push: `git push -u origin feat/update-instructions`
4. **Create a Pull Request** to merge into `main`
5. After merge, teammates run `git pull` to get the updates

**Branch naming conventions:**
- `feat/*` - New features
- `fix/*` - Bug fixes
- `chore/*` - Maintenance (dependencies, configs, submodule updates)
- `docs/*` - Documentation updates
