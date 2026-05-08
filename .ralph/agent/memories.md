# Memories

## Patterns

### mem-1778211835-fb26
> Xcode projects created programmatically need shared schemes for command-line builds. Without xcshareddata/xcschemes/*.xcscheme, xcodebuild -scheme <name> fails with scheme not found.
<!-- tags: xcode, build, macos | created: 2026-05-08 -->

## Decisions

## Fixes

### mem-1778216103-6210
> gh pr list requires git repo context (fails with 'not a git repository'). Use 'gh search prs --author=@me' instead - works from anywhere and returns same JSON format
<!-- tags: github, gh-cli, api | created: 2026-05-08 -->

### mem-1778212997-40ad
> failure: cmd=xcodebuild -list -project PRDesk.xcodeproj, exit=1, error=xcode-select: error: tool 'xcodebuild' requires Xcode, but active developer directory '/Library/Developer/CommandLineTools' is a command line tools instance, next=Install Xcode from Mac App Store or run: sudo xcode-select -s /Applications/Xcode.app if Xcode is already installed
<!-- tags: xcode, build, macos, tooling | created: 2026-05-08 -->

## Context
