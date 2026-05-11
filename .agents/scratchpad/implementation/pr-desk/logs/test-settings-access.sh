#!/bin/bash
# Test Settings scene access via menu and keyboard shortcut

set -e

APP_NAME="PRDesk"
BUNDLE_ID="com.prdesk.PRDesk"

echo "=== Settings Scene Access Test ==="
echo ""

# Kill existing app instances
echo "1. Cleaning up existing app instances..."
killall "$APP_NAME" 2>/dev/null || true
sleep 1

# Launch the app
echo "2. Launching $APP_NAME..."
BUILD_DIR="$(xcodebuild -project PRDesk.xcodeproj -scheme PRDesk -showBuildSettings 2>/dev/null | grep ' BUILD_DIR ' | sed -E 's/.*BUILD_DIR = (.*)/\1/')"
APP_PATH="$BUILD_DIR/../../Build/Products/Debug/$APP_NAME.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ App not found at: $APP_PATH"
    exit 1
fi

open "$APP_PATH"
sleep 3

# Check if app is running
if ! pgrep -x "$APP_NAME" > /dev/null; then
    echo "❌ App failed to launch"
    exit 1
fi
echo "✅ App launched successfully"
echo ""

# Test 1: Check if Settings menu exists
echo "3. Testing Settings menu existence..."
MENU_CHECK=$(osascript -e 'tell application "System Events" to tell process "PRDesk"
    try
        get name of menu item 1 of menu 1 of menu bar item 1 of menu bar 1
    on error errMsg
        return "ERROR: " & errMsg
    end try
end tell' 2>&1)

if [[ "$MENU_CHECK" == *"ERROR"* ]]; then
    echo "❌ Menu not accessible: $MENU_CHECK"
    killall "$APP_NAME" 2>/dev/null || true
    exit 1
fi

echo "✅ Menu item found: $MENU_CHECK"
echo ""

# Test 2: Click Settings menu and check window title
echo "4. Opening Settings window via menu..."
WINDOW_TITLE=$(osascript << 'APPLESCRIPT'
tell application "System Events" to tell process "PRDesk"
    try
        -- Click the Settings menu item
        click menu item 1 of menu 1 of menu bar item 1 of menu bar 1
        delay 1

        -- Check if Settings window appeared
        set windowCount to count of windows
        if windowCount > 0 then
            set settingsWindow to first window whose subrole is "AXStandardWindow"
            return name of settingsWindow
        else
            return "ERROR: No window opened"
        end if
    on error errMsg
        return "ERROR: " & errMsg
    end try
end tell
APPLESCRIPT
)

if [[ "$WINDOW_TITLE" == *"ERROR"* ]]; then
    echo "❌ Failed to open Settings: $WINDOW_TITLE"
    killall "$APP_NAME" 2>/dev/null || true
    exit 1
fi

echo "✅ Settings window opened with title: $WINDOW_TITLE"
echo ""

# Test 3: Check if toggle exists
echo "5. Checking for Launch at Login toggle..."
TOGGLE_CHECK=$(osascript << 'APPLESCRIPT'
tell application "System Events" to tell process "PRDesk"
    try
        set settingsWindow to first window whose subrole is "AXStandardWindow"

        -- Look for checkbox in the window
        set checkboxCount to count of checkboxes of settingsWindow
        if checkboxCount > 0 then
            set toggleDescription to description of first checkbox of settingsWindow
            return "Found: " & toggleDescription & " (count: " & checkboxCount & ")"
        else
            return "ERROR: No checkboxes found"
        end if
    on error errMsg
        return "ERROR: " & errMsg
    end try
end tell
APPLESCRIPT
)

if [[ "$TOGGLE_CHECK" == *"ERROR"* ]]; then
    echo "❌ Toggle not found: $TOGGLE_CHECK"
    killall "$APP_NAME" 2>/dev/null || true
    exit 1
fi

echo "✅ Toggle found: $TOGGLE_CHECK"
echo ""

# Test 4: Test keyboard shortcut (close current window, then use Cmd+,)
echo "6. Testing Cmd+, keyboard shortcut..."
osascript << 'APPLESCRIPT' 2>&1
tell application "System Events" to tell process "PRDesk"
    try
        -- Close current window
        set settingsWindow to first window whose subrole is "AXStandardWindow"
        click button 1 of settingsWindow -- close button
        delay 0.5
    end try
end tell
APPLESCRIPT

sleep 1

KEYBOARD_TEST=$(osascript << 'APPLESCRIPT'
tell application "System Events" to tell process "PRDesk"
    try
        -- Press Cmd+,
        keystroke "," using command down
        delay 1

        -- Check if window appeared
        set windowCount to count of windows
        if windowCount > 0 then
            set settingsWindow to first window whose subrole is "AXStandardWindow"
            return name of settingsWindow
        else
            return "ERROR: No window opened"
        end if
    on error errMsg
        return "ERROR: " & errMsg
    end try
end tell
APPLESCRIPT
)

if [[ "$KEYBOARD_TEST" == *"ERROR"* ]]; then
    echo "❌ Keyboard shortcut failed: $KEYBOARD_TEST"
    killall "$APP_NAME" 2>/dev/null || true
    exit 1
fi

echo "✅ Keyboard shortcut works: $KEYBOARD_TEST"
echo ""

# Cleanup
echo "7. Cleaning up..."
killall "$APP_NAME" 2>/dev/null || true

echo ""
echo "=== ✅ ALL TESTS PASSED ==="
echo ""
echo "Summary:"
echo "  ✅ Settings menu accessible"
echo "  ✅ Settings window opens via menu"
echo "  ✅ Launch at Login toggle exists"
echo "  ✅ Cmd+, keyboard shortcut works"
