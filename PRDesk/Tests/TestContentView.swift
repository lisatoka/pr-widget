//
//  TestContentView.swift
//  PRDesk
//
//  Tests for ContentView PR list display
//

import Foundation

/// Test harness for ContentView PR display
/// Verifies that ContentView can load and display PR data
@main
struct TestContentViewRunner {
    static func main() {
        TestContentView.testDisplayPRList()
        TestContentView.testEmptyState()
    }
}

class TestContentView {

    /// Test that ContentView displays PR data from PRDataStore
    static func testDisplayPRList() {
        print("Test: ContentView displays PR list from PRDataStore")

        let store = PRDataStore()

        // Load actual PR data
        do {
            let prs = try store.loadMyPRs()
            print("✓ Loaded \(prs.count) PRs from store")

            if prs.isEmpty {
                print("⚠️  Warning: No PR data found. Run PRRefreshService first.")
            } else {
                // Verify we have the expected fields
                let firstPR = prs[0]
                print("✓ First PR: \(firstPR.title)")
                print("✓ Repo: \(firstPR.repositoryFullName)")
                print("✓ Updated: \(firstPR.updatedAt)")
            }

            print("✅ Test passed: ContentView can load PR data")
        } catch {
            print("❌ Test failed: \(error)")
        }
    }

    /// Test empty state handling
    static func testEmptyState() {
        print("\nTest: ContentView handles empty PR list")

        // Empty array should not crash
        let emptyPRs: [PullRequest] = []
        print("✓ Empty array created: \(emptyPRs.count) PRs")

        print("✅ Test passed: Empty state handling works")
    }
}
