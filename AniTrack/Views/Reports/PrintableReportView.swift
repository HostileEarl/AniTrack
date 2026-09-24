//
//  PrintableReportView.swift
//  AniTrack — SCREEN: printable report (popup)
//
//  The same figures as the Reports screen, laid out like a sheet of paper so a
//  manager can hand something to an owner or a cooperative office.
//
//  Sharing uses ShareLink with plain text rather than a rendered PDF. Making a
//  real PDF is a page-layout job, and a half-working export would be worse than
//  an honest one: the text that gets shared is complete and readable.
//

import SwiftUI

struct PrintableReportView: View {

    let period: ReportPeriod

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var data: FarmDataController
    @EnvironmentObject private var toasts: ToastController
    @Environment(\.dismiss) private var dismiss

    private var viewer: ViewerContext {
        return ViewerContext(user: auth.currentUser)
    }

    private var analytics: AnalyticsController {
        return AnalyticsController(data: data, viewer: viewer)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    letterhead
                    Divider().overlay(AppTheme.paddy.opacity(0.3)).padding(.vertical, 18)
                    figuresBlock
                    Divider().overlay(AppTheme.hairline).padding(.vertical, 18)
                    fieldTable
                    Divider().overlay(AppTheme.hairline).padding(.vertical, 18)
                    cropTable
                    footer
                }
                .padding(26)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.08), radius: 10, y: 3)
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
            }
            .background(AppTheme.canvas)
            .navigationTitle("Printable report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: reportText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share this report")
                }
            }
        }
    }

    // MARK: - Sections

    private var letterhead: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(auth.currentUser?.farmName ?? "Reyes Family Farm")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppTheme.paddy)

            Text(auth.currentUser?.municipality ?? "Cabanatuan, Nueva Ecija")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.muted)

            Text("Farm report — \(period.displayName.lowercased())")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
                .padding(.top, 10)

            Text("Prepared by \(auth.currentUser?.fullName ?? "Farm Manager") on \(Date().formatted(.dateTime.day().month(.wide).year()))")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.muted)
        }
    }

    private var figuresBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            heading("Summary")

            line("Amount harvested", data.amountLabel(analytics.totalHarvest(in: period)))
            line("Times harvested", "\(analytics.harvestCount(in: period))")
            line("Land harvested", "\(Formatting.hectares(analytics.hectaresHarvested(in: period))) ha")
            line("Land planted", "\(analytics.hectaresPlantedLabel) ha")
            line("Jobs finished", Formatting.percent(analytics.jobsDoneRatio(in: period)))
            line("Supplies used", Formatting.money(analytics.supplyCost(in: period)))
        }
    }

    @ViewBuilder
    private var fieldTable: some View {
        let totals = analytics.harvestByField(in: period)

        VStack(alignment: .leading, spacing: 10) {
            heading("By field")

            if totals.isEmpty {
                Text("No harvest was written down in this time.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.muted)
            } else {
                ForEach(totals) { yield in
                    line(yield.parcelName, data.amountLabel(yield.kilograms))
                }
            }
        }
    }

    @ViewBuilder
    private var cropTable: some View {
        let shares = analytics.cropShares(in: period)

        VStack(alignment: .leading, spacing: 10) {
            heading("By crop")

            if shares.isEmpty {
                Text("Nothing to break down in this time.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.muted)
            } else {
                ForEach(shares) { share in
                    line(share.cropName,
                         "\(data.amountLabel(share.kilograms))  (\(Formatting.percent(share.share)))")
                }
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 3) {
            Divider().overlay(AppTheme.hairline).padding(.vertical, 18)
            Text("Made with AniTrack")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.paddy)
            Text("This report covers farm work and harvest amounts only. It records no sales.")
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.muted)
        }
    }

    // MARK: - Pieces

    private func heading(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(AppTheme.paddy)
    }

    private func line(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.ink)
            Spacer(minLength: 10)
            Text(value)
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                .foregroundStyle(AppTheme.ink)
        }
    }

    // MARK: - Share Text

    /// A plain-text version of the same report, for sharing.
    private var reportText: String {
        var lines: [String] = []
        lines.append(auth.currentUser?.farmName ?? "Reyes Family Farm")
        lines.append("Farm report — \(period.displayName.lowercased())")
        lines.append("Prepared by \(auth.currentUser?.fullName ?? "Farm Manager") on \(Date().formatted(.dateTime.day().month(.wide).year()))")
        lines.append("")
        lines.append("SUMMARY")
        lines.append("Amount harvested: \(data.amountLabel(analytics.totalHarvest(in: period)))")
        lines.append("Times harvested: \(analytics.harvestCount(in: period))")
        lines.append("Land harvested: \(Formatting.hectares(analytics.hectaresHarvested(in: period))) ha")
        lines.append("Jobs finished: \(Formatting.percent(analytics.jobsDoneRatio(in: period)))")
        lines.append("Supplies used: \(Formatting.money(analytics.supplyCost(in: period)))")
        lines.append("")
        lines.append("BY FIELD")
        for yield in analytics.harvestByField(in: period) {
            lines.append("\(yield.parcelName): \(data.amountLabel(yield.kilograms))")
        }
        lines.append("")
        lines.append("Made with AniTrack. This report records no sales.")
        return lines.joined(separator: "\n")
    }
}

#Preview {
    PrintableReportView(period: .thisYear)
        .environmentObject(AuthController.previewSignedIn())
        .environmentObject(FarmDataController.preview)
        .environmentObject(ToastController())
}
