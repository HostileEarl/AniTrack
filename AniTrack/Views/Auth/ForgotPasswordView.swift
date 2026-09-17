//
//  ForgotPasswordView.swift
//  AniTrack — SCREEN: forgot password
//

import SwiftUI

struct ForgotPasswordView: View {

    let onBackToLogin: () -> Void

    @EnvironmentObject private var auth: AuthController

    @State private var email: String = ""
    @State private var emailError: String = ""
    @State private var isSending: Bool = false
    @State private var wasSent: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            if wasSent {
                confirmation
            } else {
                form
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppTheme.canvas)
    }

    // MARK: - Sections

    private var form: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Text("Type the email you use for AniTrack and we will send you a link to make a new password.")
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.muted)
                .lineSpacing(3)
                .padding(.bottom, 24)

            AuthField(label: "Email",
                      text: $email,
                      placeholder: "you@farm.ph",
                      keyboard: .emailAddress,
                      contentType: .emailAddress,
                      error: emailError)

            Button {
                sendLink()
            } label: {
                LoadingLabel(title: "Send reset link",
                             loadingTitle: "Sending…",
                             isLoading: isSending)
            }
            .buttonStyle(PrimaryButtonStyle(isEnabled: !isSending))
            .disabled(isSending)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    private var confirmation: some View {
        VStack(spacing: 0) {
            header

            Spacer()

            Image(systemName: "envelope.fill")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.paddy)
                .padding(.bottom, 22)

            Text("Check your email")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .padding(.bottom, 10)

            Text("If this email has an account, we sent a reset link.")
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button("Back to log in", action: onBackToLogin)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
        }
    }

    private var header: some View {
        HStack {
            Button(action: onBackToLogin) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back to log in")
                        .font(.system(size: 15))
                }
                .foregroundStyle(AppTheme.paddy)
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.bottom, 28)
    }

    // MARK: - Actions

    private func sendLink() {
        emailError = ""
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            emailError = "Type your email"
            return
        }
        Task {
            isSending = true
            // The confirmation is shown whether or not the email has an account,
            // so this form cannot be used to find out who is registered.
            try? await auth.sendPasswordReset(to: email)
            isSending = false
            wasSent = true
        }
    }
}

#Preview {
    ForgotPasswordView(onBackToLogin: {})
        .environmentObject(AuthController.previewSignedOut)
}
