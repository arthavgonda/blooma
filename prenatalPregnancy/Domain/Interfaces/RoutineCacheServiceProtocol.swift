//
//  RoutineCacheServiceProtocol.swift
//  prenatalPregnancy
//

import Foundation

protocol RoutineCacheServiceProtocol: AnyObject {
    func cachedItems(for dayKey: String, type: RoutineType) -> [RoutineItem]?
    func cachedRoutines(for dayKey: String) -> [RoutineType: [RoutineItem]]?
    func setCachedRoutines(_ routines: [RoutineType: [RoutineItem]], for dayKey: String)
    func populateFromSnapshot(_ snapshot: RoutineDaySnapshot, for dayKey: String)
    func invalidateDayKeepingProgress(dayKey: String)
    func filterStore(keepingDayKey key: String)
    func clearAll()
}
