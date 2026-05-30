//
//  DebugSeedService.swift
//  prenatalPregnancy
//

#if DEBUG
import Foundation
import FirebaseFirestore

final class DebugSeedService {
    private let db: Firestore
    private let progressStore: ProgressStoreService
    private let progressFirestore: ProgressFirestoreServiceProtocol
    private let profileFirestore: ProfileFirestoreServiceProtocol
    private let insightsViewModel: InsightsViewModel
    private let dateService: DateServiceProtocol
    private weak var backing: DataControllerBacking?
    private let allActivities: () -> [ActivityDefinition]

    init(
        db: Firestore,
        progressStore: ProgressStoreService,
        progressFirestore: ProgressFirestoreServiceProtocol,
        profileFirestore: ProfileFirestoreServiceProtocol,
        insightsViewModel: InsightsViewModel,
        dateService: DateServiceProtocol,
        allActivities: @escaping () -> [ActivityDefinition],
        backing: DataControllerBacking?
    ) {
        self.db = db
        self.progressStore = progressStore
        self.progressFirestore = progressFirestore
        self.profileFirestore = profileFirestore
        self.insightsViewModel = insightsViewModel
        self.dateService = dateService
        self.allActivities = allActivities
        self.backing = backing
    }

    func attach(backing: DataControllerBacking) {
        self.backing = backing
    }

    // Debug helper: keep this seeder for local/demo verification of the week/day
    // Firestore structure. It intentionally writes valid progress into progress_weeks.
    func loadDummyProgressDataUntilCurrentDay(completion: (() -> Void)? = nil) {
        guard progressStore.progressStore.isEmpty else {
            completion?()
            return
        }
        guard let userId = backing?.currentUserId else {
            let seed = makeDummyProgressSeedUntilCurrentDay()
            progressStore.replaceProgressState(restored: seed.records, feedbackLookup: seed.feedbackLookup)
            completion?()
            return
        }
        db.collection("users")
            .document(userId)
            .collection("progress_weeks")
            .getDocuments { [weak self] snapshot, error in
                guard let self else {
                    completion?()
                    return
                }
                if let error = error {
                    print("Dummy seed preflight Firestore error:", error)
                    let seed = self.makeDummyProgressSeedUntilCurrentDay()
                    self.progressStore.replaceProgressState(restored: seed.records, feedbackLookup: seed.feedbackLookup)
                    completion?()
                    return
                }
                let docs = snapshot?.documents ?? []
                if !docs.isEmpty {
                    let restored = self.progressFirestore.restoreProgressRecords(fromWeekDocuments: docs)
                    var feedbackLookup: [UUID: UserFeedback] = [:]
                    restored.values.forEach { record in
                        if let feedback = record.feedback {
                            feedbackLookup[feedback.id] = feedback
                        }
                    }
                    self.progressStore.replaceProgressState(restored: restored, feedbackLookup: feedbackLookup)
                    completion?()
                    return
                }
                let seed = self.makeDummyProgressSeedUntilCurrentDay()
                self.backing?.saveProfileToFirestore()
                self.persistSeedProgressToFirestore(records: seed.records) { _ in
                    self.progressStore.replaceProgressState(restored: seed.records, feedbackLookup: seed.feedbackLookup)
                    completion?()
                }
            }
    }

