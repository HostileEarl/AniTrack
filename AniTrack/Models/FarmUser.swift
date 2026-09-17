//
//  FarmUser.swift
//  AniTrack — MODEL LAYER
//
//  An account that can sign in. The password is never stored in plain text:
//  only a SHA-256 hash is kept, and sign-in compares hashes. This is still not
//  production-grade security — a real system would salt each password — but it
//  is the correct shape and avoids storing readable passwords.
//

import Foundation

struct FarmUser: Identifiable, Codable, Hashable {

    var id: String { email.lowercased() }

    var email: String
    var passwordHash: String
    var fullName: String
    var role: AccountRole
    /// Links the account to a team member, so a team leader sees only their work.
    var workerID: String?
    var mobile: String
    var farmName: String
    var municipality: String
    var memberSince: Date

    init(email: String,
         passwordHash: String,
         fullName: String,
         role: AccountRole,
         workerID: String? = nil,
         mobile: String = "",
         farmName: String = "Reyes Family Farm",
         municipality: String = "Cabanatuan, Nueva Ecija",
         memberSince: Date = Date()) {
        self.email = email
        self.passwordHash = passwordHash
        self.fullName = fullName
        self.role = role
        self.workerID = workerID
        self.mobile = mobile
        self.farmName = farmName
        self.municipality = municipality
        self.memberSince = memberSince
    }

    var firstName: String {
        return String(fullName.split(separator: " ").first ?? "there")
    }

    var initials: String {
        let letters = fullName.split(separator: " ").prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }
}
