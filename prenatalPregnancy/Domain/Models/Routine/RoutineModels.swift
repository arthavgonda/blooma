//
//  
// RoutineModels.swift
//  prenatalPregnancy
//

import Foundation
import UIKit

enum RoutineType: String, Codable, CaseIterable {
    case walking
    case exercise
    case yoga
}

enum RoutineItemStatus: String, Codable {
    case pending
    case inProgress = "active"
    case paused
    case partiallyCompleted = "partially_completed"
    case completed
    case skipped
}

struct ActivityDefinition: Codable, Identifiable {
    
    let activityId: String
    let metadata: Metadata
    let content: Content
    let media: Media
    let prescription: Prescription
    let intensity: Intensity
    let medicalSafety: MedicalSafety
    let userCapabilityRequirement: Capability
    
    var id: String { activityId }
    
    struct Metadata: Codable {
        let title: String
        let description: String
    }
    
    struct Content: Codable {
        let benefits: [String]
        let instructions: [String]
        let safetyTips: [String]
    }
    
    struct Media: Codable {
        let video: String
        let image: String
    }
    
    struct Prescription: Codable {
        let trimester: [String]
        let sets: Int?
        let reps: Int?
        let durationMinutes: Int
        let recommendedDistanceMeters: Int?
    }
    
    struct Intensity: Codable {
        let intensityLevel: String
    }
    
    struct MedicalSafety: Codable {
        let medicalConditions: [String]
        let contraindications: [String]
    }
    
    struct Capability: Codable {
        let allowedActivityLevels: [String]
    }
}

struct RoutineItem: Identifiable {
    /// Stable identifier derived from the activity and type — unlike a random
    /// UUID this is consistent across multiple instantiations of the same item.
    var id: String { "\(activityId)_\(routineType.rawValue)" }
    
    
    let activityId: String
    let routineType: RoutineType
    let title: String
    
    let video: String
    let image: String
    
    let durationSeconds: Int
    let distanceMeters: Int?
    let sets: Int?
    let reps: Int?
    let difficulty: String?
    
    let description: String
    let benefits: [String]
    let instructions: [String]
    let safetyTips: [String]
    
    var status: RoutineItemStatus
}

struct RoutineDaySnapshot: Codable {
    let dayKey: String
    let generatedAt: Date
    let pregnancyDay: Int
    let gestationalWeek: Int
    let trimester: Trimester
    var routines: [RoutineType: [RoutineItemSnapshot]]
}

struct RoutineItemSnapshot: Codable {
    let activityId: String
    let routineType: RoutineType
    let title: String
    let video: String
    let image: String
    let durationSeconds: Int
    let distanceMeters: Int?
    let sets: Int?
    let reps: Int?
    let difficulty: String?
    let description: String
    let benefits: [String]
    let instructions: [String]
    let safetyTips: [String]
    
    nonisolated init(
        activityId: String,
        routineType: RoutineType,
        title: String,
        video: String,
        image: String,
        durationSeconds: Int,
        distanceMeters: Int?,
        sets: Int?,
        reps: Int?,
        difficulty: String?,
        description: String,
        benefits: [String],
        instructions: [String],
        safetyTips: [String]
    ) {
        self.activityId = activityId
        self.routineType = routineType
        self.title = title
        self.video = video
        self.image = image
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.sets = sets
        self.reps = reps
        self.difficulty = difficulty
        self.description = description
        self.benefits = benefits
        self.instructions = instructions
        self.safetyTips = safetyTips
    }

    nonisolated init(item: RoutineItem) {
        activityId = item.activityId
        routineType = item.routineType
        title = item.title
        video = item.video
        image = item.image
        durationSeconds = item.durationSeconds
        distanceMeters = item.distanceMeters
        sets = item.sets
        reps = item.reps
        difficulty = item.difficulty
        description = item.description
        benefits = item.benefits
        instructions = item.instructions
        safetyTips = item.safetyTips
    }
    
    nonisolated func routineItem(status: RoutineItemStatus = .pending) -> RoutineItem {
        return RoutineItem(
            activityId: activityId,
            routineType: routineType,
            title: title,
            video: video,
            image: image,
            durationSeconds: durationSeconds,
            distanceMeters: distanceMeters,
            sets: sets,
            reps: reps,
            difficulty: difficulty,
            description: description,
            benefits: benefits,
            instructions: instructions,
            safetyTips: safetyTips,
            status: status
        )
    }
}

struct RoutineSession: Identifiable {
    /// Stable identifier based on the routine type so two sessions for the
    /// same type on the same day are considered equal in any diffing context.
    var id: String { routineType.rawValue }
    let routineType: RoutineType
    let totalItems: Int
    let totalDuration: Int
}

struct ActivityExecutionRecord: Codable {
    
    let activityId: String
    let date: Date
    // NEW: Preserve the Firestore progress_weeks document week so Insights can
    // render the exact saved week even if the local profile dates change later.
    var firestoreWeek: Int?
    
    var startTime: Date?
    var endTime: Date?
    var status: RoutineItemStatus
    
    var durationSeconds: Int?
    var distanceMeters: Double?
    var activeEnergyKcal: Double?
    
    // Watch (optional)
    var avgHeartRate: Int?
    var peakHeartRate: Int?
    var avgSpO2: Double?
    var peakSpO2: Double?
    var steps: Int?
    var reps: Int?
    var sets: Int?
    var feedback: UserFeedback?
}

struct ActivityRotationRecord: Codable {
    let activityId: String
    let lastPerformedDate: Date
}

struct RoutineItemStatusCount {
    let completed: Int
    let skipped: Int
    let pending: Int
    let total: Int
}

enum ProgressBucket {
    case notStarted
    case started
    case midway
    case almostDone
    case completed
}

enum RoutineSection: Int, CaseIterable {
    case recommended
    case routine
}

struct UserFeedback: Codable {
    
    let id: UUID
    let activityId: String
    let difficulty: DifficultyLevel
    let fatigue: FatigueLevel
    let note: String?
    let createdAt: Date
    
}

enum DifficultyLevel: String, Codable, CaseIterable {
    case beginner
    case intermediate
    case advanced

    var displayText: String {
        switch self {
        case .beginner:
            return "Beginner"
        case .intermediate:
            return "Intermediate"
        case .advanced:
            return "Advanced"
        }
    }
}

enum FatigueLevel: String, Codable, CaseIterable {
    case none
    case low
    case moderate
    case high

    var displayText: String {
        switch self {
        case .none:
            return "None"
        case .low:
            return "Low"
        case .moderate:
            return "Moderate"
        case .high:
            return "High"
        }
    }
}

enum Section: Int, CaseIterable {
    case header
    case difficulty
    case fatigue
    case notes
}

enum RoutineControlMode {
    case start
    case continueExercise
    case pause
    case play
    case completed
    case skipped
}

enum DetailSection: Int, CaseIterable {
    case description
    case instructions
    case benefits
    case safety
}