    private func makeDummyProgressSeedUntilCurrentDay() -> (
        records: [String: ActivityExecutionRecord],
        feedbackLookup: [UUID: UserFeedback]
    ) {
        let calendar = dateService.istCalendar
        let today = calendar.startOfDay(for: Date())
        let currentWeek = max(1, min(backing?.userProfile.gestationalWeek ?? 1, PregnancyDateCalculation.maxGestationalWeek))
        let currentDayIndex = max(0, min(backing?.userProfile.gestationalDay ?? 0, 6))
        var seeded: [String: ActivityExecutionRecord] = [:]
        var seededFeedback: [UUID: UserFeedback] = [:]
        let activities = allActivities()
        for week in 1...currentWeek {
            let dates = insightsViewModel.datesForGestationalWeek(week)
            let lastDayIndex = week == currentWeek ? min(currentDayIndex, max(0, dates.count - 1)) : max(0, dates.count - 1)
            guard !dates.isEmpty else { continue }
            for dayIndex in 0...lastDayIndex {
                let date = calendar.startOfDay(for: min(dates[dayIndex], today))
                let types = ActivityType.allCases.shuffled()
                for activityType in types {
                    let sessionCount = Int.random(in: 0...2)
                    guard sessionCount > 0 else { continue }
                    let candidates = activities.filter {
                        insightsViewModel.activityType(for: $0.activityId) == activityType
                    }
                    guard !candidates.isEmpty else { continue }
                    for sessionIndex in 0..<sessionCount {
                        let definition = candidates.randomElement() ?? candidates[0]
                        guard let record = dummyProgressRecord(
                            activity: definition,
                            activityType: activityType,
                            date: date,
                            sessionIndex: sessionIndex
                        ) else { continue }
                        let key = progressStore.progressKey(activityId: record.activityId, date: record.date)
                        seeded[key] = record
                        if let feedback = record.feedback {
                            seededFeedback[feedback.id] = feedback
                        }
                    }
                }
            }
        }
        return (records: seeded, feedbackLookup: seededFeedback)
    }

    private func persistSeedProgressToFirestore(
        records: [String: ActivityExecutionRecord],
        completion: @escaping (Bool) -> Void
    ) {
        guard let userId = backing?.currentUserId else {
            completion(false)
            return
        }
        var payloadsByWeek: [String: [String: Any]] = [:]
        for (documentKey, record) in records {
            guard let writePayload = progressStore.progressWeekWritePayload(
                record: record,
                item: nil,
                feedback: record.feedback,
                documentKey: documentKey
            ) else { continue }
            var merged = payloadsByWeek[writePayload.documentId] ?? [:]
            for (field, value) in writePayload.data {
                merged[field] = value
            }
            payloadsByWeek[writePayload.documentId] = merged
        }
        let batch = db.batch()
        for (documentId, payload) in payloadsByWeek {
            let ref = db.collection("users")
                .document(userId)
                .collection("progress_weeks")
                .document(documentId)
            batch.setData(payload, forDocument: ref, merge: true)
        }
        batch.commit { error in
            if let error = error {
                print("Dummy seed Firestore write error:", error)
                completion(false)
            } else {
                print("Dummy seed Firestore write success:", records.count)
                completion(true)
            }
        }
    }

