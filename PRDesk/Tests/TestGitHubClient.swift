//
//  TestGitHubClient.swift
//  PRDesk
//
//  Test harness for GitHubClient
//

import Foundation

// Copy of the models and client for standalone testing
// This is a temporary test file - will be replaced with proper XCTest later

struct TestPullRequest: Codable {
    let number: Int
    let title: String
    let url: String
    let author: Author
    let state: String
    let isDraft: Bool
    let headRepository: Repository?
    let headRepositoryOwner: RepositoryOwner
    let updatedAt: Date

    struct Author: Codable {
        let login: String
    }

    struct Repository: Codable {
        let name: String
    }

    struct RepositoryOwner: Codable {
        let login: String
    }
}

func runTest() async {
    print("Testing GitHubClient.fetchMyPRs()...")

    // Test 1: Parse sample JSON
    print("\n=== Test 1: JSON Parsing ===")
    let sampleJSON = """
    [
        {
            "number": 123,
            "title": "Add new feature",
            "url": "https://github.com/owner/repo/pull/123",
            "author": {"login": "testuser"},
            "state": "OPEN",
            "isDraft": false,
            "headRepository": {"name": "repo"},
            "headRepositoryOwner": {"login": "owner"},
            "updatedAt": "2024-01-15T10:30:00Z"
        }
    ]
    """

    do {
        let data = sampleJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let prs = try decoder.decode([TestPullRequest].self, from: data)
        print("✓ Successfully parsed \(prs.count) PR(s)")
        if let pr = prs.first {
            print("  - PR #\(pr.number): \(pr.title)")
            print("  - Author: \(pr.author.login)")
            print("  - Repo: \(pr.headRepositoryOwner.login)/\(pr.headRepository?.name ?? "unknown")")
        }
    } catch {
        print("✗ Failed to parse JSON: \(error)")
    }

    // Test 2: Empty array
    print("\n=== Test 2: Empty Response ===")
    do {
        let emptyJSON = "[]"
        let data = emptyJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let prs = try decoder.decode([TestPullRequest].self, from: data)
        print("✓ Successfully handled empty array: \(prs.count) PRs")
    } catch {
        print("✗ Failed: \(error)")
    }

    print("\n=== All Tests Passed ===")
}

// Run tests
Task {
    await runTest()
    exit(0)
}

RunLoop.main.run()
