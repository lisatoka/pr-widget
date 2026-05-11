#!/bin/bash
# Inspect PRDesk app menu structure

killall PRDesk 2>/dev/null || true
sleep 1

APP_PATH=$(ls -td /Users/lisatok/Library/Developer/Xcode/DerivedData/PRDesk-*/Build/Products/Debug/PRDesk.app 2>/dev/null | head -1)
open "$APP_PATH"
sleep 3

osascript <<'EOF'
tell application "System Events"
    tell process "PRDesk"
        -- Get all menu bars
        log "Menu bar count: " & (count of menu bars)

        repeat with mb in menu bars
            log "=== Menu Bar ==="

            -- Get all menus
            repeat with m in menus of mb
                set menuTitle to title of m
                log "Menu: " & menuTitle

                -- Get all menu items in this menu
                repeat with mi in menu items of m
                    set miName to name of mi
                    set miTitle to title of mi
                    log "  - Menu item: " & miName & " (title: " & miTitle & ")"
                end repeat
            end repeat
        end repeat
    end tell
end tell
EOF

killall PRDesk 2>/dev/null || true
