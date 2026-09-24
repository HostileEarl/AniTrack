//
//  SettingsView.swift
//  AniTrack — SCREEN: settings
//
//  Everything that changes how the app behaves, in one place.
//

import SwiftUI

struct SettingsView: View {

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var data: FarmDataController
    @EnvironmentObject private var toasts: ToastController

    @State private var isConfirmingSignOut: Bool = false

    private var viewer: ViewerContext {
        return ViewerContext(user: auth.currentUser)
    }

    var body: some View {
        List {
            if let user = auth.currentUser {
                Section("Farm") {
                    LabeledContent("Manager", value: user.fullName)
                    LabeledContent("Farm", value: user.farmName)
                    LabeledContent("Place", value: user.municipality)
                }
            }

            Section {
                Toggle(isOn: Binding(get: { data.showAmountsInSacks },
                                     set: {
                                         data.setShowAmountsInSacks($0)
                                         toasts.show($0 ? "Showing sacks" : "Showing kilos")
                                     })) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Show amounts in sacks")
                        Text("One sack is 50 kg")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.muted)
                    }
                }
                .tint(AppTheme.paddy)

                LabeledContent("Language", value: "English")
            } header: {
                Text("How things are shown")
            }

            Section("Saving") {
                NavigationLink(value: AppRoute.backup) {
                    Label("Saving and backup", systemImage: "externaldrive")
                }
                NavigationLink(value: AppRoute.activity) {
                    Label("Recent activity", systemImage: "clock.arrow.circlepath")
                }
                LabeledContent("Accounts kept", value: auth.providerName)
            }

            Section("Your account") {
                NavigationLink(value: AppRoute.profile) {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                NavigationLink(value: AppRoute.changePassword) {
                    Label("Change password", systemImage: "lock.rotation")
                }
            }

            // Only shown when accounts are kept on the phone, because there are
            // no stored passwords to switch between once Firebase is running.
            if !auth.demoCredentials.isEmpty {
                Section {
                    ForEach(auth.demoCredentials, id: \.email) { account in
                        Button {
                            Task {
                                await auth.useDemoAccount(email: account.email)
                                toasts.show("Now logged in as \(account.role.displayName)")
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(account.role.displayName)
                                        .foregroundStyle(AppTheme.ink)
                                    Text(account.email)
                                        .font(.system(size: 12))
                                        .foregroundStyle(AppTheme.muted)
                                }
                                Spacer()
                                if auth.currentUser?.email == account.email {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(AppTheme.paddy)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Change test role")
                } footer: {
                    Text("For showing the app only. This lets you switch roles without typing a password.")
                }
            }

            Section {
                Button("Log out", role: .destructive) {
                    isConfirmingSignOut = true
                }
            } footer: {
                Text("AniTrack — farm operations companion")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
            }
        }
        .farmBackground()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Log out of AniTrack?",
                            isPresented: $isConfirmingSignOut,
                            titleVisibility: .visible) {
            Button("Log out", role: .destructive) {
                Task { await auth.signOut() }
            }
            Button("Stay logged in", role: .cancel) { }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthController.previewSignedIn())
            .environmentObject(FarmDataController.preview)
            .environmentObject(ToastController())
    }
}
