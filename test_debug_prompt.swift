#!/usr/bin/env swift
import Foundation

struct PullRequestAuthor: Codable {
    let login: String
}

struct PullRequest: Codable {
    let number: Int
    let title: String
    let url: String
    let state: String
    let isDraft: Bool
    let author: PullRequestAuthor
    let repositoryFullName: String
    let updatedAt: String
    let createdAt: String
}

let testPR = PullRequest(
    number: 42,
    title: "Test PR",
    url: "https://github.com/test/repo/pull/42",
    state: "OPEN",
    isDraft: false,
    author: PullRequestAuthor(login: "testuser"),
    repositoryFullName: "test/repo",
    updatedAt: "2026-05-14T12:00:00Z",
    createdAt: "2026-05-13T10:00:00Z"
)

let template = "PR #{pr_number}: {pr_title}"
var result = template
result = result.replacingOccurrences(of: "{pr_number}", with: "\(testPR.number)")
result = result.replacingOccurrences(of: "{pr_title}", with: testPR.title)

print("Template: \(template)")
print("Result: \(result)")
print("Length: \(result.count)")
