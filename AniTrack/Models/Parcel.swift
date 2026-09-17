//
//  Parcel.swift
//  AniTrack — MODEL LAYER
//
//  Shown to the user as a "field". The type keeps the name Parcel because it is
//  the land record, and renaming it across the codebase would gain nothing that
//  the display labels do not already give.
//

import Foundation

struct Parcel: Identifiable, Codable, Hashable {

    let id: String
    var name: String
    var barangay: String
    var municipality: String
    var areaHectares: Double
    var crop: CropType
    var stage: GrowthStage
    var condition: FieldCondition
    var plantedOn: Date
    var harvestDueOn: Date
    var teamLeaderID: String?
    var notes: String
    var latitude: Double
    var longitude: Double

    init(id: String = UUID().uuidString,
         name: String,
         barangay: String,
         municipality: String,
         areaHectares: Double,
         crop: CropType,
         stage: GrowthStage,
         condition: FieldCondition,
         plantedOn: Date,
         harvestDueOn: Date,
         teamLeaderID: String? = nil,
         notes: String = "",
         latitude: Double = 0,
         longitude: Double = 0) {
        self.id = id
        self.name = name
        self.barangay = barangay
        self.municipality = municipality
        self.areaHectares = areaHectares
        self.crop = crop
        self.stage = stage
        self.condition = condition
        self.plantedOn = plantedOn
        self.harvestDueOn = harvestDueOn
        self.teamLeaderID = teamLeaderID
        self.notes = notes
        self.latitude = latitude
        self.longitude = longitude
    }

    /// "Sto. Niño, Cabanatuan"
    var placeLabel: String {
        return "\(barangay), \(municipality)"
    }

    /// "3.2 ha"
    var areaLabel: String {
        return String(format: "%.1f ha", areaHectares)
    }

    var daysUntilHarvest: Int {
        let calendar = Calendar.current
        let from = calendar.startOfDay(for: Date())
        let to = calendar.startOfDay(for: harvestDueOn)
        return calendar.dateComponents([.day], from: from, to: to).day ?? 0
    }

    /// Short countdown for the field row.
    var harvestCountdown: String {
        guard stage.isPlanted else { return "Resting" }
        let days = daysUntilHarvest
        if days < 0 { return "Late by \(abs(days))d" }
        if days == 0 { return "Harvest today" }
        return "Harvest in \(days)d"
    }
}
