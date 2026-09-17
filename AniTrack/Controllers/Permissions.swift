//
//  Permissions.swift
//  AniTrack — CONTROLLER LAYER
//
//  What the signed-in role is allowed to do. Views ask these questions and skip
//  rendering the control entirely when the answer is no. Nothing is merely
//  greyed out: a control the user cannot use is a control that should not be on
//  screen at all.
//

import Foundation

struct Permissions {

    let role: AccountRole

    init(role: AccountRole?) {
        self.role = role ?? .farmManager
    }

    // MARK: - Role Tests

    var isManager: Bool { role == .farmManager }
    var isTeamLeader: Bool { role == .teamLeader }
    var isOwner: Bool { role == .owner }

    /// The owner can look at everything and change nothing.
    var isReadOnly: Bool { role == .owner }

    // MARK: - Fields

    var canAddFields: Bool { isManager }
    var canEditFields: Bool { isManager }
    var canDeleteFields: Bool { isManager }
    var canChangeFieldCondition: Bool { !isOwner }
    var canAdvanceStage: Bool { !isOwner }

    // MARK: - Jobs

    var canAddJobs: Bool { isManager }
    var canFinishJobs: Bool { !isOwner }
    var canStartJobs: Bool { !isOwner }
    var canDeleteJobs: Bool { isManager }

    // MARK: - Records

    var canRecordHarvest: Bool { !isOwner }
    var canSendFieldNotes: Bool { !isOwner }
    var canResolveFieldNotes: Bool { isManager }
    var canRecordStock: Bool { !isOwner }
    var canEditWarningLevels: Bool { isManager }

    // MARK: - Screens

    var canSeeSupplies: Bool { !isTeamLeader }
    var canSeeSettings: Bool { !isOwner }
    var canSeeAllTeamWork: Bool { isManager }

    /// A team leader only sees their own fields and jobs.
    var seesOnlyOwnWork: Bool { isTeamLeader }

    /// Shown as the home screen title.
    var homeTitle: String {
        return isTeamLeader ? "My work" : "Dashboard"
    }
}
