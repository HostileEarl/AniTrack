//
//  FieldNotesView.swift
//  AniTrack — SCREEN: field notes
//
//  What the team sends in from the field. A team leader sees only notes about
//  their own fields, which the controller decides.
//

import SwiftUI

struct FieldNotesView: View {

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var data: FarmDataController

    @State private var isWritingNote: Bool = false

    private var viewer: ViewerContext {
        return ViewerContext(user: auth.currentUser)
    }

    /// Unresolved first, most urgent first, then newest.
    private var notes: [FieldNote] {
        return data.visibleFieldNotes(for: viewer).sorted { left, right in
            if left.isResolved != right.isResolved { return !left.isResolved }
            if left.urgency.severityRank != right.urgency.severityRank {
                return left.urgency.severityRank < right.urgency.severityRank
            }
            return left.filedOn > right.filedOn
        }
    }

    var body: some View {
        Group {
            if notes.isEmpty {
                EmptyStateView(symbolName: "doc.text",
                               title: "No notes yet",
                               message: "Use the plus button to send in what you see on the field.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.canvas)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(notes) { note in
                            NavigationLink(value: AppRoute.fieldNote(note.id)) {
                                card(for: note)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppTheme.screenPadding)
                    .padding(.vertical, 12)
                }
                .background(AppTheme.canvas)
            }
        }
        .navigationTitle("Field notes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if viewer.permissions.isReadOnly {
                    ReadOnlyTag()
                }
                if viewer.permissions.canSendFieldNotes {
                    Button {
                        isWritingNote = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Send a field note")
                }
            }
        }
        .sheet(isPresented: $isWritingNote) {
            NewFieldNoteSheet()
        }
    }

    // MARK: - Card

    private func card(for note: FieldNote) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Circle()
                    .fill(AppTheme.paddy)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(note.initials)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(data.parcelName(for: note.parcelID))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text("\(note.reportedByName) · \(Formatting.relativeTime(from: note.filedOn))")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.muted)
                }

                Spacer(minLength: 4)

                if note.isResolved {
                    StatusChip(text: "Fixed", tint: AppTheme.shoot, symbolName: "checkmark")
                } else {
                    StatusChip(text: note.urgency.displayName, tint: note.urgency.tint)
                }
            }

            Text(note.observation)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.ink.opacity(0.8))
                .lineLimit(2)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            if note.photoCount > 0 {
                HStack(spacing: 5) {
                    Image(systemName: "photo")
                        .font(.system(size: 11))
                    Text("\(note.photoCount) \(note.photoCount == 1 ? "photo" : "photos")")
                        .font(.system(size: 12))
                }
                .foregroundStyle(AppTheme.muted)
            }
        }
        .cardSurface()
        .opacity(note.isResolved ? 0.7 : 1)
    }
}

#Preview {
    NavigationStack {
        FieldNotesView()
            .environmentObject(AuthController.previewSignedIn())
            .environmentObject(FarmDataController.preview)
            .environmentObject(ToastController())
    }
}
