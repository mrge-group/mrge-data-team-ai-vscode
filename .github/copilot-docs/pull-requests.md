# Pull Requests (GitHub)

When the user requests a PR/pull request description:

## Option 1: Create PR Directly (Recommended)

**Use the GitHub MCP server to create the PR directly:**

1. Use `mcp_github-local_create_pull_request` with:
   - `owner`: `mrge-group` (or appropriate org)
   - `repo`: repository name
   - `title`: Short, descriptive (e.g., "Fix: Job X Memory Exhaustion")
   - `head`: feature branch name
   - `base`: target branch (usually `main`)
   - `body`: Full PR description
   - `draft`: `true` if user wants to review before making it ready

2. **No manual copy-paste needed** — PR is created directly in GitHub

## Option 2: Save Description for Manual PR Creation

If the user prefers to review the description first or create the PR manually:

1. **Save to:** `.github/pr-descriptions/PR_DESCRIPTION_<ticket-id>.md`
2. **Folder is git-ignored** — files in `.github/pr-descriptions/` are automatically excluded from version control
3. **User workflow:** User reviews the file, then creates PR manually in GitHub (copy-paste or reference the file)

## PR Description Structure

**Keep it concise and executive-summary style:**

- **Title:** Short, descriptive (e.g., "Fix: Job X Memory Exhaustion")
- **Problem:** 1-2 sentences on what was broken
- **Root Cause:** Brief technical explanation
- **Solution:** What was changed and why
- **Changes:** Bullet list of modified files with short descriptions
- **Impact:** Cost, performance, data quality implications
- **Testing:** Checklist of verification steps

## Avoid

- Excessive code blocks (1-2 max for clarity)
- Implementation details that belong in code comments
- Repeating the full diff — reviewers can see that in GitHub
- **Never mention changes to `.github/copilot-instructions.md`** — these are internal tooling updates, not part of the PR
- **Never use `~` as an approximation symbol** (e.g., `~30%`) in PR descriptions or Slack messages — Slack interprets `~text~` as ~~strikethrough~~. Use "roughly", "approximately", or "about" instead.

## Slack Messages

When composing messages for the user to copy-paste into Slack:
- **Never use markdown links** like `[text](url)` — VS Code's chat UI rewrites these to `vscode://` scheme URIs, which break when pasted into Slack.
- Instead, write URLs as **plain text** (e.g., `https://github.com/mrge-group/...`) so they copy-paste correctly.
- Use Slack's native formatting: `*bold*`, `_italic_`, `` `code` ``.

## GitHub PR Workflow

**Preferred approach:** Use the GitHub MCP server to create PRs directly (Option 1) — no manual steps needed.

**Fallback:** Save description to `.github/pr-descriptions/` (Option 2) if the user wants to review first or has specific workflow requirements.

## Git Commits

- **Never use `\n` in commit messages** — the GitKraken MCP and some tools treat `\n` as literal text, not newlines.
- For multi-line commits, use `git commit` in the terminal with **multiple `-m` flags**:
  ```
  git commit -m "Subject line" -m "Body paragraph"
  ```
- Keep subject line under 72 chars, use imperative mood (e.g., "Fix X" not "Fixed X").
- Prefix with Jira ticket: `DAT-XXXX: Subject line`
