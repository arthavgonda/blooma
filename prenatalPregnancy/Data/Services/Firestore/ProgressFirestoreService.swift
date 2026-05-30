//
//  ProgressFirestoreService.swift
//  prenatalPregnancy
//

import Foundation
import FirebaseFirestore

final class ProgressFirestoreService: ProgressFirestoreServiceProtocol {

    private let db: Firestore
    private weak var coordinator: ProgressFirestoreCoordinating?
    private var progressListener: ListenerRegistration?

    init(db: Firestore, coordinator: ProgressFirestoreCoordinating?) {
        self.db = db
        self.coordinator = coordinator
    }

    deinit {
        progressListener?.remove()
    }

    func stopProgressListener() {
        progressListener?.remove()
        progressListener = nil
    }

    func saveProgressToFirestore(
        record: ActivityExecutionRecord,
        item: RoutineItem? = nil,
        feedback: UserFeedback? = nil,
        documentKey: String? = nil
    ) {
        guard let userId = coordinator?.currentUserId else { return }
        guard let coordinator else { return }

        let key = documentKey
            ?? coordinator.progressEntry(activityId: record.activityId, on: record.date)?.key
            ?? coordinator.progressKey(activityId: record.activityId, date: record.date)
        guard let writePayload = coordinator.progressWeekWritePayload(
            record: record,
            item: item,
            feedback: feedback,
            documentKey: key
        ) else { return }

        db.collection("users")
            .document(userId)
            .collection("progress_weeks")
            .document(writePayload.documentId)
            .setData(writePayload.data, merge: true) { error in
                if let error = error {
                    print("Progress Firestore save error:", error)
                } else {
                    print("Progress saved to Firestore")
                }
            }
    }

    func startProgressListener() {
        progressListener?.remove()

        guard let userId = coordinator?.currentUserId else {
            coordinator?.clearProgressState()
            return
        }

        progressListener = db.collection("users")
            .document(userId)
            .collection("progress_weeks")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Progress Firestore listener error:", error)
                    return
                }

                guard let docs = snapshot?.documents else { return }

                let restored = self.restoreProgressRecords(fromWeekDocuments: docs)
                var feedbackLookup: [UUID: UserFeedback] = [:]

                for record in restored.values {
                    if let feedback = record.feedback {
                        feedbackLookup[feedback.id] = feedback
                    }
                }

