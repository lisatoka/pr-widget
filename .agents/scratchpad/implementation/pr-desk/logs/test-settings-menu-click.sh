#!/bin/bash
# Test clicking the Settings menu item

killall PRDesk 2>/dev/null || true
sleep 1

APP_PATH=$(ls -td /Users/lisatok/Library/Developer/Xcode/DerivedData/PRDesk-*/Build/Products/Debug/PRDesk.app 2>/dev/null | head -1)
open "$APP_PATH"
sleep 3

osascript <<'EOF'
tell application "System Events"
    tell process "PRDesk"
        -- Access the app menu (second menu in menu bar)
        set appMenu to menu 1 of menu bar item 2 of menu bar 1

        log "App menu items:"
        repeat with mi in menu items of appMenu
            log "  - " & title of mi
        end repeat

        -- Click Settings...
        click menu item "Settings…" of appMenu
        delay 2

        -- Check what windows exist
        log "Windows after clicking Settings:"
        repeat with w in windows
            log "  - Window: " & name of w & " (class: " & class of w & ")"
        end repeat

        -- Try to find any window related to preferences or settings
        set foundPrefs to false
        repeat with w in windows
            set wName to name of w
            if wName contains "Preferences" or wName contains "Settings" or wName contains "PRDesk" then
                log "Found potential settings window: " & wName
                set foundPrefs to true

                -- List all elements in this window
                tell w
                    log "Window " & wName & " elements:"
                    try
                        set elementCount to count of UI elements
                        log "  Element count: " & elementCount

                        repeat with elem in UI elements
                            log "    - " & description of elem
                        end repeat
                    on error errMsg
                        log "  Error getting elements: " & errMsg
                    end try
                end tell
            end if
        end repeat

        if not foundPrefs then
            log "ERROR: No Preferences/Settings window found after clicking menu"
        end if
    end tell
end tell
EOF

killall PRDesk 2>/dev/null || true
