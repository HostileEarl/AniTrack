//
//  DashboardView.swift
//  AniTrack — SCREEN 1
//
//  Every figure here comes from AnalyticsController, which is built from what
//  this viewer is allowed to see. A team leader's numbers therefore describe
//  their own fields, not the whole farm, without this screen knowing anything
//  about roles beyond the title.
//

import SwiftUI

struct DashboardView: View {

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var data: FarmDataController

    private var viewer: ViewerContext {
        return ViewerContext(user: auth.currentUser)
    }

    private var analytics: AnalyticsController {
        return AnalyticsController(data: data, viewer: viewer)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                    greeting
                    kpiGrid
                    harvestByField
                    fieldsToWatch
                    dueToday
                }
                .padding(.horizontal, AppTheme.screenPadding)
                .padding(.bottom, 28)
            }
            .background(AppTheme.canvas)
            .navigationTitle(viewer.permissions.homeTitle)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if viewer.permissions.isReadOnly {
                        ReadOnlyTag()
                    }
                    AlertBell(unreadCount: data.unreadAlertCount)
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                RouteDestination(route: route)
            }
        }
    }

    // MARK: - Greeting

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Kumusta, \(auth.currentUser?.firstName ?? "there")")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
            Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.muted)
        }
        .padding(.top, 2)
    }

    // MARK: - Headline Figures

    private var kpiGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)],
                  spacing: 12) {

            KPICard(value: "\(analytics.plantedFieldCount)",
                    label: "Fields planted",
                    caption: "\(analytics.totalFieldCount) total",
                    symbolName: "map.fill",
                    tint: AppTheme.paddy)

            KPICard(value: analytics.hectaresPlantedLabel,
                    label: "Land planted",
                    caption: "Resting land not counted",
                    symbolName: "square.dashed",
                    tint: AppTheme.shoot)

            KPICard(value: "\(analytics.jobsDueTodayCount)",
                    label: "Due today",
                    caption: analytics.lateJobCount > 0
                        ? "\(analytics.lateJobCount) late"
                        : "Nothing late",
                    symbolName: "checklist",
                    tint: analytics.lateJobCount > 0 ? AppTheme.clay : AppTheme.paddy)

            KPICard(value: data.amountLabel(analytics.harvestThisMonth),
                    label: "This month",
                    caption: "Best: \(analytics.bestFieldName)",
                    symbolName: "basket.fill",
                    tint: AppTheme.husk,
                    compactValue: true)
        }
    }

    // MARK: - Harvest by Field

    @ViewBuilder
    private var harvestByField: some View {
        if !analytics.harvestByField.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Harvest by field", trailing: "All records")

                ForEach(analytics.harvestByField.prefix(4)) { yield in
                    MetricBar(label: yield.parcelName,
                              valueText: data.amountLabel(yield.kilograms),
                              caption: yield.cropName,
                              ratio: analytics.barRatio(for: yield.kilograms),
                              tint: AppTheme.paddy)
                }
            }
            .cardSurface()
        }
    }

    // MARK: - Fields to Watch

    private var fieldsToWatch: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Fields to watch",
                          trailing: analytics.fieldsNeedingAttention.isEmpty
                              ? nil
                              : "\(analytics.fieldsNeedingAttention.count)",
                          trailingTint: AppTheme.clay)

            if analytics.fieldsNeedingAttention.isEmpty {
                Text("Every field is in good condition.")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.muted)
            } else {
                ForEach(analytics.fieldsNeedingAttention) { parcel in
                    NavigationLink(value: AppRoute.field(parcel.id)) {
                        ParcelRow(parcel: parcel)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cardSurface()
    }

    // MARK: - Due Today

    private var dueToday: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Due today",
                          trailing: "\(analytics.jobsDonePercentLabel) done overall")

            if analytics.jobsDueToday.isEmpty {
                Text("No jobs due today.")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.muted)
            } else {
                ForEach(analytics.jobsDueToday) { job in
                    JobRow(job: job,
                           fieldName: data.parcelName(for: job.parcelID),
                           assigneeName: data.assigneeName(for: job),
                           canFinish: viewer.permissions.canFinishJobs,
                           onToggleDone: { data.toggleJobDone(job, by: viewer) })
                }
            }
        }
        .cardSurface()
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthController.previewSignedIn())
        .environmentObject(FarmDataController.preview)
}
