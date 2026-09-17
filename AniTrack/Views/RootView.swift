//
//  RootView.swift
//  AniTrack — VIEW LAYER
//
//  Decides whether to show the sign-in flow or the app. Nothing behind the sign
//  in is built until there is a signed-in user, so no screen has to guard
//  against a missing account.
//

import SwiftUI

struct RootView: View {

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var data: FarmDataController
    @EnvironmentObject private var toasts: ToastController

    var body: some View {
        ZStack {
            if auth.currentUser == nil {
                AuthFlowView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }

            ToastOverlay(toasts: toasts)
        }
        .animation(.easeInOut(duration: 0.3), value: auth.currentUser?.id)
        .task {
            await auth.restoreSession()
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AuthController.previewSignedOut)
        .environmentObject(FarmDataController.preview)
        .environmentObject(ToastController())
}
