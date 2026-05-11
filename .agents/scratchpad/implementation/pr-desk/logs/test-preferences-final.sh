#!/bin/bash
# Final Critic test harness for Launch at Login toggle feature
# Tests: Menu access, Preferences button, toggle functionality

set -e

APP_PATH="/Users/lisatok/Library/Developer/Xcode/DerivedData/PRDesk-*/Build/Products/Debug/PRDesk.app"
LOG_FILE="/Users/lisatok/not_work/git_widget/.agents/scratchpad/implementation/pr-desk/logs/test-preferences-final.log"

echo "=== Critic Final Test: Launch at Login Toggle ===" > "$LOG_FILE"
echo "Started at: $(date)" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Kill any running instance
echo "1. Killing existing PRDesk instances..." >> "$LOG_FILE"
killall PRDesk 2>/dev/null || true
sleep 2

# Reset UserDefaults to clean state
echo "2. Resetting UserDefaults..." >> "$LOG_FILE"
defaults delete com.prdesk.PRDesk launchAtLoginEnabled 2>/dev/null || true

# Launch the app
echo "3. Launching PRDesk..." >> "$LOG_FILE"
ACTUAL_APP=$(ls -td $APP_PATH 2>/dev/null | head -1)
if [ -z "$ACTUAL_APP" ]; then
    echo "ERROR: App not found at $APP_PATH" >> "$LOG_FILE"
    exit 1
fi
echo "   Found app at: $ACTUAL_APP" >> "$LOG_FILE"

open "$ACTUAL_APP"
sleep 3

# Verify app is running
echo "4. Verifying app is running..." >> "$LOG_FILE"
if ! pgrep -x "PRDesk" > /dev/null; then
    echo "ERROR: App failed to launch" >> "$LOG_FILE"
    exit 1
fi
echo "   ✓ App is running" >> "$LOG_FILE"

# Test 1: Access Preferences via menu
echo "" >> "$LOG_FILE"
echo "=== TEST 1: Access Preferences via Settings Menu ===" >> "$LOG_FILE"
osascript <<'EOF' 2>&1 | tee -a "$LOG_FILE"
tell application "System Events"
    tell process "PRDesk"
        -- Find the app menu
        set appMenu to menu 1 of menu bar 1
        set menuItemsList to name of every menu item of appMenu
        log "Menu items: " & (menuItemsList as string)

        -- Find Settings or Preferences menu item
        repeat with menuItem in menu items of appMenu
            set itemName to name of menuItem
            if itemName contains "Settings" or itemName contains "Preferences" then
                log "Found menu item: " & itemName
                click menuItem
                delay 1

                -- Check if Preferences window opened
                set windowNames to name of every window
                log "Windows after menu click: " & (windowNames as string)

                if (count of windows) > 0 then
                    repeat with w in windows
                        if name of w contains "Preferences" then
                            log "✓ Preferences window opened: " & name of w
                            return "PASS: Preferences accessible via menu"
                        end if
                    end repeat
                end if

                return "FAIL: Settings menu clicked but no Preferences window found"
            end if
        end repeat

        return "FAIL: No Settings/Preferences menu item found"
    end tell
end tell
EOF

TEST1_RESULT=$?
echo "Test 1 exit code: $TEST1_RESULT" >> "$LOG_FILE"

# Give time for window to appear
sleep 2

# Test 2: Verify toggle is present and functional
echo "" >> "$LOG_FILE"
echo "=== TEST 2: Verify Toggle Exists and Works ===" >> "$LOG_FILE"
osascript <<'EOF' 2>&1 | tee -a "$LOG_FILE"
tell application "System Events"
    tell process "PRDesk"
        -- Find Preferences window
        set prefWindow to missing value
        repeat with w in windows
            if name of w contains "Preferences" then
                set prefWindow to w
                exit repeat
            end if
        end repeat

        if prefWindow is missing value then
            return "FAIL: Preferences window not found"
        end if

        -- Find the toggle
        tell prefWindow
            set toggleFound to false
            set toggles to every checkbox

            repeat with t in toggles
                set toggleDesc to description of t
                set toggleTitle to title of t
                log "Found toggle: title=" & toggleTitle & ", description=" & toggleDesc

                if toggleTitle contains "Launch" or toggleDesc contains "Launch" then
                    set toggleFound to true

                    -- Get initial state
                    set initialValue to value of t
                    log "Initial toggle value: " & initialValue

                    -- Toggle it
                    click t
                    delay 1

                    -- Get new state
                    set newValue to value of t
                    log "New toggle value: " & newValue

                    if initialValue is not equal to newValue then
                        log "✓ Toggle changed from " & initialValue & " to " & newValue

                        -- Toggle back
                        click t
                        delay 1

                        set finalValue to value of t
                        log "Final toggle value: " & finalValue

                        if finalValue is equal to initialValue then
                            return "PASS: Toggle works correctly"
                        else
                            return "FAIL: Toggle didn't revert correctly"
                        end if
                    else
                        return "FAIL: Toggle state didn't change"
                    end if
                end if
            end repeat

            if not toggleFound then
                return "FAIL: Launch at Login toggle not found in Preferences window"
            end if
        end tell
    end tell
