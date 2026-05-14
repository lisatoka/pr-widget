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
- Show a total count of active PRs (PRs requiring attention) in the corner of each widget.
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

## Menu bar presence

PR Desk should have a menu bar icon (similar to f.lux, Telegram, etc.) at the top of the screen rather than a dock icon at the bottom.

The menu bar icon should:
- Display the total number of PRs requiring attention across both categories (My PRs + PRs I'm Tagged In)
- Be always visible in the macOS menu bar
- Provide quick access to the app (clicking opens the full window or provides a menu)

Implementation:
- Use `NSStatusBar.system.statusItem` to create the menu bar icon
- Set `NSApp.setActivationPolicy(.accessory)` to hide the dock icon
- Update the status bar icon badge/text with the total PR count

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

### 3. Make Detail Window Size Dynamic
The detail window should automatically size itself based on the available screen space.

Required behavior:
- Window size should be dynamic based on screen dimensions
- Current window size should be the maximum window size possible while maintaining comfortable margins
- Should adapt to different screen sizes and resolutions
- Should be comfortable to read PR details without resizing

Implementation:
- In `DetailWindow.swift`, calculate window size based on `NSScreen.main?.visibleFrame`
- Use a percentage of the screen size (e.g., 80-90% of screen width/height) or leave appropriate margins
- Account for menu bar and dock space
- Example: `let screenFrame = NSScreen.main?.visibleFrame ?? .zero; let width = screenFrame.width * 0.85; let height = screenFrame.height * 0.85`

### 4. Make Claude Prompts Customizable via JSON Config
Currently the Claude prompts are hardcoded in `ClaudeIntegrationService.swift`. Users who install via Homebrew cannot modify prompts without rebuilding the entire app.

Required behavior:
- Store default prompts in a JSON config file that users can edit
- Allow users to customize both the prompts sent to Claude AND the button text
- Support template variables like `{pr_title}`, `{pr_url}`, `{pr_body}`, `{repo_name}`, etc.
- If config file doesn't exist or is invalid, fall back to sensible defaults
- The "Open in Claude" button text and associated prompt should both be configurable

Implementation:
- Create a config file at `~/Library/Application Support/PRDesk/prompts.json`
- Default structure:
  ```json
  {
    "buttonText": "Open in Claude",
    "myPRs": "I'm working on PR #{pr_number} in {repo_name}: {pr_title}\n\nPR URL: {pr_url}\n\nPR Description:\n{pr_body}\n\nPlease help me address reviewer feedback and suggest code changes.",
    "reviewRequested": "I need to review PR #{pr_number} in {repo_name}: {pr_title}\n\nPR URL: {pr_url}\n\nPR Description:\n{pr_body}\n\nPlease help me understand the changes and provide a thorough review."
  }
  ```
- Update `ClaudeIntegrationService.swift` to:
  - Load config on initialization
  - Parse template variables and replace with actual PR data
  - Fall back to hardcoded defaults if config is missing/invalid
- Update button text in UI (DetailWindow.swift) to use the configurable `buttonText` value
- Create the config file with sensible defaults on first launch if it doesn't exist
- Consider adding a "Reveal Config" button in preferences to help users find and edit the file

Benefits:
- Homebrew users can customize prompts without rebuilding
- Users can share and iterate on prompt templates
- Power users can tailor prompts to their workflow
- Users can customize the button text (e.g., "Ask Claude", "Get AI Help", etc.)

### 5. Add "Launch at Login" Toggle in App UI
Currently users must manually configure Launch at Login through System Settings after installing via Homebrew.

Required behavior:
- Add a "Launch at Login" checkbox/toggle in the app UI
- When enabled, app automatically starts when user logs in to macOS
- State should persist across app restarts

Implementation:
- Add a Preferences/Settings menu item or window
- Use `ServiceManagement` framework's `SMAppService` API (macOS 13+)
- Add a toggle UI element that:
  - Shows current launch-at-login status
  - Allows user to enable/disable
  - Persists setting in UserDefaults
- Alternative for older macOS versions: Use `LSSharedFileList` API

Example code pattern:
```swift
import ServiceManagement

let service = SMAppService.mainApp
if service.status == .enabled {
    // Already enabled
} else {
    try? service.register()
}
```

Benefits:
- Seamless onboarding for Homebrew users
- Widgets are "always there" as intended in product vision
- No need to explain System Settings configuration
