#!/usr/bin/env swift
import Foundation
struct PullRequestAuthor: Codable { let login: String }
struct PullRequest: Codable {
    let number: Int; let title: String; let url: String; let state: String
    let isDraft: Bool; let author: PullRequestAuthor; let repositoryFullName: String
    let updatedAt: String; let createdAt: String
}
struct PromptsConfiguration: Codable { let buttonText: String; let myPRs: String; let reviewRequested: String }
enum WidgetType { case myPRs; case reviewRequested }
class PromptConfigService {
    private var config: PromptsConfiguration
    private let configPath: URL
    init() {
        let appSupport = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/PRDesk")
        configPath = appSupport.appendingPathComponent("prompts.json")
        if let loadedConfig = Self.loadConfig(from: configPath) { config = loadedConfig }
        else { config = Self.defaultConfig(); Self.createDefaultConfig(at: configPath, config: config) }
    }
    func getConfig() -> PromptsConfiguration { return config }
    func replaceTemplateVariables(_ template: String, pr: PullRequest) -> String {
        var result = template
        result = result.replacingOccurrences(of: "{pr_number}", with: "\(pr.number)")
        result = result.replacingOccurrences(of: "{pr_title}", with: pr.title)
        result = result.replacingOccurrences(of: "{repo_name}", with: pr.repositoryFullName)
        result = result.replacingOccurrences(of: "{pr_url}", with: pr.url)
        result = result.replacingOccurrences(of: "{pr_author}", with: pr.author.login)
        result = result.replacingOccurrences(of: "{pr_state}", with: pr.state)
        result = result.replacingOccurrences(of: "{pr_draft}", with: pr.isDraft ? " (Draft)" : "")
        result = result.replacingOccurrences(of: "{pr_body}", with: "(not available)")
        return result
    }
    private static func loadConfig(from path: URL) -> PromptsConfiguration? {
        guard FileManager.default.fileExists(atPath: path.path) else { return nil }
        do { let data = try Data(contentsOf: path); return try JSONDecoder().decode(PromptsConfiguration.self, from: data) }
        catch { return nil }
    }
    private static func createDefaultConfig(at path: URL, config: PromptsConfiguration) {}
    private static func defaultConfig() -> PromptsConfiguration {
        PromptsConfiguration(buttonText: "Open in Claude", myPRs: "", reviewRequested: "")
    }
}
class ClaudeIntegrationService {
    private let promptConfigService: PromptConfigService
    init() { self.promptConfigService = PromptConfigService() }
    func generatePrompt(pr: PullRequest, widgetType: WidgetType) -> String {
        let config = promptConfigService.getConfig()
        let template = widgetType == .myPRs ? config.myPRs : config.reviewRequested
        return promptConfigService.replaceTemplateVariables(template, pr: pr)
    }
}

let testPR = PullRequest(number: 42, title: "Add feature", url: "https://github.com/test/repo/pull/42",
    state: "OPEN", isDraft: false, author: PullRequestAuthor(login: "testuser"),
    repositoryFullName: "test/repo", updatedAt: "2026-05-14T12:00:00Z", createdAt: "2026-05-13T10:00:00Z")

let service = ClaudeIntegrationService()
let reviewPrompt = service.generatePrompt(pr: testPR, widgetType: .reviewRequested)
print("=== REVIEW REQUESTED PROMPT ===")
print(reviewPrompt)
print("\n=== VERIFICATION ===")
print(reviewPrompt.contains("testuser") ? "✓ Contains author: testuser" : "❌ Missing author")
print(reviewPrompt.contains("42") ? "✓ Contains PR number: 42" : "❌ Missing PR number")
print(reviewPrompt.contains("test/repo") ? "✓ Contains repo: test/repo" : "❌ Missing repo")
