//
//  LocalAuthService.swift
//  AniTrack — CONTROLLER LAYER
//
//  Accounts kept on the device. Used when Firebase has not been added to the
//  project, in SwiftUI previews, and as the fallback for demonstrations without
//  a network.
//
//  Passwords are stored as SHA-256 hashes, never as readable text. A real
//  system would also salt each password, which is exactly what Firebase does
//  once FirebaseAuthService takes over.
//

import Foundation
import CryptoKit

actor LocalAuthService: AuthService {

    nonisolated var providerName: String { "On this device" }
    nonisolated var isRemote: Bool { false }

    private var accounts: [FarmUser]
    private var signedInEmail: String?
    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        let saved = persistence.loadAccounts()
        self.accounts = saved.isEmpty ? LocalAuthService.seededAccounts : saved
    }

    // MARK: - Hashing

    /// SHA-256 of the password, written as hexadecimal.
    nonisolated static func hash(_ password: String) -> String {
        let digest = SHA256.hash(data: Data(password.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Seeded Accounts

    /// The three demo accounts, used for testing and marking.
    nonisolated static let demoCredentials: [(email: String, password: String, role: AccountRole)] = [
        ("ana@reyesfarm.ph", "harvest2026", .farmManager),
        ("marilou@reyesfarm.ph", "crew2026", .teamLeader),
        ("owner@reyesfarm.ph", "owner2026", .owner)
    ]

    nonisolated static var seededAccounts: [FarmUser] {
        return [
            FarmUser(email: "ana@reyesfarm.ph",
                     passwordHash: hash("harvest2026"),
                     fullName: "Ana Reyes",
                     role: .farmManager,
                     workerID: nil,
                     mobile: "0917 555 0001",
                     memberSince: DateComponents(calendar: .current, year: 2024, month: 1, day: 15).date ?? Date()),
            FarmUser(email: "marilou@reyesfarm.ph",
                     passwordHash: hash("crew2026"),
                     fullName: "Marilou Bautista",
                     role: .teamLeader,
                     workerID: "w1",
                     mobile: "0917 555 0142",
                     memberSince: DateComponents(calendar: .current, year: 2024, month: 3, day: 1).date ?? Date()),
            FarmUser(email: "owner@reyesfarm.ph",
                     passwordHash: hash("owner2026"),
                     fullName: "Teodoro Reyes",
                     role: .owner,
                     workerID: nil,
                     mobile: "0917 555 0003",
                     memberSince: DateComponents(calendar: .current, year: 2023, month: 6, day: 10).date ?? Date())
        ]
    }

    // MARK: - AuthService

    func restoreSession() async -> FarmUser? {
        guard let email = signedInEmail else { return nil }
        return accounts.first { $0.email.lowercased() == email.lowercased() }
    }

    func signIn(email: String, password: String) async throws -> FarmUser {
        // Mirrors a network round trip so the button's loading state is visible.
        try? await Task.sleep(nanoseconds: 700_000_000)

        let typed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let hash = LocalAuthService.hash(password)

        guard let match = accounts.first(where: {
            $0.email.lowercased() == typed && $0.passwordHash == hash
        }) else {
            throw AuthError.wrongCredentials
        }

        signedInEmail = match.email
        return match
    }

    func signUp(details: SignUpDetails) async throws -> FarmUser {
        try? await Task.sleep(nanoseconds: 700_000_000)

        let typed = details.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !accounts.contains(where: { $0.email.lowercased() == typed }) else {
            throw AuthError.emailTaken
        }

        let user = FarmUser(email: typed,
                            passwordHash: LocalAuthService.hash(details.password),
                            fullName: details.fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                            role: details.role,
                            workerID: nil,
                            mobile: details.mobile,
                            farmName: details.farmName.isEmpty ? "My Farm" : details.farmName,
                            municipality: details.municipality,
                            memberSince: Date())

        accounts.append(user)
        signedInEmail = user.email
        persistence.saveAccounts(accounts)
        return user
    }

    func signOut() async throws {
        signedInEmail = nil
    }

    func updateProfile(_ user: FarmUser) async throws {
        guard let index = accounts.firstIndex(where: { $0.id == user.id }) else {
            throw AuthError.notSignedIn
        }
        // Keep the stored hash: the profile form never touches the password.
        var updated = user
        updated.passwordHash = accounts[index].passwordHash
        accounts[index] = updated
        signedInEmail = updated.email
        persistence.saveAccounts(accounts)
    }

    func changePassword(current: String, new: String, for user: FarmUser) async throws {
        guard let index = accounts.firstIndex(where: { $0.id == user.id }) else {
            throw AuthError.notSignedIn
        }
        guard accounts[index].passwordHash == LocalAuthService.hash(current) else {
            throw AuthError.wrongCurrentPassword
        }
        accounts[index].passwordHash = LocalAuthService.hash(new)
        persistence.saveAccounts(accounts)
    }

    func sendPasswordReset(to email: String) async throws {
        // Nothing to send without a server. The screen shows the same
        // confirmation either way, which is also what stops someone using this
        // form to find out which emails have accounts.
        try? await Task.sleep(nanoseconds: 700_000_000)
    }

    // MARK: - Demo Support

    /// Signs straight in as a seeded account, for demonstrations.
    func useDemoAccount(email: String) -> FarmUser? {
        guard let account = accounts.first(where: { $0.email.lowercased() == email.lowercased() }) else {
            return nil
        }
        signedInEmail = account.email
        return account
    }
}
