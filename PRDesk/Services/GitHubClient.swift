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
        let fields = "number,title,url,author,state,isDraft,repository,updatedAt"
        let args = ["search", "prs", "--author=@me", "--json", fields]

        let (output, exitCode) = try await runCommand("gh", args: args)

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
            return []
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let prs = try decoder.decode([PullRequest].self, from: data)
            return prs
        } catch {
            throw GitHubClientError.invalidJSON
        }
    }

    /// Fetches PRs where the current user is requested as a reviewer
    func fetchReviewRequestedPRs() async throws -> [PullRequest] {
        let fields = "number,title,url,author,state,isDraft,repository,updatedAt"
        let args = ["search", "prs", "--review-requested=@me", "--json", fields]

        let (output, exitCode) = try await runCommand("gh", args: args)

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
            return []
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let prs = try decoder.decode([PullRequest].self, from: data)
            return prs
        } catch {
            throw GitHubClientError.invalidJSON
        }
    }

    /// Runs a shell command and returns output and exit code
    private func runCommand(_ command: String, args: [String]) async throws -> (String, Int) {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [command] + args

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
}
