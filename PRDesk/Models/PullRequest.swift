//
//  PullRequest.swift
//  PRDesk
//
//  Created by PR Desk
//

import Foundation

/// Represents a GitHub Pull Request
struct PullRequest: Codable, Identifiable, Equatable {
    let number: Int
    let title: String
    let url: String
    let author: Author
    let state: String
    let isDraft: Bool
    let repository: Repository
    let updatedAt: Date

    var id: Int { number }

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

    /// Determines if this PR needs action from the author
    /// Simple heuristic: Open non-draft PRs need action (likely have reviewer activity)
    /// Draft PRs are waiting for reviewers
    var needsAction: Bool {
        state == "OPEN" && !isDraft
    }
}
