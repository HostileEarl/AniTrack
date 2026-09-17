//
//  ModelPresentation.swift
//  AniTrack — VIEW SUPPORT
//
//  Colours and SF Symbols for the model enums. These live in the view layer on
//  purpose: they are presentation choices, so keeping them here is what allows
//  every file in Models/ to import Foundation only.
//

import SwiftUI

extension FieldCondition {

    var tint: Color {
        switch self {
        case .good: return AppTheme.shoot
        case .watch: return AppTheme.husk
        case .problem: return AppTheme.clay
        }
    }

    var symbolName: String {
        switch self {
        case .good: return "checkmark.seal.fill"
        case .watch: return "eye.fill"
        case .problem: return "exclamationmark.triangle.fill"
        }
    }
}

extension CropType {

    var symbolName: String {
        switch self {
        case .rice: return "leaf.fill"
        case .corn: return "laurel.leading"
        case .sugarcane: return "line.diagonal"
        case .banana: return "tree.fill"
        case .coconut: return "circle.hexagongrid.fill"
        case .vegetables: return "carrot.fill"
        }
    }
}

extension GrowthStage {

    var symbolName: String {
        switch self {
        case .fallow: return "moon.zzz.fill"
        case .landPreparation: return "hammer.fill"
        case .planting: return "arrow.down.to.line"
        case .vegetative: return "leaf.fill"
        case .flowering: return "camera.macro"
        case .maturing: return "sun.max.fill"
        case .readyForHarvest: return "basket.fill"
        }
    }
}

extension JobStatus {

    var symbolName: String {
        switch self {
        case .notStarted: return "circle"
        case .started: return "circle.lefthalf.filled"
        case .done: return "checkmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .notStarted: return AppTheme.ink.opacity(0.35)
        case .started: return AppTheme.husk
        case .done: return AppTheme.shoot
        }
    }
}

extension JobPriority {

    var tint: Color {
        switch self {
        case .high: return AppTheme.clay
        case .normal: return AppTheme.paddy
        case .low: return AppTheme.shoot
        }
    }
}

extension HarvestQuality {

    var tint: Color {
        switch self {
        case .best: return AppTheme.paddy
        case .good: return AppTheme.shoot
        case .low: return AppTheme.husk
        }
    }
}

extension NoteUrgency {

    var tint: Color {
        switch self {
        case .normal: return AppTheme.shoot
        case .watch: return AppTheme.husk
        case .urgent: return AppTheme.clay
        }
    }
}

extension SupplyCategory {

    var symbolName: String {
        switch self {
        case .fertilizer: return "bag.fill"
        case .seed: return "leaf.circle.fill"
        case .fuel: return "fuelpump.fill"
        case .tools: return "wrench.and.screwdriver.fill"
        }
    }
}

extension AlertKind {

    var symbolName: String {
        switch self {
        case .urgentNote: return "exclamationmark.bubble.fill"
        case .jobLate: return "clock.badge.exclamationmark.fill"
        case .runningLow: return "shippingbox.fill"
        case .weather: return "cloud.rain.fill"
        case .readyToHarvest: return "basket.fill"
        }
    }

    var tint: Color {
        switch self {
        case .urgentNote, .jobLate: return AppTheme.clay
        case .runningLow, .weather: return AppTheme.husk
        case .readyToHarvest: return AppTheme.shoot
        }
    }
}

extension ActivityCategory {

    var symbolName: String {
        switch self {
        case .jobs: return "checklist"
        case .harvest: return "basket.fill"
        case .fields: return "map.fill"
        case .supplies: return "shippingbox.fill"
        case .reports: return "doc.text.fill"
        }
    }
}

extension AccountRole {

    var tint: Color {
        switch self {
        case .farmManager: return AppTheme.paddy
        case .teamLeader: return AppTheme.shoot
        case .owner: return AppTheme.husk
        }
    }
}
