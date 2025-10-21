/// RecipientPickerView.swift
///
/// View for selecting a recipient to start a new conversation.
/// Displays searchable list of users with filtering and validation.
///
/// Created: 2025-10-21 (Story 2.1)

@preconcurrency import FirebaseFirestore
import SwiftUI

/// View for selecting a recipient to start a conversation
struct RecipientPickerView: View {
    // MARK: - Properties

    /// Callback when user is selected
    let onSelect: (String) -> Void

    // MARK: - State

    @State private var searchText = ""
    @State private var users: [FirestoreUser] = []
    @State private var isLoading = false
    @State private var error: Error?
    @Environment(\.dismiss) private var dismiss

    // MARK: - Computed Properties

    /// Filtered users based on search text
    var filteredUsers: [FirestoreUser] {
        if searchText.isEmpty {
            return users
        }
        return users.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading users...")
                        .progressViewStyle(.circular)
                } else if let error = error {
                    ContentUnavailableView(
                        "Error Loading Users",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error.localizedDescription)
                    )
                } else if filteredUsers.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Users Found" : "No Results",
                        systemImage: "person.slash",
                        description: Text(searchText.isEmpty ? "No users available" : "Try a different search term")
                    )
                } else {
                    List(filteredUsers) { user in
                        Button {
                            onSelect(user.id)
                            dismiss()
                        } label: {
                            UserRowView(user: user)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search users")
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadUsers()
            }
        }
    }

    // MARK: - Methods

    /// Load users from Firestore
    private func loadUsers() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let firestore = Firestore.firestore()
            let currentUserID = AuthService.shared.currentUserID ?? ""

            // Fetch users from Firestore
            let snapshot = try await firestore.collection("users").getDocuments()

            var fetchedUsers: [FirestoreUser] = []

            for document in snapshot.documents {
                let data = document.data()

                // Skip current user
                guard document.documentID != currentUserID else {
                    continue
                }

                let user = FirestoreUser(
                    id: document.documentID,
                    displayName: data["displayName"] as? String ?? "Unknown",
                    email: data["email"] as? String ?? "",
                    photoURL: data["photoURL"] as? String
                )

                fetchedUsers.append(user)
            }

            // Sort by display name
            self.users = fetchedUsers.sorted { $0.displayName < $1.displayName }
        } catch {
            self.error = error
        }
    }
}

// MARK: - User Row View

/// View for displaying a user row in the picker
struct UserRowView: View {
    let user: FirestoreUser

    var body: some View {
        HStack(spacing: 12) {
            // Profile picture
            AsyncImage(url: URL(string: user.photoURL ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            // User info
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.system(size: 17))
                    .foregroundColor(.primary)

                Text(user.email)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Supporting Types

/// Firestore user model for recipient picker
struct FirestoreUser: Identifiable {
    let id: String
    let displayName: String
    let email: String
    let photoURL: String?
}

// MARK: - Previews

#Preview {
    RecipientPickerView { userID in
        print("Selected user: \(userID)")
    }
}
