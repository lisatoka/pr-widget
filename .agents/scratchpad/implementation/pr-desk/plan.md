# PR Desk - Implementation Plan

## Step 1 - Scaffold macOS App Project
**Demo:** Xcode project builds and launches a minimal macOS app window

Expected subtasks:
- Create Xcode project structure for macOS app
- Set up basic SwiftUI app entry point with main window
- Verify app builds and launches successfully

## Step 2 - GitHub Data Layer
**Demo:** App can fetch and display real PR data from GitHub CLI

Expected subtasks:
- Implement `gh` CLI wrapper to fetch user's PRs
- Implement `gh` CLI wrapper to fetch PRs where user is tagged
- Parse PR data and store in local model
- Create basic data refresh mechanism

## Step 3 - Desktop Widget UI (My PRs)
**Demo:** First draggable desktop widget displays "My PRs" with proper styling

Expected subtasks:
- Create floating window/panel for "My PRs" widget
- Implement draggable behavior with position persistence
- Apply dark translucent macOS styling
- Display PR list with compact info (title, repo, time, highlight state)

## Step 4 - Desktop Widget UI (PRs I'm Tagged In)
**Demo:** Second draggable desktop widget displays "PRs I'm Tagged In"

Expected subtasks:
- Create second floating window for "PRs I'm Tagged In" widget
- Implement same draggable/styling behavior
- Display tagged PR list with highlighting logic

## Step 5 - Full Detail Window
**Demo:** Clicking widget opens full window with detailed PR information

Expected subtasks:
- Create main detail window with two tabs/sections
- Display detailed PR rows (title, number, repo, status, activity, usernames)
- Wire widget click to open detail window

## Step 6 - Claude Integration
**Demo:** "Open in Claude" button launches Terminal with appropriate Claude Code context

Expected subtasks:
- Implement "Open in Claude" button action
- Generate appropriate prompt based on PR type (my PRs vs tagged)
- Launch Terminal and execute Claude Code with context

## Step 7 - Polling and State Management
**Demo:** App automatically refreshes PR data periodically and updates UI

Expected subtasks:
- Implement periodic polling mechanism
- Update widget highlight states based on new data
- Handle edge cases (network failures, rate limits)

## Step 8 - Bug Fixes
**Demo:** Widgets sit on desktop background and successfully fetch PR data from GitHub

Expected subtasks:
- Fix window level: change from floating to desktop background
- Fix GitHub CLI error: debug and resolve gh command execution issues

## Step 9 - Additional Bug Fixes (Per Updated Objective)
**Demo:** PRs filtered to open only, sorted by recent activity, detail window opens at comfortable size

Expected subtasks:
- Filter out closed and merged PRs: add --state=open flag to gh search commands
- Sort PRs by most recent activity: add --sort=updated flag to gh search commands
- Fix detail window opening too small: increase NSRect from 800x600 to larger size (1000x800)

## Step 10 - Advanced Configuration Features
**Demo:** Users can customize Claude prompts via JSON config and toggle "Launch at Login" from app UI

Expected subtasks:
- Implement customizable Claude prompts via JSON config file with template variable support
- Add "Launch at Login" toggle in app UI using ServiceManagement framework
