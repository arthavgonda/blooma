//
//  ValueHelpers.swift
//  prenatalPregnancy
//

import Foundation
import FirebaseFirestore

enum ValueHelpers {
    static func intValue(_ value: Any?) -> Int? {
        if let value = value as? Int { return value }
        if let value = value as? NSNumber { return value.intValue }
        if let value = value as? String { return Int(value) }
        return nil
    }

    static func doubleValue(_ value: Any?) -> Double? {
        if let value = value as? Double { return value }
        if let value = value as? NSNumber { return value.doubleValue }
        if let value = value as? String { return Double(value) }
        return nil
    }

    static func stableHash(_ value: String) -> Int {
        value.unicodeScalars.reduce(7) { partial, scalar in
            ((partial * 31) + Int(scalar.value)) & 0x7fffffff
        }
    }

    static func routineItemStatus(from rawValue: String) -> RoutineItemStatus {
        switch rawValue {
        case "inProgress":
            return .inProgress
        case "partial", "partiallyCompleted":
            return .partiallyCompleted
        default:
            return RoutineItemStatus(rawValue: rawValue) ?? .pending
        }
    }

    static func feedback(from value: Any?) -> UserFeedback? {
        guard let payload = value as? [String: Any],
              let idString = payload["id"] as? String,
              let id = UUID(uuidString: idString),
              let activityId = payload["activityId"] as? String,
              let difficultyRaw = payload["difficulty"] as? String,
              let fatigueRaw = payload["fatigue"] as? String,
              let difficulty = DifficultyLevel(rawValue: difficultyRaw),
              let fatigue = FatigueLevel(rawValue: fatigueRaw) else {
            return nil
        }
        return UserFeedback(
            id: id,
            activityId: activityId,
            difficulty: difficulty,
            fatigue: fatigue,
            note: {
                let note = payload["note"] as? String
                return (note?.isEmpty == false) ? note : nil
            }(),
            createdAt: (payload["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
