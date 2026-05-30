//
//  RoutineSnapshotServiceProtocol.swift
//  prenatalPregnancy
//

import Foundation

protocol RoutineSnapshotServiceProtocol: AnyObject {
    func snapshot(for dayKey: String, userId: String?) -> RoutineDaySnapshot?
    func storeInMemory(_ snapshot: RoutineDaySnapshot)
    func saveSnapshot(_ snapshot: RoutineDaySnapshot, userId: String?)
    func routineSnapshotDefaultsKey(for dayKey: String, userId: String?) -> String
    func clearAll()
}
