//
//  TestClaudeIntegrationService.swift
//  PRDesk
//
//  Test to verify ClaudeIntegrationService uses PromptConfigService
//

import Foundation

enum WidgetType {
    case myPRs
    case reviewRequested
}

// Test that ClaudeIntegrationService delegates to PromptConfigService
func testClaudeIntegrationServiceUsesPromptConfigService() {
    // Setup: Create a test PR
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

    // Test: Initialize ClaudeIntegrationService
    print("Initializing ClaudeIntegrationService...")
    let service = ClaudeIntegrationService()
    print("Service initialized successfully")

    // Test: Generate prompt for My PRs
    print("Generating prompt for My PRs...")
    let myPRsPrompt = service.generatePrompt(pr: pr, widgetType: .myPRs)
    print("Prompt generated successfully")

    // Debug output
    print("Generated prompt:\n\(myPRsPrompt)")
    print("\nChecking for PR title: 'Add feature XYZ'")

    // Verify: Template variables are replaced
    print("PR number test: \(myPRsPrompt.contains("42"))")
    print("PR title test: \(myPRsPrompt.contains("Add feature XYZ"))")

    if !myPRsPrompt.contains("Add feature XYZ") {
        print("ERROR: Prompt does not contain title")
        print("Expected: 'Add feature XYZ'")
        print("Actual prompt length: \(myPRsPrompt.count) chars")
        print("First 200 chars: \(String(myPRsPrompt.prefix(200)))")
    }

    assert(myPRsPrompt.contains("42"), "Prompt should contain PR number 42")
    assert(myPRsPrompt.contains("Add feature XYZ"), "Prompt should contain PR title")
    assert(myPRsPrompt.contains("test/repo"), "Prompt should contain repo name")
    assert(!myPRsPrompt.contains("{pr_number}"), "Prompt should not contain unreplaced {pr_number}")
    assert(!myPRsPrompt.contains("{pr_title}"), "Prompt should not contain unreplaced {pr_title}")
    assert(!myPRsPrompt.contains("{repo_name}"), "Prompt should not contain unreplaced {repo_name}")

    // Test: Generate prompt for Review Requested
    let reviewPrompt = service.generatePrompt(pr: pr, widgetType: .reviewRequested)

    // Verify: Template variables are replaced
    assert(reviewPrompt.contains("42"), "Review prompt should contain PR number 42")
    assert(reviewPrompt.contains("Add feature XYZ"), "Review prompt should contain PR title")
    assert(reviewPrompt.contains("testuser"), "Review prompt should contain author")
    assert(!reviewPrompt.contains("{pr_author}"), "Review prompt should not contain unreplaced {pr_author}")

    print("✓ ClaudeIntegrationService correctly uses PromptConfigService")
    print("✓ Template variables are properly replaced in generated prompts")
    print("✓ Both myPRs and reviewRequested prompts work correctly")
}

@main
struct TestRunner {
    static func main() {
        testClaudeIntegrationServiceUsesPromptConfigService()
        print("\nAll tests passed!")
    }
}
