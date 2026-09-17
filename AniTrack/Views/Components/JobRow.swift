//
//  JobRow.swift
//  AniTrack — REUSABLE COMPONENT
//
//  Split into two pieces on purpose.
//
//  `JobRowContent` is everything except the status circle. `JobRow` puts the
//  circle in front of it for screens where the whole row is not a link.
//
//  Screens that need the row to navigate compose the two themselves, because a
//  Button nested inside a NavigationLink inside a List does not reliably
//  receive its own taps — the link swallows them and the circle stops working.
//  Keeping the circle outside the link is what makes both behave.
//

import SwiftUI

// MARK: - Row Content

/// The text side of a job row: title, where and who, and the chips.
struct JobRowContent: View {

    let job: FarmJob
    let fieldName: String
    let assigneeName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(job.title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.ink)
                .strikethrough(job.status.isDone, color: AppTheme.ink.opacity(0.4))
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)

            Text("\(fieldName) · \(assigneeName)")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.muted)
                .lineLimit(1)

            HStack(spacing: 6) {
                StatusChip(text: job.dueLabel,
                           tint: job.isLate ? AppTheme.clay : AppTheme.paddy,
                           symbolName: "calendar")

                if job.priority == .high && !job.status.isDone {
                    StatusChip(text: "High priority", tint: AppTheme.clay, symbolName: "flag.fill")
                }

                if job.status == .started {
                    StatusChip(text: "Started", tint: AppTheme.husk)
                }
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(job.status.isDone ? 0.55 : 1)
    }
}

// MARK: - Status Circle

/// The tappable circle that marks a job done. Drawn but inert for the owner.
struct JobStatusCircle: View {

    let status: JobStatus
    var canTap: Bool = true
    var onTap: () -> Void = {}

    var body: some View {
        Group {
            if canTap {
                Button(action: onTap) { circle }
                    .buttonStyle(.plain)
                    .accessibilityLabel(status.isDone ? "Mark as not done" : "Mark as done")
            } else {
                circle
            }
        }
    }

    private var circle: some View {
        Image(systemName: status.symbolName)
            .font(.system(size: 20))
            .foregroundStyle(status.tint)
            .frame(width: 26, height: 26)
            .contentShape(Rectangle())
    }
}

// MARK: - Complete Row

/// Circle plus content, for screens where the row itself is not a link.
struct JobRow: View {

    let job: FarmJob
    let fieldName: String
    let assigneeName: String
    var canFinish: Bool = true
    var onToggleDone: () -> Void = {}

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            JobStatusCircle(status: job.status, canTap: canFinish, onTap: onToggleDone)
            JobRowContent(job: job, fieldName: fieldName, assigneeName: assigneeName)
        }
        .padding(.vertical, 7)
    }
}

#Preview {
    VStack(spacing: 0) {
        JobRow(job: SampleFarmData.jobs[2],
               fieldName: "Sapang Bato Banana Rows",
               assigneeName: "R. Sarmiento")
        JobRow(job: SampleFarmData.jobs[6],
               fieldName: "Hilltop Corn Field",
               assigneeName: "E. Villamor")
    }
    .padding()
}
