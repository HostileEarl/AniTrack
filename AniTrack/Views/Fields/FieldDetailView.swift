//
//  FieldDetailView.swift
//  AniTrack — SCREEN 2a (pushed)
//
//  This screen takes an id, not an object, and looks the field up each time the
//  body runs. That started as a fix for value semantics — a struct handed to a
//  screen is a copy, so edits made elsewhere never appeared here. Since the move
//  to SwiftData the models are classes, but taking an id is still the right
//  choice: a screen that outlives a deleted record shows "not found" instead of
//  holding a dangling object.
//

import SwiftUI

struct FieldDetailView: View {

    let parcelID: String

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var data: FarmDataController
    @EnvironmentObject private var toasts: ToastController

    private var viewer: ViewerContext {
        return ViewerContext(user: auth.currentUser)
    }

    private var current: Parcel? {
        return data.parcel(id: parcelID)
    }

    private var openJobs: [FarmJob] {
        return data.openJobs(forParcel: parcelID)
    }

    private var recentHarvests: [HarvestRecord] {
        return data.harvests(forParcel: parcelID)
    }

    var body: some View {
        Group {
            if current == nil {
                EmptyStateView(symbolName: "questionmark.folder",
                               title: "This field is gone",
                               message: "It was removed while you were looking at it.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.canvas)
            } else {
                content
            }
        }
        .navigationTitle(current?.name ?? "Field")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewer.permissions.isReadOnly {
                ToolbarItem(placement: .navigationBarTrailing) { ReadOnlyTag() }
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                if let field = current {
                    summaryCard(field)
                    cropStageCard(field)
                    jobsCard(field)
                    harvestsCard(field)
                    notesCard(field)
                }
            }
            .padding(.horizontal, AppTheme.screenPadding)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(AppTheme.canvas)
    }

    // MARK: - Summary

    private func summaryCard(_ field: Parcel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                StatusChip(text: field.condition.displayName,
                           tint: field.condition.tint,
                           symbolName: field.condition.symbolName)
                StatusChip(text: field.crop.displayName,
                           tint: AppTheme.paddy,
                           symbolName: field.crop.symbolName)
            }

            Text(field.placeLabel)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppTheme.ink)

            HStack(alignment: .top, spacing: 20) {
                figure(title: "Size", value: field.areaLabel)
                figure(title: "Team leader",
                       value: data.worker(id: field.teamLeaderID)?.shortName ?? "Not assigned")
                figure(title: "Harvest", value: field.harvestCountdown)
            }
        }
        .cardSurface()
    }

    // MARK: - Crop Stage

    private func cropStageCard(_ field: Parcel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Crop stage")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                StatusChip(text: field.stage.displayName,
                           tint: AppTheme.paddy,
                           symbolName: field.stage.symbolName)
            }

            MetricBar(label: "Progress to harvest",
                      valueText: Formatting.percent(field.stage.progress),
                      caption: "Planted \(field.plantedOn.formatted(.dateTime.day().month(.abbreviated).year()))",
                      ratio: field.stage.progress,
                      tint: AppTheme.shoot)

            if viewer.permissions.canAdvanceStage {
                Button {
                    data.advanceStage(for: field, by: viewer)
                    toasts.show("Moved to \(field.stage.displayName)")
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

    private func jobsCard(_ field: Parcel) -> some View {
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
                           fieldName: field.name,
                           assigneeName: data.assigneeName(for: job),
                           canFinish: viewer.permissions.canFinishJobs,
                           onToggleDone: { data.toggleJobDone(job, by: viewer) })
                }
            }
        }
        .cardSurface()
    }

    // MARK: - Harvests

    private func harvestsCard(_ field: Parcel) -> some View {
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
                               fieldName: field.name,
                               amountText: data.amountLabel(record.kilograms))
                }
            }
        }
        .cardSurface()
    }

    // MARK: - Notes

    private func notesCard(_ field: Parcel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Notes from the field")

            Text(field.notes.isEmpty ? "No notes written down." : field.notes)
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
            get: { current?.condition ?? .good },
            set: { newValue in
                guard let field = current else { return }
                data.updateCondition(newValue, for: field, by: viewer)
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
        FieldDetailView(parcelID: "p5")
            .environmentObject(AuthController.previewSignedIn())
            .environmentObject(FarmDataController.preview)
            .environmentObject(ToastController())
    }
}
