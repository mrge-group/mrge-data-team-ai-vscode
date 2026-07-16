---
name: jira-worklog
description: Auto-fill Jira worklogs for the current month based on assigned tickets and PR activity. Use when the user asks to log time, fill worklogs, track working time on Jira tickets, or fill their timesheet. Calculates 8h per German working day from month start to today, spreads hours across assigned tickets weighted by PR evidence, and posts worklogs only after explicit table approval.
---

# Jira Worklog Auto-Fill

Fill Jira worklogs for the current month: 8 hours per working day, spread across the user's assigned tickets, weighted by their PR activity. Nothing is posted to Jira without explicit approval of the final schedule table.

## Hard rules (never violate)

1. **Scope**: only tickets **assigned to the current user** whose status is **not "To Do"**. Never touch other people's tickets.
2. **Current-month activity only**: a ticket qualifies only if it has **real activity inside the current calendar month** — a status transition, comment, worklog, or a PR/commit by the user dated this month. `updated >= startOfMonth()` alone is not sufficient evidence: verify via the ticket's history/comments and PR dates, and drop tickets whose only "update" is trivial (label edit, sprint move, bulk change). Hours are never allocated to a ticket for days outside its activity window.
3. **Total hours**: exactly `working_days × 8` from the 1st of the current month through **today** (inclusive if today is a working day). Working days are Monday–Friday excluding German public holidays. NEVER log more or less than this total (after applying user adjustments from step 3).
4. **Daily window**: all logged blocks fall within **09:00–19:00** local time (Europe/Berlin), exactly 8h per working day unless the user said otherwise.
5. **No overlaps**: time blocks on the same day must never overlap — one ticket at a time.
6. **Approval gate**: before calling any Jira write tool, print the full schedule table and get an explicit "yes" from the user. If the user edits anything, re-print the corrected table and ask again.
7. **Respect existing logs (gap-fill only)**: existing worklogs — manually entered or created by a previous run of this skill — are immutable. Never edit, delete, overwrite, or duplicate them. Each run only fills the gap: `new hours = required total − hours already logged this month by the user`. Existing blocks occupy their time slots: new blocks must not overlap them, and a day's combined total (existing + new) must equal 8h — if a day already has ≥ 8h logged, add nothing to it; if it has more than 8h, flag it to the user but leave it untouched.
8. **Frozen tickets**: tickets in status **Done** (or an equivalent closed status) that **already have worklogs** get no new logs. Their existing hours still count toward the monthly total. A Done ticket with zero logged time may still receive logs for the days the user actually worked on it.

## Workflow

### Step 1 — Gather context

- Load the Jira tools via ToolSearch: `atlassianUserInfo`, `getAccessibleAtlassianResources`, `searchJiraIssuesUsingJql`, `getJiraIssue`, `addWorklogToJiraIssue`.
- Get today's date with `date +%Y-%m-%d` (Bash) — do not guess it.
- Call `atlassianUserInfo` to get the user's accountId and confirm which Jira site is connected. Tell the user which site you're about to write to before doing anything else.

### Step 2 — Compute available hours

