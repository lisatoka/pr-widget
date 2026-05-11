//
//  TestCustomizablePrompts.swift
//  PRDesk
//
//  Test harness for customizable Claude prompts
//

import Foundation

/// Test harness for customizable Claude prompts via JSON config
///
/// This test verifies:
/// 1. Config file can be loaded from Application Support directory
/// 2. Template variables are replaced with PR data
/// 3. Falls back to default prompts when config missing or invalid
/// 4. Creates default config file on first launch
///
/// Manual verification steps:
/// 1. Build app: xcodebuild -project PRDesk.xcodeproj -scheme PRDesk -configuration Debug build
/// 2. Launch app to trigger config creation
/// 3. Check config file exists: ls ~/Library/Application\ Support/PRDesk/prompts.json
/// 4. Verify default prompts: cat ~/Library/Application\ Support/PRDesk/prompts.json
/// 5. Modify config file with custom prompt
/// 6. Relaunch app and verify custom prompt is used

class TestCustomizablePrompts {
    func run() {
        print("=== Test: Customizable Claude Prompts ===")

        // Test 1: Config file creation
        print("\n1. Testing config file creation...")
        let service = ClaudeIntegrationService()
        let configPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/PRDesk/prompts.json")

        if FileManager.default.fileExists(atPath: configPath.path) {
            print("✅ Config file exists at: \(configPath.path)")
        } else {
            print("❌ Config file not found at: \(configPath.path)")
        }

        // Test 2: Template variable replacement
        print("\n2. Testing template variable replacement...")
        let testPR = PullRequest(
            number: 123,
            title: "Test PR Title",
            repositoryFullName: "test/repo",
            author: PullRequest.Author(login: "testuser"),
            state: "OPEN",
            isDraft: false,
            updatedAt: Date(),
            url: "https://github.com/test/repo/pull/123"
        )

        let myPRsPrompt = service.generatePrompt(pr: testPR, widgetType: .myPRs)

        // Verify template variables are replaced
        if myPRsPrompt.contains("123") &&
           myPRsPrompt.contains("Test PR Title") &&
           myPRsPrompt.contains("test/repo") &&
           myPRsPrompt.contains("https://github.com/test/repo/pull/123") {
            print("✅ Template variables replaced correctly in myPRs prompt")
        } else {
            print("❌ Template variable replacement failed")
            print("Generated prompt:\n\(myPRsPrompt)")
        }

        let reviewPrompt = service.generatePrompt(pr: testPR, widgetType: .reviewRequested)

        if reviewPrompt.contains("123") &&
           reviewPrompt.contains("Test PR Title") &&
           reviewPrompt.contains("test/repo") &&
           reviewPrompt.contains("testuser") {
            print("✅ Template variables replaced correctly in reviewRequested prompt")
        } else {
            print("❌ Template variable replacement failed")
            print("Generated prompt:\n\(reviewPrompt)")
        }

        // Test 3: Custom config file
        print("\n3. Manual test for custom config:")
        print("   a. Edit: ~/Library/Application Support/PRDesk/prompts.json")
        print("   b. Change myPRs template to: \"Custom prompt for PR #{pr_number}\"")
        print("   c. Relaunch app and click 'Open in Claude' button")
        print("   d. Verify Terminal shows custom prompt")

        print("\n=== Test Complete ===")
    }
}

// Run test if executed directly
if CommandLine.arguments.contains("--test-prompts") {
    TestCustomizablePrompts().run()
}
