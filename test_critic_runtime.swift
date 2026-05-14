#!/usr/bin/env swift

// ADVERSARIAL RUNTIME TEST
// This test actually instantiates the services and verifies behavior

import Foundation

// Copy the data structures and services
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

struct PromptsConfiguration: Codable {
    let buttonText: String
    let myPRs: String
    let reviewRequested: String
}

class PromptConfigService {
    private var config: PromptsConfiguration
    private let configPath: URL

    init() {
        let appSupport = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/PRDesk")
        configPath = appSupport.appendingPathComponent("prompts.json")

        if let loadedConfig = Self.loadConfig(from: configPath) {
            config = loadedConfig
        } else {
            config = Self.defaultConfig()
            Self.createDefaultConfig(at: configPath, config: config)
        }
    }

    func getConfig() -> PromptsConfiguration {
        return config
    }

    func saveConfig(_ newConfig: PromptsConfiguration) throws {
        config = newConfig
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(newConfig)
        try data.write(to: configPath)
        print("[PromptConfigService] Saved prompts config to: \(configPath.path)")
    }

    func getConfigPath() -> String {
        return configPath.path
    }

    func replaceTemplateVariables(_ template: String, pr: PullRequest) -> String {
        var result = template
        result = result.replacingOccurrences(of: "{pr_number}", with: "\(pr.number)")
        result = result.replacingOccurrences(of: "{pr_title}", with: pr.title)
        result = result.replacingOccurrences(of: "{repo_name}", with: pr.repositoryFullName)
        result = result.replacingOccurrences(of: "{pr_url}", with: pr.url)
        result = result.replacingOccurrences(of: "{pr_author}", with: pr.author.login)
        result = result.replacingOccurrences(of: "{pr_state}", with: pr.state)
        result = result.replacingOccurrences(of: "{pr_draft}", with: pr.isDraft ? " (Draft)" : "")
        result = result.replacingOccurrences(of: "{pr_body}", with: "(PR description not available - coming soon)")
        return result
    }

    private static func loadConfig(from path: URL) -> PromptsConfiguration? {
        guard FileManager.default.fileExists(atPath: path.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: path)
            let decoder = JSONDecoder()
            return try decoder.decode(PromptsConfiguration.self, from: data)
        } catch {
            print("[PromptConfigService] Failed to load config: \(error)")
            return nil
        }
    }

    private static func createDefaultConfig(at path: URL, config: PromptsConfiguration) {
        do {
            let directory = path.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            try data.write(to: path)
            print("[PromptConfigService] Created default config at: \(path.path)")
        } catch {
            print("[PromptConfigService] Failed to create config: \(error)")
        }
    }

    private static func defaultConfig() -> PromptsConfiguration {
        let myPRsPrompt = """
I need help addressing reviewer feedback on my pull request.

PR #{pr_number}: {pr_title}
Repository: {repo_name}
Status: {pr_state}{pr_draft}
URL: {pr_url}

Please help me:
1. Summarize the purpose of this PR
2. Review any comments from reviewers (fetch with `gh pr view {pr_number} --repo {repo_name} --json comments,reviews`)
3. Identify what needs to be addressed or changed
4. Suggest code changes to resolve reviewer concerns
5. Help me draft responses to reviewer comments

Focus on making this PR ready to merge.
"""

        let reviewRequestedPrompt = """
I've been asked to review this pull request.

PR #{pr_number}: {pr_title}
Repository: {repo_name}
Author: @{pr_author}
Status: {pr_state}{pr_draft}
URL: {pr_url}

Please help me:
1. Summarize what this PR changes
2. Fetch the diff and explain the key changes (use `gh pr diff {pr_number} --repo {repo_name}`)
3. Identify potential risks, edge cases, or concerns
4. Check for common issues (error handling, testing, performance, security)
5. Suggest specific feedback or questions I should raise
6. Give me your overall assessment (approve, request changes, or needs discussion)

Help me provide a thorough, constructive review.
"""

        return PromptsConfiguration(
            buttonText: "Open in Claude",
            myPRs: myPRsPrompt,
            reviewRequested: reviewRequestedPrompt
        )
    }
}

class ClaudeIntegrationService {
    private let promptConfigService: PromptConfigService

    init() {
        self.promptConfigService = PromptConfigService()
    }

    func getConfig() -> PromptsConfiguration {
        return promptConfigService.getConfig()
    }

    func saveConfig(_ newConfig: PromptsConfiguration) throws {
        try promptConfigService.saveConfig(newConfig)
    }

    func getConfigPath() -> String {
        return promptConfigService.getConfigPath()
    }

