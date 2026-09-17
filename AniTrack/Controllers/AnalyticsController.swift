//
//  AnalyticsController.swift
//  AniTrack — CONTROLLER LAYER
//
//  Every figure the app displays is calculated here, so no view body ever does
//  arithmetic on model data.
//
//  It is a struct rather than an ObservableObject on purpose: it holds a
//  snapshot of the data and owns no state, which keeps the observation graph to
//  a single object and makes every metric testable by handing it fixed arrays.
//

import Foundation

// MARK: - Supporting Types

struct ParcelYield: Identifiable, Hashable {
    let id: String
    let parcelName: String
    let cropName: String
    let kilograms: Double
    let hectares: Double

    /// Kilos per hectare, so a big field does not look better simply for being big.
    var perHectare: Double {
        guard hectares > 0 else { return 0 }
        return kilograms / hectares
    }
}

struct HarvestMonthGroup: Identifiable, Hashable {
    let id: Int
    let title: String
    let records: [HarvestRecord]
    let totalKilograms: Double
}

struct CropShare: Identifiable, Hashable {
    let id: String
    let cropName: String
    let kilograms: Double
    let share: Double
}

struct MonthlyPoint: Identifiable, Hashable {
    let id: Int
    let label: String
    let kilograms: Double
}

struct ActivityDayGroup: Identifiable, Hashable {
    let id: String
    let title: String
    let entries: [ActivityEntry]
}

// MARK: - Controller

struct AnalyticsController {

    private let parcels: [Parcel]
    private let jobs: [FarmJob]
    private let harvests: [HarvestRecord]
    private let supplies: [SupplyItem]
    private let movements: [StockMovement]

    /// Built from what the viewer is allowed to see, so a team leader's numbers
    /// describe their own work rather than the whole farm.
    ///
    /// Marked @MainActor because it reads state owned by FarmDataController,
    /// which is main-actor isolated. Views are already on the main actor, so
    /// this costs nothing at the call site.
    @MainActor
    init(data: FarmDataController, viewer: ViewerContext) {
        self.parcels = data.visibleParcels(for: viewer)
        self.jobs = data.visibleJobs(for: viewer)
        self.harvests = data.visibleHarvests(for: viewer)
        self.supplies = data.supplies
        self.movements = data.stockMovements
    }

    // MARK: - Headline Figures

    var plantedFieldCount: Int {
        return parcels.filter { $0.stage.isPlanted }.count
    }

    var totalFieldCount: Int {
        return parcels.count
    }

    var hectaresPlanted: Double {
        return parcels
            .filter { $0.stage.isPlanted }
            .reduce(0) { $0 + $1.areaHectares }
    }

    var hectaresPlantedLabel: String {
        return Formatting.hectares(hectaresPlanted)
    }

    var jobsDueTodayCount: Int {
        return jobs.filter { $0.isDueToday && !$0.status.isDone }.count
    }

    var lateJobCount: Int {
        return jobs.filter { $0.isLate }.count
    }

    var harvestThisMonth: Double {
        return harvests
            .filter { $0.harvestedOn >= Date.startOfThisMonth }
            .reduce(0) { $0 + $1.kilograms }
    }

    var totalHarvest: Double {
        return harvests.reduce(0) { $0 + $1.kilograms }
    }

    var jobsDoneRatio: Double {
        guard !jobs.isEmpty else { return 0 }
        let done = jobs.filter { $0.status.isDone }.count
        return Double(done) / Double(jobs.count)
    }

    var jobsDonePercentLabel: String {
        return Formatting.percent(jobsDoneRatio)
    }

    // MARK: - Attention Lists

    var fieldsNeedingAttention: [Parcel] {
        return parcels
            .filter { $0.condition.needsAttention }
            .sorted { $0.condition.severityRank < $1.condition.severityRank }
    }

    var jobsDueToday: [FarmJob] {
        return jobs
            .filter { $0.isDueToday && !$0.status.isDone }
            .sorted { $0.priority.severityRank < $1.priority.severityRank }
    }

    var lateJobs: [FarmJob] {
        return jobs
            .filter { $0.isLate }
            .sorted { $0.dueOn < $1.dueOn }
    }

    // MARK: - Harvest by Field

    var harvestByField: [ParcelYield] {
        let grouped = Dictionary(grouping: harvests, by: { $0.parcelID })
        return grouped
            .compactMap { parcelID, records -> ParcelYield? in
                guard let parcel = parcels.first(where: { $0.id == parcelID }) else { return nil }
                let total = records.reduce(0) { $0 + $1.kilograms }
                return ParcelYield(id: parcel.id,
                                   parcelName: parcel.name,
                                   cropName: parcel.crop.displayName,
                                   kilograms: total,
                                   hectares: parcel.areaHectares)
            }
            .sorted { $0.kilograms > $1.kilograms }
    }

    var highestFieldHarvest: Double {
        return harvestByField.first?.kilograms ?? 0
    }

    var bestFieldName: String {
        return harvestByField.first?.parcelName ?? "No records yet"
    }

    /// How wide a comparison bar should be, from 0 to 1.
    func barRatio(for kilograms: Double) -> Double {
        guard highestFieldHarvest > 0 else { return 0 }
        return kilograms / highestFieldHarvest
    }

    // MARK: - Month Grouping

    var harvestsByMonth: [HarvestMonthGroup] {
        let grouped = Dictionary(grouping: harvests, by: { $0.monthKey })
        return grouped
            .map { key, records -> HarvestMonthGroup in
                let sorted = records.sorted { $0.harvestedOn > $1.harvestedOn }
                return HarvestMonthGroup(id: key,
                                         title: sorted.first?.monthTitle ?? "",
                                         records: sorted,
                                         totalKilograms: sorted.reduce(0) { $0 + $1.kilograms })
            }
            .sorted { $0.id > $1.id }
    }

