//
//  FieldNote.swift
//  AniTrack — MODEL LAYER
//
//  An observation sent in from the field by a team member.
//

import Foundation
import SwiftData

@Model
final class FieldNote {

    @Attribute(.unique) var id: String

    var parcelID: String
    var reportedByName: String
    var urgency: NoteUrgency
    var observation: String
    var photoCount: Int
    var filedOn: Date
    var isResolved: Bool
    var notifyManager: Bool

    init(id: String = UUID().uuidString,
         parcelID: String,
         reportedByName: String,
         urgency: NoteUrgency,
         observation: String,
         photoCount: Int = 0,
         filedOn: Date = Date(),
         isResolved: Bool = false,
         notifyManager: Bool = false) {
        self.id = id
        self.parcelID = parcelID
        self.reportedByName = reportedByName
        self.urgency = urgency
        self.observation = observation
        self.photoCount = photoCount
        self.filedOn = filedOn
        self.isResolved = isResolved
        self.notifyManager = notifyManager
    }

    var initials: String {
        let letters = reportedByName.split(separator: " ").prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }
}
