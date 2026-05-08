//
//  TestPRDataStore.swift
//  PRDesk
//
//  Test harness for PRDataStore
//

import Foundation

// Test 1: Create store, save PRs, retrieve PRs
func testBasicSaveAndLoad() {
    print("Test 1: Basic save and load")

    let store = PRDataStore()

    // Create sample PRs
    let pr1 = PullRequest(
        number: 123,
        title: "Test PR",
        url: "https://github.com/test/repo/pull/123",
        author: PullRequest.Author(login: "testuser"),
        state: "OPEN",
        isDraft: false,
        repository: PullRequest.Repository(name: "repo", nameWithOwner: "test/repo"),
        updatedAt: Date()
    )

    let pr2 = PullRequest(
        number: 456,
        title: "Review PR",
        url: "https://github.com/test/repo/pull/456",
        author: PullRequest.Author(login: "otheruser"),
        state: "OPEN",
        isDraft: false,
        repository: PullRequest.Repository(name: "repo", nameWithOwner: "test/repo"),
        updatedAt: Date()
    )

    // Save PRs
    do {
        try store.saveMyPRs([pr1])
        try store.saveReviewRequestedPRs([pr2])
        print("✅ Saved PRs successfully")
    } catch {
        print("❌ Failed to save PRs: \(error)")
        return
    }

    // Retrieve PRs
    do {
        let myPRs = try store.loadMyPRs()
        let reviewPRs = try store.loadReviewRequestedPRs()

        if myPRs.count == 1 && myPRs[0].number == 123 {
            print("✅ Retrieved myPRs correctly")
        } else {
            print("❌ myPRs mismatch: expected 1 PR with number 123, got \(myPRs.count) PRs")
        }

        if reviewPRs.count == 1 && reviewPRs[0].number == 456 {
            print("✅ Retrieved reviewRequestedPRs correctly")
        } else {
            print("❌ reviewRequestedPRs mismatch: expected 1 PR with number 456, got \(reviewPRs.count) PRs")
        }
    } catch {
        print("❌ Failed to load PRs: \(error)")
    }
}

// Test 2: Empty store returns empty arrays
func testEmptyStore() {
    print("\nTest 2: Empty store")

    let store = PRDataStore()

    do {
        let myPRs = try store.loadMyPRs()
        let reviewPRs = try store.loadReviewRequestedPRs()

        if myPRs.isEmpty && reviewPRs.isEmpty {
            print("✅ Empty store returns empty arrays")
        } else {
            print("❌ Expected empty arrays, got myPRs: \(myPRs.count), reviewPRs: \(reviewPRs.count)")
        }
    } catch {
        print("❌ Failed to load from empty store: \(error)")
    }
}

// Test 3: Persistence across instances
func testPersistence() {
    print("\nTest 3: Persistence across instances")

    let pr = PullRequest(
        number: 789,
        title: "Persistent PR",
        url: "https://github.com/test/repo/pull/789",
        author: PullRequest.Author(login: "testuser"),
        state: "OPEN",
        isDraft: false,
        repository: PullRequest.Repository(name: "repo", nameWithOwner: "test/repo"),
        updatedAt: Date()
    )

    // Save with first instance
    do {
        let store1 = PRDataStore()
        try store1.saveMyPRs([pr])
        print("✅ Saved with first instance")
    } catch {
        print("❌ Failed to save: \(error)")
        return
    }

    // Load with second instance
    do {
        let store2 = PRDataStore()
        let loaded = try store2.loadMyPRs()

        if loaded.count == 1 && loaded[0].number == 789 {
            print("✅ Loaded with second instance - persistence works")
        } else {
            print("❌ Persistence failed: expected 1 PR, got \(loaded.count)")
        }
    } catch {
        print("❌ Failed to load with second instance: \(error)")
    }
}

// Run tests
testBasicSaveAndLoad()
testEmptyStore()
testPersistence()
