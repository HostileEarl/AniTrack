//
//  EmptyStateView.swift
//  AniTrack — REUSABLE COMPONENT
//

import SwiftUI

/// Shown when a list has nothing in it. The message always says what to do
/// next, rather than only reporting that there is nothing there.
struct EmptyStateView: View {

    let symbolName: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbolName)
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(AppTheme.shoot)
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .padding(.horizontal, 28)
    }
}
