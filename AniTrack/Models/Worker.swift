//
//  Worker.swift
//  AniTrack — MODEL LAYER
//

import Foundation
import SwiftData

@Model
final class Worker {

    @Attribute(.unique) var id: String

    var fullName: String
    var role: TeamRole
    var contactNumber: String
    var homeBarangay: String

    init(id: String = UUID().uuidString,
         fullName: String,
         role: TeamRole,
         contactNumber: String,
         homeBarangay: String) {
        self.id = id
        self.fullName = fullName
        self.role = role
        self.contactNumber = contactNumber
        self.homeBarangay = homeBarangay
    }

    // MARK: - Computed (not stored)

    /// Up to two letters for the round avatar badge.
    var initials: String {
        let letters = fullName.split(separator: " ").prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    /// "R. Sarmiento" — keeps long names from wrapping in tight rows.
    var shortName: String {
        let parts = fullName.split(separator: " ")
        guard let first = parts.first, parts.count > 1 else { return fullName }
        return "\(first.prefix(1)). \(parts.dropFirst().joined(separator: " "))"
    }
}
