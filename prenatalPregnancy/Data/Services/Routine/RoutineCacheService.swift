//
//  RoutineCacheService.swift
//  prenatalPregnancy
//

import Foundation

final class RoutineCacheService: RoutineCacheServiceProtocol {

    // MARK: - Storage

    private var dailyRoutineStore: [String: [RoutineType: [RoutineItem]]] = [:]

    // MARK: - Read

    func cachedItems(for dayKey: String, type: RoutineType) -> [RoutineItem]? {
        guard let cached = dailyRoutineStore[dayKey]?[type], !cached.isEmpty else {
            return nil
        }
        return cached
    }

    func cachedRoutines(for dayKey: String) -> [RoutineType: [RoutineItem]]? {
        dailyRoutineStore[dayKey]
    }

    // MARK: - Write

    func setCachedRoutines(_ routines: [RoutineType: [RoutineItem]], for dayKey: String) {
        dailyRoutineStore[dayKey] = routines
    }

    func populateFromSnapshot(_ snapshot: RoutineDaySnapshot, for dayKey: String) {
        dailyRoutineStore[dayKey] = snapshot.routines.mapValues { snapshots in
            snapshots.map { $0.routineItem() }
        }
    }

    // MARK: - Invalidation

    /// Clears the cached RoutineItem arrays for a given day so they will be
    /// re-derived from the saved snapshot on the next getRoutineItems call.
    /// Progress status is re-applied by RoutineViewModel.itemsWithSavedProgress,
    /// so no progress data is lost by this call.
    func invalidateDayKeepingProgress(dayKey: String) {
        dailyRoutineStore[dayKey] = [:]
    }

    func filterStore(keepingDayKey key: String) {
        dailyRoutineStore = dailyRoutineStore.filter { $0.key == key }
    }

    func clearAll() {
        dailyRoutineStore.removeAll()
    }
}
