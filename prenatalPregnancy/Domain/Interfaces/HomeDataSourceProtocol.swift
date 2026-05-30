//
//  HomeDataSourceProtocol.swift
//  prenatalPregnancy
//

import Foundation

protocol HomeDataSourceProtocol: AnyObject {
    var userProfile: UserProfile { get }
    var currentUserId: String? { get }
    var progressStore: [String: ActivityExecutionRecord] { get }
    var latestHealthVitals: ActivityExecutionRecord? { get set }
}
