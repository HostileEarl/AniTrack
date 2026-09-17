//
//  FirebaseBootstrap.swift
//  AniTrack — APP
//
//  Starts Firebase if it is present, and says so plainly if it is not.
//
//  Everything is behind `#if canImport(FirebaseCore)`, so the app builds and
//  runs whether or not the Firebase package has been added to the project.
//

import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif

enum FirebaseBootstrap {

    /// True when Firebase is in the project and its settings file was found.
    private(set) static var isReady: Bool = false

    /// Called once, at app launch, before any controller is built.
    static func start() {
        #if canImport(FirebaseCore)
        guard FileManager.default.fileExists(
            atPath: Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") ?? ""
        ) else {
            print("""
                  AniTrack: the Firebase package is installed but GoogleService-Info.plist \
                  is missing from the app target. Falling back to accounts stored on this \
                  device. See FIREBASE-SETUP.md, step 4.
                  """)
            isReady = false
            return
        }

        FirebaseApp.configure()
        isReady = true
        print("AniTrack: signed in through Firebase.")
        #else
        isReady = false
        print("AniTrack: Firebase not installed. Using accounts stored on this device.")
        #endif
    }

    /// Picks the account system to use. Firebase when it is ready, otherwise
    /// the on-device one, so the app is never left without a way to log in.
    static func makeAuthService() -> AuthService {
        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore)
        if isReady {
            return FirebaseAuthService()
        }
        #endif
        return LocalAuthService()
    }
}



