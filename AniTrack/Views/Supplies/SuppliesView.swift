//
//  SuppliesView.swift
//  AniTrack — SCREEN: supplies
//
//  Only things the farm buys to operate — seed, fertilizer, fuel, tools. Never
//  crops, and nothing here is for sale.
//

import SwiftUI

struct SuppliesView: View {

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var data: FarmDataController

    @State private var isRecordingMovement: Bool = false

    private var viewer: ViewerContext {
        return ViewerContext(user: auth.currentUser)
    }

    /// Running low first, then by name.
    private var items: [SupplyItem] {
        return data.supplies.sorted { left, right in
            if left.isRunningLow != right.isRunningLow { return left.isRunningLow }
            return left.name < right.name
        }
    }

    private var lowCount: Int {
        return data.runningLowItems.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                summaryStrip

                ForEach(items) { item in
                    NavigationLink(value: AppRoute.supplyItem(item.id)) {
                        row(for: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.screenPadding)
            .padding(.vertical, 12)
        }
        .background(AppTheme.canvas)
        .navigationTitle("Supplies")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if viewer.permissions.isReadOnly {
                    ReadOnlyTag()
                }
                if viewer.permissions.canRecordStock {
                    Button {
                        isRecordingMovement = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add or use supplies")
                }
            }
        }
        .sheet(isPresented: $isRecordingMovement) {
            StockMovementSheet(preselectedItemID: nil)
        }
    }

    // MARK: - Summary

    private var summaryStrip: some View {
        HStack(spacing: 12) {
            figure(value: "\(data.supplies.count)",
                   label: "Items",
                   tint: AppTheme.paddy)
            figure(value: "\(lowCount)",
                   label: lowCount == 1 ? "Running low" : "Running low",
                   tint: lowCount > 0 ? AppTheme.clay : AppTheme.shoot)
        }
    }

    private func figure(value: String, label: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(tint)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.muted)
        }
        .cardSurface(padding: 14)
    }

    // MARK: - Row

    private func row(for item: SupplyItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppTheme.paddy.opacity(0.10))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: item.category.symbolName)
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.paddy)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                    StatusChip(text: item.category.displayName, tint: AppTheme.paddy)
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(item.quantityLabel)
                        .font(.system(size: 15, weight: .semibold).monospacedDigit())
                        .foregroundStyle(item.isRunningLow ? AppTheme.clay : AppTheme.ink)
                    if item.isRunningLow {
                        StatusChip(text: "Running low", tint: AppTheme.clay)
                    }
                }
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppTheme.ink.opacity(0.07))
                    Capsule()
                        .fill(item.isRunningLow ? AppTheme.clay : AppTheme.shoot)
                        .frame(width: max(proxy.size.width * item.stockRatio, 4))
                }
            }
            .frame(height: 6)

            Text("Warn me below \(Formatting.wholeNumber(item.warnBelow)) \(item.unit)")
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.muted)
        }
        .cardSurface()
    }
}

#Preview {
    NavigationStack {
        SuppliesView()
            .environmentObject(AuthController.previewSignedIn())
            .environmentObject(FarmDataController.preview)
            .environmentObject(ToastController())
    }
}
