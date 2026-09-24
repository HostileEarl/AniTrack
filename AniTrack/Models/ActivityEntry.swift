//
//  ActivityEntry.swift
//  AniTrack — MODEL LAYER
//
//  One line in the "Recent activity" trail. Every change to the data appends
//  one of these, which is what lets the app show who did what and when.
//

import Foundation
import SwiftData

@Model
final class ActivityEntry {

    @Attribute(.unique) var id: String

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
///
/// Deliberately NOT a @Model: the waiting list describes this run of the app,
/// not the farm, and saving it would mean a change could look like it was still
/// waiting long after it had been backed up.
struct PendingChange: Identifiable, Hashable {

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
