//
//  WeatherDay.swift
//  AniTrack — MODEL LAYER
//
//  One day of the outlook. This is sample data, not a live feed: the app says
//  so plainly on the weather screen rather than letting anyone plan real work
//  around numbers that were never measured.
//

import Foundation

struct WeatherDay: Identifiable, Codable, Hashable {

    let id: String
    var dayLabel: String
    var condition: String
    var temperatureC: Int
    var humidityPercent: Int
    var rainfallMM: Int

    init(id: String = UUID().uuidString,
         dayLabel: String,
         condition: String,
         temperatureC: Int,
         humidityPercent: Int,
         rainfallMM: Int) {
        self.id = id
        self.dayLabel = dayLabel
        self.condition = condition
        self.temperatureC = temperatureC
        self.humidityPercent = humidityPercent
        self.rainfallMM = rainfallMM
    }

    var temperatureLabel: String { "\(temperatureC)°C" }
    var humidityLabel: String { "\(humidityPercent)%" }
    var rainfallLabel: String { "\(rainfallMM) mm" }

    /// Heavier rain gets a wetter symbol, so the row reads at a glance.
    var symbolName: String {
        switch rainfallMM {
        case 0...2: return "sun.max.fill"
        case 3...10: return "cloud.sun.fill"
        case 11...25: return "cloud.rain.fill"
        default: return "cloud.heavyrain.fill"
        }
    }
}

/// What the coming weather means for one field.
struct FieldWeatherImpact: Identifiable, Hashable {
    let id: String
    let fieldName: String
    let advice: String
}
