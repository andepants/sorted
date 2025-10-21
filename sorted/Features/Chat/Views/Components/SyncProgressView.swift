/// SyncProgressView.swift
///
/// Progress indicator for syncing large message queues (>5 pending messages).
/// Shows progress spinner and message count.
///
/// Created: 2025-10-21 (Story 2.5)

import SwiftUI

/// Progress indicator for message sync operations
struct SyncProgressView: View {
    @ObservedObject var syncCoordinator = SyncCoordinator.shared

    var body: some View {
        if syncCoordinator.isSyncing && syncCoordinator.pendingCount > 5 {
            HStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.blue)

                Text("Sending \(syncCoordinator.pendingCount) messages...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
            .transition(.opacity)
            .animation(.easeInOut, value: syncCoordinator.isSyncing)
        }
    }
}

// MARK: - Preview

#Preview {
    SyncProgressView()
}
