# GitHub MCP — Code & Pull Requests

**Server:** `github-local` — configured in `.vscode/mcp.json` with `@modelcontextprotocol/server-github` and token env var `MRGE_GITHUB_PERSONAL_ACCESS_TOKEN`.

## Repositories in This Workspace

These repositories are defined in `.gitmodules` and should be referenced with GitHub `owner/repo` format:

| Workspace Path | GitHub Repository | Default Branch |
|---|---|---|
| `bi-airflow-dags` | `mrge-group/bi-airflow-dags` | `main` |
| `data-platform` | `mrge-group/data-platform` | `main` |
| `data-platform-dagster-group` | `mrge-group/data-platform-dagster-group` | `main` |
| `data-platform-infra` | `mrge-group/data-platform-infra` | `main` |
| `databricks-assets` | `mrge-group/databricks-assets` | `main` |

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
