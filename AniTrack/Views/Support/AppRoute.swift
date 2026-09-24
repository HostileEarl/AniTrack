//
//  AppRoute.swift
//  AniTrack — VIEW SUPPORT
//
//  Every pushed screen is named here, so navigation is driven by a value rather
//  than by nesting destinations inside links.
//
//  Routes carry identifiers rather than model objects. Since the move to
//  SwiftData the models are classes, and a route holding an object could still
//  be pointing at something that has since been deleted. An id is looked up
//  fresh each time the screen is built, so a deleted record simply shows as
//  missing instead of crashing.
//

import SwiftUI

enum AppRoute: Hashable {
    case field(String)
    case alerts

    case fieldNotes
    case fieldNote(String)

    case supplies
    case supplyItem(String)

    case team
    case workerJobs(String)

    case map
    case weather

    case reports
    case profile
    case editProfile
    case changePassword
    case settings
    case backup
    case activity
}
