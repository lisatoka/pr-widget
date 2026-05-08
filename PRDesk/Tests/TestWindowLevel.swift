//
//  TestWindowLevel.swift
//  PRDesk
//
//  Test harness for window level verification
//

/*
 Manual verification for window level fix:

 1. BUILD THE APP
    xcodebuild -project PRDesk.xcodeproj -scheme PRDesk -configuration Debug build

 2. LAUNCH THE APP
    open ~/Library/Developer/Xcode/DerivedData/PRDesk-*/Build/Products/Debug/PRDesk.app

 3. TEST DESKTOP BACKGROUND BEHAVIOR:
    a. Verify widgets appear on the desktop
    b. Click on another app window (e.g., Finder, Safari)
    c. Expected: Other app windows should appear ABOVE the PR Desk widgets
    d. Expected: Widgets should remain visible on desktop background
    e. Expected: Widgets should NOT float above other windows

 4. TEST DRAGGING:
    a. Click and drag widget on desktop
    b. Expected: Widget should move smoothly
    c. Expected: Widget should remain at desktop level during drag

 5. VERIFY WINDOW LEVEL:
    Expected: FloatingPanel.level should be below normal window level
    Incorrect: .floating (level 3) - floats above all windows
    Correct: .normal - 1 (level -1) - sits on desktop background
    Correct: NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))

 SUCCESS CRITERIA:
 - Build succeeds
 - Widgets sit on desktop background
 - Other app windows appear above widgets
 - Widgets remain draggable
 - Widgets visible but not intrusive
 */
