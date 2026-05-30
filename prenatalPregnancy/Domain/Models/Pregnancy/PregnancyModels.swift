//
//  
// PregnancyModels.swift
//  prenatalPregnancy
//

import Foundation
import UIKit

struct UserProfile: Codable, Identifiable {
    let userId: UUID
    var profileImageData: Data?
    var profileImageUrl: String?
    var name: String
    var email: String?
    var userName: String
    var password: String
    var age: Int
    var lmpDate: Date?
    var eddDate: Date?
    var gestationalWeek: Int
    var gestationalDay: Int
    var trimester: Trimester
    var medicalConditions: [MedicalCondition]
    var activityLevel: ActivityLevel
    var hasAppleWatch: Bool
    
    var id: UUID { userId }
}

enum Trimester: Int, Codable {
    case first = 1
    case second = 2
    case third = 3
    
    var displayTitle: String {
        switch self {
        case .first: return "First Trimester"
        case .second: return "Second Trimester"
        case .third: return "Third Trimester"
        }
    }
}

struct PregnancyDateCalculation {
    let lmpDate: Date
    let eddDate: Date
    let gestationalWeek: Int
    let gestationalDay: Int
    let trimester: Trimester
    
    var gestationalDisplay: String {
        "Week \(gestationalWeek) + \(gestationalDay) day\(gestationalDay == 1 ? "" : "s")"
    }
    
    static let pregnancyLengthInDays = 280
    static let maxGestationalWeek = 42
    
    static func fromLMP(_ date: Date, calendar: Calendar = .current, today: Date = Date()) -> PregnancyDateCalculation {
        let normalizedLMP = calendar.startOfDay(for: date)
        let normalizedToday = calendar.startOfDay(for: today)
        let totalDays = max(0, calendar.dateComponents([.day], from: normalizedLMP, to: normalizedToday).day ?? 0)
        let week = max(1, min(maxGestationalWeek, (totalDays / 7) + 1))
        let day = totalDays % 7
        let eddDate = calendar.date(byAdding: .day, value: pregnancyLengthInDays, to: normalizedLMP) ?? normalizedLMP
        
        return PregnancyDateCalculation(
            lmpDate: normalizedLMP,
            eddDate: eddDate,
            gestationalWeek: week,
            gestationalDay: day,
            trimester: trimester(for: week)
        )
    }
    
    static func fromEDD(_ date: Date, calendar: Calendar = .current, today: Date = Date()) -> PregnancyDateCalculation {
        let normalizedEDD = calendar.startOfDay(for: date)
        let lmpDate = calendar.date(byAdding: .day, value: -pregnancyLengthInDays, to: normalizedEDD) ?? normalizedEDD
        return fromLMP(lmpDate, calendar: calendar, today: today)
    }
    
    static func trimester(for week: Int) -> Trimester {
        switch week {
        case 1...12:
            return .first
        case 13...27:
            return .second
        default:
            return .third
        }
    }
    
    static func estimatedLMP(fromWeek week: Int, day: Int, calendar: Calendar = .current, today: Date = Date()) -> Date {
        let totalDays = max(0, ((max(1, week) - 1) * 7) + max(0, day))
        return calendar.date(byAdding: .day, value: -totalDays, to: calendar.startOfDay(for: today)) ?? today
    }
}

enum ActivityLevel: String, Codable, CaseIterable {
    case low
    case moderate
    case high
    
    var displayName: String {
        switch self {
        case .low: return "Gentle"
        case .moderate: return "Balanced"
        case .high: return "Active"
        }
    }
}

enum MedicalCondition: String, Codable, CaseIterable {
    case none
    case anemia
    case hypertension
    case diabetes
    case thyroid
    case obesity
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .anemia: return "Anemia"
        case .hypertension: return "Hypertension"
        case .diabetes: return "Diabetes"
        case .thyroid: return "Thyroid"
        case .obesity: return "Obesity"
        }
    }
}
