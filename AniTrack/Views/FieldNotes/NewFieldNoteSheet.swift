//
//  NewFieldNoteSheet.swift
//  AniTrack — SCREEN: send a field note (popup)
//
//  An urgent note does three things at once: it files the note, sets the field
//  to Problem, and raises an alert. That chain lives in the controller, so it
//  cannot be half-done depending on which screen sent the note.
//

import SwiftUI

struct NewFieldNoteSheet: View {

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var data: FarmDataController
    @EnvironmentObject private var toasts: ToastController
    @Environment(\.dismiss) private var dismiss

    @State private var fieldID: String?
    @State private var urgency: NoteUrgency = .normal
    @State private var observation: String = ""
    @State private var photoCount: Int = 0
    @State private var notifyManager: Bool = true

    private let characterLimit = 400

    private var viewer: ViewerContext {
        return ViewerContext(user: auth.currentUser)
    }

    private var canSend: Bool {
        return fieldID != nil
            && !observation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Which field") {
                    Picker("Field", selection: $fieldID) {
                        Text("Pick a field").tag(String?.none)
                        ForEach(data.visibleParcels(for: viewer)) { parcel in
                            Text(parcel.name).tag(String?.some(parcel.id))
                        }
                    }
                }

                Section("How urgent") {
                    Picker("How urgent", selection: $urgency) {
                        ForEach(NoteUrgency.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    if urgency == .urgent {
                        Label("This will set the field to Problem and tell the farm manager right away.",
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.clay)
                    }
                }

                Section {
                    TextField("What did you see on the field?",
                              text: $observation,
                              axis: .vertical)
                        .lineLimit(4...8)
                        .onChange(of: observation) { _, newValue in
                            if newValue.count > characterLimit {
                                observation = String(newValue.prefix(characterLimit))
                            }
                        }
                } header: {
                    Text("What you saw")
                } footer: {
                    Text("\(observation.count) of \(characterLimit) letters")
                        .foregroundStyle(observation.count >= characterLimit
                                         ? AppTheme.clay : AppTheme.muted)
                }

                Section("Photos") {
                    Stepper("\(photoCount) \(photoCount == 1 ? "photo" : "photos") attached",
                            value: $photoCount, in: 0...6)
                    Text("Taking photos with the camera comes with the next version. For now this records how many were taken.")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.muted)
                }

                Section {
                    Toggle("Tell the farm manager", isOn: $notifyManager)
                }
            }
            .navigationTitle("New field note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") { send() }
                        .disabled(!canSend)
                }
            }
            .onAppear {
                if fieldID == nil {
                    fieldID = data.visibleParcels(for: viewer).first?.id
                }
            }
        }
    }

    private func send() {
        guard let fieldID = fieldID else { return }
        data.addFieldNote(parcelID: fieldID,
                          urgency: urgency,
                          observation: observation,
                          photoCount: photoCount,
                          notifyManager: notifyManager,
                          by: viewer)
        toasts.show(urgency == .urgent ? "Sent. The manager has been told." : "Field note sent")
        dismiss()
    }
}

#Preview {
    NewFieldNoteSheet()
        .environmentObject(AuthController.previewSignedIn())
        .environmentObject(FarmDataController.preview)
        .environmentObject(ToastController())
}