Run the helper script (relative to this skill's directory):

```bash
python3 scripts/workdays.py --year <YYYY> --month <M> --until <today's day> [--state <XX>]
```

- Ask the user which German state applies (holidays differ by Bundesland; e.g. BE, BY, NW) if you don't already know it. Nationwide-only is the fallback.
- The script prints the working-day list, excluded holidays, and `total_hours`. Show the user the excluded holidays so they can sanity-check.

### Step 3 — Ask for special considerations (ALWAYS, before calculating)

Ask the user (via AskUserQuestion or plain prompt) about anything the data can't show, with examples:

- Vacation / sick days this month (subtract those days entirely).
- Days with extra or reduced hours, or weekend work to include.
- Tickets that were re-assigned away from them but that they still contributed to (include with an estimated share).
- Tickets they're assigned to but didn't actually work on (exclude).
- Days already logged manually in Jira.

Apply these adjustments to the working-day list and total before allocating.

### Step 4 — Fetch candidate tickets and existing worklogs

Fetch candidates via `searchJiraIssuesUsingJql`:

```
assignee = currentUser() AND status != "To Do" AND updated >= startOfMonth() ORDER BY updated ASC
```

Then apply the **activity filter** (hard rule 2): for each candidate, confirm real activity inside the current calendar month — a status transition or comment in the ticket history, an existing worklog, or a user PR/commit from Step 5 mapped to it. Drop tickets that only match the JQL because of a trivial update, and report the dropped ones to the user with the reason.

Then build a complete **existing-worklog inventory** — this drives the gap-fill:

1. Also run `worklogAuthor = currentUser() AND worklogDate >= startOfMonth()` to catch tickets that already have logs but fell outside the candidate query (re-assigned or Done tickets).
2. For every ticket from either query, fetch this user's worklogs for the current month (start timestamp + duration each).
3. Build a per-day occupancy map of existing blocks and compute `already_logged_total`.
4. Compute the gap: `gap = required_total − already_logged_total`. If the gap is **≤ 0**, report the reconciliation to the user and stop — there is nothing to post.
5. Mark **frozen tickets** (hard rule 8): status Done/closed AND has existing worklogs → excluded from new allocation, hours still counted.

Add any extra tickets the user named in Step 3, even if no longer assigned.

### Step 5 — Estimate effort from PRs

Use `gh` CLI to find the user's PRs this month, e.g.:

```bash
gh search prs --author "@me" --created ">=<YYYY-MM-01>" --json title,createdAt,updatedAt,repository,url,additions,deletions
```

(also check `gh pr list` in relevant org repos if search misses some).

- Map PRs to tickets by ticket key in branch name / PR title / body.
- Weight each ticket by PR evidence: number of PRs, size (additions+deletions), and the date span between first commit/PR creation and merge. A PR's activity dates anchor *when* the ticket's hours land.
- Tickets with no PRs (research, reviews, ops work) still get hours — use status-transition dates and comments as the anchor, and say so in the proposal.
- These weights guide the split, but the sum across all tickets must equal the exact total from Steps 2–3 — scale proportionally, never above or below.

### Step 6 — Build the schedule (gap-fill around existing logs)

- Allocate only the **gap** from Step 4 across non-frozen tickets, weighted by Step 5.
- For each working day, the target is `8h − existing hours that day`. Days already at 8h get nothing; days over 8h are flagged but untouched.
- New blocks go inside 09:00–19:00 and around the existing occupied slots — never overlapping them. Default shape on an empty day: `09:00–13:00` and `14:00–18:00` (1h lunch gap); adjust when a day splits across tickets or has existing entries.
- Existing worklogs without a usable start time (Jira allows date-only logs) still consume that day's hour budget; assume they occupy from 09:00 onward and place new blocks after them.
- Prefer contiguous blocks: keep one ticket per block, switch tickets at block boundaries, and keep each ticket's hours on days consistent with its PR/activity dates.
- Minimum block: 30 minutes. Round to 15-minute boundaries.
- Verify programmatically before presenting: per-day sum (existing + new) = 8h, no overlapping intervals (including against existing blocks), existing total + new total = required total. If any check fails, fix the schedule — do not present a broken one.

### Step 7 — Approval table (mandatory)

Present the complete plan as a markdown table:

| Jira ticket | Day | time_from | time_to | Hours | Source |
|---|---|---|---|---|---|

where `Source` is `existing` (shown for context, will NOT be posted) or `new` (will be posted). Follow with a reconciliation summary: `already logged + new = required total`, per-ticket subtotals, and the list of frozen tickets that were skipped. Then ask for explicit approval to post **only the `new` rows**. Do **not** post if the answer is anything but a clear yes.

### Step 8 — Post worklogs

For each approved row call `addWorklogToJiraIssue` with:

- `started`: `<day>T<time_from>:00.000+0200` (use the correct Berlin UTC offset for the date — +0200 CEST / +0100 CET),
- time spent matching the block length (e.g. `3h 30m`).

Post sequentially, track failures, and finish with a summary: rows posted, rows failed (with error), and links to the updated tickets. On partial failure, list exactly which rows still need posting so the run can be resumed without duplicating.
