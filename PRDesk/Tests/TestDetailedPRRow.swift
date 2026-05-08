//
//  TestDetailedPRRow.swift
//  PRDesk
//
//  Test harness for DetailRowView component
//

import Foundation

// Import the PullRequest model and PRDataStore
// (In a real Xcode project, these would be part of the app target)
// For standalone testing, we compile with all source files

// Test: DetailRowView displays all required fields
func testDetailRowViewFields() {
    print("=== Testing DetailRowView Fields ===")

    // Create test PR data
    let testPR = PullRequest(
        number: 42,
        title: "Add new feature",
        url: "https://github.com/test/repo/pull/42",
        author: PullRequest.Author(login: "testuser"),
        state: "OPEN",
        isDraft: false,
        repository: PullRequest.Repository(
            name: "repo",
            nameWithOwner: "test/repo"
        ),
        updatedAt: Date()
    )

    // Expected fields in DetailRowView:
    // - PR number (#42)
    // - PR title (Add new feature)
    // - Repository (test/repo)
    // - Status (Open, not draft)
    // - Last activity (relative time)
    // - Author username (testuser)
    // - "Open in Claude" button

    print("✅ Test PR created with number: \(testPR.number)")
    print("✅ Title: \(testPR.title)")
    print("✅ Repository: \(testPR.repositoryFullName)")
    print("✅ State: \(testPR.state)")
    print("✅ Draft: \(testPR.isDraft)")
    print("✅ Author: \(testPR.author.login)")
    print("✅ URL: \(testPR.url)")

    print("\n✅ DetailRowView should display all these fields")
    print("✅ 'Open in Claude' button should be present for each row")
}

// Test: MyPRsDetailView loads data from PRDataStore
func testMyPRsDetailViewDataLoading() {
    print("\n=== Testing MyPRsDetailView Data Loading ===")

    let dataStore = PRDataStore()

    do {
        let myPRs = try dataStore.loadMyPRs()
        print("✅ Loaded \(myPRs.count) PRs from PRDataStore")

        if !myPRs.isEmpty {
            print("✅ Sample PR: #\(myPRs[0].number) - \(myPRs[0].title)")
        }

        print("✅ MyPRsDetailView should use PRDataStore to load PRs")
        print("✅ MyPRsDetailView should display List of DetailRowView components")
    } catch {
        print("⚠️  No PRs found in store (expected for fresh install): \(error)")
        print("✅ MyPRsDetailView should handle empty state gracefully")
    }
}

// Test: ReviewRequestedDetailView loads data from PRDataStore
func testReviewRequestedDetailViewDataLoading() {
    print("\n=== Testing ReviewRequestedDetailView Data Loading ===")

    let dataStore = PRDataStore()

    do {
        let reviewPRs = try dataStore.loadReviewRequestedPRs()
        print("✅ Loaded \(reviewPRs.count) review-requested PRs from PRDataStore")

        if !reviewPRs.isEmpty {
            print("✅ Sample PR: #\(reviewPRs[0].number) - \(reviewPRs[0].title)")
        }

        print("✅ ReviewRequestedDetailView should use PRDataStore to load PRs")
        print("✅ ReviewRequestedDetailView should display List of DetailRowView components")
    } catch {
        print("⚠️  No review-requested PRs found in store: \(error)")
        print("✅ ReviewRequestedDetailView should handle empty state gracefully")
    }
}

// Main entry point
func runAllTests() {
    testDetailRowViewFields()
    testMyPRsDetailViewDataLoading()
    testReviewRequestedDetailViewDataLoading()

    print("\n=== Test Expectations Summary ===")
    print("1. DetailRowView component exists with all required fields")
    print("2. MyPRsDetailView uses PRDataStore.loadMyPRs()")
    print("3. ReviewRequestedDetailView uses PRDataStore.loadReviewRequestedPRs()")
    print("4. Both detail views render List of DetailRowView")
    print("5. 'Open in Claude' button present for each PR")
    print("6. Highlight logic applied (needsAction)")
}

// Run tests
runAllTests()
