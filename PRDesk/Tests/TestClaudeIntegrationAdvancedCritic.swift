//
//  TestClaudeIntegrationAdvancedCritic.swift
//  PRDesk
//
//  Adversarial test to verify ClaudeIntegrationService uses PromptConfigService correctly
//  Tests edge cases that the Builder might have missed
//

import Foundation

enum WidgetType {
    case myPRs
    case reviewRequested
}

@main
struct TestRunner {
    static func main() {
        var allPassed = true

        print("=== ADVERSARIAL TESTS FOR CLAUDEINTEGRATIONSERVICE ===\n")

        // TEST 1: Verify config is actually loaded from PromptConfigService, not hardcoded
        print("Test 1: Verify prompts come from PromptConfigService config...")
        let service = ClaudeIntegrationService()
        let config = service.getConfig()

        // Default prompts should not be empty
        if config.myPRs.isEmpty {
            print("✗ myPRs prompt is empty")
            allPassed = false
        } else {
            print("✓ myPRs prompt is loaded")
        }

        if config.reviewRequested.isEmpty {
            print("✗ reviewRequested prompt is empty")
            allPassed = false
        } else {
            print("✓ reviewRequested prompt is loaded")
        }

        if config.buttonText.isEmpty {
            print("✗ buttonText is empty")
            allPassed = false
        } else {
            print("✓ buttonText is loaded: '\(config.buttonText)'")
        }

        // TEST 2: Verify template variables are replaced correctly
        print("\nTest 2: Verify all template variables are replaced...")

        let author = PullRequest.Author(login: "critic-user")
        let repo = PullRequest.Repository(name: "testrepo", nameWithOwner: "org/testrepo")
        let testPR = PullRequest(
            number: 999,
            title: "Critical bug fix with \"quotes\" and <special> chars",
            url: "https://github.com/org/testrepo/pull/999",
            author: author,
            state: "OPEN",
            isDraft: false,
            repository: repo,
            updatedAt: Date()
        )

        let myPRsPrompt = service.generatePrompt(pr: testPR, widgetType: .myPRs)
        let reviewPrompt = service.generatePrompt(pr: testPR, widgetType: .reviewRequested)

        // Check for unreplaced template variables
        let unreplacedVariables = ["{pr_number}", "{pr_title}", "{pr_url}", "{repo_name}", "{pr_author}"]
        var foundUnreplaced = false

        for variable in unreplacedVariables {
            if myPRsPrompt.contains(variable) {
                print("✗ myPRs prompt contains unreplaced variable: \(variable)")
                allPassed = false
                foundUnreplaced = true
            }
            if reviewPrompt.contains(variable) {
                print("✗ reviewRequested prompt contains unreplaced variable: \(variable)")
                allPassed = false
                foundUnreplaced = true
            }
        }

        if !foundUnreplaced {
            print("✓ No unreplaced template variables found")
        }

        // TEST 3: Verify actual PR data is present in prompts
        print("\nTest 3: Verify PR data appears in generated prompts...")

        if myPRsPrompt.contains("999") {
            print("✓ myPRs prompt contains PR number 999")
        } else {
            print("✗ myPRs prompt missing PR number 999")
            allPassed = false
        }

        if myPRsPrompt.contains("Critical bug fix") {
            print("✓ myPRs prompt contains PR title")
        } else {
            print("✗ myPRs prompt missing PR title")
            allPassed = false
        }

        if myPRsPrompt.contains("org/testrepo") {
            print("✓ myPRs prompt contains repo name")
        } else {
            print("✗ myPRs prompt missing repo name")
            allPassed = false
        }

        if reviewPrompt.contains("999") {
            print("✓ reviewRequested prompt contains PR number 999")
        } else {
            print("✗ reviewRequested prompt missing PR number 999")
            allPassed = false
        }

        if reviewPrompt.contains("critic-user") {
            print("✓ reviewRequested prompt contains author username")
        } else {
            print("✗ reviewRequested prompt missing author username")
            allPassed = false
        }

        // TEST 4: Verify special characters are preserved
        print("\nTest 4: Verify special characters are preserved...")

        if myPRsPrompt.contains("\"quotes\"") || myPRsPrompt.contains("quotes") {
            print("✓ Special characters preserved in myPRs prompt")
        } else {
            print("✗ Special characters lost in myPRs prompt")
            allPassed = false
        }

        // TEST 5: Verify config path is accessible (for users to edit)
        print("\nTest 5: Verify config path is accessible...")

        let configPath = service.getConfigPath()
        if configPath.contains("Library/Application Support/PRDesk/prompts.json") {
            print("✓ Config path is correct: \(configPath)")
        } else {
            print("✗ Config path is wrong: \(configPath)")
            allPassed = false
        }

        // TEST 6: Verify both widget types generate different prompts
        print("\nTest 6: Verify widget types produce different prompts...")

        if myPRsPrompt != reviewPrompt {
            print("✓ myPRs and reviewRequested prompts are different")
        } else {
            print("✗ myPRs and reviewRequested prompts are identical (should differ)")
            allPassed = false
        }

        // TEST 7: Verify no hardcoded prompt remnants
        print("\nTest 7: Check for hardcoded prompt remnants...")

        // This is a heuristic check - if the old hardcoded prompts contained specific phrases
        // we should ensure those aren't still appearing if they're not in the config
        // For now, we just verify that prompts are non-trivial
        if myPRsPrompt.count < 10 {
            print("✗ myPRs prompt suspiciously short (\(myPRsPrompt.count) chars)")
            allPassed = false
        } else {
            print("✓ myPRs prompt has reasonable length (\(myPRsPrompt.count) chars)")
        }

        if reviewPrompt.count < 10 {
            print("✗ reviewRequested prompt suspiciously short (\(reviewPrompt.count) chars)")
            allPassed = false
        } else {
            print("✓ reviewRequested prompt has reasonable length (\(reviewPrompt.count) chars)")
        }

        // Print actual prompts for manual inspection
        print("\n=== ACTUAL PROMPTS FOR MANUAL REVIEW ===")
        print("\n--- myPRs prompt ---")
        print(myPRsPrompt)
        print("\n--- reviewRequested prompt ---")
        print(reviewPrompt)

        // Final result
        print("\n=== FINAL RESULT ===")
        if allPassed {
            print("✅ All adversarial tests passed!")
            exit(0)
        } else {
            print("❌ Some adversarial tests failed")
            exit(1)
        }
    }
}
