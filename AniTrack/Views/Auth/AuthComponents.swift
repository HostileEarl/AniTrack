//
//  AuthComponents.swift
//  AniTrack — VIEW LAYER (shared auth pieces)
//

import SwiftUI

// MARK: - Wordmark

/// The AniTrack name with its rice-stalk mark above.
struct Wordmark: View {

    var large: Bool = true

    var body: some View {
        VStack(spacing: large ? 12 : 6) {
            Image(systemName: "leaf.fill")
                .font(.system(size: large ? 34 : 22, weight: .semibold))
                .foregroundStyle(AppTheme.paddy)
            Text("AniTrack")
                .font(.system(size: large ? 34 : 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.paddy)
        }
    }
}

// MARK: - Form Field

/// A labelled input that shows its own error underneath, in red, with a red
/// border on the box that has the problem.
struct AuthField: View {

    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType? = nil
    var error: String = ""

    @State private var isRevealed: Bool = false

    private var hasError: Bool { !error.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.muted)

            HStack(spacing: 8) {
                Group {
                    if isSecure && !isRevealed {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.ink)
                .keyboardType(keyboard)
                .textContentType(contentType)
                .autocorrectionDisabled(isSecure || keyboard == .emailAddress)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .sentences)

                if isSecure {
                    Button {
                        isRevealed.toggle()
                    } label: {
                        Image(systemName: isRevealed ? "eye.slash" : "eye")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.muted)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(hasError ? AppTheme.clay : AppTheme.hairline,
                                  lineWidth: hasError ? 1.5 : 1)
            )

            if hasError {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.clay)
            }
        }
        .padding(.bottom, 14)
    }
}

// MARK: - Error Banner

/// The red bar shown above a form when the whole attempt failed.
struct ErrorBanner: View {

    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 14))
            .foregroundStyle(AppTheme.clay)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppTheme.clay.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(AppTheme.clay.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Password Rules

/// The live checklist under a new password. Each rule ticks as it is met.
struct PasswordRulesView: View {

    let password: String

    static func isValid(_ password: String) -> Bool {
        return password.count >= 8
            && password.contains(where: \.isNumber)
            && password.contains(where: \.isUppercase)
    }

    private var rules: [(text: String, met: Bool)] {
        return [
            ("8 letters or more", password.count >= 8),
            ("One number", password.contains(where: \.isNumber)),
            ("One big letter", password.contains(where: \.isUppercase))
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(rules, id: \.text) { rule in
                HStack(spacing: 7) {
                    Image(systemName: rule.met ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 13))
                        .foregroundStyle(rule.met ? AppTheme.shoot : AppTheme.muted.opacity(0.5))
                    Text(rule.text)
                        .font(.system(size: 13))
                        .foregroundStyle(rule.met ? AppTheme.ink : AppTheme.muted)
                }
            }
        }
        .padding(.bottom, 14)
    }
}

// MARK: - Loading Button Label

/// A primary button label that swaps to a spinner while a request runs.
struct LoadingLabel: View {

    let title: String
    let loadingTitle: String
    let isLoading: Bool

    var body: some View {
        HStack(spacing: 10) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(0.85)
                Text(loadingTitle)
            } else {
                Text(title)
            }
        }
    }
}
