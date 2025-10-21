/// ForgotPasswordView.swift
/// Password reset screen with email input
/// [Source: Epic 1, Story 1.4]

import FirebaseAuth
import SwiftUI

/// View for password reset via email
struct ForgotPasswordView: View {
    @State private var email: String = ""
    @State private var isLoading: Bool = false
    @State private var showSuccess: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Icon
                Image(systemName: "lock.rotation")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                    .padding(.top, 40)

                Text("Reset Password")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Enter your email address and we'll send you a link to reset your password")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Email TextField
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .accessibilityLabel("Email address")
                    .accessibilityIdentifier("emailTextField")
                    .padding(.horizontal)

                // Send Reset Email Button
                Button(
                    action: {
                        Task { await sendPasswordReset() }
                    },
                    label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(width: 20, height: 20)
                                Text("Sending...")
                            } else {
                                Text("Send Reset Link")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValidEmail ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                )
                .disabled(isLoading || !isValidEmail)
                .padding(.horizontal)
                .accessibilityIdentifier("sendResetButton")

                // Back to Login Button
                Button("Back to Login") {
                    dismiss()
                }
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.top, 20)
            }
            .padding()
        }
        .navigationTitle("Forgot Password")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Check Your Email", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("If this email is registered, you'll receive a password reset link shortly.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    /// Sends password reset email via Firebase Auth
    private func sendPasswordReset() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            showSuccess = true

            // Haptic feedback
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            errorMessage = "Failed to send reset email. Please try again."
            showError = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    /// Email validation
    private var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ForgotPasswordView()
    }
}