    // MARK: - Reports

    func records(in period: ReportPeriod) -> [HarvestRecord] {
        return harvests.filter { $0.harvestedOn.isWithin(period) }
    }

    func totalHarvest(in period: ReportPeriod) -> Double {
        return records(in: period).reduce(0) { $0 + $1.kilograms }
    }

    func harvestCount(in period: ReportPeriod) -> Int {
        return records(in: period).count
    }

    /// Hectares of the fields that produced a harvest in the period, counted once each.
    func hectaresHarvested(in period: ReportPeriod) -> Double {
        let ids = Set(records(in: period).map(\.parcelID))
        return parcels
            .filter { ids.contains($0.id) }
            .reduce(0) { $0 + $1.areaHectares }
    }

    func jobsDoneRatio(in period: ReportPeriod) -> Double {
        let inPeriod = jobs.filter { $0.dueOn.isWithin(period) }
        guard !inPeriod.isEmpty else { return 0 }
        let done = inPeriod.filter { $0.status.isDone }.count
        return Double(done) / Double(inPeriod.count)
    }

    func harvestByField(in period: ReportPeriod) -> [ParcelYield] {
        let grouped = Dictionary(grouping: records(in: period), by: { $0.parcelID })
        return grouped
            .compactMap { parcelID, records -> ParcelYield? in
                guard let parcel = parcels.first(where: { $0.id == parcelID }) else { return nil }
                return ParcelYield(id: parcel.id,
                                   parcelName: parcel.name,
                                   cropName: parcel.crop.displayName,
                                   kilograms: records.reduce(0) { $0 + $1.kilograms },
                                   hectares: parcel.areaHectares)
            }
            .sorted { $0.kilograms > $1.kilograms }
    }

    func cropShares(in period: ReportPeriod) -> [CropShare] {
        let periodRecords = records(in: period)
        let total = periodRecords.reduce(0) { $0 + $1.kilograms }
        guard total > 0 else { return [] }
        let grouped = Dictionary(grouping: periodRecords, by: { $0.crop })
        return grouped
            .map { crop, list -> CropShare in
                let amount = list.reduce(0) { $0 + $1.kilograms }
                return CropShare(id: crop.rawValue,
                                 cropName: crop.displayName,
                                 kilograms: amount,
                                 share: amount / total)
            }
            .sorted { $0.kilograms > $1.kilograms }
    }

    /// Best and worst fields by kilos per hectare, ignoring fields with no harvest.
    func bestAndWorstPerHectare(in period: ReportPeriod) -> (best: ParcelYield?, worst: ParcelYield?) {
        let ranked = harvestByField(in: period)
            .filter { $0.hectares > 0 && $0.kilograms > 0 }
            .sorted { $0.perHectare > $1.perHectare }
        guard ranked.count > 1 else { return (ranked.first, nil) }
        return (ranked.first, ranked.last)
    }

    /// The last six months of harvest amounts, oldest first, for the trend line.
    var lastSixMonths: [MonthlyPoint] {
        let calendar = Calendar.current
        var points: [MonthlyPoint] = []
        for offset in stride(from: 5, through: 0, by: -1) {
            guard let monthStart = calendar.date(byAdding: .month, value: -offset, to: Date.startOfThisMonth),
                  let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { continue }
            let total = harvests
                .filter { $0.harvestedOn >= monthStart && $0.harvestedOn < monthEnd }
                .reduce(0) { $0 + $1.kilograms }
            let parts = calendar.dateComponents([.year, .month], from: monthStart)
            let key = ((parts.year ?? 0) * 100) + (parts.month ?? 0)
            points.append(MonthlyPoint(id: key,
                                       label: monthStart.formatted(.dateTime.month(.abbreviated)),
                                       kilograms: total))
        }
        return points
    }

    var highestMonthlyAmount: Double {
        return lastSixMonths.map(\.kilograms).max() ?? 0
    }

    // MARK: - Operating Costs

    /// What the supplies used in the period cost the farm. Costs only, never sales.
    func supplyCost(in period: ReportPeriod) -> Double {
        return movements
            .filter { $0.kind == .used && $0.happenedOn.isWithin(period) }
            .reduce(0) { running, movement in
                let unitCost = supplies.first { $0.id == movement.itemID }?.unitCost ?? 0
                return running + (movement.quantity * unitCost)
            }
    }

    func supplyCostPerHectare(in period: ReportPeriod) -> Double {
        let hectares = hectaresPlanted
        guard hectares > 0 else { return 0 }
        return supplyCost(in: period) / hectares
    }
}

// MARK: - Activity Grouping

extension AnalyticsController {

    /// Groups activity into Today, Yesterday, then dated sections.
    static func groupByDay(_ entries: [ActivityEntry]) -> [ActivityDayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.happenedOn)
        }
        return grouped
            .map { day, list -> ActivityDayGroup in
                let title: String
                if calendar.isDateInToday(day) {
                    title = "Today"
                } else if calendar.isDateInYesterday(day) {
                    title = "Yesterday"
                } else {
                    title = day.formatted(.dateTime.day().month(.wide).year())
                }
                return ActivityDayGroup(id: ISO8601DateFormatter().string(from: day),
                                        title: title,
                                        entries: list.sorted { $0.happenedOn > $1.happenedOn })
            }
            .sorted { left, right in
                let leftDate = left.entries.first?.happenedOn ?? .distantPast
                let rightDate = right.entries.first?.happenedOn ?? .distantPast
                return leftDate > rightDate
            }
    }
}
