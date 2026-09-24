//
//  ChangePasswordView.swift
//  AniTrack — SCREEN: change password
//
//  The current password is a real check, not a courtesy field. With Firebase it
//  is used to sign in again before the change is allowed, which is what makes
//  "your current password is wrong" a genuine answer from the server.
//

import SwiftUI

struct ChangePasswordView: View {

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var toasts: ToastController
    @Environment(\.dismiss) private var dismiss

    @State private var current: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var currentError: String = ""
    @State private var newError: String = ""
    @State private var confirmError: String = ""
    @State private var formError: String = ""

    private var canSave: Bool {
        return !current.isEmpty
            && PasswordRulesView.isValid(newPassword)
            && newPassword == confirmPassword
            && !auth.isWorking
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if !formError.isEmpty {
                    ErrorBanner(message: formError)
                        .padding(.bottom, 18)
                }

                AuthField(label: "Current password",
                          text: $current,
                          placeholder: "The one you use now",
                          isSecure: true,
                          contentType: .password,
                          error: currentError)

                AuthField(label: "New password",
                          text: $newPassword,
                          placeholder: "Make a new password",
                          isSecure: true,
                          contentType: .newPassword,
                          error: newError)

                PasswordRulesView(password: newPassword)

                AuthField(label: "Type it again",
                          text: $confirmPassword,
                          placeholder: "The same new password",
                          isSecure: true,
                          contentType: .newPassword,
                          error: confirmError)

                Button {
                    save()
                } label: {
                    LoadingLabel(title: "Save new password",
                                 loadingTitle: "Saving…",
                                 isLoading: auth.isWorking)
                }
                .buttonStyle(PrimaryButtonStyle(isEnabled: canSave))
                .disabled(!canSave)
                .padding(.top, 6)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .background(AppTheme.canvas)
        .navigationTitle("Change password")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
    }

    private func save() {
        currentError = ""
        newError = ""
        confirmError = ""
        formError = ""

        if current.isEmpty {
            currentError = "Type your current password"
        }
        if !PasswordRulesView.isValid(newPassword) {
            newError = "Your new password does not meet the rules below"
        }
        if confirmPassword != newPassword {
            confirmError = "Passwords do not match"
        }
        guard currentError.isEmpty && newError.isEmpty && confirmError.isEmpty else { return }

        Task {
            do {
                try await auth.changePassword(current: current, new: newPassword)
                toasts.show("Your password is changed")
                dismiss()
            } catch let error as AuthError {
                if error == .wrongCurrentPassword {
                    currentError = error.errorDescription ?? "Your current password is wrong."
                } else {
                    formError = error.errorDescription ?? ""
                }
            } catch {
                formError = "Could not change your password. Please try again."
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChangePasswordView()
            .environmentObject(AuthController.previewSignedIn())
            .environmentObject(ToastController())
    }
}
