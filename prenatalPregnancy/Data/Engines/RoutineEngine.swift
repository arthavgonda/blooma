//
//  RoutineEngine.swift
//  prenatalPregnancy
//

import Foundation

final class RoutineEngine {
    private weak var context: RoutineEngineContext?
    private let filterEngine: RoutineFilterEngine
    private let scoringEngine: RoutineScoringEngine

    init(context: RoutineEngineContext?) {
        self.context = context
        let filter = RoutineFilterEngine(context: context)
        self.filterEngine = filter
        self.scoringEngine = RoutineScoringEngine(context: context, filterEngine: filter)
    }

    func attach(context: RoutineEngineContext) {
        self.context = context
        filterEngine.attach(context: context)
        scoringEngine.attach(context: context)
    }

    func pregnancyCalculation(for date: Date) -> PregnancyDateCalculation {
        guard let context else {
            return PregnancyDateCalculation.fromLMP(Date(), calendar: Calendar.current, today: date)
        }
        let calendar = context.dateService.istCalendar
        if let lmp = context.userProfile.lmpDate {
            return PregnancyDateCalculation.fromLMP(lmp, calendar: calendar, today: date)
        }
        if let edd = context.userProfile.eddDate {
            return PregnancyDateCalculation.fromEDD(edd, calendar: calendar, today: date)
        }
        let lmp = PregnancyDateCalculation.estimatedLMP(
            fromWeek: context.userProfile.gestationalWeek,
            day: context.userProfile.gestationalDay,
            calendar: calendar,
            today: Date()
        )
        return PregnancyDateCalculation.fromLMP(lmp, calendar: calendar, today: date)
    }

    func generateRoutineItems(for type: RoutineType, date: Date) -> [RoutineItem] {
        guard let context else { return [] }
        var activities = context.allActivities
        let calculation = pregnancyCalculation(for: date)
        debug("Initial", activities.count)
        activities = activities.filter { filterEngine.mapCategory($0) == type }
        debug("Type", activities.count)
        activities = activities.filter { filterEngine.trimesterAllowed($0, trimester: calculation.trimester) }
        debug("Trimester", activities.count)
        activities = activities.filter { filterEngine.ageAllowed($0) }
        debug("Age", activities.count)
        activities = activities.filter { filterEngine.medicalSafe($0) }
        debug("Medical", activities.count)
        activities = activities.filter { filterEngine.activityLevelAllowed($0) }
        debug("ActivityLevel", activities.count)
        debug("Rotation", activities.count)
        let recoveryActive = scoringEngine.isRecoveryModeActive()
        let scored = activities.map {
            ($0, scoringEngine.score($0, type: type, on: date, calculation: calculation, isRecoveryModeActive: recoveryActive))
        }
        let sorted = scored.sorted {
            if $0.1 != $1.1 { return $0.1 > $1.1 }
            return $0.0.activityId < $1.0.activityId
        }.map { $0.0 }
        debug("Scored", sorted.count)
        let count = dynamicCount(for: type)
        var selected = evolvedSelection(from: sorted, type: type, date: date, count: count)
        // SAFETY NET
        if selected.isEmpty {
            selected = context.allActivities
                .filter { filterEngine.mapCategory($0) == type }
                .filter { filterEngine.trimesterAllowed($0, trimester: calculation.trimester) }
                .filter { filterEngine.medicalSafe($0) }
                .filter { filterEngine.activityLevelAllowed($0) || $0.intensity.intensityLevel.lowercased().contains("low") }
                .sorted {
                    scoringEngine.deterministicRoutineOrderValue(for: $0, type: type, on: date) >
                        scoringEngine.deterministicRoutineOrderValue(for: $1, type: type, on: date)
                }
                .prefix(count)
                .map { $0 }
        }
        debug("Final", selected.count)
        return buildRoutineItems(from: selected, type: type, date: date)
    }

    func dynamicCount(for type: RoutineType) -> Int {
        guard let context else { return 0 }
        switch (type, context.userProfile.activityLevel) {
        case (.walking, .low): return 1
        case (.walking, .moderate): return 2
        case (.walking, .high): return 3
        case (.exercise, .low): return 5
        case (.exercise, .moderate): return 7
        case (.exercise, .high): return 9
        case (.yoga, .low): return 4
        case (.yoga, .moderate): return 6
        case (.yoga, .high): return 8
        }
    }