    private func dummyProgressRecord(
        activity: ActivityDefinition,
        activityType: ActivityType,
        date: Date,
        sessionIndex: Int
    ) -> ActivityExecutionRecord? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        let sessionOffsetMinutes = 360 + (sessionIndex * 150) + Int.random(in: 0...40)
        let startTime = dateService.istCalendar.date(byAdding: .minute, value: sessionOffsetMinutes, to: date) ?? date
        let durationMinutes: Int
        let distanceMeters: Double
        let steps: Int
        let reps: Int
        let sets: Int
        switch activityType {
        case .walking:
            durationMinutes = Int.random(in: 18...42)
            distanceMeters = Double(Int.random(in: 900...3600))
            steps = Int.random(in: 1200...6200)
            reps = 0
            sets = 0
        case .exercise:
            durationMinutes = Int.random(in: 12...35)
            distanceMeters = 0
            steps = Int.random(in: 200...1800)
            reps = Int.random(in: 10...40)
            sets = Int.random(in: 1...4)
        case .yoga:
            durationMinutes = Int.random(in: 15...40)
            distanceMeters = 0
            steps = Int.random(in: 100...900)
            reps = Int.random(in: 4...18)
            sets = Int.random(in: 1...3)
        }
        let endTime = dateService.istCalendar.date(byAdding: .minute, value: durationMinutes, to: startTime) ?? startTime
        let calories = Double(Int.random(in: 45...220))
        let heartRate = Int.random(in: 88...138)
        let spo2 = Double(Int.random(in: 94...99))
        let shouldAddFeedback = Int.random(in: 0...4) == 0
        var json: [String: Any] = [
            "activityId": activity.activityId,
            "date": isoFormatter.string(from: date),
            "startTime": isoFormatter.string(from: startTime),
            "endTime": isoFormatter.string(from: endTime),
            "status": RoutineItemStatus.completed.rawValue,
            "duration": durationMinutes * 60,
            "distance": distanceMeters,
            "reps": reps,
            "sets": sets,
            "stats": [
                "steps": steps,
                "distance": distanceMeters,
                "calories": calories,
                "reps": reps,
                "sets": sets
            ],
            "vitals": [
                "heartRate": heartRate,
                "spo2": spo2
            ]
        ]
        if shouldAddFeedback {
            json["feedback"] = [
                "id": UUID().uuidString,
                "activityId": activity.activityId,
                "difficulty": [DifficultyLevel.beginner, .intermediate, .advanced].randomElement()?.rawValue ?? DifficultyLevel.beginner.rawValue,
                "fatigue": [FatigueLevel.none, .low, .moderate].randomElement()?.rawValue ?? FatigueLevel.low.rawValue,
                "note": ["Felt good", "Nice session", "Comfortable pace", "Good energy"].randomElement() ?? "Good energy",
                "createdAt": isoFormatter.string(from: endTime)
            ]
        }
        guard JSONSerialization.isValidJSONObject(json),
              let data = try? JSONSerialization.data(withJSONObject: json),
              let decoded = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return dummyProgressRecord(fromJSON: decoded)
    }

    private func dummyProgressRecord(fromJSON payload: [String: Any]) -> ActivityExecutionRecord? {
        guard let activityId = payload["activityId"] as? String,
              let dateString = payload["date"] as? String,
              let date = ISO8601DateFormatter().date(from: dateString) else {
            return nil
        }
        let stats = payload["stats"] as? [String: Any]
        let vitals = payload["vitals"] as? [String: Any]
        let startTime = ISO8601DateFormatter().date(from: payload["startTime"] as? String ?? "")
        let endTime = ISO8601DateFormatter().date(from: payload["endTime"] as? String ?? "")
        let feedback = dummyFeedback(fromJSON: payload["feedback"] as? [String: Any])
        return ActivityExecutionRecord(
            activityId: activityId,
            date: date,
            firestoreWeek: ValueHelpers.intValue(payload["week"]),
            startTime: startTime,
            endTime: endTime,
            status: ValueHelpers.routineItemStatus(from: payload["status"] as? String ?? RoutineItemStatus.completed.rawValue),
            durationSeconds: ValueHelpers.intValue(payload["duration"]),
            distanceMeters: ValueHelpers.doubleValue(payload["distance"]) ?? ValueHelpers.doubleValue(stats?["distance"]),
            activeEnergyKcal: ValueHelpers.doubleValue(stats?["calories"]),
            avgHeartRate: ValueHelpers.intValue(vitals?["heartRate"]),
            peakHeartRate: ValueHelpers.intValue(vitals?["peakHeartRate"]) ?? ValueHelpers.intValue(vitals?["heartRate"]),
            avgSpO2: ValueHelpers.doubleValue(vitals?["spo2"]),
            peakSpO2: ValueHelpers.doubleValue(vitals?["peakSpo2"]) ?? ValueHelpers.doubleValue(vitals?["spo2"]),
            steps: ValueHelpers.intValue(stats?["steps"]),
            reps: ValueHelpers.intValue(payload["reps"]) ?? ValueHelpers.intValue(stats?["reps"]),
            sets: ValueHelpers.intValue(payload["sets"]) ?? ValueHelpers.intValue(stats?["sets"]),
            feedback: feedback
        )
    }

    private func dummyFeedback(fromJSON payload: [String: Any]?) -> UserFeedback? {
        guard let payload,
              let idString = payload["id"] as? String,
              let id = UUID(uuidString: idString),
              let activityId = payload["activityId"] as? String,
              let difficultyRaw = payload["difficulty"] as? String,
              let fatigueRaw = payload["fatigue"] as? String,
              let difficulty = DifficultyLevel(rawValue: difficultyRaw),
              let fatigue = FatigueLevel(rawValue: fatigueRaw),
              let createdAtString = payload["createdAt"] as? String,
              let createdAt = ISO8601DateFormatter().date(from: createdAtString) else {
            return nil
        }
        return UserFeedback(
            id: id,
            activityId: activityId,
            difficulty: difficulty,
            fatigue: fatigue,
            note: payload["note"] as? String,
            createdAt: createdAt
        )
    }
}
#endif
