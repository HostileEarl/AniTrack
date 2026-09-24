//
//  ParcelRow.swift
//  AniTrack — REUSABLE COMPONENT
//

import SwiftUI

/// One field in a list. Used on the dashboard and the fields screen, so a
/// change to the row shape only ever happens here.
struct ParcelRow: View {

    let parcel: Parcel

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(parcel.condition.tint.opacity(0.15))
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName: parcel.crop.symbolName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(parcel.condition.tint)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(parcel.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)

                Text("\(parcel.placeLabel) · \(parcel.areaLabel)")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    StatusChip(text: parcel.stage.displayName,
                               tint: AppTheme.paddy,
                               symbolName: parcel.stage.symbolName)
                    StatusChip(text: parcel.condition.displayName,
                               tint: parcel.condition.tint,
                               symbolName: parcel.condition.symbolName)
                }
                .padding(.top, 2)
            }

            Spacer(minLength: 4)

            Text(parcel.harvestCountdown)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(parcel.daysUntilHarvest < 0 && parcel.stage.isPlanted
                                 ? AppTheme.clay : AppTheme.muted)
                .multilineTextAlignment(.trailing)
                .frame(width: 72, alignment: .trailing)
        }
        .padding(.vertical, 7)
        .contentShape(Rectangle())
    }
}

#Preview {
    let data = FarmDataController.preview
    return VStack(spacing: 0) {
        ForEach(data.parcels.prefix(3)) { parcel in
            ParcelRow(parcel: parcel)
        }
    }
    .padding()
}
