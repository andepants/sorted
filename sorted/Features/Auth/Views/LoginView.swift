/// LoginView.swift
/// Login screen with email/password authentication
/// [Source: Epic 1, Story 1.2]

import SwiftUI

/// View for user login with email and password
struct LoginView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    @FocusState private var focusedField: Field?

    /// Enum for managing focus state across form fields
    enum Field {
        case email, password
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Logo or branding
                    Image(systemName: "envelope.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                        .padding(.top, 40)

                    Text("Welcome Back")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Log in to your account")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    // Email TextField
                    TextField("Email", text: $viewModel.email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .accessibilityLabel("Email address")
                        .accessibilityIdentifier("emailTextField")
                        .padding(.horizontal)
                        .onSubmit { focusedField = .password }

                    // Password SecureField
                    SecureField("Password", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .accessibilityLabel("Password")
                        .accessibilityIdentifier("passwordTextField")
                        .padding(.horizontal)
                        .onSubmit {
                            focusedField = nil
                            Task { await viewModel.login() }
                        }

                    // Forgot Password link
                    HStack {
                        Spacer()
                        NavigationLink(destination: ForgotPasswordView()) {
                            Text("Forgot Password?")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)

                    // Login Button
                    Button(
                        action: {
                            focusedField = nil
                            Task { await viewModel.login() }
                        },
                        label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(width: 20, height: 20)
                                    Text("Logging in...")
                                } else {
                                    Text("Log In")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    )
                    .disabled(viewModel.isLoading || !isFormValid)
                    .padding(.horizontal)
                    .accessibilityIdentifier("loginButton")

                    // Sign Up link
                    HStack {
                        Text("Don't have an account?")
                            .font(.caption)
                            .foregroundColor(.gray)
                        NavigationLink(destination: SignUpView()) {
                            Text("Sign Up")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top, 20)

                    #if DEBUG
                    // Dev tools for easier testing
                    VStack(spacing: 8) {
                        Divider()
                            .padding(.vertical, 8)

                        Text("🔧 Dev Tools - Quick Login")
                            .font(.caption2)
                            .foregroundColor(.orange)

                        // Account 1: Alice
                        HStack(spacing: 8) {
                            Button(
                                action: {
                                    viewModel.email = "alice@test.com"
                                    viewModel.password = "testpass123"
                                },
                                label: {
                                    Label("Fill Alice", systemImage: "person.fill")
                                        .font(.caption2)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 8)
                                        .background(Color.purple.opacity(0.2))
                                        .foregroundColor(.purple)
                                        .cornerRadius(6)
                                }
                            )

                            Button(
                                action: {
                                    viewModel.email = "alice@test.com"
                                    viewModel.password = "testpass123"
                                    focusedField = nil
                                    Task { await viewModel.login() }
                                },
                                label: {
                                    Label("Login Alice", systemImage: "bolt.fill")
                                        .font(.caption2)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 8)
                                        .background(Color.green.opacity(0.2))
                                        .foregroundColor(.green)
                                        .cornerRadius(6)
                                }
                            )
                            .disabled(viewModel.isLoading)
                        }

                        // Account 2: Bob
                        HStack(spacing: 8) {
                            Button(
                                action: {
                                    viewModel.email = "bob@test.com"
                                    viewModel.password = "testpass123"
                                },
                                label: {
                                    Label("Fill Bob", systemImage: "person.fill")
                                        .font(.caption2)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 8)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(6)
                                }
                            )

                            Button(
                                action: {
                                    viewModel.email = "bob@test.com"
                                    viewModel.password = "testpass123"
                                    focusedField = nil
                                    Task { await viewModel.login() }
                                },
                                label: {
                                    Label("Login Bob", systemImage: "bolt.fill")
                                        .font(.caption2)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 8)
                                        .background(Color.green.opacity(0.2))
                                        .foregroundColor(.green)
                                        .cornerRadius(6)
                                }
                            )
                            .disabled(viewModel.isLoading)
                        }

                        // Account 3: Carol
                        HStack(spacing: 8) {
                            Button(
                                action: {
                                    viewModel.email = "carol@test.com"
                                    viewModel.password = "testpass123"
                                },
                                label: {
                                    Label("Fill Carol", systemImage: "person.fill")
                                        .font(.caption2)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 8)
                                        .background(Color.pink.opacity(0.2))
                                        .foregroundColor(.pink)
                                        .cornerRadius(6)
                                }
                            )

                            Button(
                                action: {
                                    viewModel.email = "carol@test.com"
                                    viewModel.password = "testpass123"
                                    focusedField = nil
                                    Task { await viewModel.login() }
                                },
                                label: {
                                    Label("Login Carol", systemImage: "bolt.fill")
                                        .font(.caption2)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 8)
                                        .background(Color.green.opacity(0.2))
                                        .foregroundColor(.green)
                                        .cornerRadius(6)
                                }
                            )
                            .disabled(viewModel.isLoading)
                        }
                    }
                    .padding(.top, 20)
                    #endif
                }
                .padding()
            }
            .navigationBarHidden(true)
            .alert("Login Failed", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error occurred")
            }
            .onChange(of: viewModel.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    // Haptic feedback already handled in viewModel
                }
            }
            .onTapGesture {
                // Dismiss keyboard on background tap
                focusedField = nil
            }
        }
    }

    /// Form validation
    private var isFormValid: Bool {
        !viewModel.email.isEmpty && !viewModel.password.isEmpty
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
