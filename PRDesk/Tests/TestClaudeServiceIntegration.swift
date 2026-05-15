//
//  TestClaudeServiceIntegration.swift
//  PRDesk
//
//  Simple test to verify ClaudeIntegrationService uses PromptConfigService
//

import Foundation

enum WidgetType {
    case myPRs
    case reviewRequested
}

@main
struct TestRunner {
    static func main() {
        // Create a test PR
        let author = PullRequest.Author(login: "testuser")
        let repo = PullRequest.Repository(name: "repo", nameWithOwner: "test/repo")
        let pr = PullRequest(
            number: 42,
            title: "Add feature XYZ",
            url: "https://github.com/test/repo/pull/42",
            author: author,
            state: "OPEN",
            isDraft: false,
            repository: repo,
            updatedAt: Date()
        )

        print("Creating ClaudeIntegrationService...")
        let service = ClaudeIntegrationService()

        print("Generating myPRs prompt...")
        let myPRsPrompt = service.generatePrompt(pr: pr, widgetType: .myPRs)

        print("\n=== My PRs Prompt ===")
        print(myPRsPrompt)
        print("\n=== Checks ===")

        var allPassed = true

        // Check PR number
        if myPRsPrompt.contains("42") {
            print("✓ Contains PR number (42)")
        } else {
            print("✗ Missing PR number (42)")
            allPassed = false
        }

        // Check PR title
        if myPRsPrompt.contains("Add feature XYZ") {
            print("✓ Contains PR title")
        } else {
            print("✗ Missing PR title 'Add feature XYZ'")
            allPassed = false
        }

        // Check repo name
        if myPRsPrompt.contains("test/repo") {
            print("✓ Contains repo name")
        } else {
            print("✗ Missing repo name 'test/repo'")
            allPassed = false
        }

        // Check URL
        if myPRsPrompt.contains("https://github.com/test/repo/pull/42") {
            print("✓ Contains PR URL")
        } else {
            print("✗ Missing PR URL")
            allPassed = false
        }

        // Check author
        if myPRsPrompt.contains("testuser") {
            print("✓ Contains author (in prompt or could be in My PRs context)")
        }

        // Check no unreplaced variables
        if !myPRsPrompt.contains("{pr_number}") &&
           !myPRsPrompt.contains("{pr_title}") &&
           !myPRsPrompt.contains("{repo_name}") {
            print("✓ No unreplaced template variables")
        } else {
            print("✗ Found unreplaced template variables")
            allPassed = false
        }

        print("\nGenerating reviewRequested prompt...")
        let reviewPrompt = service.generatePrompt(pr: pr, widgetType: .reviewRequested)

        print("\n=== Review Requested Prompt ===")
        print(reviewPrompt)
        print("\n=== Checks ===")

        if reviewPrompt.contains("42") {
            print("✓ Contains PR number")
        } else {
            print("✗ Missing PR number")
            allPassed = false
        }

        if reviewPrompt.contains("testuser") {
            print("✓ Contains author username")
        } else {
            print("✗ Missing author username")
            allPassed = false
        }

        if allPassed {
            print("\n✅ All tests passed!")
            exit(0)
        } else {
            print("\n❌ Some tests failed")
            exit(1)
        }
    }
}
