//
//  HarvestLogView.swift
//  AniTrack — SCREEN 4
//
//  Month grouping and every total are worked out by AnalyticsController. This
//  screen only lays the results out.
//

import SwiftUI

struct HarvestLogView: View {

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var data: FarmDataController

    @State private var isRecording: Bool = false

    private var viewer: ViewerContext {
        return ViewerContext(user: auth.currentUser)
    }

    private var analytics: AnalyticsController {
        return AnalyticsController(data: data, viewer: viewer)
    }

    private var groups: [HarvestMonthGroup] {
        return analytics.harvestsByMonth
    }

    var body: some View {
        NavigationStack {
            Group {
                if groups.isEmpty {
                    EmptyStateView(symbolName: "basket",
                                   title: "No harvests written down",
                                   message: "Use the plus button to write down the first harvest.")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppTheme.canvas)
                } else {
                    List {
                        Section {
                            summaryCard
                                .listRowInsets(EdgeInsets(top: 8,
                                                          leading: AppTheme.screenPadding,
                                                          bottom: 8,
                                                          trailing: AppTheme.screenPadding))
                                .listRowBackground(Color.clear)
                        }

                        ForEach(groups) { group in
                            Section {
                                ForEach(group.records) { record in
                                    HarvestRow(record: record,
                                               fieldName: data.parcelName(for: record.parcelID),
                                               amountText: data.amountLabel(record.kilograms))
                                }
                            } header: {
                                HStack {
                                    Text(group.title)
                                    Spacer()
                                    Text(data.amountLabel(group.totalKilograms))
                                }
                                .font(.system(size: 12))
                                .textCase(nil)
                                .foregroundStyle(AppTheme.muted)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .farmBackground()
                }
            }
            .navigationTitle("Harvest")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if viewer.permissions.isReadOnly {
                        ReadOnlyTag()
                    }
                    if viewer.permissions.canRecordHarvest {
                        Button {
                            isRecording = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Write down a harvest")
                    }
                }
            }
            .sheet(isPresented: $isRecording) {
                RecordHarvestSheet()
            }
        }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Total so far")

            HStack(alignment: .top, spacing: 20) {
                figure(value: data.amountLabel(analytics.totalHarvest),
                       label: "Total amount")
                figure(value: data.amountLabel(analytics.harvestThisMonth),
                       label: "This month")
            }

            Divider().overlay(AppTheme.hairline)

            VStack(alignment: .leading, spacing: 3) {
                Text("Best field")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.muted)
                Text(analytics.bestFieldName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.paddy)
            }
        }
        .cardSurface()
    }

    private func figure(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    HarvestLogView()
        .environmentObject(AuthController.previewSignedIn())
        .environmentObject(FarmDataController.preview)
        .environmentObject(ToastController())
}
