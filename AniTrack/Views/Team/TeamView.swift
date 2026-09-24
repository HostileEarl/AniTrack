//
//  TeamView.swift
//  AniTrack — SCREEN: the team
//
//  Each card's workload is counted live by the controller, so it can never
//  drift from the job list.
//

import SwiftUI

struct TeamView: View {

    @EnvironmentObject private var data: FarmDataController

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(data.workers) { worker in
                    NavigationLink(value: AppRoute.workerJobs(worker.id)) {
                        card(for: worker)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.screenPadding)
            .padding(.vertical, 12)
        }
        .background(AppTheme.canvas)
        .navigationTitle("Team")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Card

    private func card(for worker: Worker) -> some View {
        let openJobs = data.openJobCount(forWorker: worker.id)
        let fields = data.parcelsLed(byWorker: worker.id)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(AppTheme.paddy)
                    .frame(width: 46, height: 46)
                    .overlay(
                        Text(worker.initials)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(worker.fullName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.ink)
                    Text(worker.role.displayName)
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.muted)
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(openJobs)")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(openJobs > 0 ? AppTheme.paddy : AppTheme.muted)
                    Text(openJobs == 1 ? "job left" : "jobs left")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.muted)
                }
            }

            Divider().overlay(AppTheme.hairline)

            HStack(spacing: 16) {
                detail(symbol: "phone.fill", text: worker.contactNumber)
                detail(symbol: "house.fill", text: worker.homeBarangay)
            }

            if fields.isEmpty {
                Text("Does not lead any field.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.muted)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Leads")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.muted)
                    Text(fields.map(\.name).joined(separator: ", "))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .cardSurface()
    }

    private func detail(symbol: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.shoot)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.ink.opacity(0.75))
        }
    }
}

#Preview {
    NavigationStack {
        TeamView()
            .environmentObject(FarmDataController.preview)
    }
}
