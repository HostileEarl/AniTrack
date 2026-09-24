//
//  StockMovementSheet.swift
//  AniTrack — SCREEN: add or use supplies (popup)
//
//  The field is only asked for when supplies are being used, because supplies
//  that come in arrive at the store, not at a field.
//

import SwiftUI

struct StockMovementSheet: View {

    /// Set when opened from a particular item's screen.
    let preselectedItemID: String?

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var data: FarmDataController
    @EnvironmentObject private var toasts: ToastController
    @Environment(\.dismiss) private var dismiss

    @State private var itemID: String?
    @State private var kind: StockMovementKind = .used
    @State private var quantityText: String = ""
    @State private var fieldID: String?
    @State private var happenedOn: Date = Date()
    @State private var note: String = ""

    private var viewer: ViewerContext {
        return ViewerContext(user: auth.currentUser)
    }

    private var selectedItem: SupplyItem? {
        return data.supplyItem(id: itemID)
    }

    private var quantity: Double {
        return Double(quantityText.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private var canSave: Bool {
        return itemID != nil && quantity > 0
    }

    /// Warns before saving something that would leave the store short.
    private var willRunLow: Bool {
        guard let item = selectedItem, kind == .used else { return false }
        return (item.quantity - quantity) <= item.warnBelow && !item.isRunningLow
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Which item") {
                    Picker("Item", selection: $itemID) {
                        Text("Pick an item").tag(String?.none)
                        ForEach(data.supplies) { item in
                            Text(item.name).tag(String?.some(item.id))
                        }
                    }

                    if let item = selectedItem {
                        LabeledContent("In store now") {
                            Text(item.quantityLabel)
                                .foregroundStyle(item.isRunningLow ? AppTheme.clay : AppTheme.muted)
                        }
                    }
                }

                Section("Added or used") {
                    Picker("Added or used", selection: $kind) {
                        ForEach(StockMovementKind.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        TextField("0", text: $quantityText)
                            .keyboardType(.decimalPad)
                        Text(selectedItem?.unit ?? "")
                            .foregroundStyle(AppTheme.muted)
                    }

                    if willRunLow {
                        Label("This will bring the item below its warning level.",
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.husk)
                    }
                }

                if kind == .used {
                    Section("Used on which field") {
                        Picker("Field", selection: $fieldID) {
                            Text("Not for one field").tag(String?.none)
                            ForEach(data.visibleParcels(for: viewer)) { parcel in
                                Text(parcel.name).tag(String?.some(parcel.id))
                            }
                        }
                    }
                }

                Section("When") {
                    DatePicker("Date", selection: $happenedOn, displayedComponents: .date)
                }

                Section("Note") {
                    TextField("Anything worth remembering", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(kind == .added ? "Add supplies" : "Use supplies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear {
                if itemID == nil {
                    itemID = preselectedItemID ?? data.supplies.first?.id
                }
            }
        }
    }

    private func save() {
        guard let itemID = itemID else { return }
        data.recordStockMovement(itemID: itemID,
                                 kind: kind,
                                 quantity: quantity,
                                 parcelID: kind == .used ? fieldID : nil,
                                 happenedOn: happenedOn,
                                 note: note,
                                 by: viewer)
        toasts.show(kind == .added ? "Supplies added" : "Supplies used")
        dismiss()
    }
}

#Preview {
    StockMovementSheet(preselectedItemID: nil)
        .environmentObject(AuthController.previewSignedIn())
        .environmentObject(FarmDataController.preview)
        .environmentObject(ToastController())
}
