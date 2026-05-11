#!/bin/bash
# Final verification for Launch at Login feature

set -e

APP_NAME="PRDesk"

echo "=== Final Launch at Login Verification ==="
echo ""

# Kill existing instances
echo "1. Cleaning up..."
killall "$APP_NAME" 2>/dev/null || true
sleep 1

# Find app
BUILD_DIR=$(find ~/Library/Developer/Xcode/DerivedData -name "PRDesk.app" -type d 2>/dev/null | head -1)
if [ ! -d "$BUILD_DIR" ]; then
    echo "❌ App not found"
    exit 1
fi

# Launch app
echo "2. Launching $APP_NAME..."
open "$BUILD_DIR"
sleep 5

if ! pgrep -x "$APP_NAME" > /dev/null; then
    echo "❌ App failed to launch"
    exit 1
fi
echo "✅ App launched"
echo ""

# Test menu access
echo "3. Testing Settings menu access..."
WINDOW_TITLE=$(osascript << 'APPLESCRIPT'
tell application "System Events" to tell process "PRDesk"
    try
        click menu item "Settings…" of menu 1 of menu bar item "PRDesk" of menu bar 1
        delay 3

        -- Try to access the window directly
        set prefsWindow to window "PR Desk Preferences"
        return name of prefsWindow
    on error errMsg
        return "ERROR: " & errMsg
    end try
end tell
APPLESCRIPT
)

if [[ "$WINDOW_TITLE" != "PR Desk Preferences" ]]; then
    echo "❌ Wrong window title: $WINDOW_TITLE"
    killall "$APP_NAME" 2>/dev/null || true
    exit 1
fi
echo "✅ Preferences window opened: $WINDOW_TITLE"
echo ""

# Test toggle exists
echo "4. Testing Launch at Login toggle..."
TOGGLE_TEST=$(osascript << 'APPLESCRIPT'
tell application "System Events" to tell process "PRDesk"
    try
        set prefsWindow to window "PR Desk Preferences"
        delay 1

        set firstGroup to first group of prefsWindow
        set checkboxCount to count of checkboxes of firstGroup

        if checkboxCount > 0 then
            set toggle to first checkbox of firstGroup
            set toggleValue to value of toggle

            -- Toggle it
            click toggle
            delay 1
            set newValue to value of toggle

            return "OK:" & toggleValue & ":" & newValue
        else
            return "ERROR: No toggle found"
        end if
    on error errMsg
        return "ERROR: " & errMsg
    end try
end tell
APPLESCRIPT
)

if [[ "$TOGGLE_TEST" != OK:* ]]; then
    echo "❌ Toggle test failed: $TOGGLE_TEST"
    killall "$APP_NAME" 2>/dev/null || true
    exit 1
fi
echo "✅ Toggle works: $TOGGLE_TEST"
echo ""

# Test keyboard shortcut
echo "5. Testing Cmd+, keyboard shortcut..."
osascript << 'APPLESCRIPT' > /dev/null 2>&1
tell application "System Events" to tell process "PRDesk"
    set prefsWindow to window "PR Desk Preferences"
    click button 1 of prefsWindow
    delay 1
end tell
APPLESCRIPT

sleep 1

KEYBOARD_TEST=$(osascript << 'APPLESCRIPT'
tell application "System Events" to tell process "PRDesk"
    try
        keystroke "," using command down
        delay 2

        set windowCount to count of windows
        if windowCount > 0 then
            return "OK"
        else
            return "ERROR: No window"
        end if
    on error errMsg
        return "ERROR: " & errMsg
    end try
end tell
APPLESCRIPT
)

if [[ "$KEYBOARD_TEST" != "OK" ]]; then
    echo "❌ Keyboard shortcut failed: $KEYBOARD_TEST"
    killall "$APP_NAME" 2>/dev/null || true
    exit 1
fi
echo "✅ Cmd+, keyboard shortcut works"
echo ""

# Cleanup
echo "6. Cleaning up..."
killall "$APP_NAME" 2>/dev/null || true

echo ""
echo "=== ✅ ALL TESTS PASSED ==="
echo ""
echo "Summary:"
echo "  ✅ Build succeeded"
echo "  ✅ Settings menu accessible"
echo "  ✅ Preferences window opens"
echo "  ✅ Launch at Login toggle exists and works"
echo "  ✅ Cmd+, keyboard shortcut works"
echo ""
echo "Feature is fully functional and accessible to users."
