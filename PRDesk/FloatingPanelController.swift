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
    private var sizeObserver: NSKeyValueObservation?

    init(content: Content, frame: NSRect) {
        self.panel = FloatingPanel(
            contentRect: frame,
            backing: .buffered,
            defer: false
        )
        self.hostingController = NSHostingController(rootView: content)

        super.init()

        panel.contentView = hostingController.view

        // Observe size changes from SwiftUI content and resize panel accordingly
        setupSizeObserver()
    }

    private func setupSizeObserver() {
        // Observe intrinsic content size changes
        sizeObserver = hostingController.view.observe(\.fittingSize, options: [.new]) { [weak self] view, change in
            guard let self = self, let newSize = change.newValue else { return }

            // Only resize if the size actually changed
            let currentSize = self.panel.frame.size
            if abs(currentSize.width - newSize.width) > 1 || abs(currentSize.height - newSize.height) > 1 {
                self.resizePanel(to: newSize)
            }
        }
    }

    private func resizePanel(to newSize: NSSize) {
        // Preserve the top-left corner position while resizing
        let currentFrame = panel.frame
        let newOriginY = currentFrame.origin.y + (currentFrame.size.height - newSize.height)
        let newFrame = NSRect(
            x: currentFrame.origin.x,
            y: newOriginY,
            width: newSize.width,
            height: newSize.height
        )
        panel.setFrame(newFrame, display: true, animate: true)
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

    deinit {
        sizeObserver?.invalidate()
    }
}
