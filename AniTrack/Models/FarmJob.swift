//
//  FarmJob.swift
//  AniTrack — MODEL LAYER
//
//  Named FarmJob rather than Task, because Swift Concurrency already defines a
//  type called Task and the collision produces confusing compiler errors.
//

import Foundation

struct FarmJob: Identifiable, Codable, Hashable {

    let id: String
    var title: String
    var details: String
    var parcelID: String
    var assigneeID: String?
    var dueOn: Date
    var status: JobStatus
    var priority: JobPriority

    init(id: String = UUID().uuidString,
         title: String,
         details: String = "",
         parcelID: String,
         assigneeID: String? = nil,
         dueOn: Date,
         status: JobStatus = .notStarted,
         priority: JobPriority = .normal) {
        self.id = id
        self.title = title
        self.details = details
        self.parcelID = parcelID
        self.assigneeID = assigneeID
        self.dueOn = dueOn
        self.status = status
        self.priority = priority
    }

    var isDueToday: Bool {
        return Calendar.current.isDateInToday(dueOn)
    }

    /// A finished job is never late, however old it is.
    var isLate: Bool {
        guard !status.isDone else { return false }
        let calendar = Calendar.current
        return calendar.startOfDay(for: dueOn) < calendar.startOfDay(for: Date())
    }

    var isComingUp: Bool {
        return !status.isDone && !isLate && !isDueToday
    }

    /// "Today", "Tomorrow", "Yesterday", or "18 Sep".
    var dueLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(dueOn) { return "Today" }
        if calendar.isDateInTomorrow(dueOn) { return "Tomorrow" }
        if calendar.isDateInYesterday(dueOn) { return "Yesterday" }
        return dueOn.formatted(.dateTime.day().month(.abbreviated))
    }
}
