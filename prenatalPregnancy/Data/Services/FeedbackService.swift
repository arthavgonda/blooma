//
//  FeedbackService.swift
//  prenatalPregnancy
//

import Foundation

final class FeedbackService: FeedbackServiceProtocol {
    private let progressStore: ProgressStoreServiceProtocol
    private let progressFirestore: ProgressFirestoreServiceProtocol
    private let dateService: DateServiceProtocol
    private weak var backing: DataControllerBacking?

    init(
        progressStore: ProgressStoreServiceProtocol,
        progressFirestore: ProgressFirestoreServiceProtocol,
        dateService: DateServiceProtocol,
        backing: DataControllerBacking?
    ) {
        self.progressStore = progressStore
        self.progressFirestore = progressFirestore
        self.dateService = dateService
        self.backing = backing
    }

    func attach(backing: DataControllerBacking) {
        self.backing = backing
    }

    func saveUserFeedback(activityId: String, difficulty: DifficultyLevel, fatigue: FatigueLevel, note: String?) {
        let feedback = UserFeedback(
            id: UUID(),
            activityId: activityId,
            difficulty: difficulty,
            fatigue: fatigue,
            note: note,
            createdAt: Date()
        )
        progressStore.userFeedback.append(feedback)
        progressStore.userFeedback.sort { $0.createdAt > $1.createdAt }
        if let key = progressStore.latestProgressKey(activityId: feedback.activityId, date: feedback.createdAt),
           var record = progressStore.progressStore[key] {
            record.feedback = feedback
            progressStore.reindexProgressRecord(key: key, record: record)
        }
        backing?.notifyProgressChanged()
        saveFeedbackToFirestore(feedback)
    }

    func hasFeedback(for activityId: String) -> Bool {
        progressStore.userFeedback.contains { $0.activityId == activityId }
    }

    func shouldPromptForFeedback(for activityId: String, on date: Date) -> Bool {
        let feedbackForActivity = progressStore.userFeedback
            .filter { $0.activityId == activityId }
            .sorted { $0.createdAt > $1.createdAt }
        guard let latestFeedback = feedbackForActivity.first else {
            return true
        }
        let calendar = dateService.istCalendar
        if calendar.isDate(latestFeedback.createdAt, inSameDayAs: date) {
            return false
        }
        let daysSinceLastFeedback = calendar.dateComponents([.day], from: latestFeedback.createdAt, to: date).day ?? 0
        if daysSinceLastFeedback >= 7 {
            return true
        }
        let completedCount = progressStore.progressStore.values
            .filter { $0.activityId == activityId && $0.status == .completed }
            .count
        return completedCount > 0 && completedCount.isMultiple(of: 3)
    }

    private func saveFeedbackToFirestore(_ feedback: UserFeedback) {
        guard backing?.currentUserId != nil else { return }
        let key = progressStore.latestProgressKey(activityId: feedback.activityId, date: feedback.createdAt)
            ?? progressStore.progressEntry(activityId: feedback.activityId, on: feedback.createdAt)?.key
            ?? progressStore.progressKey(activityId: feedback.activityId, date: feedback.createdAt)
        var record = progressStore.progressEntry(activityId: feedback.activityId, on: feedback.createdAt)?.record ?? ActivityExecutionRecord(
            activityId: feedback.activityId,
            date: feedback.createdAt,
            firestoreWeek: nil,
            startTime: nil,
            endTime: nil,
            status: .completed,
            durationSeconds: nil,
            distanceMeters: nil,
            activeEnergyKcal: nil,
            avgHeartRate: nil,
            peakHeartRate: nil,
            avgSpO2: nil,
            peakSpO2: nil,
            steps: nil,
            reps: nil,
            sets: nil,
            feedback: nil
        )
        record.feedback = feedback
        progressFirestore.saveProgressToFirestore(
            record: record,
            item: nil,
            feedback: feedback,
            documentKey: key
        )
    }
}
