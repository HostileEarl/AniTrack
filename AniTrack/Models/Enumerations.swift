//
//  Enumerations.swift
//  AniTrack
//
//  MODEL LAYER — Foundation only, never SwiftUI.
//
//  Every case has a stable `rawValue` used for storage and a separate
//  `displayName` used on screen. This is why the app can speak plainly to farm
//  workers ("Ripening", "Problem") without weakening the data model, and why
//  changing a label never breaks saved data.
//

import Foundation

// MARK: - Crop

enum CropType: String, Codable, CaseIterable, Identifiable, Hashable {
    case rice = "Rice"
    case corn = "Corn"
    case sugarcane = "Sugarcane"
    case banana = "Banana"
    case coconut = "Coconut"
    case vegetables = "Vegetables"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

// MARK: - Growth Stage

enum GrowthStage: String, Codable, CaseIterable, Identifiable, Hashable {
    case fallow = "Fallow"
    case landPreparation = "Land Preparation"
    case planting = "Planting"
    case vegetative = "Vegetative"
    case flowering = "Flowering"
    case maturing = "Maturing"
    case readyForHarvest = "Ready for Harvest"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fallow: return "Resting"
        case .landPreparation: return "Preparing land"
        case .planting: return "Planting"
        case .vegetative: return "Growing"
        case .flowering: return "Flowering"
        case .maturing: return "Ripening"
        case .readyForHarvest: return "Ready to harvest"
        }
    }

    /// How far through the growing cycle, from 0 to 1.
    var progress: Double {
        switch self {
        case .fallow: return 0.0
        case .landPreparation: return 0.12
        case .planting: return 0.28
        case .vegetative: return 0.48
        case .flowering: return 0.66
        case .maturing: return 0.84
        case .readyForHarvest: return 1.0
        }
    }

    var isPlanted: Bool {
        return self != .fallow
    }

    /// The next stage in the cycle, looping back to resting after harvest.
    var next: GrowthStage {
        let all = GrowthStage.allCases
        guard let index = all.firstIndex(of: self) else { return .fallow }
        let following = all.index(after: index)
        return following < all.endIndex ? all[following] : all[0]
    }
}

// MARK: - Field Condition

enum FieldCondition: String, Codable, CaseIterable, Identifiable, Hashable {
    case good = "Healthy"
    case watch = "Monitor"
    case problem = "Needs Attention"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .good: return "Good"
        case .watch: return "Watch"
        case .problem: return "Problem"
        }
    }

    /// Lower comes first, so problems are never buried down a list.
    var severityRank: Int {
        switch self {
        case .problem: return 0
        case .watch: return 1
        case .good: return 2
        }
    }

    var needsAttention: Bool {
        return self != .good
    }
}

// MARK: - Job Status

enum JobStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case notStarted = "Pending"
    case started = "In Progress"
    case done = "Completed"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .notStarted: return "Not started"
        case .started: return "Started"
        case .done: return "Done"
        }
    }

    var isDone: Bool {
        return self == .done
    }
}

// MARK: - Priority

enum JobPriority: String, Codable, CaseIterable, Identifiable, Hashable {
    case low = "Low"
    case normal = "Normal"
    case high = "High"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var severityRank: Int {
        switch self {
        case .high: return 0
        case .normal: return 1
        case .low: return 2
        }
    }
}

// MARK: - Job Filter

enum JobFilter: String, CaseIterable, Identifiable, Hashable {
    case today = "Today"
    case comingUp = "Coming up"
    case late = "Late"
    case done = "Done"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

// MARK: - Harvest Quality

enum HarvestQuality: String, Codable, CaseIterable, Identifiable, Hashable {
    case best = "Premium"
    case good = "Standard"
    case low = "Fair"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .best: return "Best"
        case .good: return "Good"
        case .low: return "Low"
        }
    }
}

// MARK: - Team Role

enum TeamRole: String, Codable, CaseIterable, Identifiable, Hashable {
    case teamLeader = "Field Crew Lead"
    case cropTechnician = "Crop Technician"
    case waterOperator = "Irrigation Operator"
    case harvestHand = "Harvest Hand"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .teamLeader: return "Team leader"
        case .cropTechnician: return "Crop technician"
        case .waterOperator: return "Water operator"
        case .harvestHand: return "Harvest hand"
        }
    }
}

// MARK: - Account Role

enum AccountRole: String, Codable, CaseIterable, Identifiable, Hashable {
    case farmManager = "Farm Manager"
    case teamLeader = "Crew Lead"
    case owner = "Owner"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .farmManager: return "Farm Manager"
        case .teamLeader: return "Team Leader"
        case .owner: return "Owner"
        }
    }

    var summary: String {
        switch self {
        case .farmManager: return "Can see and change everything"
        case .teamLeader: return "Only your fields and your jobs"
        case .owner: return "Can look but not change"
        }
    }
}

// MARK: - Field Note Urgency

enum NoteUrgency: String, Codable, CaseIterable, Identifiable, Hashable {
    case normal = "Routine"
    case watch = "Concern"
    case urgent = "Urgent"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .watch: return "Watch"
        case .urgent: return "Urgent"
        }
    }

    var severityRank: Int {
        switch self {
        case .urgent: return 0
        case .watch: return 1
        case .normal: return 2
        }
    }
}

// MARK: - Supplies

enum SupplyCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case fertilizer = "Fertiliser"
    case seed = "Seed"
    case fuel = "Fuel"
    case tools = "Equipment"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fertilizer: return "Fertilizer"
        case .seed: return "Seed"
        case .fuel: return "Fuel"
        case .tools: return "Tools"
        }
    }
}

enum StockMovementKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case added = "Received"
    case used = "Used"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .added: return "Added"
        case .used: return "Used"
        }
    }
}

// MARK: - Alerts

enum AlertKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case urgentNote = "urgent-report"
    case jobLate = "task-overdue"
    case runningLow = "low-stock"
    case weather = "weather"
    case readyToHarvest = "harvest-window"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .urgentNote: return "Urgent field note"
        case .jobLate: return "Job is late"
        case .runningLow: return "Running low"
        case .weather: return "Weather warning"
        case .readyToHarvest: return "Ready to harvest"
        }
    }
}

// MARK: - Activity

enum ActivityCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case jobs = "Tasks"
    case harvest = "Harvest"
    case fields = "Parcels"
    case supplies = "Supplies"
    case reports = "Reports"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .jobs: return "Jobs"
        case .harvest: return "Harvest"
        case .fields: return "Fields"
        case .supplies: return "Supplies"
        case .reports: return "Reports"
        }
    }
}

// MARK: - Report Period

enum ReportPeriod: String, CaseIterable, Identifiable, Hashable {
    case thisMonth = "This month"
    case lastMonth = "Last month"
    case lastThreeMonths = "Last 3 months"
    case thisYear = "This year"

    var id: String { rawValue }
    var displayName: String { rawValue }
}
