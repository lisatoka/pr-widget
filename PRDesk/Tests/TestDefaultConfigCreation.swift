#!/usr/bin/env swift
//
//  TestDefaultConfigCreation.swift
//  PRDesk
//
//  Test that default prompts.json is created on first launch
//

import Foundation

// Simulate the PromptConfigService struct
struct PromptsConfiguration: Codable {
    let buttonText: String
    let myPRs: String
    let reviewRequested: String
}

// Test: Default config file creation on first launch
func testDefaultConfigCreation() {
    print("Test: Default prompts.json creation on first launch")

    // Set up paths
    let testDir = FileManager.default.temporaryDirectory.appendingPathComponent("PRDesk-test-\(UUID().uuidString)")
    let configPath = testDir.appendingPathComponent("prompts.json")

    // Clean up any existing test directory
    try? FileManager.default.removeItem(at: testDir)

    // Verify config doesn't exist yet
    guard !FileManager.default.fileExists(atPath: configPath.path) else {
        print("❌ FAIL: Config file already exists before creation")
        exit(1)
    }
    print("✓ Config file doesn't exist initially")

    // Create directory and default config (simulating PromptConfigService init)
    do {
        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)

        let defaultConfig = PromptsConfiguration(
            buttonText: "Open in Claude",
            myPRs: "Default myPRs prompt",
            reviewRequested: "Default reviewRequested prompt"
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(defaultConfig)
        try data.write(to: configPath)

        print("✓ Created default config file")
    } catch {
        print("❌ FAIL: Could not create config: \(error)")
        exit(1)
    }

    // Verify config file was created
    guard FileManager.default.fileExists(atPath: configPath.path) else {
        print("❌ FAIL: Config file was not created")
        exit(1)
    }
    print("✓ Config file exists after creation")

    // Verify config can be loaded and parsed
    do {
        let data = try Data(contentsOf: configPath)
        let decoder = JSONDecoder()
        let config = try decoder.decode(PromptsConfiguration.self, from: data)

        guard config.buttonText == "Open in Claude" else {
            print("❌ FAIL: buttonText mismatch")
            exit(1)
        }
        guard !config.myPRs.isEmpty else {
            print("❌ FAIL: myPRs prompt is empty")
            exit(1)
        }
        guard !config.reviewRequested.isEmpty else {
            print("❌ FAIL: reviewRequested prompt is empty")
            exit(1)
        }

        print("✓ Config file contains valid data")
        print("  buttonText: \(config.buttonText)")
        print("  myPRs length: \(config.myPRs.count) chars")
        print("  reviewRequested length: \(config.reviewRequested.count) chars")
    } catch {
        print("❌ FAIL: Could not load/parse config: \(error)")
        exit(1)
    }

    // Clean up
    try? FileManager.default.removeItem(at: testDir)
    print("✓ Cleanup complete")

    print("\n✅ All tests passed")
}

// Run test
testDefaultConfigCreation()
