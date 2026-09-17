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
        case .field(let parcel):
            FieldDetailView(parcel: parcel)
        case .alerts:
            AlertsView()
        }
    }
}
