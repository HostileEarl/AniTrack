//
//  StockMovement.swift
//  AniTrack — MODEL LAYER
//

import Foundation

struct StockMovement: Identifiable, Codable, Hashable {

    let id: String
    var itemID: String
    var kind: StockMovementKind
    var quantity: Double
    /// Only set when supplies were used on a particular field.
    var parcelID: String?
    var happenedOn: Date
    var note: String
    var recordedByName: String

    init(id: String = UUID().uuidString,
         itemID: String,
         kind: StockMovementKind,
         quantity: Double,
         parcelID: String? = nil,
         happenedOn: Date = Date(),
         note: String = "",
         recordedByName: String = "") {
        self.id = id
        self.itemID = itemID
        self.kind = kind
        self.quantity = quantity
        self.parcelID = parcelID
        self.happenedOn = happenedOn
        self.note = note
        self.recordedByName = recordedByName
    }
}
