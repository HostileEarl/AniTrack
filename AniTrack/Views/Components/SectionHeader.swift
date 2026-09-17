//
//  SectionHeader.swift
//  AniTrack — REUSABLE COMPONENT
//

import SwiftUI

/// A card heading with an optional figure on the right.
struct SectionHeader: View {

    let title: String
    var trailing: String? = nil
    var trailingTint: Color = AppTheme.muted

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
            Spacer(minLength: 8)
            if let trailing = trailing {
                Text(trailing)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(trailingTint)
            }
        }
    }
}
