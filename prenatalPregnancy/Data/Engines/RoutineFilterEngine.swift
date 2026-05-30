//
//  RoutineFilterEngine.swift
//  prenatalPregnancy
//

import Foundation

final class RoutineFilterEngine {
    private weak var context: RoutineEngineContext?

    init(context: RoutineEngineContext?) {
        self.context = context
    }

    func attach(context: RoutineEngineContext) {
        self.context = context
    }

    func mapCategory(_ activity: ActivityDefinition) -> RoutineType {
        guard let context else { return .exercise }
        return context.routineType(for: activity.activityId)
    }

    func trimesterAllowed(_ activity: ActivityDefinition, trimester: Trimester) -> Bool {
        activity.prescription.trimester.contains("\(trimester.rawValue)")
    }

    func trimesterAllowed(_ activity: ActivityDefinition) -> Bool {
        guard let context else { return false }
        return trimesterAllowed(activity, trimester: context.userProfile.trimester)
    }

    func ageAllowed(_ activity: ActivityDefinition) -> Bool {
        guard let context else { return false }
        let age = context.userProfile.age
        let intensity = activity.intensity.intensityLevel.lowercased()
        if age < 20 {
            return intensity == "low"
        } else if age <= 30 {
            return intensity.contains("low") || intensity.contains("moderate")
        } else {
            return !intensity.contains("high")
        }
    }

    func medicalSafe(_ activity: ActivityDefinition) -> Bool {
        guard let context else { return false }
        let userConditions = Set(context.userProfile.medicalConditions.map { $0.rawValue }.filter { $0 != "none" })
        let allowedConditions = Set(activity.medicalSafety.medicalConditions.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
        let contraindications = Set(activity.medicalSafety.contraindications.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }.filter { !$0.isEmpty })
        if !userConditions.isDisjoint(with: contraindications) {
            return false
        }
        if userConditions.isEmpty {
            return true
        }
        if !userConditions.isDisjoint(with: allowedConditions) {
            return true
        }
        if allowedConditions.contains("none") && activity.intensity.intensityLevel.lowercased().contains("low") {
            return true
        }
        return false
    }

    func activityLevelAllowed(_ activity: ActivityDefinition) -> Bool {
        guard let context else { return false }
        let userLevel = context.userProfile.activityLevel.rawValue
        let allowed = activity.userCapabilityRequirement.allowedActivityLevels
        if allowed.contains(userLevel) {
            return true
        }
        if userLevel == "high" {
            return allowed.contains("moderate") || allowed.contains("low")
        }
        if userLevel == "moderate" {
            return allowed.contains("low")
        }
        return false
    }

    func notRecentlyUsed(_ activity: ActivityDefinition, on date: Date) -> Bool {
        guard let context else { return true }
        let cal = context.dateService.istCalendar
        let today = cal.startOfDay(for: date)
        let recentWindowStart = cal.date(byAdding: .day, value: -1, to: today) ?? today
        let recentProgress = context.progressStore.values.contains { record in
            record.activityId == activity.activityId
                && record.status == .completed
                && cal.startOfDay(for: record.date) >= recentWindowStart
                && cal.startOfDay(for: record.date) <= today
        }
        if recentProgress {
            return false
        }
        guard let record = context.rotationHistory.first(where: { $0.activityId == activity.activityId }) else {
            return true
        }
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: record.lastPerformedDate), to: today).day ?? 0
        return days >= 2
    }
}
