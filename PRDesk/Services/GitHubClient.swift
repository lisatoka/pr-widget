//
//  GitHubClient.swift
//  PRDesk
//
//  Created by PR Desk
//

import Foundation

enum GitHubClientError: Error, Equatable {
    case ghNotAvailable
    case commandFailed(Int)
    case invalidJSON
}

/// Client for interacting with GitHub via gh CLI
class GitHubClient {
    /// Fetches PRs authored by the current user
    func fetchMyPRs() async throws -> [PullRequest] {
        print("[GitHubClient] fetchMyPRs() ENTRY")
        let fields = "number,title,url,author,state,isDraft,repository,updatedAt"
        let args = ["search", "prs", "--author=@me", "--json", fields]

        let (output, exitCode) = try await runGhCommand(args)
        print("[GitHubClient] fetchMyPRs() runGhCommand returned, exitCode=\(exitCode)")

        guard exitCode == 0 else {
            if exitCode == 127 {
                throw GitHubClientError.ghNotAvailable
            }
            throw GitHubClientError.commandFailed(exitCode)
        }

        guard let data = output.data(using: .utf8) else {
            return []
        }

        if data.isEmpty || output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("[GitHubClient] fetchMyPRs() EXIT - empty output, returning []")
            return []
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let prs = try decoder.decode([PullRequest].self, from: data)
            print("[GitHubClient] fetchMyPRs() EXIT - returning \(prs.count) PRs")
            return prs
        } catch {
            print("[GitHubClient] fetchMyPRs() ERROR - JSON decode failed: \(error)")
            throw GitHubClientError.invalidJSON
        }
    }

    /// Fetches PRs where the current user is requested as a reviewer
    func fetchReviewRequestedPRs() async throws -> [PullRequest] {
        print("[GitHubClient] fetchReviewRequestedPRs() ENTRY")
        let fields = "number,title,url,author,state,isDraft,repository,updatedAt"
        let args = ["search", "prs", "--review-requested=@me", "--json", fields]

        let (output, exitCode) = try await runGhCommand(args)
        print("[GitHubClient] fetchReviewRequestedPRs() runGhCommand returned, exitCode=\(exitCode)")

        guard exitCode == 0 else {
            if exitCode == 127 {
                throw GitHubClientError.ghNotAvailable
            }
            throw GitHubClientError.commandFailed(exitCode)
        }

        guard let data = output.data(using: .utf8) else {
            return []
        }

        if data.isEmpty || output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("[GitHubClient] fetchReviewRequestedPRs() EXIT - empty output, returning []")
            return []
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let prs = try decoder.decode([PullRequest].self, from: data)
            print("[GitHubClient] fetchReviewRequestedPRs() EXIT - returning \(prs.count) PRs")
            return prs
        } catch {
            print("[GitHubClient] fetchReviewRequestedPRs() ERROR - JSON decode failed: \(error)")
            throw GitHubClientError.invalidJSON
        }
    }

    /// Runs gh CLI command with full path fallback
    private func runGhCommand(_ args: [String]) async throws -> (String, Int) {
        // Try common gh installation paths in order
        let ghPaths = [
            "/opt/homebrew/bin/gh",  // Homebrew on Apple Silicon
            "/usr/local/bin/gh",      // Homebrew on Intel
            "/opt/local/bin/gh",      // MacPorts
            "gh"                       // Fallback to PATH
        ]

        for ghPath in ghPaths {
            if ghPath != "gh" {
                // Check if file exists before trying
                guard FileManager.default.fileExists(atPath: ghPath) else {
                    continue
                }
            }

            let (output, exitCode) = try await runCommand(ghPath, args: args)

            // If command succeeded or failed with non-127 exit (not "command not found")
            if exitCode != 127 {
                return (output, exitCode)
            }
        }

        // All paths failed
        throw GitHubClientError.ghNotAvailable
    }

    /// Runs a shell command and returns output and exit code
    private func runCommand(_ command: String, args: [String]) async throws -> (String, Int) {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()

            // If command is an absolute path, use it directly
            if command.hasPrefix("/") {
                process.executableURL = URL(fileURLWithPath: command)
                process.arguments = args
            } else {
                // Otherwise use env to find it in PATH
                process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                process.arguments = [command] + args
            }

            // Separate pipes for stdout and stderr to capture errors
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            // Set up environment with common PATH locations for gh
            var environment = ProcessInfo.processInfo.environment
            let additionalPaths = [
                "/usr/local/bin",
                "/opt/homebrew/bin",
                "/opt/local/bin"
            ]
            if let existingPath = environment["PATH"] {
                environment["PATH"] = additionalPaths.joined(separator: ":") + ":" + existingPath
            } else {
                environment["PATH"] = additionalPaths.joined(separator: ":")
            }
            process.environment = environment

            do {
                // File logging for diagnostics
                let timestamp = ISO8601DateFormatter().string(from: Date())
                let logMsg = "[\(timestamp)] Running: \(command) \(args.joined(separator: " "))\n"
                let pathMsg = "[\(timestamp)] PATH: \(environment["PATH"] ?? "NOT SET")\n"
                if let handle = FileHandle(forWritingAtPath: "/var/tmp/prdesk-gh-debug.log") {
                    if let data = (logMsg + pathMsg).data(using: .utf8) {
                        handle.seekToEndOfFile()
                        handle.write(data)
                        handle.closeFile()
                    }
                } else {
                    try? (logMsg + pathMsg).write(toFile: "/var/tmp/prdesk-gh-debug.log", atomically: true, encoding: .utf8)
                }

                print("[GitHubClient] Running: \(command) \(args.joined(separator: " "))")
                print("[GitHubClient] PATH: \(environment["PATH"] ?? "NOT SET")")

                try process.run()

                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

                let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                let stderr = String(data: stderrData, encoding: .utf8) ?? ""

                process.waitUntilExit()
                let exitCode = Int(process.terminationStatus)

                // File logging for diagnostics
                let timestamp2 = ISO8601DateFormatter().string(from: Date())
                var resultLog = "[\(timestamp2)] Exit code: \(exitCode)\n"
                if !stdout.isEmpty {
                    resultLog += "[\(timestamp2)] STDOUT: \(stdout.prefix(200))...\n"
                }
                if !stderr.isEmpty {
                    resultLog += "[\(timestamp2)] STDERR: \(stderr)\n"
                }
                if let handle = FileHandle(forWritingAtPath: "/var/tmp/prdesk-gh-debug.log") {
                    if let data = resultLog.data(using: .utf8) {
                        handle.seekToEndOfFile()
                        handle.write(data)
                        handle.closeFile()
                    }
                }

                print("[GitHubClient] Exit code: \(exitCode)")
                if !stdout.isEmpty {
                    print("[GitHubClient] STDOUT: \(stdout)")
                }
                if !stderr.isEmpty {
                    print("[GitHubClient] STDERR: \(stderr)")
                }

                // Return stdout for parsing, but log stderr for diagnostics
                continuation.resume(returning: (stdout, exitCode))
            } catch {
                print("[GitHubClient] Error running command: \(error)")
                continuation.resume(throwing: error)
            }
        }
    }
}
