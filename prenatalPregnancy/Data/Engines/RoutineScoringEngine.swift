//
//  RoutineScoringEngine.swift
//  prenatalPregnancy
//

import Foundation

final class RoutineScoringEngine {
    private weak var context: RoutineEngineContext?
    private let filterEngine: RoutineFilterEngine

    init(context: RoutineEngineContext?, filterEngine: RoutineFilterEngine) {
        self.context = context
        self.filterEngine = filterEngine
    }

    func attach(context: RoutineEngineContext) {
        self.context = context
    }

    func score(
        _ activity: ActivityDefinition,
        type: RoutineType,
        on date: Date,
        calculation: PregnancyDateCalculation,
        isRecoveryModeActive: Bool
    ) -> Int {
        var score = 0
        if filterEngine.trimesterAllowed(activity, trimester: calculation.trimester) { score += 20 }
        if filterEngine.notRecentlyUsed(activity, on: date) { score += 18 }
        score += exactActivityLevelBoost(for: activity)
        score += medicalConditionBoost(for: activity)
        score += recentCompletionPenalty(for: activity, on: date)
        score += feedbackAdjustment(for: activity)
        score += gestationalWeekBoost(for: activity, gestationalWeek: calculation.gestationalWeek)
        score += recoveryModeBoost(for: activity, isRecoveryModeActive: isRecoveryModeActive)
        score += deterministicRoutineOrderValue(for: activity, type: type, on: date)
        return score
    }

    func exactActivityLevelBoost(for activity: ActivityDefinition) -> Int {
        guard let context else { return 0 }
        let userLevel = context.userProfile.activityLevel.rawValue
        let allowed = activity.userCapabilityRequirement.allowedActivityLevels
        if allowed.contains(userLevel) {
            return 10
        }
        switch context.userProfile.activityLevel {
        case .high:
            return allowed.contains("moderate") ? 6 : (allowed.contains("low") ? 4 : 0)
        case .moderate:
            return allowed.contains("low") ? 5 : 0
        case .low:
            return 0
        }
    }

    func medicalConditionBoost(for activity: ActivityDefinition) -> Int {
        guard let context else { return 0 }
        let conditions = Set(context.userProfile.medicalConditions.map(\.rawValue)).subtracting(["none"])
        guard !conditions.isEmpty else {
            return activity.medicalSafety.medicalConditions.contains("none") ? 4 : 2
        }
        let supported = Set(activity.medicalSafety.medicalConditions)
        if !conditions.isDisjoint(with: supported) {
            return 12
        }
        if activity.intensity.intensityLevel.lowercased() == "low" {
            return 6
        }
        return -6
    }

    func feedbackAdjustment(for activity: ActivityDefinition) -> Int {
        guard let context else { return 0 }
        let recentFeedback = context.userFeedback
            .filter { $0.activityId == activity.activityId }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(3)
        return recentFeedback.reduce(0) { partial, feedback in
            switch feedback.fatigue {
            case .high:
                return partial - 10
            case .moderate:
                return partial - 4
            case .low:
                return partial + 2
            case .none:
                return partial + 4
            }
        }
    }

    func recentCompletionPenalty(for activity: ActivityDefinition, on date: Date) -> Int {
        guard let context else { return 0 }
        let cal = context.dateService.istCalendar
        let today = cal.startOfDay(for: date)
        let sevenDaysAgo = cal.date(byAdding: .day, value: -6, to: today) ?? today
        let recentCompletions = context.progressStore.values.filter { record in
            record.activityId == activity.activityId
                && record.status == .completed
                && cal.startOfDay(for: record.date) >= sevenDaysAgo
                && cal.startOfDay(for: record.date) <= today
        }.count
        return -(recentCompletions * 8)
    }

    func gestationalWeekBoost(for activity: ActivityDefinition, gestationalWeek: Int) -> Int {
        let week = max(1, gestationalWeek)
        let intensity = activity.intensity.intensityLevel.lowercased()
        if week <= 12 {
            return intensity == "low" ? 8 : 3
        }
        if week >= 28 {
            if activity.activityId.localizedCaseInsensitiveContains("yoga") {
                return 8
            }
            return intensity == "low" ? 6 : 2
        }
        return intensity == "moderate" ? 7 : 4
    }

    func recoveryModeBoost(for activity: ActivityDefinition, isRecoveryModeActive: Bool) -> Int {
        guard isRecoveryModeActive else { return 0 }
        let searchableText = [
            activity.metadata.title,
            activity.metadata.description,
            activity.content.benefits.joined(separator: " "),
            activity.content.instructions.joined(separator: " ")
        ].joined(separator: " ").lowercased()
        if activity.intensity.intensityLevel.lowercased().contains("low") {
            return 12
        }
        if searchableText.contains("breath")
            || searchableText.contains("walk")
            || searchableText.contains("mobility")
            || searchableText.contains("restorative")
            || searchableText.contains("relax") {
            return 10
        }
        return -8
    }

    func deterministicRoutineOrderValue(for activity: ActivityDefinition, type: RoutineType, on date: Date) -> Int {
        guard let context else { return 0 }
        let weekday = context.dateService.istCalendar.component(.weekday, from: date)
        let weekComponent = context.dateService.istCalendar.component(.weekOfYear, from: date)
        let conditionKey = context.userProfile.medicalConditions.map(\.rawValue).sorted().joined(separator: "|")
        let seed = [
            activity.activityId,
            type.rawValue,
            "\(weekday)",
            "\(weekComponent)",
            "\(context.userProfile.gestationalWeek)",
            "\(context.userProfile.trimester.rawValue)",
            context.userProfile.activityLevel.rawValue,
            conditionKey
        ].joined(separator: "#")
        return ValueHelpers.stableHash(seed) % 11
    }

    func isRecoveryModeActive() -> Bool {
        guard let context else { return false }
        let recentRecords = context.progressStore.values
            .sorted { ($0.endTime ?? $0.date) > ($1.endTime ?? $1.date) }
            .prefix(12)
        let skippedCount = recentRecords.filter { $0.status == .skipped }.count
        let partialCount = recentRecords.filter { record in
            record.status == .partiallyCompleted
                || (record.status == .pending && (record.durationSeconds ?? 0) > 0)
        }.count
        let elevatedHeartRate = recentRecords.contains { ($0.peakHeartRate ?? $0.avgHeartRate ?? 0) >= 145 }
        let recentFatigue = context.userFeedback
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(6)
            .filter { $0.fatigue == .high || $0.fatigue == .moderate }
            .count
        return skippedCount >= 3 || partialCount >= 3 || recentFatigue >= 3 || elevatedHeartRate
    }
}
