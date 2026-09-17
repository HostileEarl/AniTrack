//
//  JobsView.swift
//  AniTrack — SCREEN 3
//
//  The segmented control holds view state only. Which jobs belong in each
//  segment is decided by the controller, so the counts on the segments and the
//  rows in the list can never disagree.
//

import SwiftUI

struct JobsView: View {

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var data: FarmDataController
    @EnvironmentObject private var toasts: ToastController

    @State private var filter: JobFilter = .today
    @State private var isAddingJob: Bool = false

    private var viewer: ViewerContext {
        return ViewerContext(user: auth.currentUser)
    }

    private var jobs: [FarmJob] {
        return data.jobs(filter: filter, for: viewer)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterPicker

                if jobs.isEmpty {
                    EmptyStateView(symbolName: emptySymbol,
                                   title: emptyTitle,
                                   message: emptyMessage)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    jobList
                }
            }
            .background(AppTheme.canvas)
            .navigationTitle("Jobs")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if viewer.permissions.isReadOnly {
                        ReadOnlyTag()
                    }
                    if viewer.permissions.canAddJobs {
                        Button {
                            isAddingJob = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add job")
                    }
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                RouteDestination(route: route)
            }
            .sheet(isPresented: $isAddingJob) {
                NewJobSheet()
            }
        }
    }

    // MARK: - Filter

    private var filterPicker: some View {
        Picker("Filter", selection: $filter) {
            ForEach(JobFilter.allCases) { option in
                Text(label(for: option)).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, AppTheme.screenPadding)
        .padding(.vertical, 10)
    }

    /// Adds a live count to each segment, e.g. "Late 1".
    private func label(for option: JobFilter) -> String {
        let count = data.jobCount(filter: option, for: viewer)
        return count > 0 ? "\(option.displayName) \(count)" : option.displayName
    }

    // MARK: - List

    private var jobList: some View {
        List {
            Section {
                ForEach(jobs) { job in
                    // The circle sits outside the link so both stay tappable.
                    HStack(alignment: .top, spacing: 10) {
                        JobStatusCircle(status: job.status,
                                        canTap: viewer.permissions.canFinishJobs,
                                        onTap: { finish(job) })
                            .padding(.top, 7)

                        NavigationLink(value: routeForField(of: job)) {
                            JobRowContent(job: job,
                                          fieldName: data.parcelName(for: job.parcelID),
                                          assigneeName: data.assigneeName(for: job))
                                .padding(.vertical, 7)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if viewer.permissions.canDeleteJobs {
                            Button(role: .destructive) {
                                data.deleteJob(job, by: viewer)
                                toasts.show("Job deleted")
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .swipeActions(edge: .leading) {
                        if viewer.permissions.canStartJobs && job.status == .notStarted {
                            Button {
                                data.startJob(job, by: viewer)
                                toasts.show("Marked as started")
                            } label: {
                                Label("Start", systemImage: "play.fill")
                            }
                            .tint(AppTheme.husk)
                        }
                    }
                }
            } header: {
                Text("\(jobs.count) \(jobs.count == 1 ? "job" : "jobs")")
                    .font(.system(size: 12))
                    .textCase(nil)
                    .foregroundStyle(AppTheme.muted)
            }
        }
        .listStyle(.insetGrouped)
        .farmBackground()
    }

    /// Tapping a job row opens the field it belongs to.
    private func routeForField(of job: FarmJob) -> AppRoute {
        let parcel = data.parcel(id: job.parcelID) ?? SampleFarmData.parcels[0]
        return .field(parcel)
    }

    private func finish(_ job: FarmJob) {
        let wasDone = job.status.isDone
        data.toggleJobDone(job, by: viewer)
        toasts.show(wasDone ? "Marked as not done" : "Job finished")
    }

    // MARK: - Empty State Copy

    private var emptySymbol: String {
        switch filter {
        case .today: return "sun.max"
        case .comingUp: return "calendar"
        case .late: return "checkmark.circle"
        case .done: return "tray"
        }
    }

    private var emptyTitle: String {
        switch filter {
        case .today: return "Nothing due today"
        case .comingUp: return "Nothing planned ahead"
        case .late: return "Nothing is late"
        case .done: return "No jobs finished yet"
        }
    }

    private var emptyMessage: String {
        switch filter {
        case .today: return "Add a job to plan the team's work for today."
        case .comingUp: return "Plan the next round of field work using the plus button."
        case .late: return "The team is on time across every field."
        case .done: return "Finished jobs will collect here once the team marks them done."
        }
    }
}

#Preview {
    JobsView()
        .environmentObject(AuthController.previewSignedIn())
        .environmentObject(FarmDataController.preview)
        .environmentObject(ToastController())
}
