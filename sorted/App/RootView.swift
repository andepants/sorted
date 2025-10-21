/// RootView.swift
/// Root view that handles authentication state and navigation
/// [Source: Epic 1, Story 1.3]

import SwiftUI

/// Root view that manages authenticated vs unauthenticated navigation
struct RootView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if authViewModel.isLoading {
                // Loading state during auth check
                VStack {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                }
            } else if authViewModel.isAuthenticated {
                // Authenticated: Show conversation list (main app)
                // TEMPORARY: ConversationListView disabled for build testing
                Text("Conversations - Coming Soon")
                    .font(.title)
                    .foregroundColor(.secondary)
            } else {
                // Not authenticated: Show login screen
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
        .task {
            // Check auth status on app launch
            await authViewModel.checkAuthStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Refresh auth when app returns to foreground
            if newPhase == .active {
                Task {
                    await authViewModel.checkAuthStatus()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RootView()
}
