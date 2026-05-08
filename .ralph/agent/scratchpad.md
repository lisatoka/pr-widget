# PR Desk Scratchpad

## Current Objective

Implementing 3 bug fixes for PR Desk as specified in objective:
1. Filter out closed and merged PRs (use --state=open flag)
2. Sort PRs by most recent activity (use --sort=updated flag)
3. Fix detail window opening too small (increase from 800x600 to larger size)

## Current Understanding (2026-05-09 09:20)

Previous work completed all 8 steps of the original plan. The app is fully functional with:
- Two desktop widgets (My PRs, PRs I'm Tagged In)
- GitHub CLI integration with gh command
- Position persistence, highlight logic, polling, Claude integration
- All bugs from Step 8 fixed (window level, gh CLI execution)

New fixes needed per objective:
1. **Filter closed/merged PRs**: Currently fetching ALL PRs. Need to add `--state=open` to gh search commands in GitHubClient.swift
2. **Sort by recent activity**: Need to add `--sort=updated` to gh search commands for newest-first ordering
3. **Detail window size**: Currently opens at 800x600, too small. Should be ~1000x800 or larger per objective

## Implementation Plan

Step 9 will have 3 focused tasks:
- Fix 1: Add --state=open flag to both fetchMyPRs and fetchReviewRequestedPRs
- Fix 2: Add --sort=updated flag to both fetch methods
- Fix 3: Update DetailWindow NSRect initialization to larger size

All changes are in GitHubClient.swift (fixes 1 & 2) and DetailWindow.swift (fix 3).

## Critic Review (2026-05-09 09:20)

### Event Context
Reviewing `review.ready - filter-closed-prs: Added --state=open flag to both gh search commands`

### Fresh-Eyes Review Findings

**REJECTED** — Multiple requirements not met

#### Issue 1: Missing --sort=updated flag
**File**: PRDesk/Services/GitHubClient.swift:22, 59
**Current state**: Commands only have `--state=open`
**Required**: Commands must have BOTH `--state=open` AND `--sort=updated`

Lines 22 and 59 currently show:
```swift
let args = ["search", "prs", "--state=open", "--author=@me", "--json", fields]
let args = ["search", "prs", "--state=open", "--review-requested=@me", "--json", fields]
```

Should be:
```swift
let args = ["search", "prs", "--state=open", "--sort=updated", "--author=@me", "--json", fields]
let args = ["search", "prs", "--state=open", "--sort=updated", "--review-requested=@me", "--json", fields]
```

The objective explicitly states: "add sorting to the gh search prs command using --sort=updated flag"

#### Issue 2: Detail window size not updated
**File**: PRDesk/Views/DetailWindow.swift:16
**Current state**: `NSRect(x: 0, y: 0, width: 800, height: 600)`
**Required**: `NSRect(x: 0, y: 0, width: 1000, height: 800)`

The objective states: "update the NSWindow contentRect initialization from NSRect(x: 0, y: 0, width: 800, height: 600) to NSRect(x: 0, y: 0, width: 1000, height: 800)"

#### Verification
Build status: ✓ Succeeds
But implementation incomplete — only 1 of 3 fixes applied

#### Decision
Rejecting for Builder to complete all 3 required fixes:
1. ✓ Add --state=open (completed)
2. ✗ Add --sort=updated (missing)
3. ✗ Update window size to 1000x800 (missing)


## Critic Review (2026-05-09 09:22) — sort-by-activity task

### Event Context
Reviewing `review.ready - sort-by-activity: Added --sort=updated flag to both gh search commands in GitHubClient.swift`

### Fresh-Eyes Review Findings

**REJECTED** — One critical requirement still missing

#### Issue: Detail window size NOT updated
**File**: PRDesk/Views/DetailWindow.swift:16
**Current state**: `NSRect(x: 0, y: 0, width: 800, height: 600)`
**Required**: `NSRect(x: 0, y: 0, width: 1000, height: 800)`

The task description explicitly states:
> "In DetailWindow.swift, update the NSWindow contentRect initialization from NSRect(x: 0, y: 0, width: 800, height: 600) to NSRect(x: 0, y: 0, width: 1000, height: 800). This provides a more comfortable default size for reading PR details."

The Builder completed the --sort=updated change correctly in GitHubClient.swift (lines 22 and 59 both have `--sort=updated`), but did NOT make the required change to DetailWindow.swift.

#### Verification
- ✓ Build status: succeeds
- ✓ GitHubClient.swift lines 22, 59: Both have `--state=open` and `--sort=updated` flags
- ✗ DetailWindow.swift line 16: Still has 800x600, needs 1000x800

#### Decision
Rejecting task-1778282453-cc6a for Builder to apply the missing window size change.

The task requires ONE change: update DetailWindow.swift:16 from width=800,height=600 to width=1000,height=800.


## Critic Review (2026-05-09 09:25) — detail-window-size task

### Event Context
Reviewing `review.ready - detail-window-size: Updated NSWindow contentRect from 800x600 to 1000x800 in DetailWindow.swift:16`

### Fresh-Eyes Review Findings

**APPROVED** ✓

#### Verification Results

**1. Requirement Fidelity Check**
Task: "Increase detail window size from 800x600 to 1000x800"
- ✓ DetailWindow.swift:16 correctly updated to `NSRect(x: 0, y: 0, width: 1000, height: 800)`
- ✓ Change is minimal and focused on the exact requirement

**2. Code Review**
- ✓ No speculative code added
- ✓ Change follows KISS principle (single-line modification)
- ✓ Matches native codebase pattern (NSWindow initialization)

**3. Build Verification**
```
xcodebuild -project PRDesk.xcodeproj -scheme PRDesk build
** BUILD SUCCEEDED **
```

**4. Automated Verification**
Created verification script that:
- Parses DetailWindow.swift using regex
- Extracts width/height from NSRect initialization
- Result: ✓ Found 1000x800 as expected

#### All Three Bug Fixes Complete

Verified all three fixes from the objective are now implemented:

1. ✓ **Filter closed/merged PRs**: GitHubClient.swift:22,59 both use `--state=open`
2. ✓ **Sort by recent activity**: GitHubClient.swift:22,59 both use `--sort=updated`
3. ✓ **Fix detail window size**: DetailWindow.swift:16 uses `width: 1000, height: 800`

#### Decision
Approving task-1778282453-cc6a for Finalizer review.
All requirements met, build passes, implementation is clean and minimal.


## Finalization - Step 9 Complete (2026-05-09 09:30)

**Event received:** `review.passed - task-1778282453-cc6a approved`

### All Three Bug Fixes Verified Complete

**Final verification results:**

1. ✅ **Filter out closed/merged PRs** (Fix 1)
   - GitHubClient.swift:22 - `--state=open` flag present in fetchMyPRs()
   - GitHubClient.swift:59 - `--state=open` flag present in fetchReviewRequestedPRs()
   - Only OPEN PRs will be fetched from GitHub

2. ✅ **Sort by recent activity** (Fix 2)
   - GitHubClient.swift:22 - `--sort=updated` flag present in fetchMyPRs()
   - GitHubClient.swift:59 - `--sort=updated` flag present in fetchReviewRequestedPRs()
   - PRs ordered by most recent activity (newest first)

3. ✅ **Detail window size increased** (Fix 3)
   - DetailWindow.swift:16 - `width: 1000, height: 800` (was 800x600)
   - More comfortable default size for reading PR details

**Build status:** ✅ BUILD SUCCEEDED

**Acceptance criteria:** All met
- ✅ Closed/merged PRs filtered at GitHub CLI query level
- ✅ PRs sorted by recent activity
- ✅ Detail window opens at comfortable size (1000x800)
- ✅ All changes minimal and focused (KISS principle)
- ✅ Build succeeds

**Task status:** task-1778282453-cc6a CLOSED

### Step 9 - Additional Bug Fixes ✅ COMPLETE

**All tasks complete:**
- ✅ task-1778282451-6978: filter-closed-prs
- ✅ task-1778282451-7d3e: sort-by-activity  
- ✅ task-1778282453-cc6a: detail-window-size

**Step 9 Demo achieved:**
✅ PRs filtered to open only (--state=open)
✅ PRs sorted by recent activity (--sort=updated)
✅ Detail window opens at comfortable size (1000x800)
✅ Build succeeds
✅ All changes are minimal, focused, and KISS-compliant

### All 9 Steps Complete

The PR Desk application is now fully complete with all planned features and all bug fixes:

**Steps 1-8:** Previously completed (see progress.md)
**Step 9:** Bug fixes for filtering, sorting, and window size ✅

**No runtime tasks remain open.**

