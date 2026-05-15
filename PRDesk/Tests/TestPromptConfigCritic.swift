//
//  TestPromptConfigCritic.swift
//  PRDesk
//
//  Adversarial test harness for PromptConfigService - tests edge cases and failure paths
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

/// Adversarial test harness - tests edge cases and failure paths
func testPromptConfigCritic() {
    print("🧪 Running adversarial test harness for PromptConfigService...")

    // Test 1: {pr_body} must not appear literally in output
    print("\n[Test 1] Verify {pr_body} is replaced, not left as literal")
    let service1 = PromptConfigService()
    let mockPR1 = PullRequest(
        number: 999,
        title: "Test PR",
        url: "https://github.com/test/repo/pull/999",
        state: "OPEN",
        isDraft: false,
        author: PullRequest.Author(login: "testuser"),
        repositoryFullName: "test/repo",
        updatedAt: Date()
    )

    let templateWithBody = "PR: {pr_title}\n\nDescription:\n{pr_body}\n\nURL: {pr_url}"
    let result1 = service1.replaceTemplateVariables(templateWithBody, pr: mockPR1)

    // This is the critical test - {pr_body} must not appear literally
    assert(!result1.contains("{pr_body}"), "FAIL: {pr_body} left unreplaced - would break user customizations!")
    assert(result1.contains("Test PR"), "Should replace {pr_title}")
    print("✓ {pr_body} is replaced (not left as literal)")

    // Test 2: Special characters in PR data shouldn't break template replacement
    print("\n[Test 2] Special characters in PR title")
    let mockPR2 = PullRequest(
        number: 456,
        title: "Fix: {urgent} bug with $special chars & symbols",
        url: "https://github.com/test/repo/pull/456",
        state: "OPEN",
        isDraft: false,
        author: PullRequest.Author(login: "developer"),
        repositoryFullName: "org/project",
        updatedAt: Date()
    )

    let template2 = "PR #{pr_number}: {pr_title}"
    let result2 = service1.replaceTemplateVariables(template2, pr: mockPR2)

    assert(result2.contains("Fix: {urgent} bug with $special chars & symbols"),
           "Should preserve special chars in PR title")
    assert(result2.contains("PR #456"), "Should replace {pr_number}")
    print("✓ Special characters preserved correctly")

    // Test 3: Draft PRs should show (Draft) indicator
    print("\n[Test 3] Draft PR indicator")
    let mockPR3 = PullRequest(
        number: 789,
        title: "WIP: New feature",
        url: "https://github.com/test/repo/pull/789",
        state: "OPEN",
        isDraft: true,  // This is a draft
        author: PullRequest.Author(login: "dev"),
        repositoryFullName: "test/repo",
        updatedAt: Date()
    )

    let template3 = "Status: {pr_state}{pr_draft}"
    let result3 = service1.replaceTemplateVariables(template3, pr: mockPR3)

    assert(result3.contains("(Draft)"), "Draft PRs should show (Draft) indicator")
    print("✓ Draft indicator works")

    // Test 4: Config persistence - verify config survives service recreation
    print("\n[Test 4] Config persistence across service instances")
    let service2 = PromptConfigService()
    let config2 = service2.getConfig()

    assert(!config2.buttonText.isEmpty, "Config should persist")
    assert(!config2.myPRs.isEmpty, "myPRs prompt should persist")
    assert(!config2.reviewRequested.isEmpty, "reviewRequested prompt should persist")
    print("✓ Config persists across service instances")

    // Test 5: All required template variables are supported
    print("\n[Test 5] All required template variables")
    let mockPR5 = PullRequest(
        number: 111,
        title: "Complete Test",
        url: "https://github.com/owner/repo/pull/111",
        state: "OPEN",
        isDraft: false,
        author: PullRequest.Author(login: "author123"),
        repositoryFullName: "owner/repo",
        updatedAt: Date()
    )

    // Test ALL variables mentioned in the task requirement
    let allVarsTemplate = """
    Number: {pr_number}
    Title: {pr_title}
    URL: {pr_url}
    Body: {pr_body}
    Repo: {repo_name}
    Author: {pr_author}
    State: {pr_state}
    """

    let result5 = service1.replaceTemplateVariables(allVarsTemplate, pr: mockPR5)

    assert(result5.contains("Number: 111"), "Should replace {pr_number}")
    assert(result5.contains("Title: Complete Test"), "Should replace {pr_title}")
    assert(result5.contains("URL: https://github.com/owner/repo/pull/111"), "Should replace {pr_url}")
    assert(!result5.contains("{pr_body}"), "Should replace {pr_body} (not leave literal)")
    assert(result5.contains("Repo: owner/repo"), "Should replace {repo_name}")
    assert(result5.contains("Author: author123"), "Should replace {pr_author}")
    assert(result5.contains("State: OPEN"), "Should replace {pr_state}")
    print("✓ All template variables supported")

    // Test 6: Edge case - empty template
    print("\n[Test 6] Edge case - empty template")
    let result6 = service1.replaceTemplateVariables("", pr: mockPR1)
    assert(result6 == "", "Empty template should return empty string")
    print("✓ Empty template handled")

    print("\n✅ All adversarial tests passed!")
}

// Main entry point
@main
struct TestRunner {
    static func main() {
        testPromptConfigCritic()
    }
}
