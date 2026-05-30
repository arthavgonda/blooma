//
//  InsightsDataSourceProtocol.swift
//  prenatalPregnancy
//

import Foundation

protocol InsightsDataSourceProtocol: AnyObject {
    var userProfile: UserProfile { get }
    var allActivities: [ActivityDefinition] { get }
    var currentUserId: String? { get }
    var progressStore: [String: ActivityExecutionRecord] { get }
    var userFeedback: [UserFeedback] { get }
    func weekRecords(for gestationalWeek: Int) -> [String: [String: ActivityExecutionRecord]]
}
