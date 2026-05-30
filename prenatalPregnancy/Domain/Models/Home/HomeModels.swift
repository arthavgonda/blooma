//
//  
// HomeModels.swift
//  prenatalPregnancy
//

import Foundation
import UIKit

//Home
struct WatchVitalViewModel {
    let icon: String
    let title: String
    let value: String
    let tint: UIColor
}

struct Insights {
    let image: UIImage
    let title: String
    let description: String
    let points: String
}

struct InsightResponse: Codable {
    let week: Int
    let categories: [Category]
}

struct Category: Codable {
    let id: String
    let title: String
    let subtitle: String
    let heroImage: String
    let items: [InsightItem]
}

struct InsightItem: Codable {
    let title: String
    let shortDescription: String
    let detailDescription: String
}

struct DayItem {
    let title: String
    let isSelected: Bool
}

struct DummyMemoryRoot: Codable {
    let weeks: [DummyMemoryWeek]
}

struct DummyMemoryWeek: Codable {
    let week: Int
    let images: [DummyMemoryImage]
}

struct DummyMemoryImage: Codable {
    let id: String
    let fileName: String
}

struct RoutineCardData {
    let routineType: RoutineType
    let firstIncompleteItem: RoutineItem?
    let incompleteCount: Int
    let totalCount: Int
    let progress: RoutineItemProgress?
}

struct RoutineItemProgress: Codable {
    let activityId: String
    let date: Date
    var elapsedSeconds: Int
    var heartRateAverage: Int?
    var caloriesBurned: Double?
    var distanceCovered: Double?
    var repetitionsCompleted: Int?
    var status: RoutineItemStatus
}

struct HomeWeeklyProgressActivity {
    let routineType: RoutineType
    let category: String
    let name: String
    let value: Double
    let unit: String
    let goal: Double
    let goalUnit: String
    let progress: Double
    let color: UIColor
    let imageName: String
}

struct HomeWeeklyProgressSnapshot {
    let displayWeek: Int
    let overallPercent: Int
    let motivation: String
    let dayLabels: [String]
    let chartValues: [RoutineType: [Double]]
    let activities: [HomeWeeklyProgressActivity]
}
