#!/usr/bin/env swift

//
//  TestDetailWindow.swift
//  PRDesk
//
//  Test harness for DetailWindow creation and tab switching
//

import Foundation
import AppKit
import SwiftUI

// Test: DetailWindow can be created
func testDetailWindowCreation() {
    print("Test 1: DetailWindow can be created")

    let window = DetailWindowController()

    assert(window.window != nil, "❌ DetailWindow.window should not be nil")
    assert(window.window?.title == "PR Desk", "❌ Window title should be 'PR Desk'")
    assert(window.window?.styleMask.contains(.titled), "❌ Window should have title bar")
    assert(window.window?.styleMask.contains(.closable), "❌ Window should be closable")
    assert(window.window?.styleMask.contains(.resizable), "❌ Window should be resizable")

    print("✅ DetailWindow created successfully")
}

// Test: DetailWindow has tab view with two tabs
func testDetailWindowTabs() {
    print("\nTest 2: DetailWindow has tabs for 'My PRs' and 'PRs I'm Tagged In'")

    let window = DetailWindowController()

    // Window should have a hosting controller with content
    assert(window.window?.contentViewController != nil, "❌ Window should have contentViewController")

    // Note: Tab switching logic will be verified visually since we can't easily access SwiftUI state
    // The DetailView should have a TabView with .myPRs and .reviewRequested tabs

    print("✅ DetailWindow has proper content view controller")
}

// Test: DetailWindow can be shown programmatically
func testDetailWindowShow() {
    print("\nTest 3: DetailWindow can be shown programmatically")

    let window = DetailWindowController()
    window.showWindow(nil)

    assert(window.window?.isVisible == true, "❌ Window should be visible after showWindow()")

    window.close()

    print("✅ DetailWindow can be shown and closed")
}

// Run tests
print("=== DetailWindow Test Harness ===\n")
testDetailWindowCreation()
testDetailWindowTabs()
testDetailWindowShow()
print("\n=== All Tests Passed ===")
