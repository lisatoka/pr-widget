//
//  ClaudeIntegrationService.swift
//  PRDesk
//
//  Service for Claude Code integration
//

import Foundation

/// Service that handles Claude Code integration
/// This service now delegates to PromptConfigService for prompt management
class ClaudeIntegrationService {
    private let promptConfigService: PromptConfigService

    /// Initialize the service with PromptConfigService
    init() {
        self.promptConfigService = PromptConfigService()
    }

    /// Get the current prompts configuration
    func getConfig() -> PromptsConfiguration {
        return promptConfigService.getConfig()
    }

    /// Save new prompts configuration
    /// - Parameter newConfig: The new prompts configuration to save
    /// - Throws: Error if save fails
    func saveConfig(_ newConfig: PromptsConfiguration) throws {
        try promptConfigService.saveConfig(newConfig)
    }

    /// Get the config file path (useful for UI to show user where file is located)
    func getConfigPath() -> String {
        return promptConfigService.getConfigPath()
    }

    /// Generates an appropriate Claude Code prompt based on the PR and widget context
    /// - Parameters:
    ///   - pr: The pull request to generate a prompt for
    ///   - widgetType: The widget context (.myPRs or .reviewRequested)
    /// - Returns: A context-rich, actionable prompt for Claude Code
    func generatePrompt(pr: PullRequest, widgetType: WidgetType) -> String {
        let config = promptConfigService.getConfig()
        let template = widgetType == .myPRs ? config.myPRs : config.reviewRequested
        return promptConfigService.replaceTemplateVariables(template, pr: pr)
    }
}
