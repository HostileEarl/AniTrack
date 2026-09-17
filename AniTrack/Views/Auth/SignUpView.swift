//
//  SignUpView.swift
//  AniTrack — SCREEN: make an account
//
//  Three steps. Nothing is written to the account list until the last step is
//  confirmed, so backing out leaves no half-made account behind.
//

import SwiftUI

struct SignUpView: View {

    @EnvironmentObject private var auth: AuthController

    let onCancel: () -> Void
    let onCreated: (String) -> Void

    @State private var step: Int = 1

    // Step 1 — about you
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var mobile: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var nameError: String = ""
    @State private var emailError: String = ""
    @State private var passwordError: String = ""
    @State private var confirmError: String = ""

    // Step 2 — about your farm
    @State private var farmName: String = ""
    @State private var municipality: String = ""
    @State private var province: String = ""
    @State private var fieldCount: String = ""
    @State private var farmNameError: String = ""

    // Step 3 — what you do
    @State private var role: AccountRole = .farmManager

    /// Shown as a red bar above the step when the whole attempt failed.
    @State private var formError: String = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            progressBar

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if !formError.isEmpty {
                        ErrorBanner(message: formError)
                            .padding(.bottom, 18)
                    }

                    switch step {
                    case 1: stepOne
                    case 2: stepTwo
                    default: stepThree
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.canvas)
    }

    // MARK: - Chrome

    private var header: some View {
        HStack {
            Button(action: goBack) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text(step == 1 ? "Log in" : "Back")
                        .font(.system(size: 15))
                }
                .foregroundStyle(AppTheme.paddy)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Step \(step) of 3")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.muted)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 14)
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(AppTheme.paddy.opacity(0.1))
                Capsule()
                    .fill(AppTheme.paddy)
                    .frame(width: proxy.size.width * (Double(step) / 3.0))
                    .animation(.easeInOut(duration: 0.25), value: step)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 24)
    }

    private var footer: some View {
        Button {
            advance()
        } label: {
            LoadingLabel(title: step == 3 ? "Make account" : "Next",
                         loadingTitle: "Making your account…",
                         isLoading: auth.isWorking)
        }
        .buttonStyle(PrimaryButtonStyle(isEnabled: !auth.isWorking))
        .disabled(auth.isWorking)
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 28)
    }

    // MARK: - Step 1

    private var stepOne: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("About you")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppTheme.ink)
                .padding(.bottom, 22)

            AuthField(label: "Full name", text: $fullName,
                      placeholder: "Ana Reyes", contentType: .name, error: nameError)

            AuthField(label: "Email", text: $email,
                      placeholder: "you@farm.ph", keyboard: .emailAddress,
                      contentType: .emailAddress, error: emailError)

            AuthField(label: "Mobile number", text: $mobile,
                      placeholder: "0917 555 0000", keyboard: .phonePad,
                      contentType: .telephoneNumber)

            AuthField(label: "Password", text: $password,
                      placeholder: "Make a password", isSecure: true,
                      contentType: .newPassword, error: passwordError)

            PasswordRulesView(password: password)

            AuthField(label: "Type password again", text: $confirmPassword,
                      placeholder: "Type it again", isSecure: true,
                      contentType: .newPassword, error: confirmError)
        }
    }

    // MARK: - Step 2

    private var stepTwo: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("About your farm")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppTheme.ink)
                .padding(.bottom, 22)

            AuthField(label: "Farm name", text: $farmName,
                      placeholder: "Reyes Family Farm", error: farmNameError)

            AuthField(label: "Municipality", text: $municipality,
                      placeholder: "Cabanatuan")

            AuthField(label: "Province", text: $province,
                      placeholder: "Nueva Ecija")

            AuthField(label: "How many fields", text: $fieldCount,
                      placeholder: "6", keyboard: .numberPad)
        }
    }

    // MARK: - Step 3

    private var stepThree: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("What you do")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppTheme.ink)
                .padding(.bottom, 8)

            Text("This sets what you can see and change in the app.")
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.muted)
                .padding(.bottom, 22)

            VStack(spacing: 12) {
                ForEach(AccountRole.allCases) { option in
                    Button {
                        role = option
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: role == option ? "largecircle.fill.circle" : "circle")
                                .font(.system(size: 20))
                                .foregroundStyle(role == option ? AppTheme.paddy : AppTheme.muted.opacity(0.5))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(option.displayName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(AppTheme.ink)
                                Text(option.summary)
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppTheme.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(AppTheme.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(role == option ? AppTheme.paddy : AppTheme.hairline,
                                              lineWidth: role == option ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Navigation

    private func goBack() {
        if step == 1 {
            onCancel()
        } else {
            withAnimation { step -= 1 }
        }
    }

    private func advance() {
        switch step {
        case 1:
            guard validateStepOne() else { return }
            withAnimation { step = 2 }
        case 2:
            guard validateStepTwo() else { return }
            withAnimation { step = 3 }
        default:
            createAccount()
        }
    }

    // MARK: - Validation

    private func validateStepOne() -> Bool {
        nameError = ""
        emailError = ""
        passwordError = ""
        confirmError = ""
        var isValid = true

        if fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            nameError = "Type your full name"
            isValid = false
        }
        let typedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if typedEmail.isEmpty {
            emailError = "Type your email"
            isValid = false
        } else if !typedEmail.contains("@") || !typedEmail.contains(".") {
            emailError = "That does not look like an email"
            isValid = false
        }
        if !PasswordRulesView.isValid(password) {
            passwordError = "Your password does not meet the rules below"
            isValid = false
        }
        if confirmPassword != password {
            confirmError = "Passwords do not match"
            isValid = false
        }
        return isValid
    }

    private func validateStepTwo() -> Bool {
        farmNameError = ""
        guard !farmName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            farmNameError = "Type your farm name"
            return false
        }
        return true
    }

    private func createAccount() {
        Task { await performCreate() }
    }

    private func performCreate() async {
        let place = [municipality, province]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        let details = SignUpDetails(fullName: fullName,
                                    email: email,
                                    mobile: mobile,
                                    password: password,
                                    role: role,
                                    farmName: farmName,
                                    municipality: place)
        do {
            try await auth.signUp(details: details)
            let first = String(fullName.split(separator: " ").first ?? "there")
            onCreated(first)
        } catch let error as AuthError {
            switch error {
            case .emailTaken, .invalidEmail:
                emailError = error.errorDescription ?? "Check your email"
                withAnimation { step = 1 }
            case .weakPassword:
                passwordError = error.errorDescription ?? "Pick a stronger password"
                withAnimation { step = 1 }
            default:
                formError = error.errorDescription ?? ""
            }
        } catch {
            formError = "Something went wrong. Please try again."
        }
    }
}

#Preview {
    SignUpView(onCancel: {}, onCreated: { _ in })
        .environmentObject(AuthController.previewSignedOut)
}
