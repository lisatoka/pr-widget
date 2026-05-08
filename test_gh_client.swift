#!/usr/bin/env swift

import Foundation

// Minimal GitHubClient for testing
enum GitHubClientError: Error {
    case ghNotAvailable
    case commandFailed(Int)
    case invalidJSON
}

struct TestPR: Codable {
    let number: Int
    let title: String
}

func runCommand(_ command: String, args: [String]) async throws -> (String, Int) {
    return try await withCheckedThrowingContinuation { continuation in
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = args

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            process.waitUntilExit()
            let exitCode = Int(process.terminationStatus)
            continuation.resume(returning: (output, exitCode))
        } catch {
            continuation.resume(throwing: error)
        }
    }
}

func testGHCommand() async {
    print("Testing gh CLI wrapper...")

    // Test gh availability
    print("\n=== Test 1: Check gh CLI ===")
    do {
        let (output, exitCode) = try await runCommand("/opt/homebrew/bin/gh", args: ["--version"])
        if exitCode == 0 {
            print("✓ gh CLI available")
            print("  Version: \(output.components(separatedBy: "\n").first ?? "")")
        } else {
            print("✗ gh CLI failed with exit code \(exitCode)")
        }
    } catch {
        print("✗ gh CLI not available: \(error)")
    }

    // Test JSON parsing with empty response
    print("\n=== Test 2: Parse empty JSON ===")
    let emptyJSON = "[]"
    if let data = emptyJSON.data(using: .utf8) {
        do {
            let decoder = JSONDecoder()
            let prs = try decoder.decode([TestPR].self, from: data)
            print("✓ Empty array parsed: \(prs.count) items")
        } catch {
            print("✗ Failed to parse: \(error)")
        }
    }

    print("\n=== Tests Complete ===")
}

Task {
    await testGHCommand()
    exit(0)
}

RunLoop.main.run()
