//
//  RouteDestination.swift
//  AniTrack — VIEW SUPPORT
//
//  Turns a route value into the screen it names. Every tab registers this one
//  destination, so a screen opens the same way from anywhere in the app.
//

import SwiftUI

struct RouteDestination: View {

    let route: AppRoute

    var body: some View {
        switch route {
        case .field(let id):
            FieldDetailView(parcelID: id)
        case .alerts:
            AlertsView()
        case .fieldNotes:
            FieldNotesView()
        case .fieldNote(let id):
            FieldNoteDetailView(noteID: id)
        case .supplies:
            SuppliesView()
        case .supplyItem(let id):
            SupplyItemDetailView(itemID: id)
        case .team:
            TeamView()
        case .workerJobs(let id):
            WorkerJobsView(workerID: id)
        case .map:
            FieldMapView()
        case .weather:
            WeatherView()
        case .reports:
            ReportsView()
        case .profile:
            ProfileView()
        case .editProfile:
            EditProfileView()
        case .changePassword:
            ChangePasswordView()
        case .settings:
            SettingsView()
        case .backup:
            BackupView()
        case .activity:
            ActivityView()
        }
    }
}
