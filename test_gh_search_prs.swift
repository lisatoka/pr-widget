#!/usr/bin/env swift
//
// Test gh search prs command (works from any directory, no git repo required)
//

import Foundation

let process = Process()
process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/gh")
process.arguments = ["search", "prs", "--author=@me", "--json", "number,title,url,author,state,isDraft,repository,updatedAt", "--limit", "1"]

let pipe = Pipe()
process.standardOutput = pipe
process.standardError = pipe

do {
    try process.run()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""

    process.waitUntilExit()
    let exitCode = Int(process.terminationStatus)

    if exitCode == 0 {
        print("✅ PASS: gh search prs succeeded with exit code 0")
        print("Output preview: \(output.prefix(200))...")
    } else {
        print("❌ FAIL: gh search prs failed with exit code \(exitCode)")
        print("Output: \(output)")
    }
} catch {
    print("❌ FAIL: Failed to run gh command: \(error)")
}
