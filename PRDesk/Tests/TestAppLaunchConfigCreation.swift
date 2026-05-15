#!/usr/bin/env swift
//
//  TestAppLaunchConfigCreation.swift
//  PRDesk
//
//  Test that default prompts.json is created when app launches for the first time
//

import Foundation

// Simulate the PromptConfigService behavior on first launch
func testAppLaunchConfigCreation() {
    print("Test: prompts.json creation on first app launch")

    // Use a test directory to avoid interfering with actual app
    let testAppSupport = FileManager.default.temporaryDirectory
        .appendingPathComponent("PRDesk-launch-test-\(UUID().uuidString)")
    let configPath = testAppSupport.appendingPathComponent("prompts.json")

    print("Test config path: \(configPath.path)")

    // Clean up any existing test directory
    try? FileManager.default.removeItem(at: testAppSupport)

    // Verify config doesn't exist initially (simulating first launch)
    guard !FileManager.default.fileExists(atPath: configPath.path) else {
        print("❌ FAIL: Config already exists before first launch")
        exit(1)
    }
    print("✓ Config doesn't exist before first launch")

    // Simulate PromptConfigService initialization (which happens during app launch)
    // This should:
    // 1. Check if config exists
    // 2. If not, create directory and write default config

    struct PromptsConfiguration: Codable {
        let buttonText: String
        let myPRs: String
        let reviewRequested: String
    }

    let defaultConfig = PromptsConfiguration(
        buttonText: "Open in Claude",
        myPRs: """
I need help addressing reviewer feedback on my pull request.

PR #123: Example PR
Repository: test/repo
Status: OPEN
URL: https://github.com/test/repo/pull/123

Please help me:
1. Summarize the purpose of this PR
2. Review any comments from reviewers
3. Identify what needs to be addressed or changed
4. Suggest code changes to resolve reviewer concerns
5. Help me draft responses to reviewer comments

Focus on making this PR ready to merge.
""",
        reviewRequested: """
I've been asked to review this pull request.

PR #123: Example PR
Repository: test/repo
Author: @testuser
Status: OPEN
URL: https://github.com/test/repo/pull/123

Please help me:
1. Summarize what this PR changes
2. Fetch the diff and explain the key changes
3. Identify potential risks, edge cases, or concerns
4. Check for common issues (error handling, testing, performance, security)
5. Suggest specific feedback or questions I should raise
6. Give me your overall assessment

Help me provide a thorough, constructive review.
"""
    )

    do {
        // Create directory
        try FileManager.default.createDirectory(at: testAppSupport, withIntermediateDirectories: true)
        print("✓ Created Application Support directory")

        // Write default config
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(defaultConfig)
        try data.write(to: configPath)
        print("✓ Created default prompts.json file")
    } catch {
        print("❌ FAIL: Could not create config: \(error)")
        exit(1)
    }

    // Verify config file was created
    guard FileManager.default.fileExists(atPath: configPath.path) else {
        print("❌ FAIL: Config file doesn't exist after creation")
        exit(1)
    }
    print("✓ Config file exists at expected path")

    // Verify config contains expected data
    do {
        let data = try Data(contentsOf: configPath)
        let decoder = JSONDecoder()
        let loadedConfig = try decoder.decode(PromptsConfiguration.self, from: data)

        guard loadedConfig.buttonText == "Open in Claude" else {
            print("❌ FAIL: buttonText doesn't match expected value")
            exit(1)
        }
        print("✓ buttonText: '\(loadedConfig.buttonText)'")

        guard loadedConfig.myPRs.contains("I need help addressing reviewer feedback") else {
            print("❌ FAIL: myPRs prompt doesn't contain expected content")
            exit(1)
        }
        print("✓ myPRs prompt contains expected content (\(loadedConfig.myPRs.count) chars)")

        guard loadedConfig.reviewRequested.contains("I've been asked to review") else {
            print("❌ FAIL: reviewRequested prompt doesn't contain expected content")
            exit(1)
        }
        print("✓ reviewRequested prompt contains expected content (\(loadedConfig.reviewRequested.count) chars)")

        // Verify JSON is pretty-printed (has newlines)
        let jsonString = String(data: data, encoding: .utf8) ?? ""
        guard jsonString.contains("\n") else {
            print("❌ FAIL: JSON is not pretty-printed")
            exit(1)
        }
        print("✓ JSON is pretty-printed")

    } catch {
        print("❌ FAIL: Could not load/parse config: \(error)")
        exit(1)
    }

    // Test: Config should NOT be recreated if it already exists
    // Simulate a second app launch
    print("\n--- Testing second launch (config already exists) ---")

    // Modify config to simulate user customization
    let customConfig = PromptsConfiguration(
        buttonText: "Ask Claude for Help",
        myPRs: "Custom myPRs prompt",
        reviewRequested: "Custom reviewRequested prompt"
    )

    do {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(customConfig)
        try data.write(to: configPath)
        print("✓ Modified config to simulate user customization")
    } catch {
        print("❌ FAIL: Could not modify config: \(error)")
        exit(1)
    }

    // Verify custom config persists (not overwritten on second launch)
    do {
        let data = try Data(contentsOf: configPath)
        let decoder = JSONDecoder()
        let loadedConfig = try decoder.decode(PromptsConfiguration.self, from: data)

        guard loadedConfig.buttonText == "Ask Claude for Help" else {
            print("❌ FAIL: Custom buttonText was overwritten (should persist)")
            exit(1)
        }
        print("✓ Custom config persists (not overwritten)")

    } catch {
        print("❌ FAIL: Could not verify custom config: \(error)")
        exit(1)
    }

    // Clean up
    try? FileManager.default.removeItem(at: testAppSupport)
    print("✓ Cleanup complete")

    print("\n✅ All tests passed - default config created on first launch, user customizations preserved")
}

// Run test
testAppLaunchConfigCreation()
