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
        // Escape the prompt for shell execution
        let escapedPrompt = escapeForShell(prompt)

        // Build the command to execute in Terminal
        // Using 'claude' command from Claude Code CLI
        let command = "claude \(escapedPrompt)"

        // AppleScript to open Terminal and execute the command
        let appleScript = """
        tell application "Terminal"
            activate
            do script "\(escapeForAppleScript(command))"
        end tell
        """

        // Execute the AppleScript
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScript) {
            let output = scriptObject.executeAndReturnError(&error)

            if let error = error {
                print("[TerminalLauncher] Error executing AppleScript: \(error)")
                showErrorAlert(message: "Failed to launch Terminal with Claude Code. Error: \(error)")
            } else {
                print("[TerminalLauncher] Successfully launched Terminal with Claude Code")
                print("[TerminalLauncher] Command: \(command)")
            }
        } else {
            print("[TerminalLauncher] Failed to create AppleScript object")
            showErrorAlert(message: "Failed to create AppleScript for Terminal launch")
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
