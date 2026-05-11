//
//  TestConfigCreation.swift
//  PRDesk
//
//  Manual test for config file creation
//

import Foundation

/// Manual test to verify config file creation
func testConfigCreation() {
    print("=== Testing Config File Creation ===\n")

    // Create service instance (triggers config creation)
    let service = ClaudeIntegrationService()

    // Check if config file was created
    let configPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/PRDesk/prompts.json")

    if FileManager.default.fileExists(atPath: configPath.path) {
        print("✅ Config file created at: \(configPath.path)\n")

        // Read and display config
        if let data = try? Data(contentsOf: configPath),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            print("Config contents:")
            print("  myPRs template: \(json["myPRs"]?.prefix(100) ?? "N/A")...")
            print("  reviewRequested template: \(json["reviewRequested"]?.prefix(100) ?? "N/A")...")
        }
    } else {
        print("❌ Config file not found")
    }

    // Test template variable replacement
    print("\n=== Testing Template Variable Replacement ===\n")

    let testPR = PullRequest(
        number: 42,
        title: "Fix critical bug",
        repositoryFullName: "owner/repo",
        author: PullRequest.Author(login: "alice"),
        state: "OPEN",
        isDraft: false,
        updatedAt: Date(),
        url: "https://github.com/owner/repo/pull/42"
    )

    let myPRsPrompt = service.generatePrompt(pr: testPR, widgetType: .myPRs)

    // Verify template variables are replaced
    let checks = [
        ("PR number", myPRsPrompt.contains("42")),
        ("PR title", myPRsPrompt.contains("Fix critical bug")),
        ("Repo name", myPRsPrompt.contains("owner/repo")),
        ("PR URL", myPRsPrompt.contains("https://github.com/owner/repo/pull/42"))
    ]

    for (name, passed) in checks {
        print("\(passed ? "✅" : "❌") \(name) replacement")
    }

    print("\n=== Test Complete ===")
}

// Run test
testConfigCreation()
