//
//  RecordHarvestSheet.swift
//  AniTrack — SCREEN 4a (popup)
//
//  The crop is not asked for: it is read from whichever field is chosen, since
//  a field only grows one crop at a time and asking twice invites a mismatch.
//

import SwiftUI

struct RecordHarvestSheet: View {

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var data: FarmDataController
    @EnvironmentObject private var toasts: ToastController
    @Environment(\.dismiss) private var dismiss

    @State private var fieldID: String?
    @State private var amountText: String = ""
    @State private var quality: HarvestQuality = .good
    @State private var harvestedOn: Date = Date()
    @State private var recordedByID: String?
    @State private var remarks: String = ""

    private var viewer: ViewerContext {
        return ViewerContext(user: auth.currentUser)
    }

    private var selectedField: Parcel? {
        return data.parcel(id: fieldID)
    }

    private var amount: Double {
        return Double(amountText.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private var canSave: Bool {
        return fieldID != nil && amount > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("What was harvested") {
                    Picker("Field", selection: $fieldID) {
                        Text("Pick a field").tag(String?.none)
                        ForEach(data.parcels) { parcel in
                            Text(parcel.name).tag(String?.some(parcel.id))
                        }
                    }

                    LabeledContent("Crop") {
                        Text(selectedField?.crop.displayName ?? "Pick a field first")
                            .foregroundStyle(AppTheme.muted)
                    }
                }

                Section("How much") {
                    HStack {
                        TextField("0", text: $amountText)
                            .keyboardType(.numberPad)
                        Text("kg")
                            .foregroundStyle(AppTheme.muted)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quality")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.ink)
                        Picker("Quality", selection: $quality) {
                            ForEach(HarvestQuality.allCases) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 2)
                }

                Section("When and who") {
                    DatePicker("Date", selection: $harvestedOn, displayedComponents: .date)

                    Picker("Written down by", selection: $recordedByID) {
                        Text("Nobody").tag(String?.none)
                        ForEach(data.workers) { worker in
                            Text(worker.fullName).tag(String?.some(worker.id))
                        }
                    }
                }

                Section("Notes") {
                    TextField("Anything worth remembering", text: $remarks, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Write down harvest")
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
                if fieldID == nil { fieldID = data.parcels.first?.id }
                if recordedByID == nil { recordedByID = data.workers.first?.id }
            }
        }
    }

    private func save() {
        guard let field = selectedField else { return }
        data.addHarvest(parcelID: field.id,
                        crop: field.crop,
                        harvestedOn: harvestedOn,
                        kilograms: amount,
                        quality: quality,
                        recordedByID: recordedByID,
                        remarks: remarks,
                        by: viewer)
        toasts.show("Harvest written down")
        dismiss()
    }
}

#Preview {
    RecordHarvestSheet()
        .environmentObject(AuthController.previewSignedIn())
        .environmentObject(FarmDataController.preview)
        .environmentObject(ToastController())
}
