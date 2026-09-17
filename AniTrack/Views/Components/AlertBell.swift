//
//  AlertBell.swift
//  AniTrack — REUSABLE COMPONENT
//

import SwiftUI

/// The bell in the dashboard's top bar, with a count of unread alerts.
struct AlertBell: View {

    let unreadCount: Int

    var body: some View {
        NavigationLink(value: AppRoute.alerts) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(AppTheme.paddy)
                    .padding(3)

                if unreadCount > 0 {
                    Text("\(min(unreadCount, 9))")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(minWidth: 16, minHeight: 16)
                        .background(Circle().fill(AppTheme.clay))
                        .offset(x: 4, y: -3)
                }
            }
        }
        .accessibilityLabel(unreadCount > 0 ? "Alerts, \(unreadCount) unread" : "Alerts")
    }
}
