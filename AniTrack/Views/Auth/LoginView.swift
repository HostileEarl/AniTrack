//
//  LoginView.swift
//  AniTrack — SCREEN: log in
//

import SwiftUI

struct LoginView: View {

    @EnvironmentObject private var auth: AuthController

    let onCreateAccount: () -> Void
    let onForgotPassword: () -> Void

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var emailError: String = ""
    @State private var passwordError: String = ""
    @State private var formError: String = ""
    @State private var rememberMe: Bool = true
    @State private var showDemoAccounts: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Wordmark(large: true)
                    .padding(.top, 28)

                Text("Log in to your farm")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.muted)
                    .padding(.top, 10)
                    .padding(.bottom, 32)

                if !formError.isEmpty {
                    ErrorBanner(message: formError)
                        .padding(.bottom, 16)
                }

                AuthField(label: "Email",
                          text: $email,
                          placeholder: "you@farm.ph",
                          keyboard: .emailAddress,
                          contentType: .emailAddress,
                          error: emailError)

                AuthField(label: "Password",
                          text: $password,
                          placeholder: "Your password",
                          isSecure: true,
                          contentType: .password,
                          error: passwordError)

                HStack {
                    Button {
                        rememberMe.toggle()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                .font(.system(size: 17))
                                .foregroundStyle(rememberMe ? AppTheme.paddy : AppTheme.muted)
                            Text("Remember me")
                                .font(.system(size: 14))
                                .foregroundStyle(AppTheme.muted)
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button("Forgot password?", action: onForgotPassword)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.paddy)
                }
                .padding(.bottom, 20)

                Button {
                    Task { await attemptSignIn() }
                } label: {
                    LoadingLabel(title: "Log in",
                                 loadingTitle: "Logging in…",
                                 isLoading: auth.isWorking)
                }
                .buttonStyle(PrimaryButtonStyle(isEnabled: !auth.isWorking))
                .disabled(auth.isWorking)
                .padding(.bottom, 22)

                HStack(spacing: 4) {
                    Text("New here?")
                        .font(.system(size: 15))
                        .foregroundStyle(AppTheme.muted)
                    Button("Make an account", action: onCreateAccount)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.paddy)
                }
                .padding(.bottom, 22)

                if !auth.demoCredentials.isEmpty {
                    demoAccountsPanel
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(AppTheme.canvas)
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Demo Accounts

    /// Lets anyone testing the app switch roles without guessing a password.
    private var demoAccountsPanel: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation { showDemoAccounts.toggle() }
            } label: {
                HStack {
                    Text("Test accounts")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.muted)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.muted)
                        .rotationEffect(.degrees(showDemoAccounts ? 180 : 0))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(AppTheme.paddy.opacity(0.04))
            }
            .buttonStyle(.plain)

            if showDemoAccounts {
                ForEach(auth.demoCredentials, id: \.email) { account in
                    Divider().overlay(AppTheme.hairline)
                    Button {
                        Task { await auth.useDemoAccount(email: account.email) }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(account.role.displayName)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(AppTheme.ink)
                                Text("\(account.email) · \(account.password)")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppTheme.muted)
                            }
                            Spacer()
                            Text("Use")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppTheme.paddy)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(AppTheme.hairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Actions

    private func attemptSignIn() async {
        emailError = ""
        passwordError = ""
        formError = ""

        var isValid = true
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            emailError = "Type your email"
            isValid = false
        }
        if password.isEmpty {
            passwordError = "Type your password"
            isValid = false
        }
        guard isValid else { return }

        do {
            try await auth.signIn(email: email, password: password)
        } catch {
            formError = (error as? AuthError)?.errorDescription
                ?? "Something went wrong. Please try again."
        }
    }
}

#Preview {
    LoginView(onCreateAccount: {}, onForgotPassword: {})
        .environmentObject(AuthController.previewSignedOut)
}
