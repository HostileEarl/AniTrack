//
//  WorkerJobsView.swift
//  AniTrack — SCREEN: one person's jobs
//

import SwiftUI

struct WorkerJobsView: View {

    let workerID: String

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var data: FarmDataController
    @EnvironmentObject private var toasts: ToastController

    private var viewer: ViewerContext {
        return ViewerContext(user: auth.currentUser)
    }

    private var worker: Worker? {
        return data.worker(id: workerID)
    }

    /// Late first, then by due date.
    private var openJobs: [FarmJob] {
        return data.jobs
            .filter { $0.assigneeID == workerID && !$0.status.isDone }
            .sorted { left, right in
                if left.isLate != right.isLate { return left.isLate }
                return left.dueOn < right.dueOn
            }
    }

    private var finishedJobs: [FarmJob] {
        return data.jobs
            .filter { $0.assigneeID == workerID && $0.status.isDone }
            .sorted { $0.dueOn > $1.dueOn }
    }

    var body: some View {
        Group {
            if openJobs.isEmpty && finishedJobs.isEmpty {
                EmptyStateView(symbolName: "checklist",
                               title: "No jobs yet",
                               message: "\(worker?.shortName ?? "This person") has not been given any work.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.canvas)
            } else {
                List {
                    if !openJobs.isEmpty {
                        Section {
                            ForEach(openJobs) { job in
                                jobRow(job)
                            }
                        } header: {
                            Text("Still to do")
                                .font(.system(size: 12))
                                .textCase(nil)
                                .foregroundStyle(AppTheme.muted)
                        }
                    }

                    if !finishedJobs.isEmpty {
                        Section {
                            ForEach(finishedJobs) { job in
                                jobRow(job)
                            }
                        } header: {
                            Text("Finished")
                                .font(.system(size: 12))
                                .textCase(nil)
                                .foregroundStyle(AppTheme.muted)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .farmBackground()
            }
        }
        .navigationTitle(worker?.fullName ?? "Team member")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func jobRow(_ job: FarmJob) -> some View {
        JobRow(job: job,
               fieldName: data.parcelName(for: job.parcelID),
               assigneeName: worker?.shortName ?? "",
               canFinish: viewer.permissions.canFinishJobs,
               onToggleDone: {
                   let wasDone = job.status.isDone
                   data.toggleJobDone(job, by: viewer)
                   toasts.show(wasDone ? "Marked as not done" : "Job finished")
               })
    }
}

#Preview {
    NavigationStack {
        WorkerJobsView(workerID: "w1")
            .environmentObject(AuthController.previewSignedIn())
            .environmentObject(FarmDataController.preview)
            .environmentObject(ToastController())
    }
}
