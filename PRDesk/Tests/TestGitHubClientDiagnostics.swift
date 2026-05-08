//
//  TestGitHubClientDiagnostics.swift
//  PRDesk
//
//  Test harness for diagnosing GitHub CLI errors
//

import Foundation

// MANUAL TEST: Diagnose why gh CLI fails from app
//
// This test helps diagnose the GitHub CLI error by logging:
// 1. Environment variables (PATH, HOME, USER)
// 2. Separate stdout and stderr output
// 3. Exit code
// 4. Which gh binary location
//
// Run from Xcode:
// 1. Build and run PRDesk app
// 2. Check Console.app for log output
// 3. Look for lines starting with "[GH Diagnostics]"
//
// Expected findings:
// - PATH may not include gh binary location
// - HOME or USER may be missing
// - Stderr will show actual gh error message
// - Exit code will indicate type of failure
//
// Common fixes:
// - Use full path to gh binary: /usr/local/bin/gh or /opt/homebrew/bin/gh
// - Set environment: PATH, HOME, USER
// - Find gh with: Process.run("/usr/bin/which", ["gh"])

class GitHubClientDiagnostics {
    static func runDiagnostics() async {
        print("[GH Diagnostics] Starting diagnostic tests...")

        // Test 1: Print environment
        await printEnvironment()

        // Test 2: Find gh binary
        await findGhBinary()

        // Test 3: Run gh with separate stdout/stderr
        await runGhWithSeparateStreams()

        print("[GH Diagnostics] Diagnostic tests complete")
    }

    static func printEnvironment() async {
        print("[GH Diagnostics] Environment variables:")

        let env = ProcessInfo.processInfo.environment

        print("[GH Diagnostics]   PATH = \(env["PATH"] ?? "NOT SET")")
        print("[GH Diagnostics]   HOME = \(env["HOME"] ?? "NOT SET")")
        print("[GH Diagnostics]   USER = \(env["USER"] ?? "NOT SET")")
        print("[GH Diagnostics]   SHELL = \(env["SHELL"] ?? "NOT SET")")
    }

    static func findGhBinary() async {
        print("[GH Diagnostics] Finding gh binary with 'which gh'...")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["gh"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                print("[GH Diagnostics]   gh found at: \(output.trimmingCharacters(in: .whitespacesAndNewlines))")
            } else {
                print("[GH Diagnostics]   gh NOT FOUND in PATH")
                print("[GH Diagnostics]   which output: \(output)")
            }
        } catch {
            print("[GH Diagnostics]   Error running which: \(error)")
        }
    }

    static func runGhWithSeparateStreams() async {
        print("[GH Diagnostics] Running 'gh search prs --author=@me --json number' with separate streams...")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["gh", "search", "prs", "--author=@me", "--json", "number", "--limit", "1"]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()

            let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

            let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
            let stderr = String(data: stderrData, encoding: .utf8) ?? ""

            process.waitUntilExit()
            let exitCode = process.terminationStatus

            print("[GH Diagnostics]   Exit code: \(exitCode)")
            print("[GH Diagnostics]   STDOUT: \(stdout.isEmpty ? "(empty)" : stdout)")
            print("[GH Diagnostics]   STDERR: \(stderr.isEmpty ? "(empty)" : stderr)")
        } catch {
            print("[GH Diagnostics]   Error running gh: \(error)")
        }
    }
}
