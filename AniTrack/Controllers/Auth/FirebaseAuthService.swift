//
//  FirebaseAuthService.swift
//  AniTrack — CONTROLLER LAYER
//
//  Accounts held by Firebase Authentication, with the farm profile (role, farm
//  name, which team member the account belongs to) held in Cloud Firestore.
//
//  Firebase Auth stores only an email, a password and a user id. It has no idea
//  what a Farm Manager is, so the role has to live somewhere else — that is the
//  `users/{uid}` document this file reads and writes.
//
//  The whole file is wrapped in `#if canImport(FirebaseAuth)`. Before the
//  Firebase package is added to the project this compiles to nothing and the
//  app quietly uses LocalAuthService instead, so the project always builds.
//

import Foundation

#if canImport(FirebaseAuth) && canImport(FirebaseFirestore)

import FirebaseAuth
import FirebaseFirestore

final class FirebaseAuthService: AuthService {

    var providerName: String { "Firebase" }
    var isRemote: Bool { true }

    private let store = Firestore.firestore()
    private let usersCollection = "users"

    // MARK: - Session

    func restoreSession() async -> FarmUser? {
        guard let account = Auth.auth().currentUser else { return nil }
        return try? await loadProfile(uid: account.uid, email: account.email ?? "")
    }

    func signIn(email: String, password: String) async throws -> FarmUser {
        let typed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let result = try await Auth.auth().signIn(withEmail: typed, password: password)
            return try await loadProfile(uid: result.user.uid, email: result.user.email ?? typed)
        } catch let error as AuthError {
            throw error
        } catch {
            throw FirebaseAuthService.translate(error)
        }
    }

    func signUp(details: SignUpDetails) async throws -> FarmUser {
        let typed = details.email.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let result = try await Auth.auth().createUser(withEmail: typed, password: details.password)

            // Sets the name Firebase shows in its own console, which makes the
            // list of users readable when checking things there.
            let change = result.user.createProfileChangeRequest()
            change.displayName = details.fullName
            try? await change.commitChanges()

            let user = FarmUser(email: typed,
                                passwordHash: "",
                                fullName: details.fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                                role: details.role,
                                workerID: nil,
                                mobile: details.mobile,
                                farmName: details.farmName.isEmpty ? "My Farm" : details.farmName,
                                municipality: details.municipality,
                                memberSince: Date())

            try await saveProfile(user, uid: result.user.uid)
            return user
        } catch {
            throw FirebaseAuthService.translate(error)
        }
    }

    func signOut() async throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw FirebaseAuthService.translate(error)
        }
    }

    // MARK: - Profile

    func updateProfile(_ user: FarmUser) async throws {
        guard let account = Auth.auth().currentUser else { throw AuthError.notSignedIn }
        try await saveProfile(user, uid: account.uid)
    }

    /// Firebase requires a recent sign-in before a password change, so the
    /// current password is used to re-authenticate first. That is also what
    /// makes "your current password is wrong" a real check rather than a
    /// courtesy field.
    func changePassword(current: String, new: String, for user: FarmUser) async throws {
        guard let account = Auth.auth().currentUser, let email = account.email else {
            throw AuthError.notSignedIn
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: current)
        do {
            try await account.reauthenticate(with: credential)
        } catch {
            let translated = FirebaseAuthService.translate(error)
            // A rejected re-authentication means the current password is wrong.
            if translated == .wrongCredentials { throw AuthError.wrongCurrentPassword }
            throw translated
        }

        do {
            try await account.updatePassword(to: new)
        } catch {
            throw FirebaseAuthService.translate(error)
        }
    }

    func sendPasswordReset(to email: String) async throws {
        let typed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try await Auth.auth().sendPasswordReset(withEmail: typed)
        } catch {
            let translated = FirebaseAuthService.translate(error)
            // Never reveal whether an email has an account. The screen shows the
            // same confirmation either way.
            if translated == .wrongCredentials { return }
            throw translated
        }
    }

    // MARK: - Firestore Mapping

    private func saveProfile(_ user: FarmUser, uid: String) async throws {
        let data: [String: Any] = [
            "email": user.email,
            "fullName": user.fullName,
            "role": user.role.rawValue,
            "workerID": user.workerID ?? "",
            "mobile": user.mobile,
            "farmName": user.farmName,
            "municipality": user.municipality,
            "memberSince": Timestamp(date: user.memberSince)
        ]
        do {
            try await store.collection(usersCollection).document(uid).setData(data, merge: true)
        } catch {
            throw FirebaseAuthService.translate(error)
        }
    }

    private func loadProfile(uid: String, email: String) async throws -> FarmUser {
        let snapshot: DocumentSnapshot
        do {
            snapshot = try await store.collection(usersCollection).document(uid).getDocument()
        } catch {
            throw FirebaseAuthService.translate(error)
        }

        guard let data = snapshot.data() else { throw AuthError.profileMissing }

        let roleValue = data["role"] as? String ?? AccountRole.farmManager.rawValue
        let workerID = data["workerID"] as? String
        let since = (data["memberSince"] as? Timestamp)?.dateValue() ?? Date()

        return FarmUser(email: data["email"] as? String ?? email,
                        passwordHash: "",
                        fullName: data["fullName"] as? String ?? "Farm user",
                        role: AccountRole(rawValue: roleValue) ?? .farmManager,
                        workerID: (workerID?.isEmpty ?? true) ? nil : workerID,
                        mobile: data["mobile"] as? String ?? "",
                        farmName: data["farmName"] as? String ?? "My Farm",
                        municipality: data["municipality"] as? String ?? "",
                        memberSince: since)
    }

    // MARK: - Error Translation

    /// Firebase error codes are compared as plain numbers rather than through
    /// the AuthErrorCode type, because that type has been renamed and reshaped
    /// several times across SDK versions while the numbers themselves have
    /// stayed put. This keeps the file building across upgrades.
    private enum Code {
        static let invalidCredential = 17004
        static let emailAlreadyInUse = 17007
        static let invalidEmail = 17008
        static let wrongPassword = 17009
        static let userNotFound = 17011
        static let tooManyRequests = 17010
        static let networkError = 17020
        static let weakPassword = 17026
    }

    static func translate(_ error: Error) -> AuthError {
        let nsError = error as NSError
        switch nsError.code {
        case Code.wrongPassword, Code.userNotFound, Code.invalidCredential:
            return .wrongCredentials
        case Code.emailAlreadyInUse:
            return .emailTaken
        case Code.invalidEmail:
            return .invalidEmail
        case Code.weakPassword:
            return .weakPassword
        case Code.networkError:
            return .networkUnavailable
        case Code.tooManyRequests:
            return .tooManyAttempts
        default:
            return .unknown(nsError.localizedDescription)
        }
    }
}

#endif
