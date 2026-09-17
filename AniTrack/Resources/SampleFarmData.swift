//
//  SampleFarmData.swift
//  AniTrack — RESOURCES
//
//  Seed records, matching the Figma prototype exactly. Dates are offsets from
//  today so the app always looks current. Static properties are initialised
//  lazily in Swift, so later arrays can safely reference earlier IDs.
//

import Foundation

enum SampleFarmData {

    // MARK: - Team

    static let workers: [Worker] = [
        Worker(id: "w1", fullName: "Marilou Bautista", role: .teamLeader,
               contactNumber: "0917 555 0142", homeBarangay: "Sto. Niño"),
        Worker(id: "w2", fullName: "Ernesto Villamor", role: .cropTechnician,
               contactNumber: "0918 555 0177", homeBarangay: "Bantug"),
        Worker(id: "w3", fullName: "Dolores Pangilinan", role: .waterOperator,
               contactNumber: "0995 555 0208", homeBarangay: "Malabon"),
        Worker(id: "w4", fullName: "Rogelio Sarmiento", role: .harvestHand,
               contactNumber: "0906 555 0311", homeBarangay: "Sapang Bato")
    ]

    // MARK: - Fields

    static let parcels: [Parcel] = [
        Parcel(id: "p1", name: "Riverside Block A", barangay: "Sto. Niño",
               municipality: "Cabanatuan", areaHectares: 3.2, crop: .rice,
               stage: .maturing, condition: .good,
               plantedOn: .daysFromToday(-84), harvestDueOn: .daysFromToday(11),
               teamLeaderID: "w1",
               notes: "Second cropping. Water level steady after the last canal release.",
               latitude: 15.487, longitude: 120.967),
        Parcel(id: "p2", name: "Riverside Block B", barangay: "Sto. Niño",
               municipality: "Cabanatuan", areaHectares: 2.4, crop: .rice,
               stage: .flowering, condition: .watch,
               plantedOn: .daysFromToday(-61), harvestDueOn: .daysFromToday(32),
               teamLeaderID: "w1",
               notes: "Stem borer sighted along the eastern dike. Scouting twice weekly.",
               latitude: 15.491, longitude: 120.972),
        Parcel(id: "p3", name: "Hilltop Corn Field", barangay: "Bantug",
               municipality: "Cabanatuan", areaHectares: 4.6, crop: .corn,
               stage: .vegetative, condition: .good,
               plantedOn: .daysFromToday(-38), harvestDueOn: .daysFromToday(58),
               teamLeaderID: "w2",
               notes: "Side-dress fertilizer applied on schedule.",
               latitude: 15.502, longitude: 120.941),
        Parcel(id: "p4", name: "Malabon Vegetable Plot", barangay: "Malabon",
               municipality: "Zaragoza", areaHectares: 0.8, crop: .vegetables,
               stage: .readyForHarvest, condition: .good,
               plantedOn: .daysFromToday(-52), harvestDueOn: .daysFromToday(1),
               teamLeaderID: "w3",
               notes: "Ampalaya and sitaw rows. Pick early morning.",
               latitude: 15.451, longitude: 120.794),
        Parcel(id: "p5", name: "Sapang Bato Banana Rows", barangay: "Sapang Bato",
               municipality: "Zaragoza", areaHectares: 1.5, crop: .banana,
               stage: .maturing, condition: .problem,
               plantedOn: .daysFromToday(-190), harvestDueOn: .daysFromToday(-3),
               teamLeaderID: "w4",
               notes: "Yellowing confirmed on eight mats. Suspected Panama disease — isolate before replanting.",
               latitude: 15.443, longitude: 120.801),
        Parcel(id: "p6", name: "Lower Creek Lot", barangay: "Bantug",
               municipality: "Cabanatuan", areaHectares: 1.1, crop: .rice,
               stage: .fallow, condition: .good,
               plantedOn: .daysFromToday(-210), harvestDueOn: .daysFromToday(-120),
               teamLeaderID: "w2",
               notes: "Resting until the next wet season. Dikes repaired.",
               latitude: 15.498, longitude: 120.935)
    ]

    // MARK: - Jobs

