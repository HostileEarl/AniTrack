//
//  FieldDetailView.swift
//  AniTrack — SCREEN 2a (pushed)
//
//  The field passed in is treated as an identifier only. The live copy is read
//  back from the controller each time the body runs, so a change made on the
//  dashboard or by another screen shows here too. Holding the struct that was
//  passed in would leave this screen showing a stale copy, because a struct is
//  copied at the moment it is handed over.
//

import SwiftUI

struct FieldDetailView: View {

    let parcel: Parcel

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var data: FarmDataController
    @EnvironmentObject private var toasts: ToastController

    private var viewer: ViewerContext {
        return ViewerContext(user: auth.currentUser)
    }

    /// Falls back to the copy passed in if the field has been deleted.
    private var current: Parcel {
        return data.parcel(id: parcel.id) ?? parcel
    }

    private var openJobs: [FarmJob] {
        return data.openJobs(forParcel: parcel.id)
    }

    private var recentHarvests: [HarvestRecord] {
        return data.harvests(forParcel: parcel.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                summaryCard
                cropStageCard
                jobsCard
                harvestsCard
                notesCard
            }
            .padding(.horizontal, AppTheme.screenPadding)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(AppTheme.canvas)
        .navigationTitle(current.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewer.permissions.isReadOnly {
                ToolbarItem(placement: .navigationBarTrailing) { ReadOnlyTag() }
            }
        }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                StatusChip(text: current.condition.displayName,
                           tint: current.condition.tint,
                           symbolName: current.condition.symbolName)
                StatusChip(text: current.crop.displayName,
                           tint: AppTheme.paddy,
                           symbolName: current.crop.symbolName)
            }

            Text(current.placeLabel)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppTheme.ink)

            HStack(alignment: .top, spacing: 20) {
                figure(title: "Size", value: current.areaLabel)
                figure(title: "Team leader",
                       value: data.worker(id: current.teamLeaderID)?.shortName ?? "Not assigned")
                figure(title: "Harvest", value: current.harvestCountdown)
            }
        }
        .cardSurface()
    }

    // MARK: - Crop Stage

    private var cropStageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Crop stage")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                StatusChip(text: current.stage.displayName,
                           tint: AppTheme.paddy,
                           symbolName: current.stage.symbolName)
            }

            MetricBar(label: "Progress to harvest",
                      valueText: Formatting.percent(current.stage.progress),
                      caption: "Planted \(current.plantedOn.formatted(.dateTime.day().month(.abbreviated).year()))",
                      ratio: current.stage.progress,
                      tint: AppTheme.shoot)

            if viewer.permissions.canAdvanceStage {
                Button {
                    data.advanceStage(for: current, by: viewer)
                    toasts.show("Moved to \(data.parcel(id: current.id)?.stage.displayName ?? "")")
                } label: {
                    Label("Move to next stage", systemImage: "arrow.forward.circle")
                        .font(.system(size: 15, weight: .medium))
                }
                .buttonStyle(.bordered)
                .tint(AppTheme.paddy)
            }
        }
        .cardSurface()
    }

    // MARK: - Jobs

    private var jobsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Jobs to do",
                          trailing: "\(openJobs.count)",
                          trailingTint: AppTheme.paddy)

            if openJobs.isEmpty {
                Text("Nothing left to do on this field.")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.muted)
            } else {
                ForEach(openJobs) { job in
                    JobRow(job: job,
                           fieldName: current.name,
                           assigneeName: data.assigneeName(for: job),
                           canFinish: viewer.permissions.canFinishJobs,
                           onToggleDone: { data.toggleJobDone(job, by: viewer) })
                }
            }
        }
        .cardSurface()
    }

    // MARK: - Harvests

    private var harvestsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Last harvests",
                          trailing: "\(recentHarvests.count) records")

            if recentHarvests.isEmpty {
                Text("No harvest written down for this field yet.")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.muted)
            } else {
                ForEach(recentHarvests.prefix(4)) { record in
                    HarvestRow(record: record,
                               fieldName: current.name,
                               amountText: data.amountLabel(record.kilograms))
                }
            }
        }
        .cardSurface()
    }

    // MARK: - Notes

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Notes from the field")

            Text(current.notes.isEmpty ? "No notes written down." : current.notes)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.ink.opacity(0.75))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if viewer.permissions.canChangeFieldCondition {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Field condition")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.muted)

                    Picker("Field condition", selection: conditionBinding) {
                        ForEach(FieldCondition.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .cardSurface()
    }

    // MARK: - Helpers

    /// Reads through the controller and writes back through it, so this screen
    /// never keeps its own copy of the field's condition.
    private var conditionBinding: Binding<FieldCondition> {
        return Binding(
            get: { current.condition },
            set: { newValue in
                data.updateCondition(newValue, for: current, by: viewer)
                toasts.show("Field set to \(newValue.displayName)")
            }
        )
    }

    private func figure(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.muted)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        FieldDetailView(parcel: SampleFarmData.parcels[4])
            .environmentObject(AuthController.previewSignedIn())
            .environmentObject(FarmDataController.preview)
            .environmentObject(ToastController())
    }
}
