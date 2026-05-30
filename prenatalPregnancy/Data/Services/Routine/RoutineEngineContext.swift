//
//  RoutineEngineContext.swift
//  prenatalPregnancy
//

import Foundation

protocol RoutineEngineContext: AnyObject {
    var userProfile: UserProfile { get }
    var allActivities: [ActivityDefinition] { get }
    var rotationHistory: [ActivityRotationRecord] { get }
    var progressStore: [String: ActivityExecutionRecord] { get }
    var userFeedback: [UserFeedback] { get }
    var dateService: DateServiceProtocol { get }
    func routineType(for activityId: String) -> RoutineType
    func snapshot(forDayKey key: String) -> RoutineDaySnapshot?
    var currentUserId: String? { get }
}