    static let jobs: [FarmJob] = [
        FarmJob(id: "t1", title: "Scout for stem borer",
                details: "Walk the eastern dike and count damaged tillers per 10 hills.",
                parcelID: "p2", assigneeID: "w2", dueOn: .daysFromToday(0),
                status: .notStarted, priority: .high),
        FarmJob(id: "t2", title: "Open canal gate for watering",
                details: "Target 5 cm standing water, then close before dusk.",
                parcelID: "p1", assigneeID: "w3", dueOn: .daysFromToday(0),
                status: .started, priority: .normal),
        FarmJob(id: "t3", title: "Isolate affected banana mats",
                details: "Flag and rope off the eight yellowing mats. Do not move soil between rows.",
                parcelID: "p5", assigneeID: "w4", dueOn: .daysFromToday(-2),
                status: .notStarted, priority: .high),
        FarmJob(id: "t4", title: "Harvest ampalaya rows 1 to 4",
                details: "Start at 5:30 AM. Crates staged at the shed.",
                parcelID: "p4", assigneeID: "w1", dueOn: .daysFromToday(1),
                status: .notStarted, priority: .high),
        FarmJob(id: "t5", title: "Repair fence along the access road",
                details: "Two posts leaning after the storm.",
                parcelID: "p3", assigneeID: "w4", dueOn: .daysFromToday(4),
                status: .notStarted, priority: .low),
        FarmJob(id: "t6", title: "Book combine harvester slot",
                details: "Confirm the operator for the Riverside Block A window.",
                parcelID: "p1", assigneeID: "w1", dueOn: .daysFromToday(6),
                status: .notStarted, priority: .normal),
        FarmJob(id: "t7", title: "Apply side-dress fertilizer",
                details: "Second split application, 2 bags per hectare.",
                parcelID: "p3", assigneeID: "w2", dueOn: .daysFromToday(-6),
                status: .done, priority: .normal),
        FarmJob(id: "t8", title: "Clear drainage after heavy rain",
                details: "",
                parcelID: "p2", assigneeID: "w3", dueOn: .daysFromToday(-9),
                status: .done, priority: .normal)
    ]

    // MARK: - Harvests

    static let harvests: [HarvestRecord] = [
        HarvestRecord(id: "h1", parcelID: "p4", crop: .vegetables,
                      harvestedOn: .daysFromToday(-4), kilograms: 165,
                      quality: .best, recordedByID: "w3", remarks: "Ampalaya, first pick."),
        HarvestRecord(id: "h2", parcelID: "p5", crop: .banana,
                      harvestedOn: .daysFromToday(-7), kilograms: 420,
                      quality: .good, recordedByID: "w4", remarks: "Healthy mats only."),
        HarvestRecord(id: "h3", parcelID: "p4", crop: .vegetables,
                      harvestedOn: .daysFromToday(-12), kilograms: 138,
                      quality: .good, recordedByID: "w3", remarks: ""),
        HarvestRecord(id: "h4", parcelID: "p1", crop: .rice,
                      harvestedOn: .daysFromToday(-38), kilograms: 12_400,
                      quality: .best, recordedByID: "w1",
                      remarks: "First cropping, dried to 14% moisture."),
        HarvestRecord(id: "h5", parcelID: "p2", crop: .rice,
                      harvestedOn: .daysFromToday(-45), kilograms: 8_950,
                      quality: .good, recordedByID: "w1",
                      remarks: "Lodging on the low corner reduced the amount."),
        HarvestRecord(id: "h6", parcelID: "p3", crop: .corn,
                      harvestedOn: .daysFromToday(-52), kilograms: 15_600,
                      quality: .best, recordedByID: "w2", remarks: "")
    ]

    // MARK: - Field Notes

    static let fieldNotes: [FieldNote] = [
        FieldNote(id: "fr1", parcelID: "p5", reportedByName: "Rogelio Sarmiento",
                  urgency: .urgent,
                  observation: "The yellow leaves spread to two more plants since Monday. The lower leaves are drying up. We should stop moving tools between rows.",
                  photoCount: 3, filedOn: .daysFromToday(-3), notifyManager: true),
        FieldNote(id: "fr2", parcelID: "p2", reportedByName: "Ernesto Villamor",
                  urgency: .watch,
                  observation: "Counted 6 damaged tillers per 10 hills on the east side. That is more than the limit. Asking if we can spray.",
                  photoCount: 2, filedOn: .daysFromToday(-1), notifyManager: true),
        FieldNote(id: "fr3", parcelID: "p1", reportedByName: "Dolores Pangilinan",
                  urgency: .normal,
                  observation: "Water came through the canal. Level is 5 cm across the field.",
                  photoCount: 0, filedOn: .daysFromToday(0)),
        FieldNote(id: "fr4", parcelID: "p4", reportedByName: "Marilou Bautista",
                  urgency: .normal,
                  observation: "Ampalaya is ready. Crates are at the shed for tomorrow's picking.",
                  photoCount: 1, filedOn: .daysFromToday(-2)),
        FieldNote(id: "fr5", parcelID: "p3", reportedByName: "Ernesto Villamor",
                  urgency: .normal,
                  observation: "Side-dress fertilizer is done. Spread evenly, nothing washed away.",
                  photoCount: 0, filedOn: .daysFromToday(-6))
    ]

