# Tableau MCP: Usage Guide

## Overview

The Tableau MCP server is a **read-only** tool for investigating dashboards, exploring published datasources, and querying data via natural language. It connects to **Tableau Cloud** (`https://dub01.online.tableau.com`, site: `mrge`).

Authentication uses a **Personal Access Token (PAT)** configured via environment variables.

### Authentication Setup

The MCP server requires two environment variables in your shell configuration file (`~/.zshrc`):

```bash
export MRGE_TABLEAU_PAT_NAME="your-username@mrge.com"
export MRGE_TABLEAU_PAT_VALUE='your-tableau-password'
```

**Important:** Use single quotes around `PAT_VALUE` to prevent shell expansion of special characters.

### Troubleshooting Authentication

If you get an error like `The environment variable PAT_NAME is not set`:

1. **Completely quit VS Code** (⌘Q, not just reload window)
2. Open a new terminal session
3. Launch VS Code from the terminal:
   ```bash
   code /Users/ovedsablan/git_repos/mrge/mrge-data-team-ai-vscode
   ```

This ensures VS Code inherits your shell environment variables. If you launch VS Code from the GUI (Finder/Dock) before adding the variables to `~/.zshrc`, it won't pick them up until you restart.

---

## Available Tools

| Tool | What it does |
|---|---|
| `list-datasources` | List all published datasources on the site |
| `list-workbooks` | List workbooks (filterable by project, owner, etc.) |
| `list-views` | List views across the site |
| `get-workbook` | Fetch metadata for a specific workbook |
| `get-datasource-metadata` | Fetch field names, types, and descriptions for a datasource |
| `get-view-data` | Export a view's underlying data as CSV |
| `get-view-image` | Render a view as a PNG image |
| `query-datasource` | Run a structured VizQL query against a published datasource |
| `search-content` | Search across workbooks, views, and datasources by keyword |
| `list-all-pulse-metric-definitions` | List all Pulse metric definitions |
| `list-pulse-metric-definitions-from-definition-ids` | Fetch specific Pulse metric definitions by ID |
| `list-pulse-metrics-from-metric-definition-id` | List metrics linked to a definition |
| `list-pulse-metrics-from-metric-ids` | Fetch specific Pulse metrics by ID |
| `list-pulse-metric-subscriptions` | List Pulse subscriptions for the current user |
| `generate-pulse-metric-value-insight-bundle` | Generate a Pulse insight bundle for a metric |
| `generate-pulse-insight-brief` | Generate an AI-powered Pulse narrative (answer/summarize/advise) |

**The MCP server has NO write capabilities.** It cannot publish, refresh, update, delete, or modify anything.

---

## When to Use

- **Investigating stale dashboards** — check if a datasource exists, what fields it has, query it directly
- **Understanding what Tableau content exists** — list workbooks/views in a project before pointing pipelines at them
- **Ad-hoc data questions** — query a published datasource without building a view in Tableau
- **Pulse metric debugging** — inspect metric definitions, subscriptions, and generated insights

## When NOT to Use

- Publishing or refreshing datasources → use the REST API (`tableauserverclient` Python library)
- Managing permissions, users, schedules → use the REST API
- Anything mutating → this MCP server is read-only by design

---

## Usage Guidelines

- **Always use `search-content` or `list-*` tools first** to find the correct datasource/workbook ID before calling `query-datasource` or `get-view-image`.
- **`query-datasource` requires a VizQL query** — use `get-datasource-metadata` first to understand available fields before constructing a query.
- The MCP server targets the `codility` site on `dub01.online.tableau.com`. Do not assume content from other sites is accessible.
- Results are scoped to what the PAT owner has permission to see on the site.
