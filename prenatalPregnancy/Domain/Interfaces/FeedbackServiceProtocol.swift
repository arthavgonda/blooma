//
//  FeedbackServiceProtocol.swift
//  prenatalPregnancy
//

import Foundation

protocol FeedbackServiceProtocol: AnyObject {
    func saveUserFeedback(activityId: String, difficulty: DifficultyLevel, fatigue: FatigueLevel, note: String?)
    func hasFeedback(for activityId: String) -> Bool
    func shouldPromptForFeedback(for activityId: String, on date: Date) -> Bool
}
