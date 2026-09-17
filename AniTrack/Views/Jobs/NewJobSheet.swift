//
//  NewJobSheet.swift
//  AniTrack — SCREEN 3a (popup)
//
//  Form fields are local @State. Nothing reaches the model until Add job is
//  pressed, so closing the sheet leaves no half-made job behind.
//

import SwiftUI

struct NewJobSheet: View {

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var data: FarmDataController
    @EnvironmentObject private var toasts: ToastController
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var details: String = ""
    @State private var fieldID: String?
    @State private var assigneeID: String?
    @State private var dueOn: Date = Date()
    @State private var priority: JobPriority = .normal

    private var viewer: ViewerContext {
        return ViewerContext(user: auth.currentUser)
    }

    private var canSave: Bool {
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && fieldID != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("What needs doing") {
                    TextField("Job title", text: $title)
                    TextField("What the team should do", text: $details, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Where and who") {
                    Picker("Field", selection: $fieldID) {
                        Text("Pick a field").tag(String?.none)
                        ForEach(data.parcels) { parcel in
                            Text(parcel.name).tag(String?.some(parcel.id))
                        }
                    }

                    Picker("Give to", selection: $assigneeID) {
                        Text("Nobody yet").tag(String?.none)
                        ForEach(data.workers) { worker in
                            Text(worker.fullName).tag(String?.some(worker.id))
                        }
                    }
                }

                Section("When") {
                    DatePicker("Due date", selection: $dueOn, displayedComponents: .date)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Priority")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.ink)
                        Picker("Priority", selection: $priority) {
                            ForEach(JobPriority.allCases) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationTitle("New job")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add job") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear {
                if fieldID == nil { fieldID = data.parcels.first?.id }
            }
        }
    }

    private func save() {
        guard let fieldID = fieldID else { return }
        data.addJob(title: title,
                    details: details,
                    parcelID: fieldID,
                    assigneeID: assigneeID,
                    dueOn: dueOn,
                    priority: priority,
                    by: viewer)
        toasts.show("Job added")
        dismiss()
    }
}

#Preview {
    NewJobSheet()
        .environmentObject(AuthController.previewSignedIn())
        .environmentObject(FarmDataController.preview)
        .environmentObject(ToastController())
}
