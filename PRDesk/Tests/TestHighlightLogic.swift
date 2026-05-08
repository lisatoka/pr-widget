//
//  TestHighlightLogic.swift
//  PRDesk
//
//  Test harness for PR highlight state logic
//

import Foundation

@main
struct TestHighlightLogic {
    static func main() {
        testHighlightLogic()
    }
}

// Test the needsAction logic for PR highlighting
func testHighlightLogic() {
    print("=== Testing PR Highlight Logic ===\n")

    // Test case 1: Open non-draft PR (should need action - bright)
    let actionNeededPR = PullRequest(
        number: 123,
        title: "Fix: critical bug in auth",
        url: "https://github.com/test/repo/pull/123",
        author: PullRequest.Author(login: "testuser"),
        state: "OPEN",
        isDraft: false,
        repository: PullRequest.Repository(name: "repo", nameWithOwner: "test/repo"),
        updatedAt: Date()
    )

    print("Test 1: Open non-draft PR")
    print("  isDraft: \(actionNeededPR.isDraft)")
    print("  state: \(actionNeededPR.state)")
    print("  needsAction: \(actionNeededPR.needsAction)")
    print("  Expected: true (bright)")
    assert(actionNeededPR.needsAction == true, "Open non-draft PR should need action")
    print("  ✅ PASS\n")

    // Test case 2: Draft PR (should be waiting - dimmed)
    let waitingPR = PullRequest(
        number: 456,
        title: "WIP: new feature",
        url: "https://github.com/test/repo/pull/456",
        author: PullRequest.Author(login: "testuser"),
        state: "OPEN",
        isDraft: true,
        repository: PullRequest.Repository(name: "repo", nameWithOwner: "test/repo"),
        updatedAt: Date()
    )

    print("Test 2: Draft PR")
    print("  isDraft: \(waitingPR.isDraft)")
    print("  state: \(waitingPR.state)")
    print("  needsAction: \(waitingPR.needsAction)")
    print("  Expected: false (dimmed)")
    assert(waitingPR.needsAction == false, "Draft PR should be waiting (not need action)")
    print("  ✅ PASS\n")

    // Test case 3: Closed PR (should not need action - dimmed)
    let closedPR = PullRequest(
        number: 789,
        title: "Merged: old feature",
        url: "https://github.com/test/repo/pull/789",
        author: PullRequest.Author(login: "testuser"),
        state: "CLOSED",
        isDraft: false,
        repository: PullRequest.Repository(name: "repo", nameWithOwner: "test/repo"),
        updatedAt: Date()
    )

    print("Test 3: Closed PR")
    print("  isDraft: \(closedPR.isDraft)")
    print("  state: \(closedPR.state)")
    print("  needsAction: \(closedPR.needsAction)")
    print("  Expected: false (dimmed)")
    assert(closedPR.needsAction == false, "Closed PR should not need action")
    print("  ✅ PASS\n")

    print("=== All Tests Passed ✅ ===")
}
