//
//  ProfileView.swift
//  AniTrack — SCREEN: profile
//
//  The three figures at the bottom are counted live by the controller, so they
//  can never disagree with the fields and jobs screens.
//

import SwiftUI

struct ProfileView: View {

    @EnvironmentObject private var auth: AuthController
    @EnvironmentObject private var data: FarmDataController

    private var viewer: ViewerContext {
        return ViewerContext(user: auth.currentUser)
    }

    var body: some View {
        ScrollView {
            if let user = auth.currentUser {
                VStack(alignment: .leading, spacing: AppTheme.sectionSpacing) {
                    header(for: user)
                    detailsCard(for: user)
                    statsCard(for: user)
                    accountSystemCard
                }
                .padding(.horizontal, AppTheme.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .background(AppTheme.canvas)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(value: AppRoute.editProfile) {
                    Text("Edit")
                        .font(.system(size: 15, weight: .medium))
                }
            }
        }
    }

    // MARK: - Header

    private func header(for user: FarmUser) -> some View {
        VStack(spacing: 12) {
            Circle()
                .fill(AppTheme.paddy)
                .frame(width: 84, height: 84)
                .overlay(
                    Text(user.initials)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white)
                )

            Text(user.fullName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppTheme.ink)

            RoleTag(role: user.role)

            Text(user.role.summary)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Details

    private func detailsCard(for user: FarmUser) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Details")

            row(symbol: "envelope.fill", label: "Email", value: user.email)
            Divider().overlay(AppTheme.hairline)
            row(symbol: "phone.fill", label: "Mobile",
                value: user.mobile.isEmpty ? "Not set" : user.mobile)
            Divider().overlay(AppTheme.hairline)
            row(symbol: "leaf.fill", label: "Farm", value: user.farmName)
            Divider().overlay(AppTheme.hairline)
            row(symbol: "mappin.circle.fill", label: "Place", value: user.municipality)
            Divider().overlay(AppTheme.hairline)
            row(symbol: "calendar", label: "Joined",
                value: user.memberSince.formatted(.dateTime.month(.wide).year()))
        }
        .cardSurface()
    }

    // MARK: - Stats

    private func statsCard(for user: FarmUser) -> some View {
        let fieldsLed = user.workerID.map { data.parcelsLed(byWorker: $0).count } ?? data.parcels.count
        let openJobs = user.workerID.map { data.openJobCount(forWorker: $0) }
            ?? data.jobs.filter { !$0.status.isDone }.count
        let harvests = user.workerID
            .map { id in data.harvests.filter { $0.recordedByID == id }.count }
            ?? data.harvests.count

        return VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Your work")

            HStack(spacing: 12) {
                stat(value: "\(fieldsLed)", label: fieldsLed == 1 ? "Field" : "Fields")
                stat(value: "\(openJobs)", label: "Jobs left")
                stat(value: "\(harvests)", label: "Harvests")
            }
        }
        .cardSurface()
    }

    // MARK: - Account System

    private var accountSystemCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Account")

            HStack {
                Text("Accounts kept")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                StatusChip(text: auth.providerName,
                           tint: auth.isUsingRemoteAccounts ? AppTheme.paddy : AppTheme.husk,
                           symbolName: auth.isUsingRemoteAccounts ? "icloud.fill" : "iphone")
            }

            Text(auth.isUsingRemoteAccounts
                 ? "Your account is kept on a server, so you can log in from another phone."
                 : "Your account is kept on this phone only.")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cardSurface()
    }

    // MARK: - Pieces

    private func row(symbol: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.shoot)
                .frame(width: 22)
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.muted)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.paddy)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppTheme.paddy.opacity(0.05))
        )
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AuthController.previewSignedIn())
            .environmentObject(FarmDataController.preview)
    }
}
