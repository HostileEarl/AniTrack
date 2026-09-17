//
//  FarmAlert.swift
//  AniTrack — MODEL LAYER
//

import Foundation

/// Where tapping an alert should take the user.
enum AlertDestination: String, Codable, Hashable {
    case fieldNotes
    case jobs
    case supplies
    case weather
    case fields
}

struct FarmAlert: Identifiable, Codable, Hashable {

    let id: String
    var kind: AlertKind
    var message: String
    var relatedID: String?
    var destination: AlertDestination
    var raisedOn: Date
    var isRead: Bool

    init(id: String = UUID().uuidString,
         kind: AlertKind,
         message: String,
         relatedID: String? = nil,
         destination: AlertDestination,
         raisedOn: Date = Date(),
         isRead: Bool = false) {
        self.id = id
        self.kind = kind
        self.message = message
        self.relatedID = relatedID
        self.destination = destination
        self.raisedOn = raisedOn
        self.isRead = isRead
    }
}