end tell
EOF

TEST2_RESULT=$?
echo "Test 2 exit code: $TEST2_RESULT" >> "$LOG_FILE"

# Test 3: Close Preferences and verify UserDefaults persistence
echo "" >> "$LOG_FILE"
echo "=== TEST 3: Verify UserDefaults Persistence ===" >> "$LOG_FILE"

# Close Preferences window
osascript <<'EOF' >> "$LOG_FILE" 2>&1
tell application "System Events"
    tell process "PRDesk"
        repeat with w in windows
            if name of w contains "Preferences" then
                click button 1 of w  -- Close button
                delay 1
            end if
        end repeat
    end tell
end tell
EOF

sleep 1

# Check UserDefaults
DEFAULTS_VALUE=$(defaults read com.prdesk.PRDesk launchAtLoginEnabled 2>/dev/null || echo "NOT_SET")
echo "UserDefaults value: $DEFAULTS_VALUE" >> "$LOG_FILE"

if [ "$DEFAULTS_VALUE" = "NOT_SET" ]; then
    echo "FAIL: UserDefaults not set after toggling" >> "$LOG_FILE"
else
    echo "✓ PASS: UserDefaults persisted (value: $DEFAULTS_VALUE)" >> "$LOG_FILE"
fi

# Test 4: Access Preferences via DetailWindow button
echo "" >> "$LOG_FILE"
echo "=== TEST 4: Access Preferences via DetailWindow Button ===" >> "$LOG_FILE"

# Click on a widget to open DetailWindow
osascript <<'EOF' >> "$LOG_FILE" 2>&1
tell application "System Events"
    tell process "PRDesk"
        -- Find a widget panel (may be named "My PRs" or "PRs I'm Tagged In")
        set widgetFound to false
        repeat with w in windows
            set wName to name of w
            if wName contains "My PRs" or wName contains "Tagged" then
                log "Found widget: " & wName
                -- Click anywhere on the widget to open DetailWindow
                click w
                delay 2
                set widgetFound to true
                exit repeat
            end if
        end repeat

        if not widgetFound then
            return "FAIL: No widget window found to click"
        end if

        -- Now look for DetailWindow
        repeat with w in windows
            if name of w is "PR Desk" then
                log "✓ DetailWindow opened"
                return "DetailWindow found"
            end if
        end repeat

        return "FAIL: DetailWindow didn't open after clicking widget"
    end tell
end tell
EOF

sleep 2

# Try to click Preferences button in DetailWindow
osascript <<'EOF' 2>&1 | tee -a "$LOG_FILE"
tell application "System Events"
    tell process "PRDesk"
        -- Find PR Desk window
        set detailWindow to missing value
        repeat with w in windows
            if name of w is "PR Desk" then
                set detailWindow to w
                exit repeat
            end if
        end repeat

        if detailWindow is missing value then
            return "FAIL: DetailWindow not found"
        end if

        -- Find and click Preferences button
        tell detailWindow
            set prefButtonFound to false
            set allButtons to every button

            repeat with btn in allButtons
                set btnName to name of btn
                set btnDesc to description of btn
                log "Found button: name=" & btnName & ", desc=" & btnDesc

                if btnName contains "Preferences" or btnDesc contains "Preferences" then
                    set prefButtonFound to true
                    log "Found Preferences button, clicking..."
                    click btn
                    delay 2

                    -- Check if Preferences window opened
                    tell process "PRDesk"
                        repeat with w in windows
                            if name of w contains "Preferences" then
                                log "✓ Preferences window opened via DetailWindow button"
                                return "PASS: DetailWindow Preferences button works"
                            end if
                        end repeat
                    end tell

                    return "FAIL: Clicked Preferences button but window didn't open"
                end if
            end repeat

            if not prefButtonFound then
                return "FAIL: Preferences button not found in DetailWindow"
            end if
        end tell
    end tell
end tell
EOF

TEST4_RESULT=$?
echo "Test 4 exit code: $TEST4_RESULT" >> "$LOG_FILE"

# Cleanup
echo "" >> "$LOG_FILE"
echo "=== CLEANUP ===" >> "$LOG_FILE"
killall PRDesk 2>/dev/null || true
echo "Test completed at: $(date)" >> "$LOG_FILE"

echo "" >> "$LOG_FILE"
echo "=== SUMMARY ===" >> "$LOG_FILE"
echo "Check the log above for PASS/FAIL results for each test." >> "$LOG_FILE"

cat "$LOG_FILE"
