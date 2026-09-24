//
//  SupplyItem.swift
//  AniTrack — MODEL LAYER
//
//  Things the farm buys to operate — seed, fertilizer, fuel, tools. Never crops
//  and never anything for sale.
//

import Foundation
import SwiftData

@Model
final class SupplyItem {

    @Attribute(.unique) var id: String

    var name: String
    var category: SupplyCategory
    var quantity: Double
    var unit: String
    /// Warn the user once the quantity reaches or drops below this.
    var warnBelow: Double
    /// What one unit costs the farm, used for the operating cost summary.
    var unitCost: Double

    init(id: String = UUID().uuidString,
         name: String,
         category: SupplyCategory,
         quantity: Double,
         unit: String,
         warnBelow: Double,
         unitCost: Double = 0) {
        self.id = id
        self.name = name
        self.category = category
        self.quantity = quantity
        self.unit = unit
        self.warnBelow = warnBelow
        self.unitCost = unitCost
    }

    // MARK: - Computed (not stored)

    var isRunningLow: Bool {
        return quantity <= warnBelow
    }

    /// "8 bags"
    var quantityLabel: String {
        return "\(Formatting.wholeNumber(quantity)) \(unit)"
    }

    /// How full the stock is against twice the warning level, capped at 1.
    var stockRatio: Double {
        let ceiling = max(warnBelow * 2, 1)
        return min(max(quantity / ceiling, 0), 1)
    }
}
