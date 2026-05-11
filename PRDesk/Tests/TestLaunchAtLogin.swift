//
//  TestLaunchAtLogin.swift
//  PRDesk
//
//  Test harness for Launch at Login functionality
//

/*
TEST PLAN: Launch at Login Toggle

This test harness verifies that the Launch at Login functionality works correctly.

Manual Testing Steps:

1. Build and run the app:
   xcodebuild -project PRDesk.xcodeproj -scheme PRDesk -configuration Debug build
   open ~/Library/Developer/Xcode/DerivedData/PRDesk-*/Build/Products/Debug/PRDesk.app

2. Open Settings/Preferences window:
   - Look for "Preferences..." menu item in app menu
   - OR right-click on widget and look for preferences option
   - Window should appear with "Launch at Login" toggle

3. Verify current state display:
   - Toggle should show current launch-at-login status
   - Status should be accurate (check System Settings > Login Items)

4. Test enabling:
   - If toggle is OFF, click to enable
   - App should register with ServiceManagement
   - Verify in System Settings > Login Items that PRDesk appears

5. Test disabling:
   - If toggle is ON, click to disable
   - App should unregister from ServiceManagement
   - Verify in System Settings > Login Items that PRDesk is removed

6. Test persistence:
   - Enable launch at login
   - Quit app
   - Relaunch app
   - Open preferences - toggle should still show enabled
   - Check UserDefaults:
     defaults read com.prdesk.PRDesk launchAtLoginEnabled

7. Test actual launch at login:
   - Enable launch at login
   - Quit app
   - Log out and log back in
   - App should launch automatically

Expected Behavior:
✅ Preferences window accessible from menu
✅ Toggle shows current status accurately
✅ Enable/disable works via SMAppService
✅ Setting persists in UserDefaults
✅ App launches automatically when enabled
✅ Build succeeds without errors

Implementation Requirements:
- PreferencesWindow.swift or Settings view
- Use ServiceManagement framework (import ServiceManagement)
- SMAppService.mainApp for registration
- UserDefaults key: "launchAtLoginEnabled"
- Menu item or keyboard shortcut to open preferences
- Toggle UI element (Toggle in SwiftUI or NSButton in AppKit)
*/
