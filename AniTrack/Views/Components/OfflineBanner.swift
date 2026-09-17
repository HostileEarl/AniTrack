//
//  OfflineBanner.swift
//  AniTrack — REUSABLE COMPONENT
//

import SwiftUI

/// The thin gold strip shown on every screen while offline mode is on.
struct OfflineBanner: View {

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 11, weight: .semibold))
            Text("No internet — your changes will be saved when you connect again")
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(AppTheme.husk)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(AppTheme.husk.opacity(0.13))
    }
}

/// The small tag shown in the navigation bar for the owner account.
struct ReadOnlyTag: View {

    var body: some View {
        Text("Look only")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(AppTheme.muted)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.chipRadius, style: .continuous)
                    .fill(AppTheme.ink.opacity(0.07))
            )
    }
}

/// The role badge shown next to a user's name.
struct RoleTag: View {

    let role: AccountRole

    var body: some View {
        Text(role.displayName)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(role.tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.chipRadius, style: .continuous)
                    .fill(role.tint.opacity(0.13))
            )
    }
}
