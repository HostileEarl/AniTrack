//
//  ActivityEntry.swift
//  AniTrack — MODEL LAYER
//
//  One line in the "Recent activity" trail. Every change to the data appends
//  one of these, which is what lets the app show who did what and when.
//

import Foundation

struct ActivityEntry: Identifiable, Codable, Hashable {

    let id: String
    var happenedOn: Date
    var actorName: String
    var summary: String
    var category: ActivityCategory

    init(id: String = UUID().uuidString,
         happenedOn: Date = Date(),
         actorName: String,
         summary: String,
         category: ActivityCategory) {
        self.id = id
        self.happenedOn = happenedOn
        self.actorName = actorName
        self.summary = summary
        self.category = category
    }
}

/// A change made while offline, waiting to be backed up.
struct PendingChange: Identifiable, Codable, Hashable {

    let id: String
    var madeOn: Date
    var summary: String

    init(id: String = UUID().uuidString,
         madeOn: Date = Date(),
         summary: String) {
        self.id = id
        self.madeOn = madeOn
        self.summary = summary
    }
}