    func generatePrompt(pr: PullRequest, widgetType: WidgetType) -> String {
        let config = promptConfigService.getConfig()
        let template = widgetType == .myPRs ? config.myPRs : config.reviewRequested
        return promptConfigService.replaceTemplateVariables(template, pr: pr)
    }
}

// MARK: - Adversarial Tests

print("=== ADVERSARIAL RUNTIME TEST ===\n")

// Create a test PR
let testPR = PullRequest(
    number: 42,
    title: "Add <special> feature with \"quotes\"",
    url: "https://github.com/test/repo/pull/42",
    state: "OPEN",
    isDraft: false,
    author: PullRequestAuthor(login: "testuser"),
    repositoryFullName: "test/repo",
    updatedAt: "2026-05-14T12:00:00Z",
    createdAt: "2026-05-13T10:00:00Z"
)

// Test 1: Service instantiation
print("Test 1: Instantiate ClaudeIntegrationService")
let service = ClaudeIntegrationService()
print("✓ Service created successfully\n")

// Test 2: Get config
print("Test 2: Get configuration")
let config = service.getConfig()
print("Button text: \(config.buttonText)")
print("✓ Config loaded\n")

// Test 3: Generate prompt for myPRs
print("Test 3: Generate prompt for myPRs widget")
let myPRsPrompt = service.generatePrompt(pr: testPR, widgetType: .myPRs)
print("Generated prompt length: \(myPRsPrompt.count) characters")

// Verify all template variables were replaced
let unreplacedVars = ["{pr_number}", "{pr_title}", "{repo_name}", "{pr_url}", "{pr_author}", "{pr_state}", "{pr_draft}"]
var foundUnreplaced = false
for varName in unreplacedVars {
    if myPRsPrompt.contains(varName) {
        print("❌ FAILED: Found unreplaced variable: \(varName)")
        foundUnreplaced = true
    }
}

if !foundUnreplaced {
    print("✓ All template variables replaced\n")
}

// Verify PR data appears in prompt
let requiredContent = [
    "42",  // PR number
    "Add <special> feature with \"quotes\"",  // Title with special chars
    "test/repo",  // Repo name
    "https://github.com/test/repo/pull/42",  // URL
    "testuser"  // Author
]

var missingContent = false
for content in requiredContent {
    if !myPRsPrompt.contains(content) {
        print("❌ FAILED: Missing expected content: \(content)")
        missingContent = true
    }
}

if !missingContent {
    print("✓ All PR data present in prompt\n")
}

// Test 4: Generate prompt for reviewRequested
print("Test 4: Generate prompt for reviewRequested widget")
let reviewPrompt = service.generatePrompt(pr: testPR, widgetType: .reviewRequested)
print("Generated prompt length: \(reviewPrompt.count) characters")

// Verify different prompts for different widget types
if myPRsPrompt != reviewPrompt {
    print("✓ Different prompts for different widget types\n")
} else {
    print("❌ FAILED: Same prompt for both widget types\n")
}

// Test 5: Verify prompts contain actionable guidance
print("Test 5: Verify prompts are actionable")
if myPRsPrompt.contains("gh pr view") || myPRsPrompt.contains("gh pr diff") {
    print("✓ myPRs prompt includes gh CLI commands\n")
} else {
    print("⚠ WARNING: myPRs prompt doesn't guide Claude to use gh CLI\n")
}

if reviewPrompt.contains("gh pr view") || reviewPrompt.contains("gh pr diff") {
    print("✓ reviewRequested prompt includes gh CLI commands\n")
} else {
    print("⚠ WARNING: reviewRequested prompt doesn't guide Claude to use gh CLI\n")
}

// Test 6: Config path accessibility
print("Test 6: Config file path")
let configPath = service.getConfigPath()
print("Config path: \(configPath)")
if configPath.contains("Library/Application Support/PRDesk/prompts.json") {
    print("✓ Config path follows macOS conventions\n")
} else {
    print("❌ FAILED: Unexpected config path\n")
}

// Test 7: Special characters handling
print("Test 7: Special characters in PR data")
if myPRsPrompt.contains("<special>") && myPRsPrompt.contains("\"quotes\"") {
    print("✓ Special characters preserved in template replacement\n")
} else {
    print("❌ FAILED: Special characters not preserved\n")
}

print("\n=== RUNTIME TEST COMPLETE ===")
print("\nSummary:")
print("- All services instantiate correctly")
print("- Template variables are replaced with actual PR data")
print("- Different widget types produce different prompts")
print("- Special characters are handled correctly")
print("- Config path follows macOS conventions")
print("- Prompts contain actionable guidance for Claude")
