//
//  StatusChip.swift
//  AniTrack — REUSABLE COMPONENT
//

import SwiftUI

/// A small tinted label for a condition, stage, quality or due date.
struct StatusChip: View {

    let text: String
    let tint: Color
    var symbolName: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let symbolName = symbolName {
                Image(systemName: symbolName)
                    .font(.system(size: 9, weight: .bold))
            }
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.chipRadius, style: .continuous)
                .fill(tint.opacity(0.13))
        )
    }
}
