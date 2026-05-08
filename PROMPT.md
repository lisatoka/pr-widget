# PR Desk

Build a native macOS app called PR Desk.

## Product vision

PR Desk is an always-visible, calm desktop companion for GitHub pull requests.

It should feel like a native macOS desktop widget, similar to the Clock widget: always visible, draggable, lightweight, and glanceable.

The goal is to reduce GitHub/email checking and make it easy to act on PRs through Claude Code.

## Core UI

### Desktop widgets

Create two separate draggable desktop widgets:

1. **My PRs**
   - Shows PRs authored by me.
   - Highlight PRs that need my action.
   - Dim PRs that are waiting for reviewers and do not need my action.
   - Only show inactive PRs if there is enough space.

2. **PRs I’m Tagged In**
   - Shows PRs where I am requested as a reviewer or mentioned.
   - Highlight PRs that need my review/action.
   - Dim PRs with no new activity.
   - Only show inactive PRs if there is enough space.

Widgets should:
- Be movable around the desktop by the user.
- Remember their positions.
- Use dark translucent macOS styling.
- Show only compact information:
  - PR title
  - repo name
  - last activity time
  - action-needed visual highlight
- Do NOT show detailed comment counts in the small widgets.

## Highlighting rules

For **My PRs**:
- Highlight when there are new reviewer comments that have not been addressed.
- Do not highlight when the PR is simply waiting for reviewers.
- Waiting-for-reviewer PRs should appear dimmed.

For **PRs I’m Tagged In**:
- Highlight when I have been requested as reviewer and have not reviewed yet.
- Highlight when there are new comments requiring my attention.
- Dim items with no new activity.

## Full window

Clicking a widget opens a larger PR Desk window.

The full window should have two separate sections or tabs:

1. **My PRs**
2. **PRs I’m Tagged In**

The full window should show detailed rows with:
- PR title
- PR number
- repository
- status
- last activity time
- usernames of people who requested reviews
- usernames of people who left comments
- action button: `Open in Claude`

For My PRs, distinguish:
- `Action needed: new comments from reviewers`
- `Waiting for reviewers: no action needed`

For PRs I’m Tagged In, distinguish:
- `Review requested by <username>`
- `New comments from <username>`
- `No new activity`

## Claude integration

Clicking `Open in Claude` should open Terminal and launch Claude Code with the correct context.

For **My PRs with new comments**, Claude should:
- summarize the PR
- summarize reviewer comments
- explain what needs to be addressed
- suggest code changes
- propose a response plan

For **PRs I’m tagged in**, Claude should:
- summarize the PR
- explain what changed
- identify risks or possible issues
- give a review opinion
- suggest comments I may want to leave

## GitHub integration

Use GitHub CLI `gh` first.

The app should poll GitHub periodically and support:
- PRs authored by me
- PRs where review is requested from me
- PR comments / review threads
- unresolved or unaddressed reviewer comments
- last activity timestamps

Use local-first architecture.

## Local repo integration

Support a config file mapping GitHub repos to local paths.

Example:

```json
{
  "canva/frontend": "~/work/frontend",
  "canva/seo": "~/work/seo"
}
```

## FIXES NEEDED

### 1. Filter Out Closed and Merged PRs
Currently all PRs are displayed (open, merged, closed, stale, etc).

Required behavior:
- Only show OPEN PRs
- Filter out merged and closed PRs entirely
- Do this at the GitHub CLI query level to avoid fetching unnecessary data

Implementation:
- In `GitHubClient.swift`, add `--state=open` flag to the `gh search prs` commands
- Update both `fetchMyPRs()` and `fetchReviewRequestedPRs()` to use: `gh search prs --state=open --author=@me` and `gh search prs --state=open --review-requested=@me`
- This ensures merged/closed PRs are never fetched or stored

### 2. Sort PRs by Most Recent Activity
PRs should be ordered by most recent activity (newest first).

Required behavior:
- PRs with fresh pushes/comments should appear before PRs without recent updates
- Both widgets and detail window should use this ordering

Implementation:
- In `GitHubClient.swift`, add sorting to the `gh search prs` command using `--sort=updated` flag
- Update both fetch methods to include: `gh search prs --sort=updated --author=@me` and `gh search prs --sort=updated --review-requested=@me`
- GitHub CLI returns results in descending order by default (newest first) when using `--sort=updated`

### 3. Fix Detail Window Opening Too Small
The detail window currently opens very small initially.

Required behavior:
- Detail window should open at a reasonable default size (e.g., 900x700 or larger)
- Should be comfortable to read PR details without resizing

Implementation:
- In `DetailWindow.swift`, update the `NSWindow` contentRect initialization
- Change from `NSRect(x: 0, y: 0, width: 800, height: 600)` to `NSRect(x: 0, y: 0, width: 1000, height: 800)` or similar
- Consider making it slightly larger since it contains detailed PR information
