//
//  ProgressFirestoreServiceProtocol.swift
//  prenatalPregnancy
//

import Foundation
import FirebaseFirestore

protocol ProgressRecordFirestoreEncoding: AnyObject {
    func firestoreData(for record: ActivityExecutionRecord, item: RoutineItem?, feedback: UserFeedback?) -> [String: Any]
    func firestoreData(for feedback: UserFeedback) -> [String: Any]
    func progressRecord(from data: [String: Any], fallbackWeek: Int?) -> ActivityExecutionRecord?
    func restoreProgressRecords(fromWeekDocuments docs: [QueryDocumentSnapshot]) -> [String: ActivityExecutionRecord]
}

protocol ProgressFirestoreServiceProtocol: AnyObject, ProgressRecordFirestoreEncoding {
    func startProgressListener()
    func stopProgressListener()
    func loadProgressFromFirestore(completion: @escaping () -> Void)
    func saveProgressToFirestore(
        record: ActivityExecutionRecord,
        item: RoutineItem?,
        feedback: UserFeedback?,
        documentKey: String?
    )
    func saveProgressStatsToFirestore(
        activityId: String,
        date: Date,
        steps: Int?,
        distance: Double?,
        heartRate: Int?
    )
}
