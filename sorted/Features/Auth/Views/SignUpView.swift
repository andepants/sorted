/// SignUpView.swift
/// Sign up screen with email, password, and display name fields
/// [Source: Epic 1, Story 1.1]

import SwiftUI

/// View for user registration with email/password and displayName
struct SignUpView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    @FocusState private var focusedField: Field?

    /// Enum for managing focus state across form fields
    enum Field {
        case email, password, confirmPassword, displayName
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Logo / Branding
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                        .padding(.top, 40)

                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Join Sorted to manage your fan messages")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Email TextField
                    TextField("Email", text: $viewModel.email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .accessibilityLabel("Email address")
                        .accessibilityIdentifier("emailTextField")
                        .padding(.horizontal)
                        .onSubmit { focusedField = .password }

                    // Password SecureField with validation
                    VStack(alignment: .leading, spacing: 4) {
                        SecureField("Password", text: $viewModel.password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.next)
                            .accessibilityLabel("Password")
                            .accessibilityHint("Minimum 8 characters")
                            .accessibilityIdentifier("passwordTextField")
                            .padding(.horizontal)
                            .onChange(of: viewModel.password) { _, newValue in
                                viewModel.validatePassword(newValue)
                                // Also revalidate confirm password if it's not empty
                                if !viewModel.confirmPassword.isEmpty {
                                    viewModel.validateConfirmPassword(viewModel.confirmPassword)
                                }
                            }
                            .onSubmit { focusedField = .confirmPassword }

                        // Password requirements / error
                        if !viewModel.passwordError.isEmpty {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(viewModel.passwordError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal)
                        } else if !viewModel.password.isEmpty && viewModel.password.count >= 8 {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Password meets requirements")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Confirm Password SecureField with validation
                    VStack(alignment: .leading, spacing: 4) {
                        SecureField("Confirm Password", text: $viewModel.confirmPassword)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .confirmPassword)
                            .submitLabel(.next)
                            .accessibilityLabel("Confirm Password")
                            .accessibilityIdentifier("confirmPasswordTextField")
                            .padding(.horizontal)
                            .onChange(of: viewModel.confirmPassword) { _, newValue in
                                viewModel.validateConfirmPassword(newValue)
                            }
                            .onSubmit { focusedField = .displayName }

                        // Password match indicator
                        if !viewModel.confirmPasswordError.isEmpty {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(viewModel.confirmPasswordError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal)
                        } else if !viewModel.confirmPassword.isEmpty &&
                                    viewModel.confirmPassword == viewModel.password {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Passwords match")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Display Name TextField
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Username", text: $viewModel.displayName)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.none)
                            .focused($focusedField, equals: .displayName)
                            .submitLabel(.done)
                            .accessibilityLabel("Username")
                            .accessibilityHint("3-30 characters, letters, numbers, periods, and underscores only")
                            .accessibilityIdentifier("displayNameTextField")
                            .padding(.horizontal)
                            .onChange(of: viewModel.displayName) { _, newValue in
                                // Debounced availability check
                                Task {
                                    try? await Task.sleep(nanoseconds: 500_000_000) // 500ms debounce
                                    await viewModel.checkDisplayNameAvailability(newValue)
                                }
                            }
                            .onSubmit {
                                focusedField = nil
                                Task { await viewModel.signUp() }
                            }

                        // Availability indicator
                        HStack {
                            if viewModel.isCheckingAvailability {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Checking availability...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } else if !viewModel.displayNameError.isEmpty {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(viewModel.displayNameError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            } else if viewModel.displayNameAvailable && !viewModel.displayName.isEmpty {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Available")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Sign Up Button
                    Button(
                        action: {
                            focusedField = nil
                            Task { await viewModel.signUp() }
                        },
                        label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(width: 20, height: 20)
                                    Text("Creating Account...")
                                } else {
                                    Text("Sign Up")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isSignUpFormValid ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    )
                    .disabled(viewModel.isLoading || !viewModel.isSignUpFormValid)
                    .padding(.horizontal)
                    .accessibilityIdentifier("signUpButton")

                    // Login Link
                    HStack {
                        Text("Already have an account?")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Button("Log In") {
                            // Navigate to LoginView (handled by parent navigation)
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
            .navigationBarHidden(true)
            .alert("Sign Up Failed", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error occurred")
            }
            .onTapGesture {
                // Dismiss keyboard on background tap
                focusedField = nil
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SignUpView()
        .environmentObject(AuthViewModel())
}
