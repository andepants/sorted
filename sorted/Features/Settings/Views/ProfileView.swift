/// ProfileView.swift
/// User profile screen with display name, photo upload, and logout
/// [Source: Epic 1, Stories 1.5, 1.6]

import Combine
@preconcurrency import FirebaseFirestore
import PhotosUI
import SwiftUI

/// View for managing user profile (display name, profile picture, logout)
struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: ProfileViewModel
    @State private var showLogoutConfirmation = false

    init() {
        // Initialize ProfileViewModel with empty state (authViewModel will be set via binding)
        _viewModel = StateObject(wrappedValue: ProfileViewModel())
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Picture
                    ZStack {
                        if let photoURL = viewModel.photoURL {
                            AsyncImage(url: photoURL) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 120, height: 120)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                                case .failure:
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 120, height: 120)
                                        .foregroundColor(.gray)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.gray)
                        }

                        // Upload progress overlay
                        if viewModel.isUploading {
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 120, height: 120)

                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        }
                    }
                    .onTapGesture {
                        viewModel.showImagePicker = true
                    }
                    .accessibilityLabel("Profile picture")
                    .accessibilityHint("Double tap to change")

                    Text("Tap to change photo")
                        .font(.caption)
                        .foregroundColor(.gray)

                    // Display Name TextField
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Username", text: $viewModel.displayName)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .disabled(viewModel.isLoading)
                            .padding(.horizontal)

                        // Availability indicator
                        if viewModel.isCheckingAvailability {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Checking availability...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal)
                        } else if !viewModel.displayNameError.isEmpty {
                            Text(viewModel.displayNameError)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        } else if viewModel.displayNameAvailable && viewModel.hasDisplayNameChanged {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Available")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Save Button
                    Button(
                        action: {
                            Task {
                                await viewModel.updateProfile(authViewModel: authViewModel)
                            }
                        },
                        label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(width: 20, height: 20)
                                    Text("Saving...")
                                } else {
                                    Text("Save Changes")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.hasChanges ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    )
                    .disabled(viewModel.isLoading || !viewModel.hasChanges)
                    .padding(.horizontal)

                    Spacer()
                        .frame(height: 40)

                    // Logout Button
                    Button(
                        action: {
                            showLogoutConfirmation = true
                        },
                        label: {
                            Text("Log Out")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(10)
                        }
                    )
                    .padding(.horizontal)
                }
                .padding(.top, 40)
            }
            .navigationTitle("Profile")
            .alert("Success", isPresented: $viewModel.showSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Profile updated successfully")
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .confirmationDialog("Log out of your account?", isPresented: $showLogoutConfirmation) {
                Button("Log Out", role: .destructive) {
                    Task {
                        await authViewModel.logout()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You can log back in anytime.")
            }
            .sheet(isPresented: $viewModel.showImagePicker) {
                PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images) {
                    Text("Select Photo")
                }
            }
            .onChange(of: viewModel.selectedPhoto) { _, _ in
                Task {
                    await viewModel.loadSelectedImage(authViewModel: authViewModel)
                }
            }
            .onAppear {
                viewModel.loadCurrentUser(authViewModel: authViewModel)
            }
        }
    }
}

// MARK: - ProfileViewModel

