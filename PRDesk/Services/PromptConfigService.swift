//
//  PromptConfigService.swift
//  PRDesk
//
//  Service for managing customizable Claude prompts configuration
//

import Foundation

/// Configuration structure for Claude prompts with customizable button text
struct PromptsConfiguration: Codable {
    let buttonText: String
    let myPRs: String
    let reviewRequested: String
}

/// Service that handles loading, parsing, and managing Claude prompt configuration
class PromptConfigService {
    private var config: PromptsConfiguration
    private let configPath: URL

    /// Initialize the service and load config from Application Support
    init() {
        // Set up config file path
        let appSupport = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/PRDesk")
        configPath = appSupport.appendingPathComponent("prompts.json")

        // Load config or create default
        if let loadedConfig = Self.loadConfig(from: configPath) {
            config = loadedConfig
        } else {
            // Use default prompts and create config file
            config = Self.defaultConfig()
            Self.createDefaultConfig(at: configPath, config: config)
        }
    }

    /// Get the current prompts configuration
    func getConfig() -> PromptsConfiguration {
        return config
    }

    /// Save new prompts configuration
    /// - Parameter newConfig: The new prompts configuration to save
    /// - Throws: Error if save fails
    func saveConfig(_ newConfig: PromptsConfiguration) throws {
        // Update in-memory config
        config = newConfig

        // Save to disk
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(newConfig)
        try data.write(to: configPath)

        print("[PromptConfigService] Saved prompts config to: \(configPath.path)")
    }

    /// Get the config file path (useful for UI to show user where file is located)
    func getConfigPath() -> String {
        return configPath.path
    }

    /// Replaces template variables in a prompt template with actual PR data
    /// - Parameters:
    ///   - template: The prompt template string with variables like {pr_number}, {pr_title}, etc.
    ///   - pr: The pull request data to substitute
    /// - Returns: The template with variables replaced by actual PR data
    func replaceTemplateVariables(_ template: String, pr: PullRequest) -> String {
        var result = template

        // Replace all supported template variables
        result = result.replacingOccurrences(of: "{pr_number}", with: "\(pr.number)")
        result = result.replacingOccurrences(of: "{pr_title}", with: pr.title)
        result = result.replacingOccurrences(of: "{repo_name}", with: pr.repositoryFullName)
        result = result.replacingOccurrences(of: "{pr_url}", with: pr.url)
        result = result.replacingOccurrences(of: "{pr_author}", with: pr.author.login)
        result = result.replacingOccurrences(of: "{pr_state}", with: pr.state)
        result = result.replacingOccurrences(of: "{pr_draft}", with: pr.isDraft ? " (Draft)" : "")

        // {pr_body} is not yet available in PullRequest model - use placeholder
        result = result.replacingOccurrences(of: "{pr_body}", with: "(PR description not available - coming soon)")

        return result
    }

    // MARK: - Private Helpers

    /// Loads config from disk
    /// - Parameter path: Path to prompts.json file
    /// - Returns: Loaded config or nil if not found or invalid
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

    /// Creates default config file if it doesn't exist
    /// - Parameters:
    ///   - path: Path to prompts.json file
    ///   - config: Config to write
    private static func createDefaultConfig(at path: URL, config: PromptsConfiguration) {
        do {
            // Create directory if it doesn't exist
            let directory = path.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            // Write config file
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            try data.write(to: path)

            print("[PromptConfigService] Created default config at: \(path.path)")
        } catch {
            print("[PromptConfigService] Failed to create config: \(error)")
        }
    }

    /// Returns the default prompt configuration
    /// - Returns: Default config with sensible prompts and button text
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
