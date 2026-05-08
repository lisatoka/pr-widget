//
//  TestTwoWidgets.swift
//  PRDesk
//
//  Test harness to verify two separate FloatingPanel instances can be created
//  and displayed simultaneously with offset positions.
//

import AppKit
import SwiftUI

/// Test harness: Create two separate FloatingPanel instances
func testTwoWidgetsDisplay() {
    print("🧪 Testing two widget display...")

    // Create first panel with unique position key
    let frame1 = NSRect(x: 100, y: 100, width: 300, height: 400)
    let panel1 = FloatingPanelController(
        content: ContentView(widgetType: .myPRs),
        frame: frame1,
        positionKey: "MyPRsPanelPosition"
    )
    panel1.show()

    // Create second panel with offset position and unique position key
    let frame2 = NSRect(x: 420, y: 100, width: 300, height: 400)
    let panel2 = FloatingPanelController(
        content: ContentView(widgetType: .reviewRequested),
        frame: frame2,
        positionKey: "ReviewRequestedPanelPosition"
    )
    panel2.show()

    // Verify both are visible
    assert(panel1.isVisible, "❌ Panel 1 should be visible")
    assert(panel2.isVisible, "❌ Panel 2 should be visible")

    print("✅ Both panels created and visible")
    print("   Panel 1: x=\(frame1.origin.x), y=\(frame1.origin.y) [key: MyPRsPanelPosition]")
    print("   Panel 2: x=\(frame2.origin.x), y=\(frame2.origin.y) [key: ReviewRequestedPanelPosition]")
    print("   Offset: \(frame2.origin.x - frame1.origin.x) pixels")
}
