#!/usr/bin/env swift
import Foundation

struct PromptsConfiguration: Codable {
    let buttonText: String
    let myPRs: String
    let reviewRequested: String
}

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

enum WidgetType {
    case myPRs
    case reviewRequested
}

class PromptConfigService {
    private var config: PromptsConfiguration

    init() {
        config = Self.defaultConfig()
        print("[DEBUG] Config created, myPRs length: \(config.myPRs.count)")
    }

    func getConfig() -> PromptsConfiguration {
        return config
    }

    func replaceTemplateVariables(_ template: String, pr: PullRequest) -> String {
        print("[DEBUG] Template before: length=\(template.count)")
        print("[DEBUG] Template: \(template.prefix(100))...")
        var result = template
        result = result.replacingOccurrences(of: "{pr_number}", with: "\(pr.number)")
        result = result.replacingOccurrences(of: "{pr_title}", with: pr.title)
        result = result.replacingOccurrences(of: "{repo_name}", with: pr.repositoryFullName)
        result = result.replacingOccurrences(of: "{pr_url}", with: pr.url)
        result = result.replacingOccurrences(of: "{pr_author}", with: pr.author.login)
        result = result.replacingOccurrences(of: "{pr_state}", with: pr.state)
        result = result.replacingOccurrences(of: "{pr_draft}", with: pr.isDraft ? " (Draft)" : "")
        result = result.replacingOccurrences(of: "{pr_body}", with: "(not available)")
        print("[DEBUG] Result after: length=\(result.count)")
        return result
    }

    private static func defaultConfig() -> PromptsConfiguration {
        let myPRsPrompt = """
I need help addressing reviewer feedback.

PR #{pr_number}: {pr_title}
Repository: {repo_name}
URL: {pr_url}
"""
        
        let reviewPrompt = "Review: {pr_title}"

        return PromptsConfiguration(
            buttonText: "Open in Claude",
            myPRs: myPRsPrompt,
            reviewRequested: reviewPrompt
        )
    }
}

class ClaudeIntegrationService {
    private let promptConfigService: PromptConfigService

    init() {
        self.promptConfigService = PromptConfigService()
    }

    func generatePrompt(pr: PullRequest, widgetType: WidgetType) -> String {
        let config = promptConfigService.getConfig()
        print("[DEBUG] Widget type: \(widgetType)")
        let template = widgetType == .myPRs ? config.myPRs : config.reviewRequested
        print("[DEBUG] Selected template length: \(template.count)")
        return promptConfigService.replaceTemplateVariables(template, pr: pr)
    }
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

let service = ClaudeIntegrationService()
let prompt = service.generatePrompt(pr: testPR, widgetType: .myPRs)
print("\nFinal prompt:")
print(prompt)
print("\nLength: \(prompt.count)")
