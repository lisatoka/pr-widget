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
    /// - Parameter prompt: The prompt to pass to Claude Code
    func launchClaude(with prompt: String) {
        // Create a temporary shell script that will run claude with the prompt
        let tempDir = FileManager.default.temporaryDirectory
        let scriptPath = tempDir.appendingPathComponent("launch_claude_\(UUID().uuidString).sh")

        // Escape the prompt for shell script
        let escapedPrompt = prompt.replacingOccurrences(of: "'", with: "'\\''")

        // Create shell script content
        let scriptContent = """
        #!/bin/bash
        claude '\(escapedPrompt)'
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
