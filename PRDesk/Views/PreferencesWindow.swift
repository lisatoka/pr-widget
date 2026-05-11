//
//  PreferencesWindow.swift
//  PRDesk
//
//  Preferences window with Launch at Login toggle
//

import SwiftUI
import ServiceManagement

class PreferencesWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "PR Desk Preferences"
        window.center()
        window.contentView = NSHostingView(rootView: PreferencesView())

        self.init(window: window)
    }
}

struct PreferencesView: View {
    @State private var launchAtLoginEnabled: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        let _ = print("[PreferencesView] body computed")
        return VStack(spacing: 20) {
            Text("Preferences")
                .font(.title)
                .padding(.top)

            Toggle("Launch at Login", isOn: $launchAtLoginEnabled)
                .toggleStyle(.switch)
                .onChange(of: launchAtLoginEnabled) { newValue in
                    setLaunchAtLogin(enabled: newValue)
                }

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Spacer()
        }
        .padding()
        .frame(width: 400, height: 200)
        .onAppear {
            print("[PreferencesView] onAppear called")
            loadCurrentStatus()
        }
    }

    private func loadCurrentStatus() {
        // Load from UserDefaults
        let savedState = UserDefaults.standard.bool(forKey: "launchAtLoginEnabled")
        launchAtLoginEnabled = savedState

        // Verify with SMAppService
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            let actualState = (service.status == .enabled)

            // Sync if out of sync
            if actualState != savedState {
                launchAtLoginEnabled = actualState
                UserDefaults.standard.set(actualState, forKey: "launchAtLoginEnabled")
            }

            print("[Preferences] Launch at login status: \(launchAtLoginEnabled ? "enabled" : "disabled")")
        }
    }

    private func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp

            do {
                if enabled {
                    // Register for launch at login
                    if service.status == .enabled {
                        print("[Preferences] Already registered for launch at login")
                    } else {
                        try service.register()
                        print("[Preferences] Registered for launch at login")
                    }
                } else {
                    // Unregister from launch at login
                    if service.status == .notRegistered {
                        print("[Preferences] Already not registered")
                    } else {
                        try service.unregister()
                        print("[Preferences] Unregistered from launch at login")
                    }
                }

                // Save to UserDefaults
                UserDefaults.standard.set(enabled, forKey: "launchAtLoginEnabled")
                errorMessage = nil
            } catch {
                print("[Preferences] Error setting launch at login: \(error)")
                errorMessage = "Failed to update launch at login: \(error.localizedDescription)"

                // Revert toggle state
                launchAtLoginEnabled = !enabled
            }
        } else {
            // Fallback for older macOS versions
            errorMessage = "Launch at Login requires macOS 13 or later"
            launchAtLoginEnabled = false
        }
    }
}

#Preview {
    PreferencesView()
}
