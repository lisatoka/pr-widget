#!/usr/bin/env swift

import Foundation

// Copy the actual implementation to test it
enum GitHubClientError: Error, Equatable {
    case ghNotAvailable
    case commandFailed(Int)
    case invalidJSON
}

struct PullRequest: Codable, Identifiable, Equatable {
    let number: Int
    let title: String
    let url: String
    let author: Author
    let state: String
    let isDraft: Bool
    let headRepository: Repository?
    let headRepositoryOwner: RepositoryOwner
    let updatedAt: Date

    var id: Int { number }

    struct Author: Codable, Equatable {
        let login: String
    }

    struct Repository: Codable, Equatable {
        let name: String
    }

    struct RepositoryOwner: Codable, Equatable {
        let login: String
    }

    var repositoryFullName: String {
        "\(headRepositoryOwner.login)/\(headRepository?.name ?? "unknown")"
    }
}

class GitHubClient {
    func fetchMyPRs() async throws -> [PullRequest] {
        let fields = "number,title,url,author,state,isDraft,headRepository,headRepositoryOwner,updatedAt"
        let command = "/opt/homebrew/bin/gh"
        let args = ["pr", "list", "--author", "@me", "--json", fields]

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

// Test the real implementation
Task {
    do {
        let client = GitHubClient()
        print("🧪 Testing GitHubClient.fetchMyPRs()...")

        let prs = try await client.fetchMyPRs()

        print("✅ SUCCESS: Fetched \(prs.count) PRs")

        if prs.isEmpty {
            print("   (No PRs found for current user)")
        } else {
            print("\n📋 PRs found:")
            for pr in prs {
                print("   #\(pr.number): \(pr.title)")
                print("      Repo: \(pr.repositoryFullName)")
                print("      URL: \(pr.url)")
                print("      State: \(pr.state), Draft: \(pr.isDraft)")
                print("      Updated: \(pr.updatedAt)")
                print("")
            }
        }

        exit(0)
    } catch GitHubClientError.ghNotAvailable {
        print("❌ FAIL: gh CLI not available")
        exit(1)
    } catch GitHubClientError.commandFailed(let code) {
        print("❌ FAIL: gh command failed with exit code \(code)")
        exit(1)
    } catch GitHubClientError.invalidJSON {
        print("❌ FAIL: Invalid JSON from gh CLI")
        exit(1)
    } catch {
        print("❌ FAIL: Unexpected error: \(error)")
        exit(1)
    }
}

// Keep the script running
RunLoop.main.run()
