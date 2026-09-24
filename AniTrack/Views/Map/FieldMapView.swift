//
//  FieldMapView.swift
//  AniTrack — SCREEN: map
//
//  A real map rather than a drawing, because the whole point of AniTrack is
//  that the land is spread out. Pins are coloured by field condition so a
//  problem is visible without tapping anything.
//

import SwiftUI
import MapKit

struct FieldMapView: View {

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var data: FarmDataController

    @State private var selectedField: Parcel?
    @State private var camera: MapCameraPosition = .automatic

    private var viewer: ViewerContext {
        return ViewerContext(user: auth.currentUser)
    }

    private var fields: [Parcel] {
        return data.visibleParcels(for: viewer)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $camera) {
                ForEach(fields) { field in
                    Annotation(field.name,
                               coordinate: CLLocationCoordinate2D(latitude: field.latitude,
                                                                  longitude: field.longitude)) {
                        pin(for: field)
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat))
            .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 10) {
                legend

                if let field = selectedField {
                    fieldCard(for: field)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, AppTheme.screenPadding)
            .padding(.bottom, 16)
        }
        .navigationTitle("Map")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: frameAllFields)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selectedField)
    }

    // MARK: - Pin

    private func pin(for field: Parcel) -> some View {
        Button {
            selectedField = (selectedField?.id == field.id) ? nil : field
        } label: {
            ZStack {
                Circle()
                    .fill(field.condition.tint)
                    .frame(width: 30, height: 30)
                    .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
                Image(systemName: field.crop.symbolName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
            .overlay(
                Circle()
                    .strokeBorder(.white, lineWidth: selectedField?.id == field.id ? 3 : 2)
            )
            .scaleEffect(selectedField?.id == field.id ? 1.2 : 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 14) {
            ForEach(FieldCondition.allCases) { condition in
                HStack(spacing: 5) {
                    Circle()
                        .fill(condition.tint)
                        .frame(width: 9, height: 9)
                    Text(condition.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.ink)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            Capsule().fill(AppTheme.surface)
        )
        .overlay(
            Capsule().strokeBorder(AppTheme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Selected Field Card

    private func fieldCard(for field: Parcel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(field.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(field.placeLabel)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.muted)
                }

                Spacer()

                Button {
                    selectedField = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppTheme.muted.opacity(0.6))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }

            HStack(spacing: 6) {
                StatusChip(text: field.crop.displayName, tint: AppTheme.paddy,
                           symbolName: field.crop.symbolName)
                StatusChip(text: field.areaLabel, tint: AppTheme.paddy)
                StatusChip(text: field.condition.displayName, tint: field.condition.tint,
                           symbolName: field.condition.symbolName)
            }

            Text(field.harvestCountdown)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.muted)

            NavigationLink(value: AppRoute.field(field.id)) {
                Text("Open this field")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(AppTheme.paddy)
                    )
            }
        }
        .cardSurface()
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
    }

    // MARK: - Camera

    /// Frames every field with a little breathing room around the edges.
    private func frameAllFields() {
        guard !fields.isEmpty else { return }

        let latitudes = fields.map(\.latitude)
        let longitudes = fields.map(\.longitude)

        guard let minLat = latitudes.min(), let maxLat = latitudes.max(),
              let minLon = longitudes.min(), let maxLon = longitudes.max() else { return }

        let centre = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2,
                                            longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: max((maxLat - minLat) * 1.6, 0.05),
                                    longitudeDelta: max((maxLon - minLon) * 1.6, 0.05))

        camera = .region(MKCoordinateRegion(center: centre, span: span))
    }
}

#Preview {
    NavigationStack {
        FieldMapView()
            .environmentObject(AuthController.previewSignedIn())
            .environmentObject(FarmDataController.preview)
    }
}
