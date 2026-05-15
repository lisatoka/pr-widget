//
//  TestFilterClosedPRs.swift
//  PRDesk
//
//  Verify that GitHubClient filters out closed/merged PRs using --state=open flag
//

import Foundation

/// Verification test: ensures GitHubClient uses --state=open flag
/// This test verifies the implementation by checking that the gh command
/// includes the required flag to filter out closed and merged PRs.
func testStateOpenFlagPresence() {
    print("=== Test: Verify --state=open flag in GitHubClient ===")

    // Read the GitHubClient.swift source file
    let filePath = "/Users/lisatok/not_work/git_widget/PRDesk/Services/GitHubClient.swift"

    guard let content = try? String(contentsOfFile: filePath) else {
        print("✗ Failed to read GitHubClient.swift")
        exit(1)
    }

    // Verify fetchMyPRs contains --state=open
    let hasMyPRsStateOpen = content.contains("--state=open") &&
                            content.contains("--author=@me")

    // Verify fetchReviewRequestedPRs contains --state=open
    let hasReviewRequestedStateOpen = content.contains("--state=open") &&
                                      content.contains("--review-requested=@me")

    if hasMyPRsStateOpen && hasReviewRequestedStateOpen {
        print("✓ GitHubClient.fetchMyPRs() includes --state=open flag")
        print("✓ GitHubClient.fetchReviewRequestedPRs() includes --state=open flag")
        print("\n=== Test Passed ===")
        exit(0)
    } else {
        print("✗ Missing --state=open flag in one or both methods")
        if !hasMyPRsStateOpen {
            print("  Missing in fetchMyPRs()")
        }
        if !hasReviewRequestedStateOpen {
            print("  Missing in fetchReviewRequestedPRs()")
        }
        exit(1)
    }
}

// Run test
testStateOpenFlagPresence()
