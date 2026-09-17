//
//  FarmDataController.swift
//  AniTrack — CONTROLLER LAYER
//
//  The single source of truth for every model collection.
//
//  Two rules make the architecture hold:
//    1. Every collection is `@Published private(set)`, so a view that tries to
//       change one is a compile error rather than a matter of discipline.
//    2. Every change funnels through a method here, which is why the activity
//       trail, the offline queue and saving to disk can never be forgotten at
//       a call site — they happen in one place.
//

import Foundation
import Combine

// MARK: - Viewer Context

/// Who is looking, and what they may see. Passed into the read helpers so the
/// same controller serves a manager, a team leader and an owner correctly.
struct ViewerContext {
    let permissions: Permissions
    let workerID: String?
    let actorName: String

    init(user: FarmUser?) {
        self.permissions = Permissions(role: user?.role)
        self.workerID = user?.workerID
        self.actorName = user?.fullName ?? "Farm Manager"
    }

    static let manager = ViewerContext(user: nil)
}

// MARK: - Controller

@MainActor
final class FarmDataController: ObservableObject {

    // MARK: - Published State

    @Published private(set) var parcels: [Parcel]
    @Published private(set) var jobs: [FarmJob]
    @Published private(set) var harvests: [HarvestRecord]
    @Published private(set) var fieldNotes: [FieldNote]
    @Published private(set) var supplies: [SupplyItem]
    @Published private(set) var stockMovements: [StockMovement]
    @Published private(set) var alerts: [FarmAlert]
    @Published private(set) var activity: [ActivityEntry]
    @Published private(set) var pendingChanges: [PendingChange]

    @Published private(set) var workers: [Worker]
    @Published private(set) var lastBackedUpAt: Date
    @Published private(set) var isBackingUp: Bool = false
    @Published var isOffline: Bool = false
    @Published private(set) var showAmountsInSacks: Bool

    private let persistence: PersistenceController

