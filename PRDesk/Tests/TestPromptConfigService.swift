//
//  TestPromptConfigService.swift
//  PRDesk
//
//  Test for PromptConfigService
//

import Foundation

// Mock PullRequest for testing
struct PullRequest {
    let number: Int
    let title: String
    let url: String
    let state: String
    let isDraft: Bool
    let author: Author
    let repositoryFullName: String
    let updatedAt: Date

    struct Author {
        let login: String
    }
}

/// Test that PromptConfigService loads config and parses template variables
func testPromptConfigService() {
    print("Testing PromptConfigService...")

    // Test 1: Service initializes with defaults
    let service = PromptConfigService()
    let config = service.getConfig()

    assert(!config.buttonText.isEmpty, "Button text should not be empty")
    assert(!config.myPRs.isEmpty, "myPRs prompt should not be empty")
    assert(!config.reviewRequested.isEmpty, "reviewRequested prompt should not be empty")
    print("✓ Default config loaded")

    // Test 2: Template variable parsing
    let mockPR = PullRequest(
        number: 123,
        title: "Add new feature",
        url: "https://github.com/test/repo/pull/123",
        state: "OPEN",
        isDraft: false,
        author: PullRequest.Author(login: "testuser"),
        repositoryFullName: "test/repo",
        updatedAt: Date()
    )

    let template = "PR #{pr_number}: {pr_title} in {repo_name} at {pr_url}"
    let result = service.replaceTemplateVariables(template, pr: mockPR)

    assert(result.contains("PR #123"), "Should replace {pr_number}")
    assert(result.contains("Add new feature"), "Should replace {pr_title}")
    assert(result.contains("test/repo"), "Should replace {repo_name}")
    assert(result.contains("https://github.com/test/repo/pull/123"), "Should replace {pr_url}")
    print("✓ Template variable parsing works")

    // Test 3: Config path is correct
    let path = service.getConfigPath()
    assert(path.contains("Library/Application Support/PRDesk/prompts.json"), "Config path should be correct")
    print("✓ Config path is correct")

    // Test 4: {pr_body} template variable is replaced with placeholder
    let templateWithBody = "Title: {pr_title}\nBody: {pr_body}\nURL: {pr_url}"
    let resultWithBody = service.replaceTemplateVariables(templateWithBody, pr: mockPR)

    assert(!resultWithBody.contains("{pr_body}"), "Should not leave {pr_body} unreplaced")
    assert(resultWithBody.contains("(PR description not available"), "Should replace {pr_body} with placeholder")
    print("✓ {pr_body} template variable replaced with placeholder")

    print("✅ All PromptConfigService tests passed")
}

// Main entry point
@main
struct TestRunner {
    static func main() {
        testPromptConfigService()
    }
}
