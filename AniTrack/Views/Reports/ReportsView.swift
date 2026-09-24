//
//  ReportsView.swift
//  AniTrack — SCREEN: reports
//
//  Everything on this screen is calculated by AnalyticsController for whichever
//  period is chosen. Changing the period recalculates every figure and both
//  charts; nothing here is fixed text.
//
//  The charts use Apple's Charts framework rather than the hand-built bars used
//  elsewhere, because a real chart earns its place once there is an axis and a
//  trend to read. The cropping-cycle bar on the field screen stays hand-built,
//  where a chart would be more machinery than the job needs.
//

import SwiftUI
import Charts

struct ReportsView: View {

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var data: FarmDataController

    @State private var period: ReportPeriod = .thisMonth
    @State private var isShowingPrintable: Bool = false

    private var viewer: ViewerContext {
        return ViewerContext(user: auth.currentUser)
    }

    private var analytics: AnalyticsController {
        return AnalyticsController(data: data, viewer: viewer)
    }

    private var fieldTotals: [ParcelYield] {
        return analytics.harvestByField(in: period)
    }

    //  No NavigationStack here on purpose. This screen is both the owner's tab
    //  and a push from the More menu, and wrapping it in its own stack would
    //  nest one stack inside another when pushed. The tab supplies the stack.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                periodPicker
                headlineFigures
                amountByFieldChart
                monthlyTrendChart
                cropBreakdown
                bestAndWorst
                costSummary
                generateButton
            }
            .padding(.horizontal, AppTheme.screenPadding)
            .padding(.bottom, 28)
        }
        .background(AppTheme.canvas)
        .navigationTitle("Reports")
        .toolbar {
            if viewer.permissions.isReadOnly {
                ToolbarItem(placement: .navigationBarTrailing) { ReadOnlyTag() }
            }
        }
        .sheet(isPresented: $isShowingPrintable) {
            PrintableReportView(period: period)
        }
    }

    // MARK: - Period

    private var periodPicker: some View {
        Picker("Period", selection: $period) {
            ForEach(ReportPeriod.allCases) { option in
                Text(option.displayName).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .padding(.top, 4)
    }

    // MARK: - Headline Figures

    private var headlineFigures: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)],
                  spacing: 12) {

            KPICard(value: data.amountLabel(analytics.totalHarvest(in: period)),
                    label: "Harvested",
                    caption: period.displayName.lowercased(),
                    symbolName: "basket.fill",
                    tint: AppTheme.paddy,
                    compactValue: true)

            KPICard(value: "\(analytics.harvestCount(in: period))",
                    label: "Times harvested",
                    caption: "Separate records",
                    symbolName: "list.number",
                    tint: AppTheme.shoot)

            KPICard(value: Formatting.hectares(analytics.hectaresHarvested(in: period)),
                    label: "Land harvested",
                    caption: "Hectares that gave a harvest",
                    symbolName: "square.dashed",
                    tint: AppTheme.husk)

            KPICard(value: Formatting.percent(analytics.jobsDoneRatio(in: period)),
                    label: "Jobs finished",
                    caption: "Of jobs due in this time",
                    symbolName: "checklist",
                    tint: AppTheme.paddy)
        }
    }

    // MARK: - Amount by Field

    @ViewBuilder
    private var amountByFieldChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Amount by field",
                          trailing: "\(fieldTotals.count) fields")

            if fieldTotals.isEmpty {
                emptyNote("No harvest was written down in this time.")
            } else {
                Chart(fieldTotals) { yield in
                    BarMark(
                        x: .value("Amount", yield.kilograms),
                        y: .value("Field", yield.parcelName)
                    )
                    .foregroundStyle(AppTheme.paddy)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine().foregroundStyle(AppTheme.hairline)
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(Formatting.wholeNumber(amount))
                                    .font(.system(size: 10))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(preset: .extended, position: .leading) { _ in
                        AxisValueLabel()
                            .font(.system(size: 10))
                    }
                }
                .frame(height: max(CGFloat(fieldTotals.count) * 38, 120))
            }
        }
        .cardSurface()
    }

    // MARK: - Monthly Trend

    private var monthlyTrendChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Last six months", trailing: "All fields")

            Chart(analytics.lastSixMonths) { point in
                LineMark(
                    x: .value("Month", point.label),
                    y: .value("Amount", point.kilograms)
                )
                .foregroundStyle(AppTheme.paddy)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Month", point.label),
                    y: .value("Amount", point.kilograms)
                )
                .foregroundStyle(AppTheme.paddy)
                .symbolSize(50)

                AreaMark(
                    x: .value("Month", point.label),
                    y: .value("Amount", point.kilograms)
                )
                .foregroundStyle(AppTheme.paddy.opacity(0.10))
                .interpolationMethod(.catmullRom)
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine().foregroundStyle(AppTheme.hairline)
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(Formatting.wholeNumber(amount))
                                .font(.system(size: 10))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel().font(.system(size: 10))
                }
            }
            .frame(height: 170)

            Text("This chart always shows the last six months, whichever period is picked above.")
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.muted)
        }
        .cardSurface()
    }

    // MARK: - By Crop

    @ViewBuilder
    private var cropBreakdown: some View {
        let shares = analytics.cropShares(in: period)

        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "By crop")

            if shares.isEmpty {
                emptyNote("Nothing to break down in this time.")
            } else {
                ForEach(shares) { share in
                    MetricBar(label: share.cropName,
                              valueText: data.amountLabel(share.kilograms),
                              caption: Formatting.percent(share.share) + " of the total",
                              ratio: share.share,
                              tint: AppTheme.shoot)
                }
            }
        }
        .cardSurface()
    }

    // MARK: - Best and Worst

    @ViewBuilder
    private var bestAndWorst: some View {
        let ranked = analytics.bestAndWorstPerHectare(in: period)

        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Best and worst")

            Text("Measured in kilos per hectare, so a bigger field does not look better just for being bigger.")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.muted)
                .fixedSize(horizontal: false, vertical: true)

            if let best = ranked.best {
                rankRow(title: "Best", yield: best, tint: AppTheme.shoot)
            }

            if let worst = ranked.worst {
                Divider().overlay(AppTheme.hairline)
                rankRow(title: "Worst", yield: worst, tint: AppTheme.husk)
            }

            if ranked.best == nil {
                emptyNote("Not enough records in this time to compare fields.")
            }
        }
        .cardSurface()
    }

    private func rankRow(title: String, yield: ParcelYield, tint: Color) -> some View {
        HStack(spacing: 12) {
            StatusChip(text: title, tint: tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(yield.parcelName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.ink)
                Text("\(yield.cropName) · \(Formatting.hectares(yield.hectares)) ha")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.muted)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 2) {
                Text(Formatting.wholeNumber(yield.perHectare))
                    .font(.system(size: 16, weight: .semibold).monospacedDigit())
                    .foregroundStyle(tint)
                Text("kg per ha")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.muted)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Costs

    private var costSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "What supplies cost")

            HStack(alignment: .top, spacing: 20) {
                figure(value: Formatting.money(analytics.supplyCost(in: period)),
                       label: "Supplies used")
                figure(value: Formatting.money(analytics.supplyCostPerHectare(in: period)),
                       label: "Per hectare planted")
            }

            Text("This counts only what the farm spent on seed, fertilizer, fuel and tools. AniTrack does not record sales.")
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cardSurface()
    }

    private var generateButton: some View {
        Button {
            isShowingPrintable = true
        } label: {
            Label("Make report", systemImage: "doc.text")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.buttonRadius, style: .continuous)
                        .fill(AppTheme.paddy)
                )
        }
    }

    // MARK: - Helpers

    private func figure(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func emptyNote(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15))
            .foregroundStyle(AppTheme.muted)
    }
}

#Preview {
    NavigationStack {
        ReportsView()
            .environmentObject(AuthController.previewSignedIn())
            .environmentObject(FarmDataController.preview)
    }
}