    // MARK: - Initialisation

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        self.parcels = persistence.loadParcels() ?? SampleFarmData.parcels
        self.jobs = persistence.loadJobs() ?? SampleFarmData.jobs
        self.harvests = persistence.loadHarvests() ?? SampleFarmData.harvests
        self.fieldNotes = persistence.loadFieldNotes() ?? SampleFarmData.fieldNotes
        self.supplies = persistence.loadSupplies() ?? SampleFarmData.supplies
        self.stockMovements = persistence.loadStockMovements() ?? []
        self.alerts = persistence.loadAlerts() ?? SampleFarmData.alerts
        self.activity = persistence.loadActivity() ?? SampleFarmData.activity
        self.pendingChanges = []
        self.workers = SampleFarmData.workers
        self.lastBackedUpAt = Date()
        self.showAmountsInSacks = persistence.loadUseSacks()
    }

    // MARK: - Lookups

    func parcel(id: String?) -> Parcel? {
        guard let id = id else { return nil }
        return parcels.first { $0.id == id }
    }

    func worker(id: String?) -> Worker? {
        guard let id = id else { return nil }
        return workers.first { $0.id == id }
    }

    func supplyItem(id: String?) -> SupplyItem? {
        guard let id = id else { return nil }
        return supplies.first { $0.id == id }
    }

    func fieldNote(id: String?) -> FieldNote? {
        guard let id = id else { return nil }
        return fieldNotes.first { $0.id == id }
    }

    func job(id: String?) -> FarmJob? {
        guard let id = id else { return nil }
        return jobs.first { $0.id == id }
    }

    func parcelName(for id: String) -> String {
        return parcel(id: id)?.name ?? "Unknown field"
    }

    func assigneeName(for job: FarmJob) -> String {
        return worker(id: job.assigneeID)?.shortName ?? "Not assigned"
    }

    /// Formats an amount using the user's chosen unit.
    func amountLabel(_ kilograms: Double) -> String {
        return Formatting.amount(kilograms, inSacks: showAmountsInSacks)
    }

    // MARK: - Role-Aware Reads

    /// The fields this viewer is allowed to see. A team leader sees only theirs.
    func visibleParcels(for viewer: ViewerContext) -> [Parcel] {
        guard viewer.permissions.seesOnlyOwnWork, let workerID = viewer.workerID else {
            return parcels
        }
        return parcels.filter { $0.teamLeaderID == workerID }
    }

    /// The jobs this viewer is allowed to see.
    func visibleJobs(for viewer: ViewerContext) -> [FarmJob] {
        guard viewer.permissions.seesOnlyOwnWork, let workerID = viewer.workerID else {
            return jobs
        }
        return jobs.filter { $0.assigneeID == workerID }
    }

    func visibleHarvests(for viewer: ViewerContext) -> [HarvestRecord] {
        guard viewer.permissions.seesOnlyOwnWork else { return harvests }
        let allowed = Set(visibleParcels(for: viewer).map(\.id))
        return harvests.filter { allowed.contains($0.parcelID) }
    }

    func visibleFieldNotes(for viewer: ViewerContext) -> [FieldNote] {
        guard viewer.permissions.seesOnlyOwnWork else { return fieldNotes }
        let allowed = Set(visibleParcels(for: viewer).map(\.id))
        return fieldNotes.filter { allowed.contains($0.parcelID) }
    }

    // MARK: - Sorting and Searching

    /// Fields with problems first, then alphabetically.
    func sortedByUrgency(_ list: [Parcel]) -> [Parcel] {
        return list.sorted { left, right in
            if left.condition.severityRank != right.condition.severityRank {
                return left.condition.severityRank < right.condition.severityRank
            }
            return left.name < right.name
        }
    }

    func parcels(matching search: String, for viewer: ViewerContext) -> [Parcel] {
        let base = sortedByUrgency(visibleParcels(for: viewer))
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return base }
        return base.filter { parcel in
            parcel.name.localizedCaseInsensitiveContains(query)
                || parcel.barangay.localizedCaseInsensitiveContains(query)
                || parcel.municipality.localizedCaseInsensitiveContains(query)
                || parcel.crop.displayName.localizedCaseInsensitiveContains(query)
        }
    }

    func jobs(filter: JobFilter, for viewer: ViewerContext) -> [FarmJob] {
        let base = visibleJobs(for: viewer)
        let matching: [FarmJob]
        switch filter {
        case .today: matching = base.filter { $0.isDueToday && !$0.status.isDone }
        case .comingUp: matching = base.filter { $0.isComingUp }
        case .late: matching = base.filter { $0.isLate }
        case .done: matching = base.filter { $0.status.isDone }
        }
        return matching.sorted { left, right in
            if left.priority.severityRank != right.priority.severityRank {
                return left.priority.severityRank < right.priority.severityRank
            }
            return left.dueOn < right.dueOn
        }
    }

    func jobCount(filter: JobFilter, for viewer: ViewerContext) -> Int {
        return jobs(filter: filter, for: viewer).count
    }

    func openJobs(forParcel parcelID: String) -> [FarmJob] {
        return jobs
            .filter { $0.parcelID == parcelID && !$0.status.isDone }
            .sorted { $0.dueOn < $1.dueOn }
    }

    func openJobCount(forWorker workerID: String) -> Int {
        return jobs.filter { $0.assigneeID == workerID && !$0.status.isDone }.count
    }

    func parcelsLed(byWorker workerID: String) -> [Parcel] {
        return parcels.filter { $0.teamLeaderID == workerID }
    }

    func harvests(forParcel parcelID: String) -> [HarvestRecord] {
        return harvests
            .filter { $0.parcelID == parcelID }
            .sorted { $0.harvestedOn > $1.harvestedOn }
    }

    func notes(forParcel parcelID: String) -> [FieldNote] {
        return fieldNotes
            .filter { $0.parcelID == parcelID }
            .sorted { $0.filedOn > $1.filedOn }
    }

    func movements(forItem itemID: String) -> [StockMovement] {
        return stockMovements
            .filter { $0.itemID == itemID }
            .sorted { $0.happenedOn > $1.happenedOn }
    }

    var unreadAlertCount: Int {
        return alerts.filter { !$0.isRead }.count
    }

    var sortedAlerts: [FarmAlert] {
        return alerts.sorted { $0.raisedOn > $1.raisedOn }
    }

    var runningLowItems: [SupplyItem] {
        return supplies.filter { $0.isRunningLow }
    }

    // MARK: - Job Changes

    func addJob(title: String,
                details: String,
                parcelID: String,
                assigneeID: String?,
                dueOn: Date,
                priority: JobPriority,
                by viewer: ViewerContext) {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        let job = FarmJob(title: clean,
                          details: details.trimmingCharacters(in: .whitespacesAndNewlines),
                          parcelID: parcelID,
                          assigneeID: assigneeID,
                          dueOn: dueOn,
                          status: .notStarted,
                          priority: priority)
        jobs.append(job)
        record("Added job '\(clean)'", category: .jobs, by: viewer)
        persistence.saveJobs(jobs)
    }

    func toggleJobDone(_ job: FarmJob, by viewer: ViewerContext) {
        guard let index = jobs.firstIndex(where: { $0.id == job.id }) else { return }
        let nowDone = !jobs[index].status.isDone
        jobs[index].status = nowDone ? .done : .notStarted
        if nowDone {
            record("Finished '\(jobs[index].title)'", category: .jobs, by: viewer)
            clearAlerts(relatedTo: job.id)
        }
        persistence.saveJobs(jobs)
    }

    func startJob(_ job: FarmJob, by viewer: ViewerContext) {
        guard let index = jobs.firstIndex(where: { $0.id == job.id }) else { return }
        jobs[index].status = .started
        record("Started '\(jobs[index].title)'", category: .jobs, by: viewer)
        persistence.saveJobs(jobs)
    }

    func deleteJob(_ job: FarmJob, by viewer: ViewerContext) {
        jobs.removeAll { $0.id == job.id }
        record("Deleted job '\(job.title)'", category: .jobs, by: viewer)
        persistence.saveJobs(jobs)
    }

    // MARK: - Field Changes

    func updateCondition(_ condition: FieldCondition, for parcel: Parcel, by viewer: ViewerContext) {
        guard let index = parcels.firstIndex(where: { $0.id == parcel.id }) else { return }
        guard parcels[index].condition != condition else { return }
        parcels[index].condition = condition
        record("Set \(parcel.name) to \(condition.displayName)", category: .fields, by: viewer)
        persistence.saveParcels(parcels)
    }

    func advanceStage(for parcel: Parcel, by viewer: ViewerContext) {
        guard let index = parcels.firstIndex(where: { $0.id == parcel.id }) else { return }
        parcels[index].stage = parcels[index].stage.next
        record("Moved \(parcel.name) to \(parcels[index].stage.displayName)",
               category: .fields, by: viewer)
        persistence.saveParcels(parcels)
    }

    func addParcel(_ parcel: Parcel, by viewer: ViewerContext) {
        parcels.append(parcel)
        record("Added field '\(parcel.name)'", category: .fields, by: viewer)
        persistence.saveParcels(parcels)
    }

    func updateParcel(_ parcel: Parcel, by viewer: ViewerContext) {
        guard let index = parcels.firstIndex(where: { $0.id == parcel.id }) else { return }
        parcels[index] = parcel
        record("Changed field '\(parcel.name)'", category: .fields, by: viewer)
        persistence.saveParcels(parcels)
    }

    /// Deleting a field also removes its jobs, harvests and notes. Those records
    /// have no meaning without the land they describe, so leaving them behind
    /// would put orphans in every total the app calculates.
    func deleteParcel(_ parcel: Parcel, by viewer: ViewerContext) {
        parcels.removeAll { $0.id == parcel.id }
        jobs.removeAll { $0.parcelID == parcel.id }
        harvests.removeAll { $0.parcelID == parcel.id }
        fieldNotes.removeAll { $0.parcelID == parcel.id }
        record("Deleted field '\(parcel.name)' and its records", category: .fields, by: viewer)
        persistence.saveParcels(parcels)
        persistence.saveJobs(jobs)
        persistence.saveHarvests(harvests)
        persistence.saveFieldNotes(fieldNotes)
    }

    // MARK: - Harvest Changes

    func addHarvest(parcelID: String,
                    crop: CropType,
                    harvestedOn: Date,
                    kilograms: Double,
                    quality: HarvestQuality,
                    recordedByID: String?,
                    remarks: String,
                    by viewer: ViewerContext) {
        guard kilograms > 0 else { return }
        let record = HarvestRecord(parcelID: parcelID,
                                   crop: crop,
                                   harvestedOn: harvestedOn,
                                   kilograms: kilograms,
                                   quality: quality,
                                   recordedByID: recordedByID,
                                   remarks: remarks)
        harvests.append(record)
        let name = parcelName(for: parcelID)
        self.record("Wrote down harvest: \(name), \(Formatting.wholeNumber(kilograms)) kg \(crop.displayName)",
                    category: .harvest, by: viewer)
        persistence.saveHarvests(harvests)
    }

    // MARK: - Field Note Changes

    func addFieldNote(parcelID: String,
                      urgency: NoteUrgency,
                      observation: String,
                      photoCount: Int,
                      notifyManager: Bool,
                      by viewer: ViewerContext) {
        let clean = observation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        let note = FieldNote(parcelID: parcelID,
                             reportedByName: viewer.actorName,
                             urgency: urgency,
                             observation: clean,
                             photoCount: photoCount,
                             filedOn: Date(),
                             notifyManager: notifyManager)
        fieldNotes.insert(note, at: 0)

        let name = parcelName(for: parcelID)
        record("Sent field note: \(urgency.displayName), \(name)", category: .fields, by: viewer)

        // An urgent note is the crew telling the manager something is wrong, so
        // it both flags the field and raises an alert.
        if urgency == .urgent {
            if let index = parcels.firstIndex(where: { $0.id == parcelID }) {
                parcels[index].condition = .problem
                persistence.saveParcels(parcels)
            }
            raiseAlert(kind: .urgentNote,
                       message: "Urgent field note from \(viewer.actorName) about \(name)",
                       relatedID: note.id,
                       destination: .fieldNotes)
        }
        persistence.saveFieldNotes(fieldNotes)
    }

    func resolveFieldNote(_ note: FieldNote, by viewer: ViewerContext) {
        guard let index = fieldNotes.firstIndex(where: { $0.id == note.id }) else { return }
        fieldNotes[index].isResolved = true
        record("Marked a field note as fixed", category: .fields, by: viewer)
        clearAlerts(relatedTo: note.id)
        persistence.saveFieldNotes(fieldNotes)
    }

    // MARK: - Supply Changes

    func recordStockMovement(itemID: String,
                             kind: StockMovementKind,
                             quantity: Double,
                             parcelID: String?,
                             happenedOn: Date,
                             note: String,
                             by viewer: ViewerContext) {
        guard quantity > 0,
              let index = supplies.firstIndex(where: { $0.id == itemID }) else { return }

        let before = supplies[index]
        let movement = StockMovement(itemID: itemID,
                                     kind: kind,
                                     quantity: quantity,
                                     parcelID: parcelID,
                                     happenedOn: happenedOn,
                                     note: note,
                                     recordedByName: viewer.actorName)
        stockMovements.insert(movement, at: 0)

        let change = kind == .added ? quantity : -quantity
        supplies[index].quantity = max(0, before.quantity + change)
        let after = supplies[index]

        record("\(kind.displayName) \(Formatting.wholeNumber(quantity)) \(before.unit) of \(before.name)",
               category: .supplies, by: viewer)

        // Only warn on the crossing, not on every movement while already low.
        if after.isRunningLow && !before.isRunningLow {
            raiseAlert(kind: .runningLow,
                       message: "Running low: \(after.name) is at \(after.quantityLabel), below the warning level of \(Formatting.wholeNumber(after.warnBelow))",
                       relatedID: after.id,
                       destination: .supplies)
        }

        persistence.saveSupplies(supplies)
        persistence.saveStockMovements(stockMovements)
    }

    func updateWarningLevel(_ level: Double, for item: SupplyItem, by viewer: ViewerContext) {
        guard let index = supplies.firstIndex(where: { $0.id == item.id }) else { return }
        supplies[index].warnBelow = max(0, level)
        record("Changed the warning level for \(item.name)", category: .supplies, by: viewer)
        persistence.saveSupplies(supplies)
    }

    // MARK: - Alerts

    func raiseAlert(kind: AlertKind, message: String, relatedID: String?, destination: AlertDestination) {
        let alert = FarmAlert(kind: kind,
                              message: message,
                              relatedID: relatedID,
                              destination: destination,
                              raisedOn: Date(),
                              isRead: false)
        alerts.insert(alert, at: 0)
        persistence.saveAlerts(alerts)
    }

    func markAlertRead(_ alert: FarmAlert) {
        guard let index = alerts.firstIndex(where: { $0.id == alert.id }) else { return }
        alerts[index].isRead = true
        persistence.saveAlerts(alerts)
    }

    func markAllAlertsRead() {
        for index in alerts.indices {
            alerts[index].isRead = true
        }
        persistence.saveAlerts(alerts)
    }

    func dismissAlert(_ alert: FarmAlert) {
        alerts.removeAll { $0.id == alert.id }
        persistence.saveAlerts(alerts)
    }

    /// Removes alerts pointing at something that has just been dealt with.
    private func clearAlerts(relatedTo id: String) {
        alerts.removeAll { $0.relatedID == id }
        persistence.saveAlerts(alerts)
    }

    // MARK: - Activity and Backup

    /// Every change routes through here, which is what keeps the trail complete.
    private func record(_ summary: String, category: ActivityCategory, by viewer: ViewerContext) {
        let entry = ActivityEntry(happenedOn: Date(),
                                  actorName: viewer.actorName,
                                  summary: summary,
                                  category: category)
        activity.insert(entry, at: 0)
        persistence.saveActivity(activity)

        if isOffline {
            pendingChanges.insert(PendingChange(summary: summary), at: 0)
        }
    }

    func activity(in category: ActivityCategory?) -> [ActivityEntry] {
        let sorted = activity.sorted { $0.happenedOn > $1.happenedOn }
        guard let category = category else { return sorted }
        return sorted.filter { $0.category == category }
    }

    func backUpNow() async {
        isBackingUp = true
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        pendingChanges.removeAll()
        lastBackedUpAt = Date()
        isBackingUp = false
    }

    func setOffline(_ offline: Bool) {
        isOffline = offline
    }

    // MARK: - Settings

    func setShowAmountsInSacks(_ value: Bool) {
        showAmountsInSacks = value
        persistence.saveUseSacks(value)
    }

    var storedRecordCount: Int {
        return parcels.count + jobs.count + harvests.count
            + fieldNotes.count + supplies.count + stockMovements.count
    }

    func storageSizeLabel() -> String {
        let bytes = persistence.storageBytes()
        if bytes < 1024 { return "\(bytes) bytes" }
        let kilobytes = Double(bytes) / 1024
        return String(format: "%.1f KB", kilobytes)
    }

    /// Puts everything back to the sample data.
    func resetToSampleData() {
        persistence.eraseAll()
        parcels = SampleFarmData.parcels
        jobs = SampleFarmData.jobs
        harvests = SampleFarmData.harvests
        fieldNotes = SampleFarmData.fieldNotes
        supplies = SampleFarmData.supplies
        stockMovements = []
        alerts = SampleFarmData.alerts
        activity = SampleFarmData.activity
        pendingChanges = []
        lastBackedUpAt = Date()
        showAmountsInSacks = false
        persistence.saveUseSacks(false)
    }
}

// MARK: - Preview Support

extension FarmDataController {
    /// Sample data with no reading or writing to disk.
    static var preview: FarmDataController {
        return FarmDataController(persistence: .inMemory)
    }
}
