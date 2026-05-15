//
//  TestDetailWindowButtonText.swift
//  PRDesk
//
//  Test that DetailWindow button text uses configurable value from PromptConfigService
//

import Foundation

@main
struct TestRunner {
    static func main() {
        testDetailWindowUsesConfigurableButtonText()
    }
}

// Test that DetailRowView uses PromptConfigService for button text
func testDetailWindowUsesConfigurableButtonText() {
    print("[TestDetailWindowButtonText] Starting test...")

    // Create PromptConfigService and verify it returns the default button text
    let service = PromptConfigService()
    let config = service.getConfig()

    // The config should have a buttonText field
    let buttonText = config.buttonText
    print("[TestDetailWindowButtonText] Button text from config: '\(buttonText)'")

    // DetailRowView should use PromptConfigService for button text
    // We can't directly test SwiftUI views in a command-line test,
    // but we can verify that PromptConfigService returns the correct button text

    // Save a custom config with different button text
    let customConfig = PromptsConfiguration(
        buttonText: "Custom Button Text",
        myPRs: "Custom prompt 1",
        reviewRequested: "Custom prompt 2"
    )

    do {
        try service.saveConfig(customConfig)

        // Create a new service instance to verify it loads the custom config
        let newService = PromptConfigService()
        let loadedConfig = newService.getConfig()

        // Verify the button text matches our custom value
        assert(loadedConfig.buttonText == "Custom Button Text",
               "Button text should be 'Custom Button Text', got '\(loadedConfig.buttonText)'")

        print("[TestDetailWindowButtonText] ✅ Button text is customizable and persists")

        // Test that the button text can be changed again
        let anotherConfig = PromptsConfiguration(
            buttonText: "Ask Claude for Help",
            myPRs: "Another prompt 1",
            reviewRequested: "Another prompt 2"
        )
        try service.saveConfig(anotherConfig)

        let thirdService = PromptConfigService()
        let thirdConfig = thirdService.getConfig()

        assert(thirdConfig.buttonText == "Ask Claude for Help",
               "Button text should be 'Ask Claude for Help', got '\(thirdConfig.buttonText)'")

        print("[TestDetailWindowButtonText] ✅ Button text can be changed multiple times")

        // Reset to default
        let defaultConfig = PromptsConfiguration(
            buttonText: "Open in Claude",
            myPRs: "Default my PRs prompt",
            reviewRequested: "Default review requested prompt"
        )
        try service.saveConfig(defaultConfig)

        print("[TestDetailWindowButtonText] ✅ All tests passed!")

    } catch {
        print("[TestDetailWindowButtonText] ❌ Test failed: \(error)")
        exit(1)
    }
}
