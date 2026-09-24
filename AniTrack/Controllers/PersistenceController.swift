//
//  PersistenceController.swift
//  AniTrack — CONTROLLER LAYER
//
//  Small settings and account storage.
//
//  The farm's data — fields, jobs, harvests, notes, supplies — lives in
//  SwiftData and is handled by FarmDataController. What is left here is the
//  handful of things SwiftData is the wrong tool for:
//
//    - whether the intro pages have been seen
//    - whether amounts are shown in sacks
//    - the on-device account list, used only when Firebase is not connected
//
//  These are settings rather than farm records: a few values read once at
//  launch, with no querying, sorting or relationships. A database would be more
//  machinery than the job needs.
//

import Foundation

//  Marked Sendable because Swift 6 will not let a plain `static let` of a
//  non-Sendable type be read from a nonisolated context — which is exactly what
//  `persistence: PersistenceController = .shared` does in the initialisers of
//  LocalAuthService, AuthController and FarmDataController.
//
//  The claim is honest rather than a silencer: every stored property is a `let`
//  and never changes after init, and every write to disk happens on one private
//  serial queue. The `@unchecked` is needed only because JSONEncoder and
//  JSONDecoder are classes that Foundation has not marked Sendable.

final class PersistenceController: @unchecked Sendable {

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
        case accounts, settings
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

}