                self.coordinator?.replaceProgressState(restored: restored, feedbackLookup: feedbackLookup)
                print("Progress synced from Firestore:", restored.count)
            }
    }

    func loadProgressFromFirestore(completion: @escaping () -> Void) {
        guard let userId = coordinator?.currentUserId else {
            completion()
            return
        }

        db.collection("users")
            .document(userId)
            .collection("progress_weeks")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else {
                    completion()
                    return
                }

                if let error = error {
                    print("Progress Firestore load error:", error)
                    completion()
                    return
                }

                let docs = snapshot?.documents ?? []
                let restored = self.restoreProgressRecords(fromWeekDocuments: docs)
                var feedbackLookup: [UUID: UserFeedback] = [:]

                restored.values.forEach { record in
                    if let feedback = record.feedback {
                        feedbackLookup[feedback.id] = feedback
                    }
                }

                self.coordinator?.replaceProgressState(restored: restored, feedbackLookup: feedbackLookup)
                print("Progress loaded from Firestore:", restored.count)
                completion()
            }
    }

    func firestoreData(for record: ActivityExecutionRecord, item: RoutineItem? = nil, feedback: UserFeedback? = nil) -> [String: Any] {
        let distance = record.distanceMeters ?? (record.status == .skipped ? 0 : Double(item?.distanceMeters ?? 0))
        let stats: [String: Any] = [
            "steps": record.steps ?? 0,
            "distance": distance,
            "calories": record.activeEnergyKcal ?? 0,
            "reps": record.reps ?? (record.status == .skipped ? 0 : item?.reps ?? 0),
            "sets": record.sets ?? (record.status == .skipped ? 0 : item?.sets ?? 0)
        ]
        let vitals: [String: Any] = [
            "heartRate": record.avgHeartRate ?? 0,
            "peakHeartRate": record.peakHeartRate ?? record.avgHeartRate ?? 0,
            "spo2": record.avgSpO2 ?? 0,
            "peakSpo2": record.peakSpO2 ?? record.avgSpO2 ?? 0
        ]

        var data: [String: Any] = [
            "activityId": record.activityId,
            "date": Timestamp(date: record.date),
            "status": record.status.rawValue,
            "duration": record.durationSeconds ?? 0,
            "distance": distance,
            "stats": stats,
            "vitals": vitals
        ]

        if let startTime = record.startTime {
            data["startTime"] = Timestamp(date: startTime)
        }

        if let endTime = record.endTime {
            data["endTime"] = Timestamp(date: endTime)
        }

        if let item = item, record.status != .skipped {
            data["reps"] = item.reps ?? 0
            data["sets"] = item.sets ?? 0
        }

        if let reps = record.reps {
            data["reps"] = reps
        }

        if let sets = record.sets {
            data["sets"] = sets
        }

        if let feedback = feedback {
            data["feedback"] = firestoreData(for: feedback)
        }

        return data
    }

    func firestoreData(for feedback: UserFeedback) -> [String: Any] {
        [
            "id": feedback.id.uuidString,
            "activityId": feedback.activityId,
            "difficulty": feedback.difficulty.rawValue,
            "fatigue": feedback.fatigue.rawValue,
            "note": feedback.note ?? "",
            "createdAt": Timestamp(date: feedback.createdAt)
        ]
    }

    func progressRecord(from data: [String: Any], fallbackWeek: Int? = nil) -> ActivityExecutionRecord? {
        guard let activityId = data["activityId"] as? String else { return nil }

        let stats = data["stats"] as? [String: Any]
        let vitals = data["vitals"] as? [String: Any]
        let inferredStatus = inferredStatusForRestoredRecord(data: data, stats: stats, vitals: vitals)

        return ActivityExecutionRecord(
            activityId: activityId,
            date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
            firestoreWeek: ValueHelpers.intValue(data["week"]) ?? fallbackWeek,
            startTime: (data["startTime"] as? Timestamp)?.dateValue(),
            endTime: (data["endTime"] as? Timestamp)?.dateValue(),
            status: inferredStatus,
            durationSeconds: ValueHelpers.intValue(data["duration"]),
            distanceMeters: ValueHelpers.doubleValue(data["distance"]) ?? ValueHelpers.doubleValue(stats?["distance"]),
            activeEnergyKcal: ValueHelpers.doubleValue(stats?["calories"]),
            avgHeartRate: ValueHelpers.intValue(vitals?["heartRate"]),
            peakHeartRate: ValueHelpers.intValue(vitals?["peakHeartRate"]) ?? ValueHelpers.intValue(vitals?["heartRate"]),
            avgSpO2: ValueHelpers.doubleValue(vitals?["spo2"]),
            peakSpO2: ValueHelpers.doubleValue(vitals?["peakSpo2"]) ?? ValueHelpers.doubleValue(vitals?["spo2"]),
            steps: ValueHelpers.intValue(stats?["steps"]),
            reps: ValueHelpers.intValue(data["reps"]) ?? ValueHelpers.intValue(stats?["reps"]),
            sets: ValueHelpers.intValue(data["sets"]) ?? ValueHelpers.intValue(stats?["sets"]),
            feedback: ValueHelpers.feedback(from: data["feedback"])
        )
    }

    private func inferredStatusForRestoredRecord(
        data: [String: Any],
        stats: [String: Any]?,
        vitals: [String: Any]?
    ) -> RoutineItemStatus {
        if let rawStatus = data["status"] as? String {
            return ValueHelpers.routineItemStatus(from: rawStatus)
        }

        let hasMeaningfulValue =
            (ValueHelpers.intValue(data["duration"]) ?? 0) > 0
            || (ValueHelpers.intValue(data["reps"]) ?? ValueHelpers.intValue(stats?["reps"]) ?? 0) > 0
            || (ValueHelpers.intValue(data["sets"]) ?? ValueHelpers.intValue(stats?["sets"]) ?? 0) > 0
            || (ValueHelpers.intValue(stats?["steps"]) ?? 0) > 0
            || (ValueHelpers.doubleValue(data["distance"]) ?? ValueHelpers.doubleValue(stats?["distance"]) ?? 0) > 0
            || (ValueHelpers.doubleValue(stats?["calories"]) ?? 0) > 0
            || (ValueHelpers.intValue(vitals?["heartRate"]) ?? 0) > 0
            || data["startTime"] != nil
            || data["endTime"] != nil
            || data["feedback"] != nil

        return hasMeaningfulValue ? .completed : .pending
    }

    func saveProgressStatsToFirestore(
        activityId: String,
        date: Date,
        steps: Int?,
        distance: Double?,
        heartRate: Int?
    ) {
        guard let userId = coordinator?.currentUserId else { return }
        guard let coordinator else { return }

        let key = coordinator.latestProgressKey(activityId: activityId, date: date)
            ?? coordinator.progressEntry(activityId: activityId, on: date)?.key
            ?? coordinator.progressKey(activityId: activityId, date: date)

        var record = coordinator.progressEntry(activityId: activityId, on: date)?.record ?? ActivityExecutionRecord(
            activityId: activityId,
            date: date,
            firestoreWeek: nil,
            startTime: nil,
            endTime: nil,
            status: .inProgress,
            durationSeconds: nil,
            distanceMeters: nil,
            activeEnergyKcal: nil,
            avgHeartRate: nil,
            peakHeartRate: nil,
            avgSpO2: nil,
            peakSpO2: nil,
            steps: nil,
            reps: nil,
            sets: nil,
            feedback: nil
        )

        if let steps { record.steps = steps }
        if let distance { record.distanceMeters = distance }
        if let heartRate { record.avgHeartRate = heartRate }

        guard let writePayload = coordinator.progressWeekWritePayload(
            record: record,
            item: nil,
            feedback: nil,
            documentKey: key
        ) else { return }

        db.collection("users")
            .document(userId)
            .collection("progress_weeks")
            .document(writePayload.documentId)
            .setData(writePayload.data, merge: true)
    }

    func restoreProgressRecords(fromWeekDocuments docs: [QueryDocumentSnapshot]) -> [String: ActivityExecutionRecord] {
        var restored: [String: ActivityExecutionRecord] = [:]
        guard let coordinator else { return restored }

        for doc in docs {
            let fallbackWeek = Int(doc.documentID.replacingOccurrences(of: "W", with: ""))
            let days = normalizedDaysPayload(from: doc.data())
            guard !days.isEmpty else { continue }

            for (_, dayValue) in days {
                guard let dayPayload = dayValue as? [String: Any],
                      let records = dayPayload["records"] as? [String: Any] else { continue }

                for (_, recordValue) in records {
                    guard let recordPayload = recordValue as? [String: Any],
                          let record = progressRecord(from: recordPayload, fallbackWeek: fallbackWeek) else { continue }

                    let key = (recordPayload["documentKey"] as? String)
                        ?? coordinator.progressKey(activityId: record.activityId, date: record.date)
                    restored[key] = record
                }
            }
        }

        return restored
    }

    private func normalizedDaysPayload(from documentData: [String: Any]) -> [String: Any] {
        if let nestedDays = documentData["days"] as? [String: Any], !nestedDays.isEmpty {
            return nestedDays
        }

        return flattenedDaysPayload(from: documentData)
    }

    private func flattenedDaysPayload(from documentData: [String: Any]) -> [String: Any] {
        var days: [String: [String: Any]] = [:]

        for (key, value) in documentData {
            guard key.hasPrefix("days.") else { continue }

            let components = key.split(separator: ".").map(String.init)
            guard components.count >= 3 else { continue }

            let dayKey = components[1]
            var dayPayload = days[dayKey] ?? [:]

            if components.count == 3 {
                let fieldName = components[2]
                dayPayload[fieldName] = value
                days[dayKey] = dayPayload
                continue
            }

            guard components[2] == "records", components.count >= 4 else { continue }

            let recordKey = components[3]
            var records = dayPayload["records"] as? [String: Any] ?? [:]

            if components.count == 4 {
                records[recordKey] = value
                dayPayload["records"] = records
                days[dayKey] = dayPayload
                continue
            }

            let recordFieldPath = Array(components.dropFirst(4))
            var recordPayload = records[recordKey] as? [String: Any] ?? [:]
            setValue(value, forPath: recordFieldPath, in: &recordPayload)
            records[recordKey] = recordPayload
            dayPayload["records"] = records
            days[dayKey] = dayPayload
        }

        return days.mapValues { $0 }
    }

    private func setValue(_ value: Any, forPath path: [String], in dictionary: inout [String: Any]) {
        guard let head = path.first else { return }

        if path.count == 1 {
            dictionary[head] = value
            return
        }

        var child = dictionary[head] as? [String: Any] ?? [:]
        setValue(value, forPath: Array(path.dropFirst()), in: &child)
        dictionary[head] = child
    }
}
