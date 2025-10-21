/// ContentView.swift
/// Sorted - AI-Powered Messaging App
///
/// Placeholder view for initial project setup.
/// Will be replaced with actual messaging UI in later stories.

import SwiftData
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "message.fill")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                    .font(.system(size: 60))

                Text("Sorted")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("AI-Powered Messaging")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()
                    .frame(height: 40)

                // Show current user info
                if let user = authViewModel.currentUser {
                    VStack(spacing: 8) {
                        Text("Logged in as:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(user.displayName)
                            .font(.headline)
                        Text(user.email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }

                Spacer()

                // Navigation to Profile
                NavigationLink(destination: ProfileView()) {
                    Text("Go to Profile")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                // Test logout button
                Button(
                    action: {
                        Task {
                            await authViewModel.logout()
                        }
                    },
                    label: {
                        Text("Logout (Test)")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(10)
                    }
                )
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .modelContainer(PreviewContainer.shared)
}
