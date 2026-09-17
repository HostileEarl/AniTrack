//
//  MainTabView.swift
//  AniTrack — VIEW LAYER
//
//  The signed-in shell. Each tab owns its own NavigationStack so push history
//  is kept per tab, which is what iOS users expect when moving back and forth.
//
//  The owner gets a different set of tabs. Jobs and Harvest exist to record
//  work, and an owner records nothing, so those tabs are replaced rather than
//  shown with everything inside them switched off.
//

import SwiftUI

struct MainTabView: View {

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var data: FarmDataController

    private var viewer: ViewerContext {
        return ViewerContext(user: auth.currentUser)
    }

    var body: some View {
        VStack(spacing: 0) {
            if data.isOffline {
                OfflineBanner()
            }

            TabView {
                DashboardView()
                    .tabItem { Label("Dashboard", systemImage: "chart.bar.doc.horizontal") }

                FieldsView()
                    .tabItem { Label("Fields", systemImage: "map") }

                if viewer.permissions.isOwner {
                    ComingSoonView(title: "Reports",
                                   symbolName: "doc.text",
                                   stage: "Final")
                        .tabItem { Label("Reports", systemImage: "doc.text") }
                } else {
                    JobsView()
                        .tabItem { Label("Jobs", systemImage: "checklist") }

                    HarvestLogView()
                        .tabItem { Label("Harvest", systemImage: "basket") }
                }

                MoreTabView()
                    .tabItem { Label("More", systemImage: "ellipsis.circle") }
            }
            .tint(AppTheme.paddy)
        }
    }
}

// MARK: - Placeholder for Later Stages

/// Marks a screen that is designed and prototyped but not yet built, so the
/// gap is visible rather than hidden behind a dead tab.
struct ComingSoonView: View {

    let title: String
    let symbolName: String
    let stage: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: symbolName)
                    .font(.system(size: 38, weight: .light))
                    .foregroundStyle(AppTheme.shoot)
                Text("\(title) arrives in \(stage)")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Text("This screen is designed in the prototype and is next to be built.")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.canvas)
            .navigationTitle(title)
        }
    }
}

// MARK: - More Tab

/// The menu that holds everything outside the four main tabs. Rows for screens
/// that are not built yet say so rather than doing nothing when tapped.
struct MoreTabView: View {

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var data: FarmDataController

    @State private var isConfirmingSignOut: Bool = false

    private var viewer: ViewerContext {
        return ViewerContext(user: auth.currentUser)
    }

    var body: some View {
        NavigationStack {
            List {
                if let user = auth.currentUser {
                    Section {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(AppTheme.paddy)
                                .frame(width: 52, height: 52)
                                .overlay(
                                    Text(user.initials)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(.white)
                                )
                            VStack(alignment: .leading, spacing: 5) {
                                Text(user.fullName)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(AppTheme.ink)
                                RoleTag(role: user.role)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }

                Section("Work") {
                    NavigationLink(value: AppRoute.alerts) {
                        menuRow(symbol: "bell",
                                title: "Alerts",
                                subtitle: data.unreadAlertCount > 0
                                    ? "\(data.unreadAlertCount) unread"
                                    : "Nothing new")
                    }
                    comingSoonRow(symbol: "doc.text.magnifyingglass",
                                  title: "Field notes",
                                  subtitle: unresolvedNotesSubtitle,
                                  stage: "Final")
                    if viewer.permissions.canSeeSupplies {
                        comingSoonRow(symbol: "shippingbox",
                                      title: "Supplies",
                                      subtitle: suppliesSubtitle,
                                      stage: "Final")
                    }
                    comingSoonRow(symbol: "person.2",
                                  title: "Team",
                                  subtitle: "\(data.workers.count) people",
                                  stage: "Final")
                    comingSoonRow(symbol: "map",
                                  title: "Map",
                                  subtitle: "Where every field sits",
                                  stage: "Final")
                }

                Section("Records") {
                    comingSoonRow(symbol: "chart.bar.doc.horizontal",
                                  title: "Reports",
                                  subtitle: "Totals by month, crop and field",
                                  stage: "Final")
                    comingSoonRow(symbol: "cloud.sun",
                                  title: "Weather",
                                  subtitle: "What is coming this week",
                                  stage: "Final")
                }

                Section("Saving and backup") {
                    Toggle("No internet mode", isOn: Binding(
                        get: { data.isOffline },
                        set: { data.setOffline($0) }
                    ))
                    LabeledContent("Changes waiting", value: "\(data.pendingChanges.count)")
                    LabeledContent("Records saved", value: "\(data.storedRecordCount)")
                    LabeledContent("Storage used", value: data.storageSizeLabel())
                    LabeledContent("Accounts kept", value: auth.providerName)

                    Toggle("Show amounts in sacks", isOn: Binding(
                        get: { data.showAmountsInSacks },
                        set: { data.setShowAmountsInSacks($0) }
                    ))
                }

                Section {
                    Button("Log out", role: .destructive) {
                        isConfirmingSignOut = true
                    }
                }
            }
            .farmBackground()
            .navigationTitle("More")
            .navigationDestination(for: AppRoute.self) { route in
                RouteDestination(route: route)
            }
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

    // MARK: - Live Subtitles

    private var unresolvedNotesSubtitle: String {
        let open = data.visibleFieldNotes(for: viewer).filter { !$0.isResolved }.count
        return open > 0 ? "\(open) still to deal with" : "Nothing waiting"
    }

    private var suppliesSubtitle: String {
        let low = data.runningLowItems.count
        return low > 0 ? "\(low) running low" : "Everything in stock"
    }

    // MARK: - Rows

    private func menuRow(symbol: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.paddy)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.ink)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.muted)
            }
        }
        .padding(.vertical, 3)
    }

    private func comingSoonRow(symbol: String, title: String, subtitle: String, stage: String) -> some View {
        HStack {
            menuRow(symbol: symbol, title: title, subtitle: subtitle)
            Spacer()
            Text(stage)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.muted)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(AppTheme.ink.opacity(0.06))
                )
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthController.previewSignedIn())
        .environmentObject(FarmDataController.preview)
        .environmentObject(ToastController())
}
