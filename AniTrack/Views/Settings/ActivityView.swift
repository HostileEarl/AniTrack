//
//  ActivityView.swift
//  AniTrack — SCREEN: recent activity
//
//  Every change made anywhere in the app writes a line here, because all writes
//  go through one method on the data controller. That is what makes this trail
//  complete rather than a best effort.
//

import SwiftUI

struct ActivityView: View {

    @EnvironmentObject private var data: FarmDataController

    @State private var filter: ActivityCategory?

    private var groups: [ActivityDayGroup] {
        return AnalyticsController.groupByDay(data.activity(in: filter))
    }

    var body: some View {
        VStack(spacing: 0) {
            filterRow

            if groups.isEmpty {
                EmptyStateView(symbolName: "clock.arrow.circlepath",
                               title: "Nothing here yet",
                               message: "Every change you make in the app will be listed here.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.canvas)
            } else {
                List {
                    ForEach(groups) { group in
                        Section {
                            ForEach(group.entries) { entry in
                                row(for: entry)
                            }
                        } header: {
                            Text(group.title)
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
        .background(AppTheme.canvas)
        .navigationTitle("Recent activity")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Filter

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "All", category: nil)
                ForEach(ActivityCategory.allCases) { category in
                    chip(title: category.displayName, category: category)
                }
            }
            .padding(.horizontal, AppTheme.screenPadding)
            .padding(.vertical, 10)
        }
        .background(AppTheme.canvas)
    }

    private func chip(title: String, category: ActivityCategory?) -> some View {
        let isSelected = filter == category
        return Button {
            filter = category
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? .white : AppTheme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(isSelected ? AppTheme.paddy : AppTheme.surface)
                )
                .overlay(
                    Capsule().strokeBorder(isSelected ? Color.clear : AppTheme.hairline, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Row

    private func row(for entry: ActivityEntry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: entry.category.symbolName)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.paddy)
                .frame(width: 24)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text("\(entry.actorName) \(entry.summary.prefix(1).lowercased())\(entry.summary.dropFirst())")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(Formatting.relativeTime(from: entry.happenedOn))
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.muted)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ActivityView()
            .environmentObject(FarmDataController.preview)
    }
}
