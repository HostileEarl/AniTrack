//
//  AppRoute.swift
//  AniTrack — VIEW SUPPORT
//
//  Every pushed screen is named here, so navigation is driven by a value rather
//  than by nesting destinations inside links. Each tab's NavigationStack
//  registers the same destinations, which is why a field can be opened from the
//  dashboard, the field list or a job row and behave identically.
//
//  The final build adds cases here for field notes, supplies, the team, the map
//  and weather. Adding a case is a compile error until RouteDestination handles
//  it, which is the point: a screen cannot be half-connected.
//

import SwiftUI

enum AppRoute: Hashable {
    case field(Parcel)
    case alerts
}
