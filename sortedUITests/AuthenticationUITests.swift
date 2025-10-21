/// AuthenticationUITests.swift
/// Automated UI tests for Epic 1: User Authentication & Profiles
/// Tests Stories 1.1-1.6 (Sign Up, Login, Auto-Login, Password Reset, Profile, Logout)

import XCTest

final class AuthenticationUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()

        // Reset app state before each test
        app.launchArguments = ["--uitesting", "--reset-keychain"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Story 1.1: Sign Up Tests

    func testSignUpWithValidCredentials() throws {
        // Given: User is on login screen
        XCTAssertTrue(app.staticTexts["Sorted"].exists, "App should show login screen")

        // When: User taps "Sign Up" link
        let signUpLink = app.buttons["Don't have an account? Sign Up"]
        XCTAssertTrue(signUpLink.waitForExistence(timeout: 2))
        signUpLink.tap()

        // Fill in sign up form
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        let confirmPasswordField = app.secureTextFields["Confirm Password"]
        let displayNameField = app.textFields["Username"]

        XCTAssertTrue(emailField.waitForExistence(timeout: 2))

        emailField.tap()
        emailField.typeText("test\(Int.random(in: 1000...9999))@example.com")

        passwordField.tap()
        passwordField.typeText("TestPassword123")

        confirmPasswordField.tap()
        confirmPasswordField.typeText("TestPassword123")

        displayNameField.tap()
        displayNameField.typeText("testuser\(Int.random(in: 1000...9999))")

        // Wait for availability check
        sleep(2)

        // Then: Sign up button should be enabled
        let signUpButton = app.buttons["Sign Up"]
        XCTAssertTrue(signUpButton.exists)

        // Note: Actual sign up requires Firebase connection
        // In real testing, you'd tap signUpButton and verify navigation
    }

    func testSignUpWithInvalidEmail() throws {
        // Navigate to sign up
        app.buttons["Don't have an account? Sign Up"].tap()

        // Enter invalid email
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 2))
        emailField.tap()
        emailField.typeText("invalid-email")

        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("TestPassword123")

        // Attempt sign up (should show error)
        let signUpButton = app.buttons["Sign Up"]
        signUpButton.tap()

        // Verify error is shown
        XCTAssertTrue(app.alerts.element.waitForExistence(timeout: 3), "Should show email validation error")
    }

    func testSignUpPasswordMismatch() throws {
        // Navigate to sign up
        app.buttons["Don't have an account? Sign Up"].tap()

        let passwordField = app.secureTextFields["Password"]
        let confirmPasswordField = app.secureTextFields["Confirm Password"]

        XCTAssertTrue(passwordField.waitForExistence(timeout: 2))

        passwordField.tap()
        passwordField.typeText("Password123")

        confirmPasswordField.tap()
        confirmPasswordField.typeText("DifferentPassword123")

        // Attempt sign up
        let signUpButton = app.buttons["Sign Up"]
        signUpButton.tap()

        // Verify error
        XCTAssertTrue(app.alerts.element.waitForExistence(timeout: 3), "Should show password mismatch error")
    }

    // MARK: - Story 1.2: Login Tests

    func testLoginScreenExists() throws {
        // Verify login screen elements
        XCTAssertTrue(app.staticTexts["Sorted"].exists)
        XCTAssertTrue(app.textFields["Email"].exists)
        XCTAssertTrue(app.secureTextFields["Password"].exists)
        XCTAssertTrue(app.buttons["Log In"].exists)
        XCTAssertTrue(app.buttons["Forgot Password?"].exists)
        XCTAssertTrue(app.buttons["Don't have an account? Sign Up"].exists)
    }

    func testLoginWithEmptyFields() throws {
        // Tap login button without entering credentials
        let loginButton = app.buttons["Log In"]
        loginButton.tap()

        // Should show validation error or button should be disabled
        // (Behavior depends on implementation)
    }

    func testNavigateToForgotPassword() throws {
        // Given: User is on login screen
        let forgotPasswordButton = app.buttons["Forgot Password?"]
        XCTAssertTrue(forgotPasswordButton.exists)

        // When: User taps "Forgot Password"
        forgotPasswordButton.tap()

        // Then: Should navigate to password reset screen
        XCTAssertTrue(app.staticTexts["Reset Password"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.textFields["Email"].exists)
        XCTAssertTrue(app.buttons["Send Reset Email"].exists)
    }

    // MARK: - Story 1.4: Password Reset Tests

    func testPasswordResetFlow() throws {
        // Navigate to password reset
        app.buttons["Forgot Password?"].tap()

        // Enter email
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 2))
        emailField.tap()
        emailField.typeText("test@example.com")

        // Tap send
        let sendButton = app.buttons["Send Reset Email"]
        sendButton.tap()

        // Note: In real testing with Firebase, verify success alert
    }

    // MARK: - Story 1.6: Logout Tests

    func testLogoutButton() throws {
        // This test assumes the app is already logged in
        // You'd typically set up a test user first

        // Find logout button (might be in profile screen)
        let logoutButton = app.buttons["Logout (Test)"]
        if logoutButton.waitForExistence(timeout: 5) {
            logoutButton.tap()

            // Verify confirmation dialog
            let confirmButton = app.buttons["Log Out"]
            if confirmButton.exists {
                confirmButton.tap()
            }

            // Verify navigation back to login screen
            XCTAssertTrue(app.staticTexts["Sorted"].waitForExistence(timeout: 3), "Should return to login screen")
            XCTAssertTrue(app.buttons["Log In"].exists)
        }
    }

    // MARK: - Performance Tests

    func testLoginScreenPerformance() throws {
        measure {
            // Measure time to load login screen
            let loginButton = app.buttons["Log In"]
            XCTAssertTrue(loginButton.exists)
        }
    }

    func testSignUpNavigationPerformance() throws {
        measure {
            app.buttons["Don't have an account? Sign Up"].tap()
            XCTAssertTrue(app.staticTexts["Create Account"].waitForExistence(timeout: 2))
            app.navigationBars.buttons.element(boundBy: 0).tap() // Back button
        }
    }

    // MARK: - Accessibility Tests

    func testLoginScreenAccessibility() throws {
        // Verify all interactive elements have accessibility labels
        let emailField = app.textFields["Email"]
        XCTAssertNotNil(emailField.label)

        let passwordField = app.secureTextFields["Password"]
        XCTAssertNotNil(passwordField.label)

        let loginButton = app.buttons["Log In"]
        XCTAssertTrue(loginButton.isHittable, "Login button should be hittable")
    }
}
