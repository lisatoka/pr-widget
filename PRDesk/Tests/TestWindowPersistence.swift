//
//  TestWindowPersistence.swift
//  PRDesk
//
//  Test harness for window position persistence
//

import AppKit
import SwiftUI

// Unit tests for position persistence logic
struct WindowPersistenceTests {
    static func runAll() -> Bool {
        var allPassed = true

        print("=== Window Persistence Tests ===\n")

        allPassed = testSavePosition() && allPassed
        allPassed = testRestorePosition() && allPassed
        allPassed = testInvalidPositionHandling() && allPassed
        allPassed = testOffScreenPositionHandling() && allPassed

        print("\n=== Test Summary ===")
        print(allPassed ? "✅ All tests passed" : "❌ Some tests failed")

        return allPassed
    }

    static func testSavePosition() -> Bool {
        print("Test: Save position to UserDefaults")

        let testKey = "test.window.position"
        UserDefaults.standard.removeObject(forKey: testKey)

        let testOrigin = NSPoint(x: 200, y: 300)
        let data = try? NSKeyedArchiver.archivedData(withRootObject: testOrigin, requiringSecureCoding: false)
        UserDefaults.standard.set(data, forKey: testKey)

        let retrieved = UserDefaults.standard.data(forKey: testKey)
        let decoded = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSValue.self, from: retrieved!)
        let point = decoded?.pointValue

        let passed = point == testOrigin
        print(passed ? "✅ PASS" : "❌ FAIL")
        if !passed {
            print("  Expected: \(testOrigin), Got: \(point?.debugDescription ?? "nil")")
        }

        UserDefaults.standard.removeObject(forKey: testKey)
        return passed
    }

    static func testRestorePosition() -> Bool {
        print("Test: Restore position from UserDefaults")

        let testKey = "test.window.restore"
        let savedOrigin = NSPoint(x: 150, y: 250)
        let data = try? NSKeyedArchiver.archivedData(withRootObject: savedOrigin, requiringSecureCoding: false)
        UserDefaults.standard.set(data, forKey: testKey)

        // Simulate restore
        guard let retrievedData = UserDefaults.standard.data(forKey: testKey),
              let decoded = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSValue.self, from: retrievedData) else {
            print("❌ FAIL - Could not retrieve data")
            UserDefaults.standard.removeObject(forKey: testKey)
            return false
        }

        let restoredPoint = decoded.pointValue
        let passed = restoredPoint == savedOrigin
        print(passed ? "✅ PASS" : "❌ FAIL")
        if !passed {
            print("  Expected: \(savedOrigin), Got: \(restoredPoint)")
        }

        UserDefaults.standard.removeObject(forKey: testKey)
        return passed
    }

    static func testInvalidPositionHandling() -> Bool {
        print("Test: Handle invalid position data")

        let testKey = "test.window.invalid"
        // Store invalid data
        UserDefaults.standard.set("not a point", forKey: testKey)

        // Try to retrieve - should handle gracefully
        let retrievedData = UserDefaults.standard.data(forKey: testKey)
        let decoded = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSValue.self, from: retrievedData ?? Data())

        let passed = decoded == nil
        print(passed ? "✅ PASS" : "❌ FAIL")
        if !passed {
            print("  Expected: nil, Got: \(decoded?.debugDescription ?? "non-nil")")
        }

        UserDefaults.standard.removeObject(forKey: testKey)
        return passed
    }

    static func testOffScreenPositionHandling() -> Bool {
        print("Test: Detect off-screen positions")

        guard let mainScreen = NSScreen.main else {
            print("⚠️  SKIP - No main screen available")
            return true
        }

        let screenFrame = mainScreen.visibleFrame

        // Test position far outside screen bounds
        let offScreenPoint = NSPoint(x: screenFrame.maxX + 1000, y: screenFrame.maxY + 1000)
        let isOffScreen = !screenFrame.contains(offScreenPoint)

        let passed = isOffScreen
        print(passed ? "✅ PASS" : "❌ FAIL")
        if !passed {
            print("  Expected: off-screen, but point was detected as on-screen")
        }

        return passed
    }
}

// Visual verification harness
@main
struct TestWindowPersistenceApp: App {
    var body: some Scene {
        WindowGroup {
            TestWindowPersistenceView()
        }
    }
}

struct TestWindowPersistenceView: View {
    @State private var testResults = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Window Position Persistence Test")
                .font(.title)

            Button("Run Tests") {
                let allPassed = WindowPersistenceTests.runAll()
                testResults = allPassed ? "All tests passed ✅" : "Some tests failed ❌"
            }

            if !testResults.isEmpty {
                Text(testResults)
                    .font(.headline)
                    .foregroundColor(testResults.contains("✅") ? .green : .red)
            }

            Text("Check console for detailed output")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}
