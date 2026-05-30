//
//  ProgressStoreServiceProtocol.swift
//  prenatalPregnancy
//

import Foundation

protocol ProgressStoreServiceProtocol: AnyObject, ProgressFirestoreCoordinating {
    var progressStore: [String: ActivityExecutionRecord] { get set }
    var userFeedback: [UserFeedback] { get set }
    func weekRecords(for gestationalWeek: Int) -> [String: [String: ActivityExecutionRecord]]
    func gestationalWeek(for date: Date) -> Int?
    func insightsStartWeek() -> Int
    func availableInsightWeeks() -> [Int]
    func resetPregnancyProgressDayAnchor()
    func refreshPregnancyProgressIfNeeded(referenceDate: Date)
    func refreshProgressIndexesAfterProfileUpdate()
    func loadProgress(for item: RoutineItem, date: Date) -> RoutineItemProgress
    func saveProgress(
        for item: RoutineItem,
        elapsedSeconds: Int?,
        status: RoutineItemStatus,
        date: Date
    )
    func markItemCompleted(_ item: inout RoutineItem, date: Date)
    func markItemSkipped(_ item: inout RoutineItem, date: Date)
    func updateProgressVitals(
        for item: RoutineItem,
        date: Date,
        heartRate: Int?,
        peakHeartRate: Int?,
        spo2: Int?,
        peakSpo2: Int?,
        calories: Int?,
        steps: Int?,
        elapsedSeconds: Int?,
        status: RoutineItemStatus
    )
    func getAllProgress() -> [ActivityExecutionRecord]
    func getProgress(for activityId: String) -> [ActivityExecutionRecord]
    func latestProgressKey(activityId: String, date: Date) -> String?
    func progressKey(activityId: String, date: Date) -> String
    func progressEntry(activityId: String, on date: Date) -> (key: String, record: ActivityExecutionRecord)?
    func reindexProgressRecord(key: String, record: ActivityExecutionRecord)
    func setInsightsStartWeek(_ week: Int)
}
