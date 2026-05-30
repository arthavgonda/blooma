//
//  ProgressFirestoreCoordinating.swift
//  prenatalPregnancy
//

import Foundation

protocol ProgressFirestoreCoordinating: AnyObject {
    var currentUserId: String? { get }
    func progressKey(activityId: String, date: Date) -> String
    func progressEntry(activityId: String, on date: Date) -> (key: String, record: ActivityExecutionRecord)?
    func latestProgressKey(activityId: String, date: Date) -> String?
    func replaceProgressState(
        restored: [String: ActivityExecutionRecord],
        feedbackLookup: [UUID: UserFeedback]
    )
    func clearProgressState()
    func progressWeekWritePayload(
        record: ActivityExecutionRecord,
        item: RoutineItem?,
        feedback: UserFeedback?,
        documentKey: String
    ) -> (documentId: String, data: [String: Any])?
}
