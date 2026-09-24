//
//  FieldNoteDetailView.swift
//  AniTrack — SCREEN: one field note
//

import SwiftUI

struct FieldNoteDetailView: View {

    let noteID: String

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var data: FarmDataController
    @EnvironmentObject private var toasts: ToastController

    @State private var reply: String = ""

    private var viewer: ViewerContext {
        return ViewerContext(user: auth.currentUser)
    }

    /// Looked up each time, so marking it fixed shows here at once and a
    /// deleted note shows as missing rather than as a stale object.
    private var current: FieldNote? {
        return data.fieldNote(id: noteID)
    }

    private var field: Parcel? {
        guard let note = current else { return nil }
        return data.parcel(id: note.parcelID)
    }

    var body: some View {
        Group {
            if current == nil {
                EmptyStateView(symbolName: "questionmark.folder",
                               title: "This note is gone",
                               message: "It was removed while you were looking at it.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.canvas)
            } else {
                content
            }
        }
        .navigationTitle("Field note")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                if let note = current {
                    headerCard(note)
                    photosCard(note)
                    fieldCard
                    if viewer.permissions.canResolveFieldNotes && !note.isResolved {
                        replyCard(note)
                    }
                }
            }
            .padding(.horizontal, AppTheme.screenPadding)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(AppTheme.canvas)
    }

    // MARK: - Sections

    private func headerCard(_ note: FieldNote) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if note.isResolved {
                    StatusChip(text: "Fixed", tint: AppTheme.shoot, symbolName: "checkmark")
                } else {
                    StatusChip(text: note.urgency.displayName, tint: note.urgency.tint)
                }
                StatusChip(text: Formatting.relativeTime(from: note.filedOn),
                           tint: AppTheme.paddy,
                           symbolName: "clock")
            }

            Text(note.observation)
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.ink)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Divider().overlay(AppTheme.hairline)

            HStack(spacing: 10) {
                Circle()
                    .fill(AppTheme.paddy)
                    .frame(width: 34, height: 34)
                    .overlay(
                        Text(note.initials)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(note.reportedByName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.ink)
                    Text(note.filedOn.formatted(.dateTime.day().month(.wide).hour().minute()))
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.muted)
                }
            }
        }
        .cardSurface()
    }

    @ViewBuilder
    private func photosCard(_ note: FieldNote) -> some View {
        if note.photoCount > 0 {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Photos", trailing: "\(note.photoCount)")

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8),
                                    GridItem(.flexible(), spacing: 8),
                                    GridItem(.flexible(), spacing: 8)],
                          spacing: 8) {
                    ForEach(0..<note.photoCount, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(AppTheme.paddy.opacity(0.08))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 20))
                                    .foregroundStyle(AppTheme.paddy.opacity(0.4))
                            )
                    }
                }

                Text("Photos taken on the field are shown here.")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.muted)
            }
            .cardSurface()
        }
    }

    @ViewBuilder
    private var fieldCard: some View {
        if let field = field {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "About the field")
                NavigationLink(value: AppRoute.field(field.id)) {
                    ParcelRow(parcel: field)
                }
                .buttonStyle(.plain)
            }
            .cardSurface()
        }
    }

    private func replyCard(_ note: FieldNote) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Answer the team")

            TextField("Write back to whoever sent this", text: $reply, axis: .vertical)
                .font(.system(size: 15))
                .lineLimit(2...4)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.canvas)
                )

            Button {
                data.resolveFieldNote(note, by: viewer)
                toasts.show("Marked as fixed")
            } label: {
                Label("Mark as fixed", systemImage: "checkmark.circle")
                    .font(.system(size: 15, weight: .medium))
            }
            .buttonStyle(.bordered)
            .tint(AppTheme.shoot)
        }
        .cardSurface()
    }
}

#Preview {
    NavigationStack {
        FieldNoteDetailView(noteID: "fr1")
            .environmentObject(AuthController.previewSignedIn())
            .environmentObject(FarmDataController.preview)
            .environmentObject(ToastController())
    }
}
