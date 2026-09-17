//
//  Date+Farm.swift
//  AniTrack — UTILITIES
//

import Foundation

extension Date {

    /// A date a number of whole days from today. Negative goes backwards.
    static func daysFromToday(_ days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
    }

    static var startOfThisMonth: Date {
        let calendar = Calendar.current
        let parts = calendar.dateComponents([.year, .month], from: Date())
        return calendar.date(from: parts) ?? Date()
    }

    static var startOfLastMonth: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .month, value: -1, to: startOfThisMonth) ?? Date()
    }

    static var startOfThisYear: Date {
        let calendar = Calendar.current
        let parts = calendar.dateComponents([.year], from: Date())
        return calendar.date(from: parts) ?? Date()
    }

    static var startOfThreeMonthsAgo: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .month, value: -3, to: startOfThisMonth) ?? Date()
    }

    /// True when this date sits inside the given reporting period.
    func isWithin(_ period: ReportPeriod) -> Bool {
        switch period {
        case .thisMonth:
            return self >= Date.startOfThisMonth
        case .lastMonth:
            return self >= Date.startOfLastMonth && self < Date.startOfThisMonth
        case .lastThreeMonths:
            return self >= Date.startOfThreeMonthsAgo
        case .thisYear:
            return self >= Date.startOfThisYear
        }
    }
}
