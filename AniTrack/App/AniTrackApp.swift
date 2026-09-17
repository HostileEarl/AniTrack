//
//  AniTrackApp.swift
//  AniTrack — APP ENTRY POINT
//
//  The three controllers are created once here and put into the environment, so
//  every screen reads and writes through the same instances.


import SwiftUI

@main
struct AniTrackApp: App {

    @StateObject private var auth = AuthController()

    init() {
        // Must run before any controller is created, so the auth service can
        // be chosen once and never swapped underneath a running screen.
        FirebaseBootstrap.start()
    }
    @StateObject private var data = FarmDataController()
    @StateObject private var toasts = ToastController()

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
