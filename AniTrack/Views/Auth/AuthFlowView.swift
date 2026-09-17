//
//  AuthFlowView.swift
//  AniTrack — VIEW LAYER
//
//  Moves between the screens shown before someone is signed in. Which screen is
//  on show is view state, so it lives here rather than in a controller.
//

import SwiftUI

struct AuthFlowView: View {

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var toasts: ToastController

    private enum Step {
        case splash
        case intro
        case login
        case signUp
        case forgotPassword
    }

    @State private var step: Step = .splash

    var body: some View {
        Group {
            switch step {
            case .splash:
                SplashView(onFinish: leaveSplash)

            case .intro:
                OnboardingView(onFinish: finishIntro)

            case .login:
                LoginView(onCreateAccount: { step = .signUp },
                          onForgotPassword: { step = .forgotPassword })
                    .transition(.opacity)

            case .signUp:
                SignUpView(onCancel: { step = .login },
                           onCreated: { firstName in
                               toasts.show("Welcome to AniTrack, \(firstName)")
                           })
                    .transition(.move(edge: .trailing).combined(with: .opacity))

            case .forgotPassword:
                ForgotPasswordView(onBackToLogin: { step = .login })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: stepIdentifier)
    }

    /// Used only to drive the transition animation.
    private var stepIdentifier: Int {
        switch step {
        case .splash: return 0
        case .intro: return 1
        case .login: return 2
        case .signUp: return 3
        case .forgotPassword: return 4
        }
    }

    private func leaveSplash() {
        // Firebase may still be checking for a session left over from last
        // time. Waiting avoids showing the log in screen for a moment and then
        // snapping to the dashboard.
        Task {
            while auth.isRestoringSession {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            guard auth.currentUser == nil else { return }
            step = auth.hasSeenIntro ? .login : .intro
        }
    }

    private func finishIntro() {
        auth.markIntroSeen()
        step = .login
    }
}

#Preview {
    AuthFlowView()
        .environmentObject(AuthController.previewSignedOut)
        .environmentObject(ToastController())
}
