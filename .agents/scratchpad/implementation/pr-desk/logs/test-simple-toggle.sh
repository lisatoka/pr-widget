#!/bin/bash
# Simple toggle test

killall PRDesk 2>/dev/null || true
sleep 1
defaults delete com.prdesk.PRDesk launchAtLoginEnabled 2>/dev/null || true

APP_PATH=$(ls -td /Users/lisatok/Library/Developer/Xcode/DerivedData/PRDesk-*/Build/Products/Debug/PRDesk.app 2>/dev/null | head -1)
open "$APP_PATH"
sleep 4

osascript <<'EOF'
tell application "System Events"
    tell process "PRDesk"
        -- Open Settings
        set appMenu to menu 1 of menu bar item 2 of menu bar 1
        click menu item "Settings…" of appMenu
        delay 3

        set prefsWindow to window "PR Desk Preferences"

        tell prefsWindow
            -- Try to find checkbox by iterating groups
            try
                set theGroups to every group
                log "Groups count: " & (count of theGroups)

                repeat with g in theGroups
                    try
                        set groupCheckboxes to every checkbox of g
                        if (count of groupCheckboxes) > 0 then
                            log "Found group with checkboxes"

                            repeat with cb in groupCheckboxes
                                set cbTitle to title of cb
                                set cbValue to value of cb
                                log "Checkbox: '" & cbTitle & "' value=" & cbValue

                                -- Toggle it twice
                                click cb
                                delay 1
                                set val1 to value of cb
                                log "After first click: " & val1

                                click cb
                                delay 1
                                set val2 to value of cb
                                log "After second click: " & val2

                                return "Toggled checkbox '" & cbTitle & "'"
                            end repeat
                        end if
                    end try
                end repeat
            on error errMsg
                log "Error: " & errMsg
            end try

            return "Done"
        end tell
    end tell
end tell
EOF

sleep 2
echo ""
echo "UserDefaults: $(defaults read com.prdesk.PRDesk launchAtLoginEnabled 2>/dev/null || echo 'NOT_SET')"

killall PRDesk 2>/dev/null || true
