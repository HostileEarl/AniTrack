//
//  KPICard.swift
//  AniTrack — REUSABLE COMPONENT
//

import SwiftUI

/// One headline figure on the dashboard.
struct KPICard: View {

    let value: String
    let label: String
    let caption: String
    let symbolName: String
    var tint: Color = AppTheme.paddy
    /// Long amounts such as "15,600 kg" need a smaller size to stay on one line.
    var compactValue: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbolName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)

            Text(value)
                .font(.system(size: compactValue ? 19 : 28,
                              weight: .semibold,
                              design: .rounded))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.ink)

            Text(caption)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.muted)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
        .cardSurface(padding: 14)
    }
}

#Preview {
    HStack(spacing: 12) {
        KPICard(value: "5", label: "Fields planted", caption: "6 total",
                symbolName: "map.fill", tint: AppTheme.paddy)
        KPICard(value: "12.5", label: "Land planted", caption: "Resting land not counted",
                symbolName: "square.dashed", tint: AppTheme.shoot)
    }
    .padding()
    .background(AppTheme.canvas)
}
