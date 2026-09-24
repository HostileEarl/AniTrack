//
//  AniTrackApp.swift
//  AniTrack — APP ENTRY POINT
//
//  Builds the SwiftData store and the three controllers, then puts the
//  controllers into the environment so every screen reads and writes through
//  the same instances.
//
//  Note what is NOT here: `.modelContainer(...)`. That modifier is what lets a
//  view use @Query, and no view in AniTrack does. The container is handed to
//  FarmDataController instead, which keeps data access in the controller layer
//  where MVC says it belongs.
//

import SwiftUI
import SwiftData

@main
struct AniTrackApp: App {

    /// Every type SwiftData needs to know about. Adding a @Model class without
    /// listing it here is the usual cause of "no such table" at runtime.
    private static let schema = Schema([
        Parcel.self,
        FarmJob.self,
        HarvestRecord.self,
        FieldNote.self,
        SupplyItem.self,
        StockMovement.self,
        FarmAlert.self,
        ActivityEntry.self,
        Worker.self
    ])

    private let container: ModelContainer

    @StateObject private var auth: AuthController
    @StateObject private var data: FarmDataController
    @StateObject private var toasts = ToastController()

    init() {
        // Must run before any controller exists, so the account system is
        // chosen once and never swapped underneath a running screen.
        FirebaseBootstrap.start()

        let container: ModelContainer
        do {
            container = try ModelContainer(
                for: AniTrackApp.schema,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            // If the store on disk cannot be opened — usually because the
            // models changed shape during development — fall back to a store
            // held in memory so the app still runs and can be demonstrated.
            print("AniTrack could not open its database: \(error.localizedDescription)")
            container = try! ModelContainer(
                for: AniTrackApp.schema,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }
        self.container = container

        let context = ModelContext(container)
        _data = StateObject(wrappedValue: FarmDataController(context: context))
        _auth = StateObject(wrappedValue: AuthController())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(data)
                .environmentObject(toasts)
                .tint(AppTheme.paddy)
                .preferredColorScheme(.light)
        }
    }
}
