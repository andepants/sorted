/// ContentView.swift
/// Sorted - AI-Powered Messaging App
///
/// Placeholder view for initial project setup.
/// Will be replaced with actual messaging UI in later stories.

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "message.fill")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Sorted")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("AI-Powered Messaging")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewContainer.shared)
}
