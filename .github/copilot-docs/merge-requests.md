# Merge Requests (GitLab)

When the user requests an MR/merge request description:

## Process

1. **Save it as a temporary file** in the relevant repo root (e.g., `de-etl-jobs/MR_DESCRIPTION.md`)
2. **Keep it concise and executive-summary style**
3. **Use this structure:**
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
- Repeating the full diff — reviewers can see that in GitLab
- **Never mention changes to `.github/copilot-instructions.md`** — these are internal tooling updates, not part of the MR
- **Never use `~` as an approximation symbol** (e.g., `~30%`) in MR descriptions or Slack messages — GitLab and Slack interpret `~text~` as ~~strikethrough~~. Use "roughly", "approximately", or "about" instead.

## Slack Messages

When composing messages for the user to copy-paste into Slack:
- **Never use markdown links** like `[text](url)` — VS Code's chat UI rewrites these to `vscode://` scheme URIs, which break when pasted into Slack.
- Instead, write URLs as **plain text** (e.g., `https://gitlab.codility.net/...`) so they copy-paste correctly.
- Use Slack's native formatting: `*bold*`, `_italic_`, `` `code` ``.

## Remember

The user will copy the content to GitLab and delete the temp file.

## Git Commits

- **Never use `\n` in commit messages** — the GitKraken MCP and some tools treat `\n` as literal text, not newlines.
- For multi-line commits, use `git commit` in the terminal with **multiple `-m` flags**:
  ```
  git commit -m "Subject line" -m "Body paragraph"
  ```
- Keep subject line under 72 chars, use imperative mood (e.g., "Fix X" not "Fixed X").
- Prefix with Jira ticket: `DAT-XXXX: Subject line`
