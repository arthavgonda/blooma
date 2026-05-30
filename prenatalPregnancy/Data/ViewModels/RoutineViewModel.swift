//
//  RoutineViewModel.swift
//  prenatalPregnancy
//

import Foundation

final class RoutineViewModel {
    private let engine: RoutineEngine
    private let cache: RoutineCacheServiceProtocol
    private let snapshotService: RoutineSnapshotServiceProtocol
    private let snapshotFirestore: RoutineSnapshotFirestoreServiceProtocol
    private let progressStore: ProgressStoreServiceProtocol
    private let dateService: DateServiceProtocol
    private weak var backing: DataControllerBacking?

    /// Day keys for which we have already queried Firestore and confirmed the
    /// result (snapshot found OR confirmed absent). Only after this flag is set
    /// for a day can the engine generate a fresh routine, guaranteeing we never
    /// overwrite a real saved snapshot just because the Firestore fetch hadn't
    /// finished yet.
    private var firestoreCheckedDays: Set<String> = []

    init(
        engine: RoutineEngine,
        cache: RoutineCacheServiceProtocol,
        snapshotService: RoutineSnapshotServiceProtocol,
        snapshotFirestore: RoutineSnapshotFirestoreServiceProtocol,
        progressStore: ProgressStoreServiceProtocol,
        dateService: DateServiceProtocol,
        backing: DataControllerBacking?
    ) {
        self.engine = engine
        self.cache = cache
        self.snapshotService = snapshotService
        self.snapshotFirestore = snapshotFirestore
        self.progressStore = progressStore
        self.dateService = dateService
        self.backing = backing
    }

    func attach(backing: DataControllerBacking) {
        self.backing = backing
    }

    // MARK: - Routine Fetching

    func getRoutineItems(for type: RoutineType, date: Date) -> [RoutineItem] {
        let key = dateService.dayKey(date)

        // 1. Fastest path: in-memory per-type cache.
        if let cachedItems = cache.cachedItems(for: key, type: type) {
            if type == .yoga { print("[YogaDiag] 🟢 getRoutineItems → memory cache hit (\(cachedItems.count) items)") }
            return itemsWithSavedProgress(cachedItems, date: date)
        }

        // 2. Local snapshot: check UserDefaults (persists across cold launches).
        if let savedSnapshot = snapshotService.snapshot(for: key, userId: backing?.currentUserId) {
            snapshotService.storeInMemory(savedSnapshot)
            cache.populateFromSnapshot(savedSnapshot, for: key)
            let yogaInSnapshot = savedSnapshot.routines[.yoga]?.count ?? -1
            if type == .yoga { print("[YogaDiag] 🟡 getRoutineItems → snapshot path (yoga items in snapshot = \(yogaInSnapshot))") }
            if let savedItems = cache.cachedRoutines(for: key)?[type] {
                if type == .yoga && savedItems.isEmpty {
                    print("[YogaDiag]   ⚠️ Snapshot has yoga=[] — falling through to re-generate instead of returning empty")
                    // Fall through to generation rather than returning empty
                } else {
                    if type == .yoga { print("[YogaDiag]   Returning \(savedItems.count) items from snapshot") }
                    return itemsWithSavedProgress(savedItems, date: date)
                }
            }
        }

        // 3. Generation path: only allowed once we have positively confirmed
        //    there is no Firestore snapshot for this day. If the Firestore check
        //    hasn't completed yet (firestoreCheckedDays doesn't contain key),
        //    return an empty array so the UI shows a loading state rather than
        //    silently generating and overwriting the saved routine.
        guard firestoreCheckedDays.contains(key) else {
            if type == .yoga { print("[YogaDiag] 🔴 getRoutineItems → Firestore not checked yet, returning []") }
            return []
        }

        if type == .yoga { print("[YogaDiag] 🔵 getRoutineItems → generating fresh routine") }
        var generatedRoutines: [RoutineType: [RoutineItem]] = [:]
        RoutineType.allCases.forEach { routineType in
            generatedRoutines[routineType] = engine.generateRoutineItems(for: routineType, date: date)
        }
        cache.setCachedRoutines(generatedRoutines, for: key)
        saveRoutineSnapshot(dayKey: key, date: date)
        return itemsWithSavedProgress(generatedRoutines[type] ?? [], date: date)
    }

    // MARK: - Firestore Pre-Fetch

    func preloadTodayRoutineFromFirestore(date: Date, completion: @escaping () -> Void) {
        let key = dateService.dayKey(date)

        // If all routine types are already cached in-memory, nothing to do.
        let allTypesCached = RoutineType.allCases.allSatisfy {
            cache.cachedItems(for: key, type: $0) != nil
        }
        if allTypesCached {
            firestoreCheckedDays.insert(key)
            completion()
            return
        }

        // If there's a valid in-memory snapshot covering all types, populate cache.
        if let userId = backing?.currentUserId,
           let inMemory = snapshotService.snapshot(for: key, userId: userId),
           RoutineType.allCases.allSatisfy({ inMemory.routines[$0] != nil }) {
            cache.populateFromSnapshot(inMemory, for: key)
            firestoreCheckedDays.insert(key)
            completion()
            return
        }

        guard let userId = backing?.currentUserId else {
            // No logged-in user (guest). Allow generation immediately.
            firestoreCheckedDays.insert(key)
            completion()
            return
        }

        // Query Firestore. Mark the day as checked regardless of the result so
        // getRoutineItems can proceed to generate if truly nothing is saved.
        snapshotFirestore.loadRoutineSnapshot(for: key, userId: userId) { [weak self] snapshot in
            guard let self else {
                completion()
                return
            }
            if let snapshot {
                self.snapshotService.saveSnapshot(snapshot, userId: userId)
                self.snapshotService.storeInMemory(snapshot)
                self.cache.populateFromSnapshot(snapshot, for: key)
            }
            self.firestoreCheckedDays.insert(key)
            completion()
        }
    }

