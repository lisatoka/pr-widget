# PR Desk - Implementation Context

## Source Type
Rough description from build.start event

## Original Request Summary
Build a native macOS app called PR Desk: an always-visible, calm desktop companion for GitHub pull requests. It should feel like a native macOS desktop widget (similar to the Clock widget) - draggable, lightweight, and glanceable.

## Key Requirements

### Desktop Widgets (Two separate draggable widgets)
1. **My PRs** - Shows PRs authored by me
   - Highlight: new reviewer comments needing action
   - Dim: PRs waiting for reviewers
   - Only show inactive PRs if space permits

2. **PRs I'm Tagged In** - Shows PRs where I'm requested as reviewer or mentioned
   - Highlight: review requested but not yet reviewed, or new comments needing attention
   - Dim: no new activity

### Widget Behavior
- Movable/draggable around desktop
- Remember positions
- Dark translucent macOS styling
- Compact info: PR title, repo name, last activity time, action-needed visual highlight
- NO detailed comment counts in small widgets

### Full Window (opened when clicking widget)
Two sections/tabs: "My PRs" and "PRs I'm Tagged In"

Detailed rows showing:
- PR title, number, repository, status
- Last activity time
- Usernames of reviewers/commenters
- "Open in Claude" action button

### Claude Integration
Clicking "Open in Claude" launches Terminal + Claude Code with context:
- For My PRs: summarize PR, reviewer comments, what needs addressing, suggest code changes
- For PRs I'm tagged in: summarize PR, identify risks, give review opinion, suggest comments

### GitHub Integration
- Use GitHub CLI `gh` first
- Poll GitHub periodically
- Track: PRs authored by me, PRs where review requested, comments/review threads, unresolved comments, last activity
- Local-first architecture

### Local Repo Integration
Config file mapping GitHub repos to local paths:
```json
{
  "canva/frontend": "~/work/frontend",
  "canva/seo": "~/work/seo"
}
```

## Technology Stack

### macOS Native App
- Swift/SwiftUI for macOS widgets (NSStatusItem or similar desktop overlay approach)
- Dark translucent styling (NSVisualEffectView)
- Persistent window positions (UserDefaults)

### GitHub Integration
- Primary: GitHub CLI `gh`
- Fallback: GitHub REST/GraphQL API
- Local SQLite or JSON for caching/state

## Acceptance Criteria
1. App launches and displays two draggable desktop widgets
2. Widgets show real PRs from GitHub (my PRs + PRs I'm tagged in)
3. Highlighting logic works correctly (action needed vs waiting)
4. Clicking widget opens full window with detailed view
5. "Open in Claude" button launches Terminal with Claude Code context
6. Widgets remember their desktop positions
7. Polling works and updates PR state periodically

## Constraints
- macOS only
- Must use `gh` CLI first
- Local-first (data cached locally)
- Lightweight/glanceable UI
- No unnecessary detail in compact widget view
