# GitHub MCP — Code & Pull Requests

**Server:** `github-local` — configured in `.vscode/mcp.json` with `@modelcontextprotocol/server-github`.

## Authentication Setup

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
5. **Reload shell:** `exec $SHELL`
6. **Reload VS Code:** (⌘⇧P → "Developer: Reload Window") for the MCP server to connect

**Note:** The MCP configuration directly uses the `MRGE_GITHUB_PERSONAL_ACCESS_TOKEN` environment variable (mapped internally to `GITHUB_PERSONAL_ACCESS_TOKEN` for the MCP server).

## Repositories in This Workspace

These repositories are defined in `.gitmodules` and should be referenced with GitHub `owner/repo` format:

| Workspace Path | GitHub Repository | Default Branch |
|---|---|---|
| `bi-airflow-dags` | `mrge-group/bi-airflow-dags` | `main` |
| `data-platform` | `mrge-group/data-platform` | `main` |
| `data-platform-dagster-group` | `mrge-group/data-platform-dagster-group` | `main` |
| `data-platform-infra` | `mrge-group/data-platform-infra` | `main` |
| `databricks-assets` | `mrge-group/databricks-assets` | `main` |

## Branch Protection Rules

**⚠️ CRITICAL: Never commit directly to `main`**

All repositories enforce branch protection on the `main` branch. Direct pushes to `main` are **blocked** by repository rules.

**Required Workflow:**

1. **Always create a new branch** for any changes:
   ```bash
   git checkout -b feat/your-feature-name
   # or: chore/..., fix/..., docs/...
   ```

2. **Make changes and commit** to your feature branch:
   ```bash
   git add .
   git commit -m "descriptive commit message"
   ```

3. **Push to remote:**
   ```bash
   git push -u origin feat/your-feature-name
   ```

4. **Create a Pull Request** to merge into `main`

**Attempting to push directly to `main` will fail with:**
```
remote: error: GH013: Repository rule violations found for refs/heads/main.
remote: - Changes must be made through a pull request.
```

**Branch naming conventions:**
- `feat/*` - New features
- `fix/*` - Bug fixes
- `chore/*` - Maintenance tasks (deps, configs, etc.)
- `docs/*` - Documentation updates
- `refactor/*` - Code refactoring

## Common Operations

### Pull Requests

- List open PRs for a repository.
- Read PR details, changed files, and review comments.
- Create PRs with `head`, `base`, and clear title/description.
- Add or reply to review comments.

### Branches, Commits, and Files

- List branches and commits by repository.
- Compare branches before opening a PR.
- Read file contents at a specific ref (branch, tag, or commit SHA).
- Update files through GitHub MCP write operations when needed.

### Issues

- List issues with filters (state, labels, assignee).
- Create and update issues in the target repository.

## Usage Tips

- Always use repository names as `owner/repo` (for example: `mrge-group/data-platform`).
- This workspace is GitHub-first; use PR terminology (`pull request`) instead of GitLab MR terminology.
- All tracked repos in `.gitmodules` currently use `main` as default branch.
- Keep repo references aligned with `.gitmodules` when adding new docs or automation.

## PR/MR Description Files

When creating PR or MR descriptions for the user:

1. **Save to:** `.github/pr-descriptions/PR_DESCRIPTION_<ticket-id>.md` (or `MR_DESCRIPTION_<ticket-id>.md`)
2. **Folder is git-ignored:** Files in `.github/pr-descriptions/` are automatically excluded from version control
3. **User workflow:** User copies content to GitHub/GitLab, then deletes the local file

**Example:**
```
.github/pr-descriptions/
├── PR_DESCRIPTION_MDP-940.md
└── MR_DESCRIPTION_DAT-123.md
```

See [pull-requests.md](pull-requests.md) for PR/MR description structure and formatting guidelines.
