//
//  InsightModels.swift
//  prenatalPregnancy
//

import Foundation
import UIKit


//Progress
struct ActivitySchedule: Codable {
    let scheduleMetadata: ScheduleMetadata
    var insights: [Insight]
}

struct ScheduleMetadata: Codable {
    let planTitle: String
    let startDate: String
    let endDate: String
    let totalDays: Int
    let durationMonths: Int
}


//Insight
struct InsightsResponse: Codable {
    var insights: [Insight]
}

struct Insight: Codable {
    var activityType: String
    var title: String
    var weeks: [InsightWeek]
}

struct InsightGraphSummary {
    var title: String
    var metricTitle: String
    var displayValue: String
    var dayLabels: [String]
    var dayValues: [Double]
}

struct ActivityWeekProgressSnapshot {
    let graphSummary: InsightGraphSummary
    let days: [InsightDay]
    
    var hasProgress: Bool {
        days.contains { !$0.sessions.isEmpty }
    }
}

struct InsightWeek: Codable {
    var week: String
    var days: [InsightDay]
}

struct InsightStat: Codable {
    var title: String
    var value: String
    var unit: String
}

struct InsightDay: Codable {
    var dayKey: String
    var dayLabel: String
    let dateDisplay: String
    var sessions: [InsightSession]
}

struct InsightSession: Codable {
    var id: String
    var sessionTitle: String
    var time : String
    var stats: [SessionMetric]
    var vitals: [SessionMetric]?
    var status: RoutineItemStatus?
}

struct SessionMetric: Codable {
    var title: String
    var value: String
    var unit: String
}

struct Stat: Codable {
    var title: String
    var value: String
    var unit: String
}

struct Week {
    let title: String
    let isSelected: Bool
}

struct TodayProgress: Codable {

    let totalKcal: Int
    let steps: Int
    let distance: Double
    let stairs: Int
    let timeline: [String:Int]
}

struct WalkingData: Decodable {
    let activities: [String: ActivityData]
}
    
struct ActivityData: Decodable {
    let weeks: [WeekData]
}
    
struct WeekData: Decodable {
    let week: String
    let days: [String: Int]
    
    var averageValue: Int {
        guard !days.isEmpty else { return 0 }
        let total = days.values.reduce(0, +)
        return total / days.count
    }
    
    var sortedDays: [(String, Int)] {
        let order = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days.sorted {
            (order.firstIndex(of: $0.key) ?? 0) < (order.firstIndex(of: $1.key) ?? 0)
        }
    }
}

enum ActivityType: String, CaseIterable {
    case walking
    case exercise
    case yoga
    
    var title: String {
        switch self {
        case .walking: return "Walking"
        case .exercise: return "Exercise"
        case .yoga: return "Yoga"
        }
    }
    
    var icon: String {
        switch self {
        case .walking: return "figure.walk"
        case .exercise: return "dumbbell.fill"
        case .yoga: return "figure.yoga"
        }
    }
    
    var metricTitle: String {
        switch self {
        case .walking:
            return "Average Steps"
        case .exercise, .yoga:
            return "Average Time"
        }
    }
    
    var unit: String {
        switch self {
        case .walking:
            return "steps"
        case .exercise, .yoga:
            return "min"
        }
    }
    
    var selectedColor: UIColor {
        switch self {
        case .walking:
            return .systemGreen
        case .exercise:
            return .systemPurple
        case .yoga:
            return .systemRed
        }
    }
    
    var normalColor: UIColor {
        return .systemGray4
    }
}