    func evolvedSelection(
        from sorted: [ActivityDefinition],
        type: RoutineType,
        date: Date,
        count: Int
    ) -> [ActivityDefinition] {
        guard count > 0 else { return [] }
        let previousItems = previousRoutineItems(for: type, before: date)
        let safePreviousIds = previousItems
            .map(\.activityId)
            .filter { id in sorted.contains { $0.activityId == id } }
        let familiarTarget = min(count, max(0, Int((Double(count) * 0.65).rounded())))
        let familiar = safePreviousIds
            .prefix(familiarTarget)
            .compactMap { id in sorted.first { $0.activityId == id } }
        var selected = familiar
        let selectedIds = Set(selected.map(\.activityId))
        let variationTarget = max(0, count - selected.count)
        let variation = sorted
            .filter { !selectedIds.contains($0.activityId) }
            .prefix(variationTarget)
        selected.append(contentsOf: variation)
        if selected.count < count {
            let ids = Set(selected.map(\.activityId))
            selected.append(contentsOf: sorted.filter { !ids.contains($0.activityId) }.prefix(count - selected.count))
        }
        return Array(selected.prefix(count))
    }

    func previousRoutineItems(for type: RoutineType, before date: Date) -> [RoutineItemSnapshot] {
        guard let context else { return [] }
        let calendar = context.dateService.istCalendar
        for offset in 1...7 {
            guard let previousDate = calendar.date(byAdding: .day, value: -offset, to: date) else { continue }
            let key = context.dateService.dayKey(previousDate)
            if let items = context.snapshot(forDayKey: key)?.routines[type], !items.isEmpty {
                return items
            }
        }
        return []
    }

    func buildRoutineItems(from activities: [ActivityDefinition], type: RoutineType, date: Date) -> [RoutineItem] {
        activities.map { activity in
            let adapted = adaptedPrescription(for: activity, type: type, date: date)
            return RoutineItem(
                activityId: activity.activityId,
                routineType: type,
                title: activity.metadata.title,
                video: activity.media.video,
                image: activity.media.image,
                durationSeconds: adapted.durationSeconds,
                distanceMeters: adapted.distanceMeters,
                sets: activity.prescription.sets,
                reps: adapted.reps,
                difficulty: activity.intensity.intensityLevel,
                description: activity.metadata.description,
                benefits: activity.content.benefits,
                instructions: activity.content.instructions,
                safetyTips: activity.content.safetyTips,
                status: .pending
            )
        }
    }

    func adaptedPrescription(
        for activity: ActivityDefinition,
        type: RoutineType,
        date: Date
    ) -> (durationSeconds: Int, distanceMeters: Int?, reps: Int?) {
        guard let context else {
            return (max(60, activity.prescription.durationMinutes * 60), activity.prescription.recommendedDistanceMeters, activity.prescription.reps)
        }
        let baseDuration = max(60, activity.prescription.durationMinutes * 60)
        let baseDistance = activity.prescription.recommendedDistanceMeters
        let baseReps = activity.prescription.reps
        let records = context.progressStore.values
            .filter { $0.activityId == activity.activityId && $0.date < date }
            .sorted { ($0.endTime ?? $0.date) > ($1.endTime ?? $1.date) }
            .prefix(5)
        guard !records.isEmpty else {
            return (baseDuration, baseDistance, baseReps)
        }
        let fatigueMultiplier = scoringEngine.isRecoveryModeActive() ? 0.9 : 1.0
        let completionRatio = records.reduce(0.0) { partial, record in
            let target = Double(max(baseDuration, 1))
            let achieved = Double(record.durationSeconds ?? 0)
            let ratio: Double
            switch record.status {
            case .completed:
                ratio = 1.0
            case .skipped:
                ratio = 0.0
            case .partiallyCompleted, .pending, .inProgress, .paused:
                ratio = min(max(achieved / target, 0), 1)
            }
            return partial + ratio
        } / Double(records.count)
        let canProgress = completionRatio >= 0.85 && !scoringEngine.isRecoveryModeActive()
        let shouldEase = completionRatio < 0.55 || scoringEngine.isRecoveryModeActive()
        let durationStep = 60
        let adaptedDuration: Int
        if canProgress {
            adaptedDuration = min(baseDuration + durationStep, Int(Double(baseDuration) * 1.15))
        } else if shouldEase {
            adaptedDuration = max(60, (Int(Double(baseDuration) * fatigueMultiplier) / 60) * 60)
        } else {
            adaptedDuration = baseDuration
        }
        let adaptedReps: Int? = baseReps.map { target in
            let lastAchieved = records.compactMap(\.reps).max() ?? target
            if canProgress {
                return min(target, min(lastAchieved + 1, Int(Double(target) * 1.1)))
            }
            if shouldEase {
                return max(1, min(target, lastAchieved))
            }
            return min(target, max(lastAchieved, target - 1))
        }
        let adaptedDistance: Int? = baseDistance.map { target in
            let lastDistance = Int(records.compactMap(\.distanceMeters).max() ?? Double(target))
            if canProgress {
                return min(target, lastDistance + 100)
            }
            if shouldEase {
                return max(100, min(target, lastDistance))
            }
            return target
        }
        return (adaptedDuration, adaptedDistance, adaptedReps)
    }

    private func debug(_ stage: String, _ count: Int) {
#if DEBUG
        print("[\(stage)]: \(count) activities")
#endif
    }
}
