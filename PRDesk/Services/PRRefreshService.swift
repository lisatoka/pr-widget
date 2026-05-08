//
//  PRRefreshService.swift
//  PRDesk
//
//  Coordinates fetching PR data from GitHub and persisting to local storage
//

import Foundation

/// Coordinates PR data refresh operations
class PRRefreshService {
    private let client = GitHubClient()
    private let store = PRDataStore()

    /// Fetches PR data from GitHub and saves to local storage
    func refresh() async throws {
        print("[PRRefreshService] Starting PR data refresh...")

        // Fetch both PR lists concurrently
        async let myPRs = client.fetchMyPRs()
        async let reviewRequestedPRs = client.fetchReviewRequestedPRs()

        // Wait for both to complete
        let (myPRsResult, reviewPRsResult) = try await (myPRs, reviewRequestedPRs)
        print("[PRRefreshService] Fetched \(myPRsResult.count) myPRs, \(reviewPRsResult.count) reviewRequested PRs")

        // Save both to storage
        try store.saveMyPRs(myPRsResult)
        try store.saveReviewRequestedPRs(reviewPRsResult)
        print("[PRRefreshService] PR data saved successfully")
    }
}
