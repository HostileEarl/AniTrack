

import Foundation

enum Formatting {

    private static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private static let peso: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    /// "12,400"
    static func wholeNumber(_ value: Double) -> String {
        return decimal.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    /// "12,400 kg" or "248 sacks" when the user prefers sacks.
    static func amount(_ kilograms: Double, inSacks: Bool) -> String {
        if inSacks {
            let sacks = (kilograms / 50).rounded()
            return "\(wholeNumber(sacks)) sacks"
        }
        return "\(wholeNumber(kilograms)) kg"
    }

    /// "12.5" — hectares always to one decimal place.
    static func hectares(_ value: Double) -> String {
        return String(format: "%.1f", value)
    }

    /// "PHP 8,400"
    static func money(_ value: Double) -> String {
        let text = peso.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        return "PHP \(text)"
    }

    /// "62%"
    static func percent(_ ratio: Double) -> String {
        return "\(Int((ratio * 100).rounded()))%"
    }

    /// "2h ago", "3d ago", "Just now"
    static func relativeTime(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 60 { return "Just now" }
        let minutes = Int(seconds / 60)
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        let days = hours / 24
        if days < 7 { return "\(days)d ago" }
        let weeks = days / 7
        if weeks < 5 { return "\(weeks)w ago" }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }
}
