# PR Widget

A native macOS desktop widget for monitoring GitHub pull requests. PR Widget provides always-visible, glanceable PR status information right on your desktop, reducing the need to constantly check GitHub or email.

## Features

- **Two Desktop Widgets**: Separate draggable widgets for "My PRs" and "PRs I'm Tagged In"
- **Smart Highlighting**: Visual indicators for PRs that need your attention
- **Local-First**: All PR data is cached locally for instant display
- **Claude Code Integration**: One-click "Open in Claude" button to get AI assistance with PRs
- **Automatic Refresh**: Periodic polling with exponential backoff (5 min → 60 min max)
- **Native macOS Design**: Dark translucent styling using NSVisualEffectView

## Screenshots

*(Coming soon)*

## Installation

### Requirements

- macOS 13.0 or later
- GitHub CLI (`gh`) installed and authenticated
- Xcode (for building from source)

### GitHub CLI Setup

```bash
# Install gh if you don't have it
brew install gh

# Authenticate with GitHub
gh auth login
```

### Building from Source

```bash
# Clone the repository
git clone https://github.com/lisatoka/pr-widget.git
cd pr-widget

# Build and run
xcodebuild -project PRDesk.xcodeproj -scheme PRDesk build
open PRDesk.xcodeproj
# Then: Cmd+R in Xcode
```

## Usage

### Desktop Widgets

Two floating widgets appear on your desktop:

1. **My PRs** - Shows PRs you authored
   - Highlighted: PRs with new reviewer comments
   - Dimmed: PRs waiting for reviewers (no action needed)

2. **PRs I'm Tagged In** - Shows PRs where you're requested as reviewer
   - Highlighted: PRs needing your review or response
   - Dimmed: PRs with no new activity

Widgets are:
- Draggable (positions are remembered)
- Always visible on desktop (below normal windows)
- Auto-refreshing every 5 minutes

### Detail Window

Click any widget to open the full PR Desk window with detailed information:
- PR title, number, and repository
- Status and last activity time
- Reviewer/commenter usernames
- "Open in Claude" button for AI assistance

### Claude Integration

The "Open in Claude" button launches Terminal with Claude Code pre-loaded with context:

- **For your PRs**: Summarizes reviewer feedback and suggests code changes
- **For review requests**: Explains changes and helps you write a thorough review

## Configuration

### Claude Prompts

Customize the Claude prompts by editing:
```
~/Library/Application Support/PRDesk/prompts.json
```

Default structure:
```json
{
  "buttonText": "Open in Claude",
  "myPRs": "I'm working on PR #{pr_number} in {repo_name}...",
  "reviewRequested": "I need to review PR #{pr_number} in {repo_name}..."
}
```

Supported template variables:
- `{pr_number}` - PR number
- `{pr_title}` - PR title
- `{pr_url}` - GitHub PR URL
- `{pr_body}` - PR description
- `{repo_name}` - Repository name

### Local Repository Mapping

*(Coming soon)* Configure local paths for your GitHub repos:
```
~/Library/Application Support/PRDesk/repos.json
```

### Launch at Login

Enable "Launch at Login" in the app's Preferences to have widgets always available.

## Architecture

### Key Components

- **GitHubClient**: Uses `gh` CLI to fetch PR data
- **PRDataStore**: Local-first JSON storage in Application Support
- **PRRefreshService**: Orchestrates fetching and storing with exponential backoff
- **FloatingPanelController**: Manages desktop widget windows (NSPanel at `.normal - 1` level)
- **ClaudeIntegrationService**: Generates context-rich prompts for Claude Code
- **ContentView**: SwiftUI views with reactive updates via NotificationCenter

### Data Flow

1. `gh` CLI fetches PR data (every 5 min, up to 60 min with backoff)
2. `PRDataStore` saves to `~/Library/Application Support/PRDesk/*.json`
3. NotificationCenter broadcasts `prDataDidChange`
4. SwiftUI views automatically refresh

## Troubleshooting

### Widgets show "Failed to refresh"

Check:
1. `gh` is installed and authenticated: `gh auth status`
2. Logs at `/var/tmp/prdesk-gh-debug.log` and `/var/tmp/prdesk-app-debug.log`
3. `gh` binary paths in GitHubClient.swift match your installation

### PRs not appearing

- Only **OPEN** PRs are shown (merged/closed PRs are filtered out)
- PRs are sorted by most recent activity
- Check GitHub CLI directly: `gh search prs --state=open --author=@me`

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

*(Add your license here)*

## Credits

Built with SwiftUI for macOS. Integrates with GitHub CLI and Claude Code.
