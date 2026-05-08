# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PR Desk is a native macOS desktop widget application for monitoring GitHub pull requests. It displays two floating desktop widgets: "My PRs" and "PRs I'm Tagged In", providing glanceable PR status information with visual highlighting for PRs that need attention.

## Building and Running

```bash
# Build the app
xcodebuild -project PRDesk.xcodeproj -scheme PRDesk build

# Run the app (after building, or use Xcode)
open PRDesk.xcodeproj
# Then: Cmd+R in Xcode

# Run standalone tests (test files in project root)
swiftc -o test_output test_gh_client.swift && ./test_output
swiftc -o test_output test_gh_client_real.swift && ./test_output
```

## Architecture

### Data Flow
1. **GitHub Data Fetching**: `GitHubClient` uses `gh` CLI to fetch PR data
2. **Local Storage**: `PRDataStore` persists PR data to Application Support directory as JSON
3. **Periodic Refresh**: `PRRefreshService` orchestrates fetching and storing, called by `PRDeskApp` every 5 minutes with exponential backoff on failures
4. **Reactive UI**: SwiftUI views observe `Notification.Name.prDataDidChange` to automatically refresh when data updates

### Key Components

**PRDeskApp.swift**: Main entry point
- Creates two `FloatingPanelController` instances for the desktop widgets
- Manages periodic polling timer with exponential backoff (5m → 10m → 20m → 40m → 60m max)
- Handles widget-to-detail window navigation via NotificationCenter

**FloatingPanelController.swift**: Desktop widget window management
- Uses `NSPanel` with `level = .normal - 1` to sit on desktop background (below normal windows)
- Borderless, translucent, movable by dragging background
- Wraps SwiftUI content in `NSHostingController`

**GitHubClient.swift**: GitHub CLI integration
- Searches for `gh` binary in common paths: `/opt/homebrew/bin/gh`, `/usr/local/bin/gh`, `/opt/local/bin/gh`
- Uses `gh search prs --author=@me` and `gh search prs --review-requested=@me`
- Extensive logging to `/var/tmp/prdesk-gh-debug.log` for diagnostics

**PRDataStore.swift**: Local-first storage
- Saves to `~/Library/Application Support/PRDesk/myPRs.json` and `reviewRequestedPRs.json`
- Posts `Notification.Name.prDataDidChange` after successful saves
- Uses ISO8601 date encoding for compatibility

**ContentView.swift**: Widget UI
- `PRListViewModel` observes `prDataDidChange` notification to auto-refresh
- Applies opacity dimming (50%) to PRs that don't need action
- Uses `NSVisualEffectView` for translucent dark background (`.hudWindow` material)

**DetailWindow.swift**: Full PR details window
- Standard NSWindow with tabs for "My PRs" and "PRs I'm Tagged In"
- Shows detailed PR rows with "Open in Claude" button

**ClaudeIntegrationService.swift**: Claude Code integration
- Generates context-rich prompts tailored to widget type
- For "My PRs": focuses on addressing reviewer feedback
- For "Review Requested": focuses on providing thorough review

### PR Highlighting Logic

Defined in `PullRequest.needsAction` (Models/PullRequest.swift):
- **My PRs**: Highlight if state is OPEN and not a draft (assumes reviewer activity)
- **Review Requested**: Same logic applies
- Dimmed PRs (opacity 0.5-0.6) indicate waiting states

## Common Issues

### GitHub CLI Errors
If widgets show "Failed to refresh: The operation couldn't be completed", check:
1. `gh` is installed and authenticated: `gh auth status`
2. Check logs at `/var/tmp/prdesk-gh-debug.log` and `/var/tmp/prdesk-app-debug.log`
3. Verify `gh` paths in `GitHubClient.swift` match your installation
4. The app searches multiple paths and sets up PATH environment correctly

### Window Level
Widgets use `NSWindow.Level.normal - 1` to sit on desktop background. This means they appear below normal application windows but above the desktop wallpaper.

## Testing

Test files are located in both:
- Project root: `test_gh_client.swift`, `test_gh_client_real.swift`, etc.
- `PRDesk/Tests/`: Comprehensive test suite covering UI, data flow, and integration

## Project Structure

```
PRDesk/
├── PRDeskApp.swift              # App entry point and AppDelegate
├── Models/
│   └── PullRequest.swift        # Core data model
├── Services/
│   ├── GitHubClient.swift       # gh CLI integration
│   ├── PRDataStore.swift        # Local JSON storage
│   ├── PRRefreshService.swift   # Orchestrates fetch + save
│   ├── ClaudeIntegrationService.swift  # Claude prompt generation
│   └── TerminalLauncher.swift   # Launches Terminal with Claude Code
├── Views/
│   └── DetailWindow.swift       # Full window with tabs
├── ContentView.swift            # Widget UI components
└── FloatingPanelController.swift # Desktop widget window management
```

## Key Design Principles

1. **Local-first**: All PR data is cached locally for instant widget display
2. **Reactive UI**: SwiftUI views automatically refresh when data changes via NotificationCenter
3. **Resilient polling**: Exponential backoff prevents hammering GitHub on failures
4. **Context-aware Claude integration**: Different prompts for author vs reviewer perspectives
5. **Native macOS feel**: Uses NSVisualEffectView, desktop-level windows, and standard macOS conventions
