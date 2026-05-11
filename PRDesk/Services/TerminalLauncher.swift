//
//  TerminalLauncher.swift
//  PRDesk
//
//  Service for launching Terminal.app with Claude Code
//

import Foundation
import AppKit

/// Service that launches Terminal.app and executes Claude Code with a prompt
class TerminalLauncher {
    /// Launches Terminal.app and executes Claude Code with the provided prompt
    /// - Parameters:
    ///   - prompt: The prompt to pass to Claude Code
    ///   - repositoryName: The full repository name (e.g., "owner/repo") to find and cd into
    func launchClaude(with prompt: String, repositoryName: String? = nil) {
        // Create a temporary shell script that will run claude with the prompt
        let tempDir = FileManager.default.temporaryDirectory
        let scriptPath = tempDir.appendingPathComponent("launch_claude_\(UUID().uuidString).sh")

        // Escape the prompt for shell script
        let escapedPrompt = prompt.replacingOccurrences(of: "'", with: "'\\''")

        // Try to find the repository directory
        var cdCommand = ""
        if let repoName = repositoryName {
            if let repoPath = findRepositoryPath(repositoryName: repoName) {
                print("[TerminalLauncher] Found repository at: \(repoPath)")
                cdCommand = "cd '\(repoPath)' && "
            } else {
                print("[TerminalLauncher] Could not find repository: \(repoName)")
            }
        }

        // Create shell script content
        let scriptContent = """
        #!/bin/bash
        \(cdCommand)claude '\(escapedPrompt)'
        """

        do {
            // Write the script to the temp file
            try scriptContent.write(to: scriptPath, atomically: true, encoding: .utf8)

            // Make it executable
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath.path)

            // Open the script in Terminal (this will execute it)
            NSWorkspace.shared.openFile(scriptPath.path, withApplication: "Terminal")

            print("[TerminalLauncher] Created and opened script at: \(scriptPath.path)")

        } catch {
            print("[TerminalLauncher] Error creating script: \(error)")

            // Fallback: copy to clipboard
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(prompt, forType: .string)

            showErrorAlert(message: "Could not auto-launch Claude. The prompt has been copied to your clipboard.\n\nOpen Terminal and run:\nclaude '<paste here>'")
        }
    }

    // MARK: - Private Helpers

    /// Finds the local path to a repository
    /// - Parameter repositoryName: The full repository name (e.g., "owner/repo")
    /// - Returns: The absolute path to the repository if found, nil otherwise
    private func findRepositoryPath(repositoryName: String) -> String? {
        // Extract just the repo name (e.g., "canva" from "canva/canva")
        let repoShortName = repositoryName.split(separator: "/").last.map(String.init) ?? repositoryName

        // Common base directories where repos might be cloned
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let searchPaths = [
            "\(homeDir)/code",
            "\(homeDir)/Code",
            "\(homeDir)/repos",
            "\(homeDir)/git",
            "\(homeDir)/src",
            "\(homeDir)/work",
            "\(homeDir)/Work",
            "\(homeDir)/Projects",
            "\(homeDir)/projects",
            "\(homeDir)/dev",
            "\(homeDir)/Development",
            homeDir  // Also check home directory directly
        ]

        // For each search path, look for the repository
        for basePath in searchPaths {
            // Try the short name (e.g., ~/code/canva)
            let shortPath = "\(basePath)/\(repoShortName)"
            if isGitRepository(at: shortPath) {
                return shortPath
            }

            // Try the full name (e.g., ~/code/canva/canva or ~/code/owner/repo)
            let fullPath = "\(basePath)/\(repositoryName)"
            if isGitRepository(at: fullPath) {
                return fullPath
            }
        }

        return nil
    }

    /// Checks if a directory is a git repository
    /// - Parameter path: The directory path to check
    /// - Returns: true if the directory exists and contains a .git folder
    private func isGitRepository(at path: String) -> Bool {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false

        // Check if path exists and is a directory
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return false
        }

        // Check if .git exists
        let gitPath = "\(path)/.git"
        return fileManager.fileExists(atPath: gitPath)
    }

    /// Escapes a string for safe use in shell commands
    private func escapeForShell(_ string: String) -> String {
        // Use single quotes and escape any single quotes in the string
        let escaped = string.replacingOccurrences(of: "'", with: "'\\''")
        return "'\(escaped)'"
    }

    /// Escapes a string for safe use in AppleScript
    private func escapeForAppleScript(_ string: String) -> String {
        // Escape backslashes, double quotes, and special characters for AppleScript
        return string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }

    /// Shows an error alert to the user
    private func showErrorAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = "Claude Launch Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
