//
//  PRDeskApp.swift
//  PRDesk
//
//  Created by PR Desk
//

import SwiftUI
import AppKit

@main
struct PRDeskApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var myPRsPanel: FloatingPanelController<ContentView>?
    private var reviewRequestedPanel: FloatingPanelController<ContentView>?
    private var detailWindow: DetailWindowController?
    private var preferencesWindow: PreferencesWindowController?
    private let refreshService = PRRefreshService()
    private let promptConfigService = PromptConfigService()  // Initialize early to create default config
    private var refreshTimer: Timer?
    private let basePollingInterval: TimeInterval = 300  // 5 minutes in seconds
    private var currentPollingInterval: TimeInterval = 300  // Current interval (may increase with backoff)
    private var consecutiveFailures: Int = 0  // Track failures for exponential backoff

    override init() {
        super.init()
        let initLog = "[PRDeskApp] AppDelegate init called\n"
        try? initLog.write(toFile: "/var/tmp/prdesk-app-debug.log", atomically: true, encoding: .utf8)
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Override the Settings menu before SwiftUI creates it
        setupSettingsMenuOverride()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Also try after launching, in case menu was created late
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setupSettingsMenuOverride()
        }

        // File logging for diagnostics
        let logMsg = "[PRDeskApp] applicationDidFinishLaunching started\n"
        try? logMsg.write(toFile: "/var/tmp/prdesk-app-debug.log", atomically: true, encoding: .utf8)

        // Refresh PR data on launch
        Task {
            let taskLog = "[PRDeskApp] Refresh task started\n"
            if let handle = FileHandle(forWritingAtPath: "/var/tmp/prdesk-app-debug.log") {
                if let data = taskLog.data(using: .utf8) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            }

            do {
                try await refreshService.refresh()
                let successLog = "[PRDeskApp] ✅ PR data refreshed successfully\n"
                if let handle = FileHandle(forWritingAtPath: "/var/tmp/prdesk-app-debug.log") {
                    if let data = successLog.data(using: .utf8) {
                        handle.seekToEndOfFile()
                        handle.write(data)
                        handle.closeFile()
                    }
                }
                print("✅ PR data refreshed successfully")
            } catch {
                let errorLog = "[PRDeskApp] ⚠️  Failed to refresh PR data: \(error)\n"
                if let handle = FileHandle(forWritingAtPath: "/var/tmp/prdesk-app-debug.log") {
                    if let data = errorLog.data(using: .utf8) {
                        handle.seekToEndOfFile()
                        handle.write(data)
                        handle.closeFile()
                    }
                }
                print("⚠️  Failed to refresh PR data: \(error)")
            }
        }

        // Start periodic polling
        startPeriodicPolling()

        // Create first widget: "My PRs"
        let myPRsFrame = NSRect(x: 100, y: 100, width: 300, height: 400)
        myPRsPanel = FloatingPanelController(
            content: ContentView(widgetType: .myPRs),
            frame: myPRsFrame
        )
        myPRsPanel?.show()

        // Create second widget: "PRs I'm Tagged In" with offset position
        let reviewRequestedFrame = NSRect(x: 420, y: 100, width: 300, height: 400)
        reviewRequestedPanel = FloatingPanelController(
            content: ContentView(widgetType: .reviewRequested),
            frame: reviewRequestedFrame
        )
        reviewRequestedPanel?.show()

        // Observe PR click notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowDetailWindow(_:)),
            name: NSNotification.Name("ShowDetailWindow"),
            object: nil
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    @objc private func handleShowDetailWindow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let widgetType = userInfo["widgetType"] as? WidgetType else {
            return
        }

        let tab: DetailView.DetailTab = (widgetType == .myPRs) ? .myPRs : .reviewRequested
        showDetailWindow(tab: tab)
    }

    /// Show the detail window
    func showDetailWindow(tab: DetailView.DetailTab = .myPRs) {
        detailWindow?.close()  // Explicitly close existing window
        detailWindow = DetailWindowController(initialTab: tab)
        detailWindow?.showWindow(nil)
    }

    /// Show the preferences window
    @objc func showPreferences(_ sender: Any?) {
        if preferencesWindow == nil {
            preferencesWindow = PreferencesWindowController()
        }
        preferencesWindow?.showWindow(nil)
        preferencesWindow?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Override the Settings menu to call our custom preferences
    private func setupSettingsMenuOverride() {
        // Find the automatically created Settings menu item and update its action
        if let appMenu = NSApp.mainMenu?.items.first?.submenu {
            for item in appMenu.items {
                if item.title.contains("Settings") || item.title.contains("Preferences") {
                    item.target = self
                    item.action = #selector(showPreferences(_:))
                    print("[AppDelegate] Overrode Settings menu item: \(item.title)")
                }
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        stopPeriodicPolling()
    }

    // MARK: - Periodic Polling

    private func startPeriodicPolling() {
        let intervalMinutes = Int(currentPollingInterval / 60)
        print("[Polling] Starting periodic polling with \(intervalMinutes) minute interval")

        // Create timer that fires every currentPollingInterval seconds
        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: currentPollingInterval,
            repeats: true
        ) { [weak self] _ in
            self?.handleTimerFire()
        }
    }

    private func stopPeriodicPolling() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        print("[Polling] Timer stopped")
    }

    @objc private func handleTimerFire() {
        print("[Polling] Timer fired - refreshing PR data")

        Task {
            do {
                try await refreshService.refresh()
                print("[Polling] ✅ Periodic refresh completed successfully")

                // Reset backoff on success
                await MainActor.run {
                    if consecutiveFailures > 0 {
                        print("[Polling] Resetting backoff (was \(consecutiveFailures) failures)")
                        consecutiveFailures = 0
                        currentPollingInterval = basePollingInterval
                        restartTimerWithNewInterval()
                    }
                }
            } catch {
                print("[Polling] ⚠️  Periodic refresh failed: \(error)")

                // Increase backoff on failure
                await MainActor.run {
                    consecutiveFailures += 1
                    let previousInterval = currentPollingInterval
                    currentPollingInterval = calculateBackoffInterval()
                    let intervalMinutes = Int(currentPollingInterval / 60)
                    print("[Polling] Exponential backoff: \(consecutiveFailures) consecutive failures, next poll in \(intervalMinutes) minutes")

                    // Restart timer with new interval if it changed
                    if currentPollingInterval != previousInterval {
                        restartTimerWithNewInterval()
                    }
                }
            }
        }
    }

    /// Calculate exponential backoff interval: 5min → 10min → 20min → 40min → 60min (max)
    private func calculateBackoffInterval() -> TimeInterval {
        let backoffMultiplier = pow(2.0, Double(consecutiveFailures))
        let newInterval = basePollingInterval * backoffMultiplier
        let maxInterval: TimeInterval = 3600  // Cap at 60 minutes
        return min(newInterval, maxInterval)
    }

    /// Restart the timer with the current polling interval
    private func restartTimerWithNewInterval() {
        stopPeriodicPolling()
        startPeriodicPolling()
    }
}
