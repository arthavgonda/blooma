//
//  RoutineSnapshotFirestoreService.swift
//  prenatalPregnancy
//

import Foundation
import FirebaseFirestore

final class RoutineSnapshotFirestoreService: RoutineSnapshotFirestoreServiceProtocol {
    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    // MARK: - Save

    func saveRoutineSnapshotToFirestore(_ snapshot: RoutineDaySnapshot, userId: String) {
        let routinesPayload = snapshot.routines.reduce(into: [String: Any]()) { result, pair in
            result[pair.key.rawValue] = pair.value.map(routineSnapshotPayload)
        }
        let data: [String: Any] = [
            "dayKey": snapshot.dayKey,
            "generatedAt": Timestamp(date: snapshot.generatedAt),
            "pregnancyDay": snapshot.pregnancyDay,
            "gestationalWeek": snapshot.gestationalWeek,
            "trimester": snapshot.trimester.rawValue,
            "routines": routinesPayload,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        db.collection("users")
            .document(userId)
            .collection("routine_days")
            .document(snapshot.dayKey)
            .setData(data, merge: true)
    }

    // MARK: - Load

    func loadRoutineSnapshot(for dayKey: String, userId: String, completion: @escaping (RoutineDaySnapshot?) -> Void) {
        db.collection("users")
            .document(userId)
            .collection("routine_days")
            .document(dayKey)
            .getDocument { snapshot, error in
                guard let data = snapshot?.data(), error == nil else {
                    completion(nil)
                    return
                }
                completion(self.parseRoutineDaySnapshot(from: data))
            }
    }

    // MARK: - Parsing

    private func parseRoutineDaySnapshot(from data: [String: Any]) -> RoutineDaySnapshot? {
        guard let dayKey = data["dayKey"] as? String,
              let gestationalWeek = data["gestationalWeek"] as? Int,
              let pregnancyDay = data["pregnancyDay"] as? Int,
              let trimesterRaw = data["trimester"] as? Int,
              let trimester = Trimester(rawValue: trimesterRaw),
              let routinesMap = data["routines"] as? [String: Any] else {
            return nil
        }

        let generatedAt = (data["generatedAt"] as? Timestamp)?.dateValue() ?? Date()
        var routines: [RoutineType: [RoutineItemSnapshot]] = [:]

        for (typeKey, value) in routinesMap {
            guard let routineType = RoutineType(rawValue: typeKey),
                  let items = value as? [[String: Any]] else { continue }
            routines[routineType] = items.compactMap(parseRoutineItemSnapshot)
        }

        return RoutineDaySnapshot(
            dayKey: dayKey,
            generatedAt: generatedAt,
            pregnancyDay: pregnancyDay,
            gestationalWeek: gestationalWeek,
            trimester: trimester,
            routines: routines
        )
    }

    private func parseRoutineItemSnapshot(from data: [String: Any]) -> RoutineItemSnapshot? {
        guard let activityId = data["activityId"] as? String,
              let routineTypeRaw = data["routineType"] as? String,
              let routineType = RoutineType(rawValue: routineTypeRaw),
              let title = data["title"] as? String,
              let durationSeconds = data["durationSeconds"] as? Int else {
            return nil
        }

        return RoutineItemSnapshot(
            activityId: activityId,
            routineType: routineType,
            title: title,
            video: data["video"] as? String ?? "",
            image: data["image"] as? String ?? "",
            durationSeconds: durationSeconds,
            distanceMeters: data["distanceMeters"] as? Int,
            sets: data["sets"] as? Int,
            reps: data["reps"] as? Int,
            difficulty: data["intensityLevel"] as? String,
            description: data["description"] as? String ?? "",
            benefits: data["benefits"] as? [String] ?? [],
            instructions: data["instructions"] as? [String] ?? [],
            safetyTips: data["safetyTips"] as? [String] ?? []
        )
    }

    // MARK: - Encoding

    private func routineSnapshotPayload(_ item: RoutineItemSnapshot) -> [String: Any] {
        var payload: [String: Any] = [
            "activityId": item.activityId,
            "routineType": item.routineType.rawValue,
            "title": item.title,
            "video": item.video,
            "image": item.image,
            "durationSeconds": item.durationSeconds,
            "description": item.description,
            "benefits": item.benefits,
            "instructions": item.instructions,
            "safetyTips": item.safetyTips
        ]
        if let distanceMeters = item.distanceMeters { payload["distanceMeters"] = distanceMeters }
        if let sets = item.sets { payload["sets"] = sets }
        if let reps = item.reps { payload["reps"] = reps }
        if let difficulty = item.difficulty { payload["intensityLevel"] = difficulty }
        return payload
    }
}
