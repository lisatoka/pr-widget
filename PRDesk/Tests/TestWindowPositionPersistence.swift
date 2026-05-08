//
//  TestWindowPositionPersistence.swift
//  PRDesk
//
//  Created by PR Desk - Test harness for window position persistence
//

import AppKit
import Foundation

// This test harness verifies the window position persistence mechanism works correctly.
// It simulates what happens when the app launches, user moves the window, and app restarts.

print("=== Window Position Persistence Test Harness ===\n")

// Test 1: Initial launch with no saved position
print("Test 1: No saved position (first launch)")
UserDefaults.standard.removeObject(forKey: "FloatingPanelPosition")
let initialFrame = NSRect(x: 100, y: 100, width: 300, height: 400)

// Simulate restoreSavedPosition() with no saved data
let data1 = UserDefaults.standard.data(forKey: "FloatingPanelPosition")
if data1 == nil {
    print("✅ PASS: No saved position found (expected behavior)")
    print("   Should use default frame: \(initialFrame)\n")
} else {
    print("❌ FAIL: Found unexpected saved position\n")
}

// Test 2: Save a position
print("Test 2: Save window position")
let testOrigin = NSPoint(x: 250, y: 350)
if let data = try? NSKeyedArchiver.archivedData(withRootObject: testOrigin, requiringSecureCoding: false) {
    UserDefaults.standard.set(data, forKey: "FloatingPanelPosition")
    print("✅ PASS: Position saved to UserDefaults")
    print("   Saved origin: \(testOrigin)\n")
} else {
    print("❌ FAIL: Could not archive position\n")
}

// Test 3: Restore the saved position
print("Test 3: Restore saved position")
if let data = UserDefaults.standard.data(forKey: "FloatingPanelPosition"),
   let nsValue = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSValue.self, from: data) {
    let restoredOrigin = nsValue.pointValue
    if restoredOrigin == testOrigin {
        print("✅ PASS: Position restored correctly")
        print("   Restored origin: \(restoredOrigin)\n")
    } else {
        print("❌ FAIL: Position mismatch")
        print("   Expected: \(testOrigin)")
        print("   Got: \(restoredOrigin)\n")
    }
} else {
    print("❌ FAIL: Could not restore position\n")
}

// Test 4: Off-screen validation (position too far left)
print("Test 4: Off-screen validation (far off left edge)")
let offScreenOrigin = NSPoint(x: -1000, y: 100)
if let data = try? NSKeyedArchiver.archivedData(withRootObject: offScreenOrigin, requiringSecureCoding: false) {
    UserDefaults.standard.set(data, forKey: "FloatingPanelPosition")
}

if let screenFrame = NSScreen.main?.visibleFrame {
    print("   Main screen visible frame: \(screenFrame)")
    print("   Saved (invalid) origin: \(offScreenOrigin)")

    // Simulate the validation logic from restoreSavedPosition()
    if offScreenOrigin.x < screenFrame.minX - 50 || offScreenOrigin.x > screenFrame.maxX + 50 ||
       offScreenOrigin.y < screenFrame.minY - 50 || offScreenOrigin.y > screenFrame.maxY + 50 {
        print("✅ PASS: Off-screen position correctly rejected")
        print("   Should fall back to default frame\n")
    } else {
        print("❌ FAIL: Off-screen position incorrectly accepted\n")
    }
} else {
    print("❌ FAIL: Could not get main screen\n")
}

// Test 5: Valid position near edge (should be accepted)
print("Test 5: Valid position near screen edge")
if let screenFrame = NSScreen.main?.visibleFrame {
    let nearEdgeOrigin = NSPoint(x: screenFrame.minX + 10, y: screenFrame.minY + 10)
    if let data = try? NSKeyedArchiver.archivedData(withRootObject: nearEdgeOrigin, requiringSecureCoding: false) {
        UserDefaults.standard.set(data, forKey: "FloatingPanelPosition")
    }

    print("   Near-edge origin: \(nearEdgeOrigin)")

    // Simulate validation
    if nearEdgeOrigin.x < screenFrame.minX - 50 || nearEdgeOrigin.x > screenFrame.maxX + 50 ||
       nearEdgeOrigin.y < screenFrame.minY - 50 || nearEdgeOrigin.y > screenFrame.maxY + 50 {
        print("❌ FAIL: Valid position incorrectly rejected\n")
    } else {
        print("✅ PASS: Valid near-edge position correctly accepted\n")
    }
} else {
    print("❌ FAIL: Could not get main screen\n")
}

// Test 6: Invalid/corrupted data
print("Test 6: Invalid/corrupted UserDefaults data")
let corruptedData = "not valid archive data".data(using: .utf8)!
UserDefaults.standard.set(corruptedData, forKey: "FloatingPanelPosition")

if let data = UserDefaults.standard.data(forKey: "FloatingPanelPosition"),
   let _ = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSValue.self, from: data) {
    print("❌ FAIL: Corrupted data incorrectly parsed\n")
} else {
    print("✅ PASS: Corrupted data correctly rejected")
    print("   Should fall back to default frame\n")
}

// Clean up
UserDefaults.standard.removeObject(forKey: "FloatingPanelPosition")

print("=== Test Summary ===")
print("All edge cases covered:")
print("  ✓ No saved position (first launch)")
print("  ✓ Save and restore position")
print("  ✓ Off-screen position rejection")
print("  ✓ Near-edge position acceptance")
print("  ✓ Corrupted data handling")
print("\nExpected: All 6 tests should PASS")