    // MARK: - Supplies

    static let supplies: [SupplyItem] = [
        SupplyItem(id: "i1", name: "Urea 46-0-0", category: .fertilizer,
                   quantity: 8, unit: "bags", warnBelow: 10, unitCost: 1_650),
        SupplyItem(id: "i2", name: "Complete 14-14-14", category: .fertilizer,
                   quantity: 24, unit: "bags", warnBelow: 10, unitCost: 1_800),
        SupplyItem(id: "i3", name: "Certified rice seed", category: .seed,
                   quantity: 3, unit: "bags", warnBelow: 5, unitCost: 2_400),
        SupplyItem(id: "i4", name: "Hybrid corn seed", category: .seed,
                   quantity: 12, unit: "bags", warnBelow: 5, unitCost: 3_200),
        SupplyItem(id: "i5", name: "Diesel", category: .fuel,
                   quantity: 140, unit: "liters", warnBelow: 100, unitCost: 62),
        SupplyItem(id: "i6", name: "Knapsack sprayer", category: .tools,
                   quantity: 4, unit: "pieces", warnBelow: 2, unitCost: 1_950)
    ]

    // MARK: - Alerts

    static let alerts: [FarmAlert] = [
        FarmAlert(id: "al1", kind: .urgentNote,
                  message: "Urgent field note: banana leaves yellowing at Sapang Bato Banana Rows",
                  relatedID: "fr1", destination: .fieldNotes,
                  raisedOn: .daysFromToday(-3), isRead: false),
        FarmAlert(id: "al2", kind: .jobLate,
                  message: "Job is late: Isolate affected banana mats, 2 days late",
                  relatedID: "t3", destination: .jobs,
                  raisedOn: .daysFromToday(-2), isRead: false),
        FarmAlert(id: "al3", kind: .runningLow,
                  message: "Running low: Urea 46-0-0 is at 8 bags, below the warning level of 10",
                  relatedID: "i1", destination: .supplies,
                  raisedOn: .daysFromToday(-1), isRead: false),
        FarmAlert(id: "al4", kind: .runningLow,
                  message: "Running low: Certified rice seed is at 3 bags, below the warning level of 5",
                  relatedID: "i3", destination: .supplies,
                  raisedOn: .daysFromToday(-1), isRead: true),
        FarmAlert(id: "al5", kind: .weather,
                  message: "Weather warning: some rain expected Thursday to Saturday in Cabanatuan",
                  destination: .weather,
                  raisedOn: .daysFromToday(0), isRead: false),
        FarmAlert(id: "al6", kind: .readyToHarvest,
                  message: "Ready to harvest: Malabon Vegetable Plot",
                  relatedID: "p4", destination: .fields,
                  raisedOn: .daysFromToday(0), isRead: true)
    ]

    // MARK: - Activity

    static let activity: [ActivityEntry] = [
        ActivityEntry(id: "act1", happenedOn: .daysFromToday(-9), actorName: "Dolores Pangilinan",
                      summary: "Finished 'Clear drainage after heavy rain'", category: .jobs),
        ActivityEntry(id: "act2", happenedOn: .daysFromToday(-6), actorName: "Ernesto Villamor",
                      summary: "Finished 'Apply side-dress fertilizer'", category: .jobs),
        ActivityEntry(id: "act3", happenedOn: .daysFromToday(-52), actorName: "Ernesto Villamor",
                      summary: "Wrote down harvest: Hilltop Corn Field, 15,600 kg Corn (Best)", category: .harvest),
        ActivityEntry(id: "act4", happenedOn: .daysFromToday(-45), actorName: "Marilou Bautista",
                      summary: "Wrote down harvest: Riverside Block A, 12,400 kg Rice (Best)", category: .harvest),
        ActivityEntry(id: "act5", happenedOn: .daysFromToday(-3), actorName: "Rogelio Sarmiento",
                      summary: "Sent field note: Urgent, Sapang Bato Banana Rows", category: .fields)
    ]
}
