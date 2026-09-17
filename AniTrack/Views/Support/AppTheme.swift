//
//  AppTheme.swift
//  AniTrack — VIEW SUPPORT
//
//  The palette matches the Figma prototype exactly, so screenshots from the
//  prototype and the app read as the same product.
//

import SwiftUI

enum AppTheme {

    // MARK: - Palette (hex values shared with the prototype)

    /// #1F4D36 — deep paddy green. Primary.
    static let paddy = Color(red: 0.122, green: 0.302, blue: 0.212)

    /// #6E9C59 — young shoot green. Good condition, progress fills.
    static let shoot = Color(red: 0.431, green: 0.612, blue: 0.349)

    /// #D9A31F — dried husk gold. Watch status and single highlight figures.
    static let husk = Color(red: 0.851, green: 0.639, blue: 0.122)

    /// #A83F2E — laterite clay. Problems only.
    static let clay = Color(red: 0.659, green: 0.247, blue: 0.180)

    /// #14231B — ink for primary text.
    static let ink = Color(red: 0.078, green: 0.137, blue: 0.106)

    /// #F1F4EE — page background, a cool pale green-grey.
    static let canvas = Color(red: 0.945, green: 0.957, blue: 0.933)

    /// Cards and rows.
    static let surface = Color.white

    /// Muted body text.
    static let muted = Color(red: 0.078, green: 0.137, blue: 0.106).opacity(0.55)

    /// Hairline card border.
    static let hairline = Color(red: 0.122, green: 0.302, blue: 0.212).opacity(0.08)

    /// Inactive tab bar item.
    static let inactiveTab = Color(red: 0.561, green: 0.659, blue: 0.620)

    // MARK: - Metrics

    static let cardRadius: CGFloat = 14
    static let chipRadius: CGFloat = 7
    static let buttonRadius: CGFloat = 14
    static let cardPadding: CGFloat = 16
    static let screenPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 22
    static let buttonHeight: CGFloat = 52
}

// MARK: - Card Surface

/// A quiet raised panel: white, soft corner, hairline border, no shadow.
struct CardSurface: ViewModifier {

    var padding: CGFloat = AppTheme.cardPadding

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .fill(AppTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .strokeBorder(AppTheme.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func cardSurface(padding: CGFloat = AppTheme.cardPadding) -> some View {
        modifier(CardSurface(padding: padding))
    }

    /// Applies the app background and hides the default grouped list backdrop.
    func farmBackground() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(AppTheme.canvas)
    }
}

// MARK: - Primary Button

/// The wide green action button used across the auth screens and forms.
struct PrimaryButtonStyle: ButtonStyle {

    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.buttonRadius, style: .continuous)
                    .fill(AppTheme.paddy.opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.4))
            )
    }
}
