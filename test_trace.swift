#!/usr/bin/env swift
import Foundation

struct PromptsConfiguration: Codable {
    let buttonText: String
    let myPRs: String
    let reviewRequested: String
}

let myPRsPrompt = """
I need help addressing reviewer feedback on my pull request.

PR #{pr_number}: {pr_title}
Repository: {repo_name}
"""

let config = PromptsConfiguration(
    buttonText: "Open in Claude",
    myPRs: myPRsPrompt,
    reviewRequested: "Review prompt"
)

print("myPRs template:")
print(config.myPRs)
print("\nLength: \(config.myPRs.count)")

let replaced = config.myPRs.replacingOccurrences(of: "{pr_number}", with: "42")
print("\nAfter replacement:")
print(replaced)
print("Length: \(replaced.count)")
