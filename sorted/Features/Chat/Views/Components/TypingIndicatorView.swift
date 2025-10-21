/// TypingIndicatorView.swift
///
/// Animated typing indicator with bouncing dots.
/// Sequential fade animation for visual feedback.
///
/// Created: 2025-10-21 (Story 2.6)

import Combine
import SwiftUI

/// Animated typing indicator view
struct TypingIndicatorView: View {
    // MARK: - State

    @State private var animationPhase = 0

    // MARK: - Timer

    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    // MARK: - Body

    var body: some View {
        HStack(spacing: 4) {
            Text("Typing")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 6, height: 6)
                        .opacity(animationPhase == index ? 1.0 : 0.3)
                        .animation(
                            .easeInOut(duration: 0.4),
                            value: animationPhase
                        )
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(18)
        .accessibilityLabel("Typing indicator")
        .accessibilityHint("The other person is typing a message")
        .onReceive(timer) { _ in
            animationPhase = (animationPhase + 1) % 3
        }
    }
}

// MARK: - Preview

#Preview {
    TypingIndicatorView()
}
