//
//  HarvestRecord.swift
//  AniTrack — MODEL LAYER
//
//  Amount harvested only. AniTrack never records prices, buyers or sales — it
//  is a record of work done, not a place to sell.
//

import Foundation

struct HarvestRecord: Identifiable, Codable, Hashable {

    let id: String
    var parcelID: String
    var crop: CropType
    var harvestedOn: Date
    var kilograms: Double
    var quality: HarvestQuality
    var recordedByID: String?
    var remarks: String

    init(id: String = UUID().uuidString,
         parcelID: String,
         crop: CropType,
         harvestedOn: Date,
         kilograms: Double,
         quality: HarvestQuality,
         recordedByID: String? = nil,
         remarks: String = "") {
        self.id = id
        self.parcelID = parcelID
        self.crop = crop
        self.harvestedOn = harvestedOn
        self.kilograms = kilograms
        self.quality = quality
        self.recordedByID = recordedByID
        self.remarks = remarks
    }

    /// Sort key for month sections, e.g. 202609.
    var monthKey: Int {
        let parts = Calendar.current.dateComponents([.year, .month], from: harvestedOn)
        return ((parts.year ?? 0) * 100) + (parts.month ?? 0)
    }

    /// "September 2026"
    var monthTitle: String {
        return harvestedOn.formatted(.dateTime.month(.wide).year())
    }
}
