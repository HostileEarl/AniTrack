//
//  AuthService.swift
//  AniTrack — CONTROLLER LAYER
//
//  The boundary between AniTrack and whatever is actually storing accounts.
//
//  AuthController talks only to this protocol, so the app has no idea whether
//  sign-in is being handled on the device or by Firebase. That is what lets the
//  project build before Firebase is added, keeps SwiftUI previews off the
//  network, and means a demo still works when the campus wifi does not.
//

import Foundation

// MARK: - Sign Up Details

/// Everything the three-step sign-up form collects.
struct SignUpDetails {
    var fullName: String
    var email: String
    var mobile: String
    var password: String
    var role: AccountRole
    var farmName: String
    var municipality: String
}

// MARK: - Errors

/// Every way signing in or signing up can fail, with a message written for the
/// person using the app rather than for a developer reading a console.
enum AuthError: LocalizedError, Equatable {

    case wrongCredentials
    case emailTaken
    case weakPassword
    case invalidEmail
    case networkUnavailable
    case tooManyAttempts
    case notSignedIn
    case wrongCurrentPassword
    case profileMissing
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .wrongCredentials:
            return "That email and password do not match. Please check and try again."
        case .emailTaken:
            return "That email already has an account."
        case .weakPassword:
            return "That password is too easy to guess. Use 8 letters or more with a number and a big letter."
        case .invalidEmail:
            return "That does not look like an email."
        case .networkUnavailable:
            return "No internet. Check your connection and try again."
        case .tooManyAttempts:
            return "Too many tries. Please wait a moment before trying again."
        case .notSignedIn:
            return "You are not logged in any more. Please log in again."
        case .wrongCurrentPassword:
            return "Your current password is wrong."
        case .profileMissing:
            return "We could not find your farm details. Please contact your farm manager."
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Service

/// What AniTrack needs from an account system.
protocol AuthService {

    /// Shown on the Settings screen so it is obvious which one is running.
    var providerName: String { get }

    /// True when accounts live on a server rather than on this device.
    var isRemote: Bool { get }

    /// Returns the already-signed-in user on launch, or nil.
    func restoreSession() async -> FarmUser?

    func signIn(email: String, password: String) async throws -> FarmUser

    func signUp(details: SignUpDetails) async throws -> FarmUser

    func signOut() async throws

    func updateProfile(_ user: FarmUser) async throws

    func changePassword(current: String, new: String, for user: FarmUser) async throws

    func sendPasswordReset(to email: String) async throws
}
