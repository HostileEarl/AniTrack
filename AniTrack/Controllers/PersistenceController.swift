//
//  PersistenceController.swift
//  AniTrack — CONTROLLER LAYER
//
//  Saves the model collections as JSON files in the app's Documents directory,
//  so data survives closing the app.
//
//  Why JSON files rather than SwiftData: every model here is already a Codable
//  value type, and the whole app funnels its writes through one controller. That
//  makes file storage a small, dependable addition instead of a rewrite into
//  reference-type @Model classes, which would also weaken the strict MVC split
//  the project is built on. The save and load calls sit behind this one type, so
//  moving to SwiftData later means changing this file and nothing else.
//

import Foundation

final class PersistenceController {

    static let shared = PersistenceController()

    /// Used by previews and tests: reads and writes nothing.
    static let inMemory = PersistenceController(enabled: false)

    private let enabled: Bool
    private let queue = DispatchQueue(label: "ph.reyesfarm.anitrack.persistence", qos: .utility)
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init(enabled: Bool = true) {
        self.enabled = enabled

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    // MARK: - File Locations

    private enum Store: String {
        case parcels, jobs, harvests, fieldNotes, supplies
        case stockMovements, alerts, activity, accounts, settings
    }

    private var directory: URL? {
        return FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first
    }

    private func url(for store: Store) -> URL? {
        return directory?.appendingPathComponent("anitrack-\(store.rawValue).json")
    }

    // MARK: - Generic Read and Write

    /// Writes off the main thread so the interface never stalls on a save.
    private func write<T: Encodable>(_ value: T, to store: Store) {
        guard enabled, let url = url(for: store) else { return }
        let encoder = self.encoder
        queue.async {
            do {
                let data = try encoder.encode(value)
                try data.write(to: url, options: .atomic)
            } catch {
                // A failed save must never crash the app. The user keeps working
                // against in-memory state and the next save will retry.
                print("AniTrack could not save \(store.rawValue): \(error.localizedDescription)")
            }
        }
    }

    private func read<T: Decodable>(_ type: T.Type, from store: Store) -> T? {
        guard enabled, let url = url(for: store),
              FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(T.self, from: data)
        } catch {
            print("AniTrack could not read \(store.rawValue): \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Farm Data

    func saveParcels(_ value: [Parcel]) { write(value, to: .parcels) }
    func loadParcels() -> [Parcel]? { read([Parcel].self, from: .parcels) }

    func saveJobs(_ value: [FarmJob]) { write(value, to: .jobs) }
    func loadJobs() -> [FarmJob]? { read([FarmJob].self, from: .jobs) }

    func saveHarvests(_ value: [HarvestRecord]) { write(value, to: .harvests) }
    func loadHarvests() -> [HarvestRecord]? { read([HarvestRecord].self, from: .harvests) }

    func saveFieldNotes(_ value: [FieldNote]) { write(value, to: .fieldNotes) }
    func loadFieldNotes() -> [FieldNote]? { read([FieldNote].self, from: .fieldNotes) }

    func saveSupplies(_ value: [SupplyItem]) { write(value, to: .supplies) }
    func loadSupplies() -> [SupplyItem]? { read([SupplyItem].self, from: .supplies) }

    func saveStockMovements(_ value: [StockMovement]) { write(value, to: .stockMovements) }
    func loadStockMovements() -> [StockMovement]? { read([StockMovement].self, from: .stockMovements) }

    func saveAlerts(_ value: [FarmAlert]) { write(value, to: .alerts) }
    func loadAlerts() -> [FarmAlert]? { read([FarmAlert].self, from: .alerts) }

    func saveActivity(_ value: [ActivityEntry]) { write(value, to: .activity) }
    func loadActivity() -> [ActivityEntry]? { read([ActivityEntry].self, from: .activity) }

    // MARK: - Accounts

    func saveAccounts(_ value: [FarmUser]) { write(value, to: .accounts) }

    func loadAccounts() -> [FarmUser] {
        return read([FarmUser].self, from: .accounts) ?? []
    }

    // MARK: - Settings

    private struct StoredSettings: Codable {
        var hasSeenIntro: Bool = false
        var useSacks: Bool = false
    }

    private var settings: StoredSettings {
        return read(StoredSettings.self, from: .settings) ?? StoredSettings()
    }

    func loadHasSeenIntro() -> Bool { settings.hasSeenIntro }

    func saveHasSeenIntro(_ value: Bool) {
        var current = settings
        current.hasSeenIntro = value
        write(current, to: .settings)
    }

    func loadUseSacks() -> Bool { settings.useSacks }

    func saveUseSacks(_ value: Bool) {
        var current = settings
        current.useSacks = value
        write(current, to: .settings)
    }

    // MARK: - Reset

    /// Deletes every saved file so the app starts again from the sample data.
    func eraseAll() {
        guard enabled else { return }
        let stores: [Store] = [.parcels, .jobs, .harvests, .fieldNotes, .supplies,
                               .stockMovements, .alerts, .activity]
        for store in stores {
            guard let url = url(for: store) else { continue }
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Storage Summary

    /// Total bytes used by the saved files, shown on the Saving and backup screen.
    func storageBytes() -> Int {
        guard enabled, let directory = directory else { return 0 }
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey])) ?? []
        return contents
            .filter { $0.lastPathComponent.hasPrefix("anitrack-") }
            .reduce(0) { total, url in
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                return total + size
            }
    }
}
