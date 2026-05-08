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
    private var panelController: FloatingPanelController<ContentView>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create floating panel with initial position
        let initialFrame = NSRect(x: 100, y: 100, width: 300, height: 400)
        panelController = FloatingPanelController(
            content: ContentView(),
            frame: initialFrame
        )
        panelController?.show()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
