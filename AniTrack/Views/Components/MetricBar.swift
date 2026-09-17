//
//  MetricBar.swift
//  AniTrack — REUSABLE COMPONENT
//

import SwiftUI

/// A horizontal comparison bar. The caller passes a ratio that is already
/// worked out, so this view never does arithmetic on model data.
struct MetricBar: View {

    let label: String
    let valueText: String
    let caption: String
    /// From 0 to 1, against the largest value in the set.
    let ratio: Double
    var tint: Color = AppTheme.paddy

    private var clamped: Double {
        return min(max(ratio, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(valueText)
                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                    .foregroundStyle(AppTheme.ink)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppTheme.ink.opacity(0.07))
                    Capsule()
                        .fill(tint)
                        .frame(width: max(proxy.size.width * clamped, 4))
                }
            }
            .frame(height: 8)

            Text(caption)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.muted)
        }
    }
}
