#!/usr/bin/env swift
//
// Integration test for GitHubClient.fetchMyPRs() using gh search prs
//

import Foundation

// Inline the models and client for testing
struct PullRequest: Codable, Equatable {
    let number: Int
    let title: String
    let url: String
    let author: Author
    let state: String
    let isDraft: Bool
    let repository: Repository
    let updatedAt: Date

    struct Author: Codable, Equatable {
        let login: String
    }

    struct Repository: Codable, Equatable {
        let name: String
        let nameWithOwner: String
    }

    var repositoryFullName: String {
        repository.nameWithOwner
    }
}

enum GitHubClientError: Error {
    case ghNotAvailable
    case commandFailed(Int)
    case invalidJSON
}

class GitHubClient {
    func fetchMyPRs() async throws -> [PullRequest] {
        let fields = "number,title,url,author,state,isDraft,repository,updatedAt"
        let command = "/opt/homebrew/bin/gh"
        let args = ["search", "prs", "--author=@me", "--json", fields]

        let (output, exitCode) = try await runCommand(command, args: args)

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

    private func runCommand(_ command: String, args: [String]) async throws -> (String, Int) {
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
}

// Test
Task {
    do {
        let client = GitHubClient()
        let prs = try await client.fetchMyPRs()

        print("✅ PASS: fetchMyPRs succeeded")
        print("   Found \(prs.count) PRs")
        if let first = prs.first {
            print("   First PR: #\(first.number) - \(first.title)")
            print("   Repository: \(first.repositoryFullName)")
            print("   State: \(first.state), Draft: \(first.isDraft)")
            print("   Updated: \(first.updatedAt)")
        }
    } catch {
        print("❌ FAIL: fetchMyPRs failed with error: \(error)")
    }
    exit(0)
}

RunLoop.main.run()
