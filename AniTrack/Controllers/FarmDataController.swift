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
//       trail, the offline queue and saving can never be forgotten at a call
//       site — they happen in one place.
//
//  SWIFTDATA AND MVC
//
//  This controller owns the ModelContext. No view in the app contains @Query or
//  touches ModelContext, which is deliberate: @Query is the usual SwiftData
//  pattern but it puts data access inside the view, and that is the one thing
//  MVC exists to prevent. Views call methods here exactly as they did before
//  SwiftData was introduced — not one view file changed when the storage did.
//
//  The published arrays are a read cache kept in step with the store by
//  `reload()`. The store on disk is the source of truth; the arrays are what
//  SwiftUI observes.
//

import Foundation
import Combine
import SwiftData

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

    /// The SwiftData store. Private on purpose — nothing outside this file may
    /// reach it, which is what keeps data access out of the view layer.
    private let context: ModelContext

    // MARK: - Initialisation

    init(context: ModelContext, persistence: PersistenceController = .shared) {
        self.context = context
        self.persistence = persistence

        self.parcels = []
        self.jobs = []
        self.harvests = []
        self.fieldNotes = []
        self.supplies = []
        self.stockMovements = []
        self.alerts = []
        self.activity = []
        self.workers = []
        self.pendingChanges = []
        self.lastBackedUpAt = Date()
        self.showAmountsInSacks = persistence.loadUseSacks()

        SampleFarmData.seedIfEmpty(into: context)
        reload()
    }

    // MARK: - Reading from the Store

    /// Pulls every collection out of SwiftData into the published arrays.
    /// Called once at launch and after each change, so the interface and the
    /// store can never drift apart.
    private func reload() {
        parcels = fetch(Parcel.self)
        jobs = fetch(FarmJob.self)
        harvests = fetch(HarvestRecord.self)
        fieldNotes = fetch(FieldNote.self)
        supplies = fetch(SupplyItem.self)
        stockMovements = fetch(StockMovement.self)
        alerts = fetch(FarmAlert.self)
        activity = fetch(ActivityEntry.self)
        workers = fetch(Worker.self)
    }

    private func fetch<T: PersistentModel>(_ type: T.Type) -> [T] {
        return (try? context.fetch(FetchDescriptor<T>())) ?? []
    }

    /// Writes pending changes to disk and refreshes the arrays. Every mutating
    /// method below ends here.
    private func commit() {
        do {
            try context.save()
        } catch {
            // A failed save must never crash the app. The interface keeps
            // working against what is in memory and the next save retries.
            print("AniTrack could not save: \(error.localizedDescription)")
        }
        reload()
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

    // MARK: - Weather

    /// Sample outlook. The weather screen states plainly that it is not live.
    var weatherDays: [WeatherDay] {
        return SampleFarmData.weatherDays
    }

    var weatherAdvice: String {
        return SampleFarmData.weatherAdvice
    }

    /// What the coming weather means for each field the viewer can see.
    func weatherImpacts(for viewer: ViewerContext) -> [FieldWeatherImpact] {
        return visibleParcels(for: viewer).map { parcel in
            FieldWeatherImpact(id: parcel.id,
                               fieldName: parcel.name,
                               advice: SampleFarmData.weatherImpact[parcel.id]
                                   ?? "Nothing to watch out for on this field.")
        }
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
        context.insert(job)
        record("Added job '\(clean)'", category: .jobs, by: viewer)
        commit()
    }

    /// Objects fetched from SwiftData are references, so changing a property
    /// changes the stored object directly. There is no array element to write
    /// back to, which is one thing reference types make simpler.
    func toggleJobDone(_ job: FarmJob, by viewer: ViewerContext) {
        let nowDone = !job.status.isDone
        job.status = nowDone ? .done : .notStarted
        if nowDone {
            record("Finished '\(job.title)'", category: .jobs, by: viewer)
            clearAlerts(relatedTo: job.id)
        }
        commit()
    }

    func startJob(_ job: FarmJob, by viewer: ViewerContext) {
        job.status = .started
        record("Started '\(job.title)'", category: .jobs, by: viewer)
        commit()
    }

    func deleteJob(_ job: FarmJob, by viewer: ViewerContext) {
        let title = job.title
        context.delete(job)
        record("Deleted job '\(title)'", category: .jobs, by: viewer)
        commit()
    }

    // MARK: - Field Changes

    func updateCondition(_ condition: FieldCondition, for parcel: Parcel, by viewer: ViewerContext) {
        guard parcel.condition != condition else { return }
        parcel.condition = condition
        record("Set \(parcel.name) to \(condition.displayName)", category: .fields, by: viewer)
        commit()
    }

    func advanceStage(for parcel: Parcel, by viewer: ViewerContext) {
        parcel.stage = parcel.stage.next
        record("Moved \(parcel.name) to \(parcel.stage.displayName)",
               category: .fields, by: viewer)
        commit()
    }

    func addParcel(_ parcel: Parcel, by viewer: ViewerContext) {
        context.insert(parcel)
        record("Added field '\(parcel.name)'", category: .fields, by: viewer)
        commit()
    }

    /// With reference types the caller has already changed the object, so this
    /// only needs to write the trail and save.
    func updateParcel(_ parcel: Parcel, by viewer: ViewerContext) {
        record("Changed field '\(parcel.name)'", category: .fields, by: viewer)
        commit()
    }

    /// Deleting a field also removes its jobs, harvests and notes. Those records
    /// have no meaning without the land they describe, so leaving them behind
    /// would put orphans in every total the app calculates.
    func deleteParcel(_ parcel: Parcel, by viewer: ViewerContext) {
        let parcelID = parcel.id
        let name = parcel.name

        for job in jobs where job.parcelID == parcelID { context.delete(job) }
        for harvest in harvests where harvest.parcelID == parcelID { context.delete(harvest) }
        for note in fieldNotes where note.parcelID == parcelID { context.delete(note) }
        context.delete(parcel)

        record("Deleted field '\(name)' and its records", category: .fields, by: viewer)
        commit()
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
        context.insert(record)
        let name = parcelName(for: parcelID)
        self.record("Wrote down harvest: \(name), \(Formatting.wholeNumber(kilograms)) kg \(crop.displayName)",
                    category: .harvest, by: viewer)
        commit()
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
        context.insert(note)

        let name = parcelName(for: parcelID)
        record("Sent field note: \(urgency.displayName), \(name)", category: .fields, by: viewer)

        // An urgent note is the crew telling the manager something is wrong, so
        // it both flags the field and raises an alert.
        if urgency == .urgent {
            parcel(id: parcelID)?.condition = .problem
            raiseAlert(kind: .urgentNote,
                       message: "Urgent field note from \(viewer.actorName) about \(name)",
                       relatedID: note.id,
                       destination: .fieldNotes)
        }
        commit()
    }

    func resolveFieldNote(_ note: FieldNote, by viewer: ViewerContext) {
        note.isResolved = true
        record("Marked a field note as fixed", category: .fields, by: viewer)
        clearAlerts(relatedTo: note.id)
        commit()
    }

    // MARK: - Supply Changes

    func recordStockMovement(itemID: String,
                             kind: StockMovementKind,
                             quantity: Double,
                             parcelID: String?,
                             happenedOn: Date,
                             note: String,
                             by viewer: ViewerContext) {
        guard quantity > 0, let item = supplyItem(id: itemID) else { return }

        let wasRunningLow = item.isRunningLow
        let itemName = item.name
        let itemUnit = item.unit
        let movement = StockMovement(itemID: itemID,
                                     kind: kind,
                                     quantity: quantity,
                                     parcelID: parcelID,
                                     happenedOn: happenedOn,
                                     note: note,
                                     recordedByName: viewer.actorName)
        context.insert(movement)

        let change = kind == .added ? quantity : -quantity
        item.quantity = max(0, item.quantity + change)

        record("\(kind.displayName) \(Formatting.wholeNumber(quantity)) \(itemUnit) of \(itemName)",
               category: .supplies, by: viewer)

        // Only warn on the crossing, not on every movement while already low.
        if item.isRunningLow && !wasRunningLow {
            raiseAlert(kind: .runningLow,
                       message: "Running low: \(item.name) is at \(item.quantityLabel), below the warning level of \(Formatting.wholeNumber(item.warnBelow))",
                       relatedID: item.id,
                       destination: .supplies)
        }

        commit()
    }

    func updateWarningLevel(_ level: Double, for item: SupplyItem, by viewer: ViewerContext) {
        item.warnBelow = max(0, level)
        record("Changed the warning level for \(item.name)", category: .supplies, by: viewer)
        commit()
    }

    // MARK: - Alerts

    func raiseAlert(kind: AlertKind, message: String, relatedID: String?, destination: AlertDestination) {
        let alert = FarmAlert(kind: kind,
                              message: message,
                              relatedID: relatedID,
                              destination: destination,
                              raisedOn: Date(),
                              isRead: false)
        context.insert(alert)
        // No commit here: alerts are always raised from inside another change,
        // and that change's own commit saves this too.
    }

    func markAlertRead(_ alert: FarmAlert) {
        alert.isRead = true
        commit()
    }

    func markAllAlertsRead() {
        for alert in alerts { alert.isRead = true }
        commit()
    }

    func dismissAlert(_ alert: FarmAlert) {
        context.delete(alert)
        commit()
    }

    /// Removes alerts pointing at something that has just been dealt with.
    private func clearAlerts(relatedTo id: String) {
        for alert in alerts where alert.relatedID == id {
            context.delete(alert)
        }
    }

    // MARK: - Activity and Backup

    /// Every change routes through here, which is what keeps the trail complete.
    private func record(_ summary: String, category: ActivityCategory, by viewer: ViewerContext) {
        let entry = ActivityEntry(happenedOn: Date(),
                                  actorName: viewer.actorName,
                                  summary: summary,
                                  category: category)
        context.insert(entry)

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

    /// Size of the SwiftData store file on disk.
    func storageSizeLabel() -> String {
        guard let url = context.container.configurations.first?.url,
              let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
            return "Not known yet"
        }
        if size < 1024 { return "\(size) bytes" }
        let kilobytes = Double(size) / 1024
        if kilobytes < 1024 { return String(format: "%.0f KB", kilobytes) }
        return String(format: "%.1f MB", kilobytes / 1024)
    }

    /// Empties the store and puts the sample farm back.
    func resetToSampleData() {
        for parcel in parcels { context.delete(parcel) }
        for job in jobs { context.delete(job) }
        for harvest in harvests { context.delete(harvest) }
        for note in fieldNotes { context.delete(note) }
        for item in supplies { context.delete(item) }
        for movement in stockMovements { context.delete(movement) }
        for alert in alerts { context.delete(alert) }
        for entry in activity { context.delete(entry) }
        for worker in workers { context.delete(worker) }

        try? context.save()

        SampleFarmData.seedIfEmpty(into: context)
        reload()

        pendingChanges = []
        lastBackedUpAt = Date()
        showAmountsInSacks = false
        persistence.saveUseSacks(false)
    }
}

// MARK: - Preview Support

extension FarmDataController {

    /// A controller backed by a store held only in memory, so previews and
    /// tests never touch the real database on disk.
    static var preview: FarmDataController {
        let container = try! ModelContainer(
            for: Parcel.self, FarmJob.self, HarvestRecord.self, FieldNote.self,
            SupplyItem.self, StockMovement.self, FarmAlert.self,
            ActivityEntry.self, Worker.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return FarmDataController(context: ModelContext(container),
                                  persistence: .inMemory)
    }
}
