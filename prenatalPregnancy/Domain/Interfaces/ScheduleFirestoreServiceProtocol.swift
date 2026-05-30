//
//  ScheduleFirestoreServiceProtocol.swift
//  prenatalPregnancy
//

import Foundation

protocol ScheduleFirestoreServiceProtocol: AnyObject {
    func saveScheduleToFirestore(userId: String, schedule: ActivitySchedule)
    func loadScheduleFromFirestore(
        userId: String,
        completion: @escaping (ActivitySchedule?) -> Void
    )
}
