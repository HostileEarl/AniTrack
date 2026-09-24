//
//  WeatherView.swift
//  AniTrack — SCREEN: weather
//
//  The numbers here are sample data, not a live feed, and the screen says so at
//  the bottom. Showing invented weather without that line would invite someone
//  to plan real field work around it.
//

import SwiftUI

struct WeatherView: View {

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var data: FarmDataController

    private var viewer: ViewerContext {
        return ViewerContext(user: auth.currentUser)
    }

    private var impacts: [FieldWeatherImpact] {
        return data.weatherImpacts(for: viewer)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                outlookCard
                adviceCard
                impactCard
                disclaimer
            }
            .padding(.horizontal, AppTheme.screenPadding)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(AppTheme.canvas)
        .navigationTitle("Weather")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Outlook

    private var outlookCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.husk)
                Text(auth.currentUser?.municipality ?? "Cabanatuan, Nueva Ecija")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
            }

            HStack(spacing: 8) {
                ForEach(data.weatherDays) { day in
                    dayCard(day)
                }
            }
        }
        .cardSurface()
    }

    private func dayCard(_ day: WeatherDay) -> some View {
        VStack(spacing: 6) {
            Text(day.dayLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.muted)

            Image(systemName: day.symbolName)
                .font(.system(size: 22))
                .foregroundStyle(day.rainfallMM > 10 ? AppTheme.paddy : AppTheme.husk)
                .frame(height: 26)

            Text(day.temperatureLabel)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.ink)

            Text(day.condition)
                .font(.system(size: 10))
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 24)

            VStack(spacing: 2) {
                measure(symbol: "humidity.fill", text: day.humidityLabel, tint: AppTheme.muted)
                measure(symbol: "drop.fill", text: day.rainfallLabel, tint: AppTheme.paddy)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppTheme.paddy.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(AppTheme.hairline, lineWidth: 1)
        )
    }

    private func measure(symbol: String, text: String, tint: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: symbol)
                .font(.system(size: 9))
            Text(text)
                .font(.system(size: 10))
        }
        .foregroundStyle(tint)
    }

    // MARK: - Advice

    private var adviceCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 13))
                Text("What to do")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(AppTheme.husk)

            Text(data.weatherAdvice)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.ink.opacity(0.85))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.husk.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(AppTheme.husk.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Per Field

    private var impactCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "What this means for each field")

            ForEach(impacts) { impact in
                VStack(alignment: .leading, spacing: 3) {
                    Text(impact.fieldName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.ink)
                    Text(impact.advice)
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.muted)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)

                if impact.id != impacts.last?.id {
                    Divider().overlay(AppTheme.hairline)
                }
            }
        }
        .cardSurface()
    }

    private var disclaimer: some View {
        Text("The weather shown here is only an example and is not live. Use PAGASA or your local weather service before making real decisions.")
            .font(.system(size: 11))
            .foregroundStyle(AppTheme.muted)
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 4)
    }
}

#Preview {
    NavigationStack {
        WeatherView()
            .environmentObject(AuthController.previewSignedIn())
            .environmentObject(FarmDataController.preview)
    }
}
