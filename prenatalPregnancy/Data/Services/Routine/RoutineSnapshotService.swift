//
//  RoutineSnapshotService.swift
//  prenatalPregnancy
//

import Foundation

final class RoutineSnapshotService: RoutineSnapshotServiceProtocol {

    // MARK: - Storage

    private var routineSnapshots: [String: RoutineDaySnapshot] = [:]

    // MARK: - Read

    func snapshot(for dayKey: String, userId: String?) -> RoutineDaySnapshot? {
        if let snapshot = routineSnapshots[dayKey] {
            return snapshot
        }
        guard let data = UserDefaults.standard.data(forKey: routineSnapshotDefaultsKey(for: dayKey, userId: userId)) else {
            return nil
        }
        let decoded = try? JSONDecoder().decode(RoutineDaySnapshot.self, from: data)
        if let decoded { routineSnapshots[dayKey] = decoded }
        return decoded
    }

    // MARK: - Write

    func saveSnapshot(_ snapshot: RoutineDaySnapshot, userId: String?) {
        routineSnapshots[snapshot.dayKey] = snapshot
        if let encoded = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(
                encoded,
                forKey: routineSnapshotDefaultsKey(for: snapshot.dayKey, userId: userId)
            )
        }
    }

    func storeInMemory(_ snapshot: RoutineDaySnapshot) {
        routineSnapshots[snapshot.dayKey] = snapshot
    }

    // MARK: - Invalidation

    func clearAll() {
        routineSnapshots.removeAll()
    }

    // MARK: - Helpers

    func routineSnapshotDefaultsKey(for dayKey: String, userId: String?) -> String {
        "routineSnapshot.\(userId ?? "guest").\(dayKey)"
    }
}
