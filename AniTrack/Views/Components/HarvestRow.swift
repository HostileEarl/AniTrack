//
//  HarvestRow.swift
//  AniTrack — REUSABLE COMPONENT
//

import SwiftUI

/// One recorded harvest. The amount is formatted by the controller so it
/// follows the user's kilos-or-sacks preference everywhere at once.
struct HarvestRow: View {

    let record: HarvestRecord
    let fieldName: String
    let amountText: String

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 1) {
                Text(record.harvestedOn.formatted(.dateTime.day()))
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.paddy)
                Text(record.harvestedOn.formatted(.dateTime.month(.abbreviated)))
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.muted)
            }
            .frame(width: 38)

            VStack(alignment: .leading, spacing: 4) {
                Text(fieldName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(record.crop.displayName)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.muted)
                    StatusChip(text: record.quality.displayName, tint: record.quality.tint)
                }
            }

            Spacer(minLength: 4)

            Text(amountText)
                .font(.system(size: 15, weight: .semibold).monospacedDigit())
                .foregroundStyle(AppTheme.ink)
        }
        .padding(.vertical, 7)
    }
}
