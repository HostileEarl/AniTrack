//
//  EditProfileView.swift
//  AniTrack — SCREEN: change my details
//
//  Saving goes through AuthController, which passes it to whichever account
//  system is running. With Firebase that writes to the Firestore profile; on
//  the device it rewrites the saved accounts file. This screen does not know
//  which, and does not need to.
//

import SwiftUI

struct EditProfileView: View {

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var toasts: ToastController
    @Environment(\.dismiss) private var dismiss

    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var mobile: String = ""
    @State private var nameError: String = ""
    @State private var emailError: String = ""
    @State private var formError: String = ""
    @State private var isSaving: Bool = false

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Circle()
                            .fill(AppTheme.paddy)
                            .frame(width: 76, height: 76)
                            .overlay(
                                Text(auth.currentUser?.initials ?? "")
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundStyle(.white)
                            )
                        Text("Adding a photo comes with the next version")
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.muted)
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            if !formError.isEmpty {
                Section {
                    Text(formError)
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.clay)
                }
            }

            Section("Your details") {
                LabeledContent("Full name") {
                    TextField("Full name", text: $fullName)
                        .multilineTextAlignment(.trailing)
                }
                if !nameError.isEmpty { fieldError(nameError) }

                LabeledContent("Email") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .multilineTextAlignment(.trailing)
                }
                if !emailError.isEmpty { fieldError(emailError) }

                LabeledContent("Mobile") {
                    TextField("Mobile", text: $mobile)
                        .keyboardType(.phonePad)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section {
                NavigationLink(value: AppRoute.changePassword) {
                    Label("Change password", systemImage: "lock.rotation")
                }
            }
        }
        .navigationTitle("Change my details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(isSaving)
            }
        }
        .onAppear(perform: loadCurrentValues)
    }

    private func fieldError(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(AppTheme.clay)
    }

    private func loadCurrentValues() {
        guard let user = auth.currentUser else { return }
        fullName = user.fullName
        email = user.email
        mobile = user.mobile
    }

    private func save() {
        nameError = ""
        emailError = ""
        formError = ""

        let typedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let typedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if typedName.isEmpty {
            nameError = "Type your full name"
        }
        if typedEmail.isEmpty {
            emailError = "Type your email"
        } else if !typedEmail.contains("@") || !typedEmail.contains(".") {
            emailError = "That does not look like an email"
        }
        guard nameError.isEmpty && emailError.isEmpty else { return }

        Task {
            isSaving = true
            do {
                try await auth.updateProfile(fullName: typedName, email: typedEmail, mobile: mobile)
                toasts.show("Your details are saved")
                dismiss()
            } catch {
                formError = (error as? AuthError)?.errorDescription
                    ?? "Could not save your details. Please try again."
            }
            isSaving = false
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileView()
            .environmentObject(AuthController.previewSignedIn())
            .environmentObject(ToastController())
    }
}