/// View model for profile management
@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var photoURL: URL?
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var isLoading: Bool = false
    @Published var isUploading: Bool = false
    @Published var isCheckingAvailability: Bool = false
    @Published var displayNameAvailable: Bool = false
    @Published var displayNameError: String = ""
    @Published var showImagePicker: Bool = false
    @Published var showSuccess: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""

    private var originalDisplayName: String = ""
    private var originalPhotoURL: URL?
    private let storageService = StorageService()
    private let displayNameService = DisplayNameService()

    /// Whether the profile has unsaved changes
    var hasChanges: Bool {
        displayName != originalDisplayName || photoURL != originalPhotoURL
    }

    /// Whether display name has changed from original
    var hasDisplayNameChanged: Bool {
        displayName != originalDisplayName
    }

    /// Load current user data from AuthViewModel
    func loadCurrentUser(authViewModel: AuthViewModel) {
        guard let currentUser = authViewModel.currentUser else { return }

        displayName = currentUser.displayName
        originalDisplayName = currentUser.displayName

        if let photoURLString = currentUser.photoURL, !photoURLString.isEmpty {
            photoURL = URL(string: photoURLString)
            originalPhotoURL = photoURL
        }
    }

    /// Load selected image from PhotosPicker
    func loadSelectedImage(authViewModel: AuthViewModel) async {
        guard let selectedPhoto = selectedPhoto else { return }

        do {
            isUploading = true
            defer { isUploading = false }

            // Load image data
            guard let data = try await selectedPhoto.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                throw StorageError.imageCompressionFailed
            }

            // Get current user ID
            guard let userId = authViewModel.currentUser?.id else {
                throw StorageError.invalidDownloadURL
            }

            // Upload to Firebase Storage
            let path = "profile_pictures/\(userId)/profile.jpg"
            let downloadURL = try await storageService.uploadImage(image, path: path)

            // Update photoURL
            photoURL = downloadURL

            // Haptic feedback
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    /// Update user profile (display name and/or photo)
    func updateProfile(authViewModel: AuthViewModel) async {
        isLoading = true
        defer { isLoading = false }

        do {
            guard let currentUser = authViewModel.currentUser else {
                throw NSError(
                    domain: "com.sorted.app",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No user logged in"]
                )
            }

            var updates: [String: Any] = [:]

            // Handle displayName change
            if displayName != originalDisplayName {
                try await handleDisplayNameUpdate(userId: currentUser.id, updates: &updates)
            }

            // Handle photoURL change
            if photoURL != originalPhotoURL {
                updates["photoURL"] = photoURL?.absoluteString ?? ""
            }

            // Update Firestore if there are changes
            if !updates.isEmpty {
                try await updateFirestore(userId: currentUser.id, updates: updates)
                updateAuthViewModel(authViewModel, with: updates)
            }

            handleSuccess()
        } catch {
            handleError(error)
        }
    }

    // MARK: - Private Helpers

    /// Handles display name validation and update
    private func handleDisplayNameUpdate(userId: String, updates: inout [String: Any]) async throws {
        // Validate displayName format
        guard displayName.count >= 3 && displayName.count <= 30 else {
            throw NSError(
                domain: "com.sorted.app",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Username must be 3-30 characters"]
            )
        }

        // Check availability
        let isAvailable = try await displayNameService.checkAvailability(displayName)
        guard isAvailable else {
            displayNameError = "Username already taken"
            throw NSError(
                domain: "com.sorted.app",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Username already taken"]
            )
        }

        // Release old and reserve new displayName
        try await displayNameService.releaseDisplayName(originalDisplayName)
        try await displayNameService.reserveDisplayName(displayName, userId: userId)

        updates["displayName"] = displayName
    }

    /// Updates Firestore with profile changes
    private func updateFirestore(userId: String, updates: [String: Any]) async throws {
        try await Firestore.firestore()
            .collection("users")
            .document(userId)
            .updateData(updates)
    }

    /// Updates the AuthViewModel with new profile data
    private func updateAuthViewModel(_ authViewModel: AuthViewModel, with updates: [String: Any]) {
        if let newDisplayName = updates["displayName"] as? String {
            authViewModel.currentUser?.displayName = newDisplayName
        }
        if let newPhotoURL = updates["photoURL"] as? String {
            authViewModel.currentUser?.photoURL = newPhotoURL
        }
    }

    /// Handles successful profile update
    private func handleSuccess() {
        showSuccess = true
        originalDisplayName = displayName
        originalPhotoURL = photoURL
        displayNameError = ""
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Handles profile update error
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
