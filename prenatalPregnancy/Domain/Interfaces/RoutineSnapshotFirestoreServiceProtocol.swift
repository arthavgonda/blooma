//
//  RoutineSnapshotFirestoreServiceProtocol.swift
//  prenatalPregnancy
//

import Foundation

protocol RoutineSnapshotFirestoreServiceProtocol: AnyObject {
    func saveRoutineSnapshotToFirestore(_ snapshot: RoutineDaySnapshot, userId: String)
    func loadRoutineSnapshot(for dayKey: String, userId: String, completion: @escaping (RoutineDaySnapshot?) -> Void)
}
