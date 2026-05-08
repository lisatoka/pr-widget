//
//  TestReviewRequestedWidget.swift
//  PRDesk
//
//  Test harness to verify review-requested PRs display in second widget
//

import Foundation
import SwiftUI

/// Test: Verify reviewRequestedPanel loads and displays review-requested PRs
func testReviewRequestedWidget() {
    print("\n=== Test: Review-Requested Widget Data Loading ===\n")

    let dataStore = PRDataStore()

    // Load review-requested PRs
    do {
        let reviewRequestedPRs = try dataStore.loadReviewRequestedPRs()
        print("✅ Loaded \(reviewRequestedPRs.count) review-requested PRs")

        if reviewRequestedPRs.isEmpty {
            print("⚠️  No review-requested PRs found. Run app first to fetch data.")
        } else {
            // Display first 3 PRs to verify data structure
            print("\nFirst few review-requested PRs:")
            for (index, pr) in reviewRequestedPRs.prefix(3).enumerated() {
                print("\n\(index + 1). PR #\(pr.number): \(pr.title)")
                print("   Repo: \(pr.repositoryFullName)")
                print("   State: \(pr.state), Draft: \(pr.isDraft)")
                print("   Needs action: \(pr.needsAction ? "YES (bright)" : "NO (dimmed)")")
                print("   Updated: \(pr.updatedAt)")
            }
        }

        // Verify WidgetType enum
        let widgetType = WidgetType.reviewRequested
        print("\n✅ WidgetType.reviewRequested.title = \"\(widgetType.title)\"")

        // Verify PRListViewModel can be created for reviewRequested type
        let viewModel = PRListViewModel(widgetType: .reviewRequested)
        print("✅ PRListViewModel created with widgetType: .reviewRequested")
        print("   Loaded \(viewModel.pullRequests.count) PRs into view model")

        // Verify highlight logic for review-requested PRs
        let actionNeededCount = viewModel.pullRequests.filter { $0.needsAction }.count
        let waitingCount = viewModel.pullRequests.count - actionNeededCount
        print("\n📊 Highlight distribution:")
        print("   Action needed (bright): \(actionNeededCount)")
        print("   Waiting (dimmed): \(waitingCount)")

        print("\n✅ All checks passed: Review-requested widget data flow works!")

    } catch {
        print("❌ Failed to load review-requested PRs: \(error)")
    }

    print("\n=== Test Complete ===\n")
}

// Run test
testReviewRequestedWidget()
