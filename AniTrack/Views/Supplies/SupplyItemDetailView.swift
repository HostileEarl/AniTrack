//
//  SupplyItemDetailView.swift
//  AniTrack — SCREEN: one supply item
//

import SwiftUI

struct SupplyItemDetailView: View {

    let itemID: String

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var data: FarmDataController
    @EnvironmentObject private var toasts: ToastController

    @State private var isRecordingMovement: Bool = false
    @State private var warnBelowText: String = ""
    @State private var isEditingWarnLevel: Bool = false

    private var viewer: ViewerContext {
        return ViewerContext(user: auth.currentUser)
    }

    private var current: SupplyItem? {
        return data.supplyItem(id: itemID)
    }

    private var movements: [StockMovement] {
        return data.movements(forItem: itemID)
    }

    var body: some View {
        Group {
            if current == nil {
                EmptyStateView(symbolName: "questionmark.folder",
                               title: "This item is gone",
                               message: "It was removed while you were looking at it.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.canvas)
            } else {
                content
            }
        }
        .navigationTitle(current?.name ?? "Supply")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewer.permissions.canRecordStock {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isRecordingMovement = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add or use this item")
                }
            }
        }
        .sheet(isPresented: $isRecordingMovement) {
            StockMovementSheet(preselectedItemID: itemID)
        }
        .onAppear {
            warnBelowText = Formatting.wholeNumber(current?.warnBelow ?? 0)
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                if let item = current {
                    levelCard(item)
                    warnLevelCard(item)
                    historyCard(item)
                }
            }
            .padding(.horizontal, AppTheme.screenPadding)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(AppTheme.canvas)
    }

    // MARK: - Level

    private func levelCard(_ item: SupplyItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                StatusChip(text: item.category.displayName,
                           tint: AppTheme.paddy,
                           symbolName: item.category.symbolName)
                Spacer()
                if item.isRunningLow {
                    StatusChip(text: "Running low", tint: AppTheme.clay,
                               symbolName: "exclamationmark.triangle.fill")
                }
            }

            Text(item.quantityLabel)
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .foregroundStyle(item.isRunningLow ? AppTheme.clay : AppTheme.ink)

            Text("left in store")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.muted)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppTheme.ink.opacity(0.07))
                    Capsule()
                        .fill(item.isRunningLow ? AppTheme.clay : AppTheme.shoot)
                        .frame(width: max(proxy.size.width * item.stockRatio, 4))
                }
            }
            .frame(height: 8)
        }
        .cardSurface()
    }

    // MARK: - Warning Level

    private func warnLevelCard(_ item: SupplyItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Warning level")

            Text("You will be told when this drops to \(Formatting.wholeNumber(item.warnBelow)) \(item.unit) or less.")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.muted)
                .fixedSize(horizontal: false, vertical: true)

            if viewer.permissions.canEditWarningLevels {
                if isEditingWarnLevel {
                    HStack(spacing: 10) {
                        TextField("0", text: $warnBelowText)
                            .keyboardType(.numberPad)
                            .font(.system(size: 15))
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(AppTheme.canvas)
                            )
                        Text(item.unit)
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.muted)

                        Button("Save") { saveWarnLevel() }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppTheme.paddy)
                    }
                } else {
                    Button {
                        warnBelowText = Formatting.wholeNumber(item.warnBelow)
                        isEditingWarnLevel = true
                    } label: {
                        Label("Change warning level", systemImage: "slider.horizontal.3")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.paddy)
                }
            }
        }
        .cardSurface()
    }

    // MARK: - History

    private func historyCard(_ item: SupplyItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "What came in and went out",
                          trailing: "\(movements.count)")

            if movements.isEmpty {
                Text("Nothing added or used yet.")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.muted)
            } else {
                ForEach(movements) { movement in
                    movementRow(movement, item)
                    if movement.id != movements.last?.id {
                        Divider().overlay(AppTheme.hairline)
                    }
                }
            }
        }
        .cardSurface()
    }

    private func movementRow(_ movement: StockMovement, _ item: SupplyItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: movement.kind == .added ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(movement.kind == .added ? AppTheme.shoot : AppTheme.husk)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(movement.kind.displayName) \(Formatting.wholeNumber(movement.quantity)) \(item.unit)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.ink)

                Text(subtitle(for: movement))
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Text(movement.happenedOn.formatted(.dateTime.day().month(.abbreviated)))
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.muted)
        }
        .padding(.vertical, 6)
    }

    private func subtitle(for movement: StockMovement) -> String {
        var parts: [String] = []
        if let parcelID = movement.parcelID {
            parts.append(data.parcelName(for: parcelID))
        }
        if !movement.recordedByName.isEmpty {
            parts.append(movement.recordedByName)
        }
        return parts.isEmpty ? "No details" : parts.joined(separator: " · ")
    }

    // MARK: - Actions

    private func saveWarnLevel() {
        guard let item = current else { return }
        let value = Double(warnBelowText.replacingOccurrences(of: ",", with: "")) ?? item.warnBelow
        data.updateWarningLevel(value, for: item, by: viewer)
        isEditingWarnLevel = false
        toasts.show("Warning level saved")
    }
}

#Preview {
    NavigationStack {
        SupplyItemDetailView(itemID: "i1")
            .environmentObject(AuthController.previewSignedIn())
            .environmentObject(FarmDataController.preview)
            .environmentObject(ToastController())
    }
}
