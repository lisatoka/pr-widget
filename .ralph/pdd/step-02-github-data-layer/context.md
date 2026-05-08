# Step 2 GitHub Data Layer - Context

## Existing Architecture
- SwiftUI macOS app with floating panel architecture
- FloatingPanelController wraps SwiftUI content in NSPanel
- ContentView currently shows static placeholder text

## Task: Implement gh CLI wrapper for authored PRs
- Use `gh pr list --author @me --json` command
- Parse JSON response into Swift model
- Support local-first architecture (in-memory or file-based storage)

## gh CLI JSON Fields Available
According to gh pr list documentation, we can fetch:
- number, title, url, author, state, isDraft
- repository (includes owner/name)
- updatedAt (timestamp)
- reviewRequests (array of users)
- comments (for highlighting logic)

## Swift Conventions
- Use Swift Package Manager if needed
- Follow Swift naming conventions (camelCase)
- Use Swift's Codable for JSON parsing
- Handle Process execution for CLI commands
