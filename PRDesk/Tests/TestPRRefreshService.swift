//
//  TestPRRefreshService.swift
//  PRDesk
//
//  Test harness for PRRefreshService
//

import Foundation

@main
struct TestPRRefreshService {
    static func main() async {
        print("=== PRRefreshService Test Harness ===\n")

        await testBasicRefresh()
        await testRefreshPersistence()

        print("\n=== All tests complete ===")
    }

    static func testBasicRefresh() async {
        print("Test 1: Basic refresh operation")

        let service = PRRefreshService()

        do {
            try await service.refresh()
            print("✅ Refresh completed successfully")
        } catch {
            print("❌ Refresh failed: \(error)")
        }
    }

    static func testRefreshPersistence() async {
        print("\nTest 2: Refresh persists data to store")

        let service = PRRefreshService()
        let store = PRDataStore()

        do {
            // Refresh should fetch and save
            try await service.refresh()

            // Load from store to verify persistence
            let myPRs = try store.loadMyPRs()
            let reviewPRs = try store.loadReviewRequestedPRs()

            print("✅ Loaded \(myPRs.count) myPRs from store")
            print("✅ Loaded \(reviewPRs.count) review-requested PRs from store")

            // Verify data structure
            if let firstPR = myPRs.first {
                print("✅ First myPR: #\(firstPR.number) - \(firstPR.title)")
            }

            if let firstReviewPR = reviewPRs.first {
                print("✅ First review PR: #\(firstReviewPR.number) - \(firstReviewPR.title)")
            }
        } catch {
            print("❌ Test failed: \(error)")
        }
    }
}
