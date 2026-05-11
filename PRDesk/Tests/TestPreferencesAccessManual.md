# Manual Test: Preferences Access

## Purpose
Verify that users can access the Preferences window from the DetailWindow UI.

## Prerequisites
1. Build and launch PRDesk app
2. App should show two desktop widgets: "My PRs" and "PRs I'm Tagged In"

## Test Steps

### Test 1: Open DetailWindow and Find Preferences Button
1. Click on either desktop widget to open the DetailWindow
2. Look at the header area (top of the window)
3. **Expected:** You should see a "Preferences" button with a gear icon in the top-right corner
4. **Expected:** The button should be next to "Last updated X time ago" text

### Test 2: Click Preferences Button
1. Click the "Preferences" button in the DetailWindow header
2. **Expected:** A new window titled "PR Desk Preferences" should open
3. **Expected:** The Preferences window should contain:
   - A "Launch at Login" toggle switch
   - Toggle should be in the current state (off by default for new installations)

### Test 3: Verify Launch at Login Toggle Works
1. In the Preferences window, click the "Launch at Login" toggle to enable it
2. **Expected:** Toggle should switch to the ON state
3. **Expected:** No error message should appear
4. Close the Preferences window
5. Quit the PRDesk app (Cmd+Q or right-click Quit from Dock)
6. Verify state persisted:
   ```bash
   defaults read com.prdesk.PRDesk launchAtLoginEnabled
   ```
7. **Expected:** Should output `1` (true)

### Test 4: Verify State Persists Across App Restarts
1. Relaunch PRDesk app
2. Click on a widget to open DetailWindow
3. Click the Preferences button
4. **Expected:** The "Launch at Login" toggle should still be ON
5. Toggle it OFF
6. **Expected:** Toggle switches to OFF state
7. Close Preferences, quit app, relaunch
8. Open Preferences again
9. **Expected:** Toggle should now be OFF

### Test 5: Keyboard Shortcut (Alternative Access)
1. With PRDesk running, press Cmd+, (Command + Comma)
2. **Expected:** Preferences window should open
3. This provides an alternative way to access Preferences for users familiar with macOS conventions

## Success Criteria
- ✅ Preferences button is visible in DetailWindow header
- ✅ Button has a gear icon and "Preferences" label
- ✅ Clicking button opens Preferences window
- ✅ Launch at Login toggle is functional
- ✅ Toggle state persists across app restarts
- ✅ Cmd+, keyboard shortcut also works

## Failure Scenarios
- ❌ Preferences button is not visible → FAIL
- ❌ Button does not open window → FAIL
- ❌ Toggle does not work → FAIL
- ❌ State does not persist → FAIL

## Notes
- The Preferences button in DetailWindow is the primary access point for users
- The Cmd+, shortcut is a secondary access method for power users
- This addresses the issue where the app menu was inaccessible because the app runs as a desktop widget without a menu bar
