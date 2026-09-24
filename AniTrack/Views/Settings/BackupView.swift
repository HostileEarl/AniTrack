//
//  BackupView.swift
//  AniTrack — SCREEN: saving and backup
//
//  Shows the saving system rather than hiding it. A farm manager working out of
//  signal needs to know whether the job she just finished is safe, and a screen
//  that says nothing is a screen she cannot trust.
//

import SwiftUI

struct BackupView: View {

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var data: FarmDataController
    @EnvironmentObject private var toasts: ToastController

    @State private var isConfirmingReset: Bool = false

    private var viewer: ViewerContext {
        return ViewerContext(user: auth.currentUser)
    }

    private var waiting: Int {
        return data.pendingChanges.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                statusCard
                if waiting > 0 { waitingList }
                offlineCard
                storedCard
                if viewer.permissions.isManager { resetCard }
            }
            .padding(.horizontal, AppTheme.screenPadding)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(AppTheme.canvas)
        .navigationTitle("Saving and backup")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Start over with sample data?",
                            isPresented: $isConfirmingReset,
                            titleVisibility: .visible) {
            Button("Start over", role: .destructive) {
                data.resetToSampleData()
                toasts.show("Everything is back to the sample data")
            }
            Button("Keep my data", role: .cancel) { }
        } message: {
            Text("Every field, job and harvest you added will be removed. This cannot be undone.")
        }
    }

    // MARK: - Status

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: waiting > 0 ? "clock.fill" : "checkmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(waiting > 0 ? AppTheme.husk : AppTheme.shoot)

                VStack(alignment: .leading, spacing: 3) {
                    Text(waiting > 0 ? "\(waiting) changes waiting" : "Everything is saved")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text("Last backed up \(Formatting.relativeTime(from: data.lastBackedUpAt))")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.muted)
                }

                Spacer(minLength: 0)
            }

            Button {
                Task {
                    await data.backUpNow()
                    toasts.show("Everything is backed up")
                }
            } label: {
                LoadingLabel(title: "Back up now",
                             loadingTitle: "Backing up…",
                             isLoading: data.isBackingUp)
            }
            .buttonStyle(PrimaryButtonStyle(isEnabled: !data.isBackingUp))
            .disabled(data.isBackingUp)
        }
        .cardSurface()
    }

    // MARK: - Waiting List

    private var waitingList: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Waiting to be backed up", trailing: "\(waiting)")

            ForEach(data.pendingChanges) { change in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "arrow.up.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.husk)
                        .padding(.top, 1)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(change.summary)
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(Formatting.relativeTime(from: change.madeOn))
                            .font(.system(size: 11))
                            .foregroundStyle(AppTheme.muted)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.vertical, 3)
            }
        }
        .cardSurface()
    }

    // MARK: - Offline

    private var offlineCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: Binding(get: { data.isOffline },
                                 set: { data.setOffline($0) })) {
                Text("No internet mode")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.ink)
            }
            .tint(AppTheme.paddy)

            Text("Turn this on to keep working with no signal. Your changes are held here and saved once you connect again.")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cardSurface()
    }

    // MARK: - What Is Stored

    private var storedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "What is saved on this phone")

            countRow("Fields", data.parcels.count)
            countRow("Jobs", data.jobs.count)
            countRow("Harvest records", data.harvests.count)
            countRow("Field notes", data.fieldNotes.count)
            countRow("Supplies", data.supplies.count)
            countRow("Supply movements", data.stockMovements.count)

            Divider().overlay(AppTheme.hairline)

            HStack {
                Text("Space used")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                Text(data.storageSizeLabel())
                    .font(.system(size: 14, weight: .semibold).monospacedDigit())
                    .foregroundStyle(AppTheme.paddy)
            }

            NavigationLink(value: AppRoute.activity) {
                HStack {
                    Label("Recent activity", systemImage: "clock.arrow.circlepath")
                        .font(.system(size: 15, weight: .medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.muted)
                }
                .padding(.top, 4)
            }
        }
        .cardSurface()
    }

    private func countRow(_ label: String, _ count: Int) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.muted)
            Spacer()
            Text("\(count)")
                .font(.system(size: 14, weight: .medium).monospacedDigit())
                .foregroundStyle(AppTheme.ink)
        }
    }

    // MARK: - Reset

    private var resetCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Start over")

            Text("Puts every field, job and harvest back to the sample data the app came with.")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.muted)
                .fixedSize(horizontal: false, vertical: true)

            Button(role: .destructive) {
                isConfirmingReset = true
            } label: {
                Label("Start over with sample data", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 15, weight: .medium))
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.clay)
        }
        .cardSurface()
    }
}

#Preview {
    NavigationStack {
        BackupView()
            .environmentObject(AuthController.previewSignedIn())
            .environmentObject(FarmDataController.preview)
            .environmentObject(ToastController())
    }
}
