//
//  ContentView.swift
//  PRDesk
//
//  Created by PR Desk
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            // Translucent dark background
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)

            VStack(spacing: 12) {
                Text("PR Desk")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Desktop Widget")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
        }
        .frame(minWidth: 300, minHeight: 400)
    }
}

/// SwiftUI wrapper for NSVisualEffectView
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

#Preview {
    ContentView()
}
