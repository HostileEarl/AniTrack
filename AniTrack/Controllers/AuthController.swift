//
//  AuthController.swift
//  AniTrack — CONTROLLER LAYER
//
//  Holds the signed-in session and passes every account operation to an
//  AuthService. It does not know or care whether that service is Firebase or
//  the on-device one, which is what lets the same screens work either way.
//

import Foundation
import Combine

@MainActor
final class AuthController: ObservableObject {

    // MARK: - Published State

    @Published private(set) var currentUser: FarmUser?
    @Published private(set) var hasSeenIntro: Bool
    @Published private(set) var isWorking: Bool = false
    @Published private(set) var isRestoringSession: Bool = true

    private let service: AuthService
    private let persistence: PersistenceController

    /// Shown on the Settings screen so it is obvious which system is in use.
    var providerName: String { service.providerName }
    var isUsingRemoteAccounts: Bool { service.isRemote }

    // MARK: - Initialisation

    init(service: AuthService? = nil,
         persistence: PersistenceController = .shared) {
        self.service = service ?? FirebaseBootstrap.makeAuthService()
        self.persistence = persistence
        self.hasSeenIntro = persistence.loadHasSeenIntro()
    }

    // MARK: - Launch

    /// Picks up a session left over from last time, so a signed-in user is not
    /// asked to log in again every launch.
    func restoreSession() async {
        isRestoringSession = true
        currentUser = await service.restoreSession()
        isRestoringSession = false
    }

    // MARK: - Session

    func signIn(email: String, password: String) async throws {
        isWorking = true
        defer { isWorking = false }
        currentUser = try await service.signIn(email: email, password: password)
    }

    func signUp(details: SignUpDetails) async throws {
        isWorking = true
        defer { isWorking = false }
        currentUser = try await service.signUp(details: details)
    }

    func signOut() async {
        try? await service.signOut()
        currentUser = nil
    }

    func sendPasswordReset(to email: String) async throws {
        isWorking = true
        defer { isWorking = false }
        try await service.sendPasswordReset(to: email)
    }

    // MARK: - Profile

    func updateProfile(fullName: String, email: String, mobile: String) async throws {
        guard var user = currentUser else { throw AuthError.notSignedIn }
        user.fullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        user.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        user.mobile = mobile
        try await service.updateProfile(user)
        currentUser = user
    }

    func changePassword(current: String, new: String) async throws {
        guard let user = currentUser else { throw AuthError.notSignedIn }
        isWorking = true
        defer { isWorking = false }
        try await service.changePassword(current: current, new: new, for: user)
    }

    // MARK: - Intro

    func markIntroSeen() {
        hasSeenIntro = true
        persistence.saveHasSeenIntro(true)
    }

    // MARK: - Demo Support

    /// The three test accounts shown on the log in screen. Empty once Firebase
    /// is running, because real accounts are not seeded into the app.
    var demoCredentials: [(email: String, password: String, role: AccountRole)] {
        return service.isRemote ? [] : LocalAuthService.demoCredentials
    }

    /// Signs straight in as a test account, without typing a password.
    func useDemoAccount(email: String) async {
        guard let local = service as? LocalAuthService else { return }
        currentUser = await local.useDemoAccount(email: email)
    }
}

// MARK: - Preview Support

extension AuthController {

    /// A controller already signed in, using on-device accounts so previews and
    /// tests never reach the network.
    static func previewSignedIn(role: AccountRole = .farmManager) -> AuthController {
        let controller = AuthController(service: LocalAuthService(persistence: .inMemory),
                                        persistence: .inMemory)
        let email: String
        switch role {
        case .farmManager: email = "ana@reyesfarm.ph"
        case .teamLeader: email = "marilou@reyesfarm.ph"
        case .owner: email = "owner@reyesfarm.ph"
        }
        controller.currentUser = LocalAuthService.seededAccounts
            .first { $0.email == email }
        controller.isRestoringSession = false
        return controller
    }

    /// A signed-out controller for previewing the log in screens.
    static var previewSignedOut: AuthController {
        let controller = AuthController(service: LocalAuthService(persistence: .inMemory),
                                        persistence: .inMemory)
        controller.isRestoringSession = false
        return controller
    }
}