    func prepareRoutineForHome(date: Date, completion: @escaping ([RoutineType: [RoutineItem]]) -> Void) {
        let key = dateService.dayKey(date)

        guard let userId = backing?.currentUserId else {
            firestoreCheckedDays.insert(key)
            let routines = collectPreparedRoutines(for: key, date: date)
            completion(routines)
            return
        }

        snapshotFirestore.loadRoutineSnapshot(for: key, userId: userId) { [weak self] snapshot in
            guard let self else {
                completion([:])
                return
            }

            if let snapshot {
                self.snapshotService.saveSnapshot(snapshot, userId: userId)
                self.snapshotService.storeInMemory(snapshot)
                self.cache.populateFromSnapshot(snapshot, for: key)
                self.firestoreCheckedDays.insert(key)
                completion(self.collectPreparedRoutines(for: key, date: date))
                return
            }

            self.firestoreCheckedDays.insert(key)
            let routines = self.collectPreparedRoutines(for: key, date: date)
            if routines.values.contains(where: { !$0.isEmpty }) {
                self.cache.setCachedRoutines(routines, for: key)
                self.saveRoutineSnapshot(dayKey: key, date: date)
                print("[Routine] Saved missing Firestore routine_days/\(key) for user \(userId)")
            }
            completion(routines)
        }
    }

    private func collectPreparedRoutines(for key: String, date: Date) -> [RoutineType: [RoutineItem]] {
        let routines = RoutineType.allCases.reduce(into: [RoutineType: [RoutineItem]]()) { result, type in
            result[type] = getRoutineItems(for: type, date: date)
        }

        if routines.values.contains(where: { !$0.isEmpty }) {
            cache.setCachedRoutines(routines, for: key)
        }

        return routines
    }

    // MARK: - Summary

    func getTodayRoutineSummary(for date: Date) -> [RoutineSession] {
        RoutineType.allCases.map { type in
            let items = getRoutineItems(for: type, date: date)
            let totalDuration = items.reduce(0) { $0 + $1.durationSeconds }
            return RoutineSession(
                routineType: type,
                totalItems: items.count,
                totalDuration: totalDuration
            )
        }
    }

    // MARK: - Helpers

    func mapDifficulty(_ value: String?) -> DifficultyLevel {
        switch value?.lowercased() {
        case "low": return .beginner
        case "moderate": return .intermediate
        case "high": return .advanced
        default: return .beginner
        }
    }

    func invalidateTodayButKeepProgress() {
        cache.invalidateDayKeepingProgress(dayKey: dateService.dayKey(Date()))
    }

    // MARK: - Active Item

    func getMostRecentlyActiveItem(for type: RoutineType, date: Date) -> (item: RoutineItem, progress: RoutineItemProgress)? {
        let items = getRoutineItems(for: type, date: date)
        let inProgress = items
            .compactMap { item -> (RoutineItem, RoutineItemProgress)? in
                let p = progressStore.loadProgress(for: item, date: date)
                guard p.elapsedSeconds > 0,
                      (p.status == .pending
                        || p.status == .inProgress
                        || p.status == .paused
                        || p.status == .partiallyCompleted) else { return nil }
                return (item, p)
            }
            .sorted { $0.1.elapsedSeconds > $1.1.elapsedSeconds }
            .first
        if let inProgress = inProgress { return inProgress }
        if let pending = items.first(where: {
            progressStore.loadProgress(for: $0, date: date).status == .pending
        }) {
            return (pending, progressStore.loadProgress(for: pending, date: date))
        }
        return nil
    }

    // MARK: - Progress Overlay

    private func itemsWithSavedProgress(_ items: [RoutineItem], date: Date) -> [RoutineItem] {
        items.map { item in
            var updatedItem = item
            updatedItem.status = progressStore.loadProgress(for: item, date: date).status
            return updatedItem
        }
    }

    // MARK: - Snapshot Persistence

    private func saveRoutineSnapshot(dayKey key: String, date: Date) {
        guard let routines = cache.cachedRoutines(for: key), !routines.isEmpty else { return }
        let calculation = engine.pregnancyCalculation(for: date)
        let snapshot = RoutineDaySnapshot(
            dayKey: key,
            generatedAt: Date(),
            pregnancyDay: ((calculation.gestationalWeek - 1) * 7) + calculation.gestationalDay + 1,
            gestationalWeek: calculation.gestationalWeek,
            trimester: calculation.trimester,
            routines: routines.mapValues { items in
                items.map { RoutineItemSnapshot(item: $0) }
            }
        )
        snapshotService.saveSnapshot(snapshot, userId: backing?.currentUserId)
        if let userId = backing?.currentUserId {
            snapshotFirestore.saveRoutineSnapshotToFirestore(snapshot, userId: userId)
        }
    }
}
