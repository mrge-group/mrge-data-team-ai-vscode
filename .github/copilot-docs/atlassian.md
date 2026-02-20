# Atlassian MCP — Jira + Confluence

**Server:** `atlassian-mcp-server` — provides access to both Jira and Confluence on `codility-jira.atlassian.net`.

**Cloud ID:** `c528e912-004e-49f2-b7cc-39492384c8c8` (required for all Atlassian MCP calls).

## Jira

- **Primary board:** `Data` project (key: `MDP`). Search here first for task context.
- **Other boards:** Query other projects only when the DATA board doesn't have what's needed.
- **Common JQL patterns:**
  - Current sprint: `project = MDP AND sprint in openSprints()`
  - My tickets: `project = MDP AND assignee = currentUser()`
  - By status: `project = MDP AND status = "In progress"`

## Formatting — Jira Issues & Comments

When creating or updating Jira issues and comments, **always use rich formatting with Markdown** (the Atlassian MCP API accepts Markdown, NOT Jira wiki markup):

- **Use emojis** liberally to make content scannable: ✅ ❌ ⚠️ 💡 🔍 📋 🚀 💰 ⚡ 🔁 🚫 1️⃣ 2️⃣ 3️⃣ etc.
- **Use standard Markdown syntax**:
  - Headings: `##`, `###`
  - Bold: `**text**`
  - Italic: `_text_`
  - Code inline: `` `code` ``
  - Horizontal rule: `---`
  - Tables: `| Header | Header |` with `|---|---|` separator
  - Bullet lists: `- item` or `* item`
- **No checkbox syntax** — `[ ]` / `[x]` are rendered as literal text, not interactive checkboxes. Jira requires native ADF `taskList` nodes for real checkboxes, which the MCP API doesn't produce. **Use bullet lists (`- item`) instead** for checklists.
- **Keep it short and scannable** — optimize for a human reader. Too much detail makes tickets unreadable. Use bullet points, not paragraphs. Omit obvious context.
- **Structure with clear sections** when needed: Context → Proposal → Steps → Benefits → Risks
- **Use tables** for comparisons, ticket references, and summary data

## Confluence

- **Primary space:** `DATA` — search here first for documentation, ADRs, and runbooks.
- **Other spaces:** Query other spaces (e.g., `AR` for Architecture) when DATA space doesn't have the answer.
- **Use Confluence for:**
  - Looking up ADRs and design decisions
  - Finding runbooks and operational procedures
  - Checking data model documentation
  - Retrieving meeting notes or team agreements
