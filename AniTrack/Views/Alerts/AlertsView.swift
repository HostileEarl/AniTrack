//
//  AlertsView.swift
//  AniTrack — SCREEN: alerts (pushed from the bell)
//
//  Alerts are raised by the controller when something crosses a line: an urgent
//  field note, a supply dropping below its warning level. Nothing here creates
//  an alert, so the list can never disagree with the data that caused it.
//

import SwiftUI

struct AlertsView: View {

    @EnvironmentObject private var data: FarmDataController
    @EnvironmentObject private var toasts: ToastController

    private var alerts: [FarmAlert] {
        return data.sortedAlerts
    }

    var body: some View {
        Group {
            if alerts.isEmpty {
                EmptyStateView(symbolName: "bell.slash",
                               title: "No alerts",
                               message: "You will be told here when a field needs looking at or supplies run low.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.canvas)
            } else {
                List {
                    ForEach(alerts) { alert in
                        row(for: alert)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    data.dismissAlert(alert)
                                } label: {
                                    Label("Remove", systemImage: "xmark")
                                }
                            }
                    }
                }
                .listStyle(.insetGrouped)
                .farmBackground()
            }
        }
        .navigationTitle("Alerts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if data.unreadAlertCount > 0 {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Mark all as read") {
                        data.markAllAlertsRead()
                        toasts.show("All alerts marked as read")
                    }
                    .font(.system(size: 14))
                }
            }
        }
    }

    // MARK: - Row

    private func row(for alert: FarmAlert) -> some View {
        Button {
            data.markAlertRead(alert)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(alert.isRead ? Color.clear : AppTheme.paddy)
                    .frame(width: 7, height: 7)
                    .padding(.top, 6)

                Image(systemName: alert.kind.symbolName)
                    .font(.system(size: 16))
                    .foregroundStyle(alert.kind.tint)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.kind.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(alert.kind.tint)
                    Text(alert.message)
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(Formatting.relativeTime(from: alert.raisedOn))
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.muted)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(alert.isRead ? 0.65 : 1)
    }
}

#Preview {
    NavigationStack {
        AlertsView()
            .environmentObject(FarmDataController.preview)
            .environmentObject(ToastController())
    }
}
