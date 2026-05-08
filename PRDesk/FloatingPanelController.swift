//
//  FloatingPanelController.swift
//  PRDesk
//
//  Created by PR Desk
//

import AppKit
import SwiftUI

/// A borderless panel that sits on the desktop background (below normal windows)
class FloatingPanel: NSPanel {
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: backing,
            defer: flag
        )

        // Panel appearance
        self.isFloatingPanel = true
        self.level = .normal - 1  // Desktop background level (below normal windows)
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true

        // Interaction
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isMovableByWindowBackground = true
        self.acceptsMouseMovedEvents = true

        // Titlebar
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
    }
}

/// Controller that manages a floating panel with SwiftUI content
class FloatingPanelController<Content: View>: NSObject {
    private var panel: FloatingPanel
    private var hostingController: NSHostingController<Content>

    init(content: Content, frame: NSRect) {
        self.panel = FloatingPanel(
            contentRect: frame,
            backing: .buffered,
            defer: false
        )
        self.hostingController = NSHostingController(rootView: content)

        super.init()

        panel.contentView = hostingController.view
    }

    func show() {
        panel.orderFront(nil)
        panel.makeKey()
    }

    func hide() {
        panel.orderOut(nil)
    }

    var isVisible: Bool {
        return panel.isVisible
    }
}
