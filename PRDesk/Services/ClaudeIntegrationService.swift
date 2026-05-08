//
//  ClaudeIntegrationService.swift
//  PRDesk
//
//  Service for Claude Code integration
//

import Foundation

/// Service that handles Claude Code integration
class ClaudeIntegrationService {
    /// Generates an appropriate Claude Code prompt based on the PR and widget context
    /// - Parameters:
    ///   - pr: The pull request to generate a prompt for
    ///   - widgetType: The widget context (.myPRs or .reviewRequested)
    /// - Returns: A context-rich, actionable prompt for Claude Code
    func generatePrompt(pr: PullRequest, widgetType: WidgetType) -> String {
        switch widgetType {
        case .myPRs:
            return generateMyPRsPrompt(pr: pr)
        case .reviewRequested:
            return generateReviewRequestedPrompt(pr: pr)
        }
    }

    // MARK: - Private Helpers

    /// Generates a prompt for "My PRs" context
    /// Focus: PR summary, reviewer comments, what needs addressing
    private func generateMyPRsPrompt(pr: PullRequest) -> String {
        let prInfo = """
        I need help addressing reviewer feedback on my pull request.

        PR #\(pr.number): \(pr.title)
        Repository: \(pr.repositoryFullName)
        Status: \(pr.state)\(pr.isDraft ? " (Draft)" : "")
        URL: \(pr.url)

        Please help me:
        1. Summarize the purpose of this PR
        2. Review any comments from reviewers (fetch with `gh pr view \(pr.number) --repo \(pr.repositoryFullName) --json comments,reviews`)
        3. Identify what needs to be addressed or changed
        4. Suggest code changes to resolve reviewer concerns
        5. Help me draft responses to reviewer comments

        Focus on making this PR ready to merge.
        """

        return prInfo
    }

    /// Generates a prompt for "PRs I'm Tagged In" context
    /// Focus: Review perspective, what changed, risks, opinion
    private func generateReviewRequestedPrompt(pr: PullRequest) -> String {
        let prInfo = """
        I've been asked to review this pull request.

        PR #\(pr.number): \(pr.title)
        Repository: \(pr.repositoryFullName)
        Author: @\(pr.author.login)
        Status: \(pr.state)\(pr.isDraft ? " (Draft)" : "")
        URL: \(pr.url)

        Please help me:
        1. Summarize what this PR changes
        2. Fetch the diff and explain the key changes (use `gh pr diff \(pr.number) --repo \(pr.repositoryFullName)`)
        3. Identify potential risks, edge cases, or concerns
        4. Check for common issues (error handling, testing, performance, security)
        5. Suggest specific feedback or questions I should raise
        6. Give me your overall assessment (approve, request changes, or needs discussion)

        Help me provide a thorough, constructive review.
        """

        return prInfo
    }
}
