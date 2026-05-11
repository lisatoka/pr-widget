#!/bin/bash
# Test if the toggle is present and works

killall PRDesk 2>/dev/null || true
sleep 1

# Reset UserDefaults
defaults delete com.prdesk.PRDesk launchAtLoginEnabled 2>/dev/null || true

APP_PATH=$(ls -td /Users/lisatok/Library/Developer/Xcode/DerivedData/PRDesk-*/Build/Products/Debug/PRDesk.app 2>/dev/null | head -1)
open "$APP_PATH"
sleep 3

osascript <<'EOF'
tell application "System Events"
    tell process "PRDesk"
        -- Click Settings menu
        set appMenu to menu 1 of menu bar item 2 of menu bar 1
        click menu item "Settings…" of appMenu
        delay 2

        -- Find the Preferences window
        set prefsWindow to window "PR Desk Preferences"

        tell prefsWindow
            log "=== Exploring PR Desk Preferences window ==="

            -- Get all UI elements recursively
            set allElements to entire contents
            log "Total elements: " & (count of allElements)

            -- Look for checkboxes/toggles
            set checkboxes to every checkbox
            log "Checkboxes found: " & (count of checkboxes)

            repeat with cb in checkboxes
                try
                    set cbTitle to title of cb
                    set cbValue to value of cb
                    set cbDesc to description of cb
                    log "Checkbox: title='" & cbTitle & "', value=" & cbValue & ", desc='" & cbDesc & "'"

                    -- If this is the Launch at Login toggle, click it
                    if cbTitle contains "Launch" then
                        log "Found Launch at Login toggle!"
                        log "Initial value: " & cbValue

                        -- Click to enable
                        click cb
                        delay 1

                        set newValue to value of cb
                        log "Value after first click: " & newValue

                        -- Click to disable
                        click cb
                        delay 1

                        set finalValue to value of cb
                        log "Value after second click: " & finalValue

                        if cbValue is not equal to newValue then
                            return "SUCCESS: Toggle works - changed from " & cbValue & " to " & newValue & " to " & finalValue
                        else
                            return "FAIL: Toggle didn't change value"
                        end if
                    end if
                on error errMsg
                    log "Error inspecting checkbox: " & errMsg
                end try
            end repeat

            -- Also try looking for buttons/switches
            set buttons to every button
            log "Buttons found: " & (count of buttons)

            repeat with btn in buttons
                try
                    set btnTitle to title of btn
                    set btnDesc to description of btn
                    if btnTitle contains "Launch" or btnDesc contains "Launch" then
                        log "Found button related to Launch: title='" & btnTitle & "', desc='" & btnDesc & "'"
                    end if
                on error errMsg
                    log "Error inspecting button: " & errMsg
                end try
            end repeat

            return "Search complete - check logs"
        end tell
    end tell
end tell
EOF

# Check UserDefaults after the test
sleep 2
DEFAULTS_VALUE=$(defaults read com.prdesk.PRDesk launchAtLoginEnabled 2>/dev/null || echo "NOT_SET")
echo ""
echo "UserDefaults after toggle test: $DEFAULTS_VALUE"

killall PRDesk 2>/dev/null || true
