//
//  InsightsViewModel.swift
//  prenatalPregnancy
//

import Foundation
import UIKit

final class InsightsViewModel {
    private unowned var dataSource: InsightsDataSourceProtocol!
    private let dateService: DateServiceProtocol
    private let progressStore: ProgressStoreServiceProtocol

    init(
        dateService: DateServiceProtocol,
        progressStore: ProgressStoreServiceProtocol
    ) {
        self.dateService = dateService
        self.progressStore = progressStore
    }

    func attach(dataSource: InsightsDataSourceProtocol) {
        self.dataSource = dataSource
    }

    private var userProfile: UserProfile { dataSource.userProfile }
    private var allActivities: [ActivityDefinition] { dataSource.allActivities }
    private var progressStoreMap: [String: ActivityExecutionRecord] { dataSource.progressStore }
    private var userFeedback: [UserFeedback] { dataSource.userFeedback }
    private var istCalendar: Calendar { dateService.istCalendar }

    private func dayKey(_ date: Date) -> String {
        dateService.dayKey(date)
    }

    private func weekRecords(for gestationalWeek: Int) -> [String: [String: ActivityExecutionRecord]] {
        dataSource.weekRecords(for: gestationalWeek)
    }

    private func indexedProgressWeeks() -> [Int] {
        Array(Set(progressStoreMap.values.compactMap { record in
            record.firestoreWeek ?? gestationalWeek(for: record.date)
        }))
    }

    func insightHealthItemsForCurrentWeek() -> [HealthItem] {
    insightHealthItems(for: max(1, min(userProfile.gestationalWeek, PregnancyDateCalculation.maxGestationalWeek)))
}

    func insightHealthItems(for gestationalWeek: Int) -> [HealthItem] {
    let preferredWeek = max(1, min(gestationalWeek, PregnancyDateCalculation.maxGestationalWeek))

    return ActivityType.allCases.map { activity in
        let dates = insightDates(for: preferredWeek)
        let dayLabels = dates.map { DateService.graphDayLabelFormatter.string(from: $0) }
        let chartValues = dates.map { date in
            graphMetricValue(for: activity, sessions: liveSessions(for: activity, on: date, preferredWeek: preferredWeek))
        }
        let weeklySessions = dates.flatMap { liveSessions(for: activity, on: $0, preferredWeek: preferredWeek) }
        let progressSummary = insightProgressSummary(
            for: activity,
            sessions: weeklySessions,
            week: preferredWeek
        )
        
        return HealthItem(
            title: activity.title,
            progress: progressSummary.progressText,
            subtitle: progressSummary.subtitle,
            motivation: MotivationText.text(
                activity: progressSummary.motivationType,
                completed: progressSummary.completed,
                target: progressSummary.target
            ),
            chartValues: chartValues,
            chartLabels: dayLabels
        )
    }
}

    private func insightProgressSummary(
    for activity: ActivityType,
    sessions: [InsightSession],
    week: Int
    ) -> (progressText: String, subtitle: String, completed: Double, target: Double, motivationType: HealthActivityType) {
    switch activity {
    case .walking:
        let steps = totalMetricValue(named: "Steps", in: sessions)
        return (
            progressText: "\(Int(steps.rounded())) steps",
            subtitle: steps > 0 ? "Week \(week) walking total" : "No walking data in week \(week)",
            completed: steps,
            target: 8000,
            motivationType: .walking
        )
    case .exercise:
        let reps = totalMetricValue(named: "Reps", in: sessions)
        if reps > 0 {
            return (
                progressText: "\(Int(reps.rounded())) reps",
                subtitle: "Week \(week) exercise total",
                completed: reps,
                target: 40,
                motivationType: .exercise
            )
        }
        
        let minutes = totalMetricValue(named: "Duration", in: sessions)
        if minutes > 0 {
            return (
                progressText: "\(Int(minutes.rounded())) min",
                subtitle: "Week \(week) exercise total",
                completed: minutes,
                target: 30,
                motivationType: .exercise
            )
        }
        
        let sessionCount = Double(sessions.count)
        return (
            progressText: "\(Int(sessionCount.rounded())) sessions",
            subtitle: sessionCount > 0 ? "Week \(week) exercise count" : "No exercise data in week \(week)",
            completed: sessionCount,
            target: 30,
            motivationType: .exercise
        )
    case .yoga:
        let minutes = totalMetricValue(named: "Duration", in: sessions)
        if minutes > 0 {
            return (
                progressText: "\(Int(minutes.rounded())) min",
                subtitle: "Week \(week) yoga total",
                completed: minutes,
                target: 20,
                motivationType: .yoga
            )
        }
        
        let sessionCount = Double(sessions.count)
        return (
            progressText: "\(Int(sessionCount.rounded())) sessions",
            subtitle: sessionCount > 0 ? "Week \(week) yoga count" : "No yoga data in week \(week)",
            completed: sessionCount,
            target: 2,
            motivationType: .yoga
        )
    }
}

    private func totalMetricValue(named title: String, in sessions: [InsightSession]) -> Double {
    sessions.reduce(0.0) { partial, session in
        partial + metricValue(in: session.stats, titled: title)
    }
}

    func loadInsightsResponse() -> InsightsResponse? {
    let url = Bundle.main.bloomaResourceURL(named: "footerInsights", fileExtension: "json")
    
    guard let url else {
        print("footerInsights.json not found")
        return nil
    }
    
    do {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(InsightsResponse.self, from: data)
    } catch {
        print("Failed to decode footerInsights.json:", error)
        return nil
    }
}

    func activityWeekProgressSnapshot(for activity: ActivityType, gestationalWeek: Int) -> ActivityWeekProgressSnapshot? {
    let displayWeek = max(1, min(gestationalWeek, PregnancyDateCalculation.maxGestationalWeek))
    let dates = insightDates(for: displayWeek)
    guard !dates.isEmpty else { return nil }
    
    let days = dates.map { date -> InsightDay in
        let sessions = liveSessions(for: activity, on: date, preferredWeek: displayWeek)
        return InsightDay(
            dayKey: dayKey(date),
            dayLabel: DateService.graphDayLabelFormatter.string(from: date),
            dateDisplay: DateService.insightDateFormatter.string(from: date),
            sessions: sessions
        )
    }
    
    let values = days.map { day in
        graphMetricValue(for: activity, sessions: day.sessions)
    }
    
    let total = values.reduce(0, +)
    let activeDays = max(values.filter { $0 > 0 }.count, 1)
    let average = total / Double(activeDays)
    let metricTitle = graphMetricTitle(for: activity)
    let displayValue = graphDisplayValue(for: activity, averageValue: average)
    
    return ActivityWeekProgressSnapshot(
        graphSummary: InsightGraphSummary(
            title: activity.title,
            metricTitle: metricTitle,
            displayValue: displayValue,
            dayLabels: dates.map { DateService.graphDayLabelFormatter.string(from: $0) },
            dayValues: values
        ),
        days: days
    )
}

    func enrichedInsightSession(
    from session: InsightSession?,
    activityType: String,
    dateText: String
    ) -> InsightSession? {
    guard let session else { return nil }
    guard let date = DateService.dayKeyFormatter.date(from: dateText) else { return session }
    
    if let exactMatch = liveSession(activityId: session.id, activityType: activityType, on: date) {
        return exactMatch
    }
    
    return session
}

    func feedbackForInsightSession(
    sessionId: String?,
    activityType: String,
    dateText: String
    ) -> UserFeedback? {
    let selectedDate = DateService.dayKeyFormatter.date(from: dateText)
    let exactCandidates = candidateActivityIds(for: sessionId, activityType: activityType)
    let matchingFeedback = userFeedback.filter { feedback in
        guard exactCandidates.contains(feedback.activityId) || matchesActivityType(feedback.activityId, activityType: activityType) else {
            return false
        }
        
        guard let selectedDate else { return true }
        return istCalendar.isDate(feedback.createdAt, inSameDayAs: selectedDate)
    }
    
    return matchingFeedback.sorted { $0.createdAt > $1.createdAt }.first
        ?? userFeedback
            .filter { exactCandidates.contains($0.activityId) || matchesActivityType($0.activityId, activityType: activityType) }
            .sorted { $0.createdAt > $1.createdAt }
            .first
}

    func datesForGestationalWeek(_ gestationalWeek: Int) -> [Date] {
    let safeWeek = max(1, min(gestationalWeek, PregnancyDateCalculation.maxGestationalWeek))
    guard let startDate = startDateForGestationalWeek(safeWeek) else {
        return []
    }
    
    return (0..<7).compactMap { offset in
        istCalendar.date(byAdding: .day, value: offset, to: startDate)
    }
}

    func insightDates(for gestationalWeek: Int) -> [Date] {
    datesForStoredProgressWeek(gestationalWeek) ?? datesForGestationalWeek(gestationalWeek)
}

    private func datesForStoredProgressWeek(_ gestationalWeek: Int) -> [Date]? {
    guard !weekRecords(for: gestationalWeek).isEmpty else {
        return nil
    }

    guard let weekStart = startDateForGestationalWeek(gestationalWeek) else {
        return nil
    }

    return (0..<7).compactMap { offset in
        istCalendar.date(byAdding: .day, value: offset, to: weekStart)
    }
}

    private func startDateForGestationalWeek(_ gestationalWeek: Int) -> Date? {
    let safeWeek = max(1, min(gestationalWeek, PregnancyDateCalculation.maxGestationalWeek))
    let currentWeek = max(1, min(userProfile.gestationalWeek, PregnancyDateCalculation.maxGestationalWeek))
    let currentDay = max(0, min(userProfile.gestationalDay - 1, 6))
    let today = istCalendar.startOfDay(for: Date())

    guard let currentWeekStart = istCalendar.date(byAdding: .day, value: -currentDay, to: today) else {
        return nil
    }

    return istCalendar.date(byAdding: .day, value: (safeWeek - currentWeek) * 7, to: currentWeekStart)
}

    func liveSessions(for activity: ActivityType, on date: Date, preferredWeek: Int? = nil) -> [InsightSession] {
    let week = preferredWeek ?? gestationalWeek(for: date) ?? userProfile.gestationalWeek
    let dayRecords = weekRecords(for: week)[dayKey(date)] ?? [:]
    let records = Array(dayRecords.values)

    return records
        .filter { record in
            matchesActivityType(record.activityId, activityType: activity.rawValue)
                && record.status != .pending
                && record.status != .skipped
        }
        .sorted { lhs, rhs in
            (lhs.endTime ?? lhs.date) > (rhs.endTime ?? rhs.date)
        }
        .map(makeInsightSession(from:))
        .filter { !$0.stats.isEmpty }
}

    private func liveSession(activityId: String, activityType: String, on date: Date) -> InsightSession? {
        let sameDayRecords = progressStoreMap.values.filter { record in
            istCalendar.isDate(record.date, inSameDayAs: date)
                && record.status != .pending
                && record.status != .skipped
        }
        if let exactRecord = sameDayRecords
            .filter({ $0.activityId == activityId })
            .sorted(by: { ($0.endTime ?? $0.date) > ($1.endTime ?? $1.date) })
            .first {
            let session = makeInsightSession(from: exactRecord)
            return session.stats.isEmpty ? nil : session
        }
        guard let record = sameDayRecords
            .filter({ matchesActivityType($0.activityId, activityType: activityType) })
            .sorted(by: { ($0.endTime ?? $0.date) > ($1.endTime ?? $1.date) })
            .first else {
            return nil
        }
        let session = makeInsightSession(from: record)
        return session.stats.isEmpty ? nil : session
    }

    private func makeInsightSession(from record: ActivityExecutionRecord) -> InsightSession {
    let activityType = activityType(for: record.activityId)
    return InsightSession(
        id: record.activityId,
        sessionTitle: title(for: record.activityId),
        time: sessionTimeText(for: record),
        stats: sessionStats(for: record, activityType: activityType),
        vitals: sessionVitals(for: record),
        status: record.status
    )
}

    func graphMetricValue(for activity: ActivityType, sessions: [InsightSession]) -> Double {
    let performedSessions = sessions.filter { $0.status != .skipped }
    switch activity {
    case .walking:
        let steps = performedSessions.reduce(0) { partial, session in
            partial + metricValue(in: session.stats, titled: "Steps")
        }
        if steps > 0 {
            return steps
        }
        
        let distance = performedSessions.reduce(0) { partial, session in
            partial + metricValue(in: session.stats, titled: "Distance")
        }
        if distance > 0 {
            return distance
        }
        
        return 0
    case .exercise, .yoga:
        let metricTotal = performedSessions.reduce(0) { partial, session in
            partial + metricValue(in: session.stats, titled: "Duration")
        }
        if metricTotal > 0 {
            return metricTotal
        }
        
        return 0
    }
}

    private func graphMetricTitle(for activity: ActivityType) -> String {
    switch activity {
    case .walking:
        return "Average Steps"
    case .exercise:
        return "Average Active Minutes"
    case .yoga:
        return "Average Practice Minutes"
    }
}

    private func graphDisplayValue(for activity: ActivityType, averageValue: Double) -> String {
    switch activity {
    case .walking:
        return "\(Int(averageValue.rounded())) steps"
    case .exercise, .yoga:
        return "\(Int(averageValue.rounded())) min"
    }
}

    private func sessionStats(for record: ActivityExecutionRecord, activityType: ActivityType) -> [SessionMetric] {
    var metrics: [SessionMetric] = []
    
    if let durationSeconds = record.durationSeconds, durationSeconds > 0 {
        metrics.append(SessionMetric(title: "Duration", value: "\(max(1, durationSeconds / 60))", unit: "min"))
    }
    
    if activityType == .walking {
        if let distance = record.distanceMeters, distance > 0 {
            metrics.append(SessionMetric(title: "Distance", value: formatted(distance / 1000.0), unit: "km"))
        }
        if let steps = record.steps, steps > 0 {
            metrics.append(SessionMetric(title: "Steps", value: "\(steps)", unit: "steps"))
        }
    } else {
        if let reps = record.reps, reps > 0 {
            metrics.append(SessionMetric(title: "Reps", value: "\(reps)", unit: "reps"))
        }
        if let sets = record.sets, sets > 0 {
            metrics.append(SessionMetric(title: "Sets", value: "\(sets)", unit: "sets"))
        }
    }
    
    if let calories = record.activeEnergyKcal, calories > 0 {
        metrics.append(SessionMetric(title: "Calories", value: "\(Int(calories.rounded()))", unit: "kcal"))
    }
    
    return metrics
}

    private func sessionVitals(for record: ActivityExecutionRecord) -> [SessionMetric]? {
    var vitals: [SessionMetric] = []
    
    if let heartRate = record.avgHeartRate, heartRate > 0 {
        vitals.append(SessionMetric(title: "Heart Rate", value: "\(heartRate)", unit: "bpm"))
    }

    if let peakHeartRate = record.peakHeartRate ?? record.avgHeartRate, peakHeartRate > 0 {
        vitals.append(SessionMetric(title: "Peak Heart Rate", value: "\(peakHeartRate)", unit: "bpm"))
    }
    
    if let spo2 = record.avgSpO2, spo2 > 0 {
        vitals.append(SessionMetric(title: "Respiratory Rate", value: formatted(spo2), unit: "%"))
    }

    if let peakSpo2 = record.peakSpO2 ?? record.avgSpO2, peakSpo2 > 0 {
        vitals.append(SessionMetric(title: "Peak Respiratory Rate", value: formatted(peakSpo2), unit: "%"))
    }
    
    return vitals.isEmpty ? nil : vitals
}

    private func sessionTimeText(for record: ActivityExecutionRecord) -> String {
    if let startTime = record.startTime, let endTime = record.endTime {
        return "\(DateService.insightTimeFormatter.string(from: startTime)) - \(DateService.insightTimeFormatter.string(from: endTime))"
    }
    
    if let sessionTime = record.startTime ?? record.endTime {
        return DateService.insightTimeFormatter.string(from: sessionTime)
    }
    
    return "--"
}

    private func formatDuration(_ durationSeconds: Int) -> String {
    let minutes = max(0, durationSeconds / 60)
    if minutes >= 60 {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return remainingMinutes == 0 ? "\(hours)h" : "\(hours)h \(remainingMinutes)m"
    }
    return "\(max(1, minutes)) min"
}

    private func metricValue(in metrics: [SessionMetric], titled title: String) -> Double {
    Double(metrics.first(where: { $0.title.lowercased() == title.lowercased() })?.value ?? "") ?? 0
}

    private func title(for activityId: String) -> String {
    allActivities.first(where: { $0.activityId == activityId })?.metadata.title
        ?? activityId.replacingOccurrences(of: "_", with: " ").capitalized
}

    func activityType(for activityId: String) -> ActivityType {
    switch routineType(for: activityId) {
    case .walking:
        return .walking
    case .exercise:
        return .exercise
    case .yoga:
        return .yoga
    }
}

    func routineType(for activityId: String) -> RoutineType {
    let normalized = activityId.lowercased()

    if normalized.hasPrefix("walk_") || normalized.contains("walk") {
        return .walking
    }
    if normalized.hasPrefix("yoga_") || normalized.contains("yoga") {
        return .yoga
    }
    if normalized.hasPrefix("ex_") || normalized.contains("exercise") {
        return .exercise
    }

    if let matched = allActivities.first(where: { $0.activityId.caseInsensitiveCompare(activityId) == .orderedSame }) {
        let matchedId = matched.activityId.lowercased()
        if matchedId.hasPrefix("walk_") || matchedId.contains("walk") {
            return .walking
        }
        if matchedId.hasPrefix("yoga_") || matchedId.contains("yoga") {
            return .yoga
        }
    }

    return .exercise
}

    private func matchesActivityType(_ activityId: String, activityType activityTypeValue: String) -> Bool {
    routineType(for: activityId).rawValue == activityTypeValue.lowercased()
}

    func latestGestationalWeekWithProgress(for activity: ActivityType) -> Int? {
    indexedProgressWeeks().sorted().reversed().first { week in
        weekRecords(for: week).values.contains { dayRecords in
            dayRecords.values.contains { record in
                record.status != .pending
                    && matchesActivityType(record.activityId, activityType: activity.rawValue)
            }
        }
    }
}

    // NEW: Resolve the best week to show in Insights. Prefer the requested
    // week when it has activity data, otherwise fall back to the latest saved
    // Firestore week for that activity so the user sees real progress.
    func preferredInsightWeek(for activity: ActivityType, preferredWeek: Int) -> Int {
    let safePreferredWeek = max(1, min(preferredWeek, PregnancyDateCalculation.maxGestationalWeek))
    let preferredHasProgress = weekRecords(for: safePreferredWeek).values.contains { dayRecords in
        dayRecords.values.contains { record in
            record.status != .pending
                && matchesActivityType(record.activityId, activityType: activity.rawValue)
        }
    }

    if preferredHasProgress {
        return safePreferredWeek
    }

    return latestGestationalWeekWithProgress(for: activity) ?? safePreferredWeek
}

    func preferredHomeProgressWeek() -> Int {
    let currentWeek = max(1, min(userProfile.gestationalWeek, PregnancyDateCalculation.maxGestationalWeek))
    let hasCurrentWeekProgress = weekRecords(for: currentWeek).values.contains { dayRecords in
        dayRecords.values.contains { $0.status != .pending }
    }

    if hasCurrentWeekProgress {
        return currentWeek
    }

    return latestGestationalWeekWithAnyProgress() ?? currentWeek
}

    func latestGestationalWeekWithAnyProgress() -> Int? {
    indexedProgressWeeks().sorted().reversed().first { week in
        weekRecords(for: week).values.contains { dayRecords in
            dayRecords.values.contains { $0.status != .pending }
        }
    }
}

    func homeWeeklyActivitySummary(
    for activity: ActivityType,
    sessions: [InsightSession]
    ) -> (value: Double, unit: String, goal: Double, goalUnit: String, progress: Double) {
    switch activity {
    case .walking:
        let steps = totalMetricValue(named: "Steps", in: sessions)
        let goal = 8000.0
        return (
            value: steps,
            unit: "steps",
            goal: goal,
            goalUnit: "steps",
            progress: min(max(steps / goal, 0), 1)
        )
    case .exercise:
        let reps = totalMetricValue(named: "Reps", in: sessions)
        if reps > 0 {
            let goal = 300.0
            return (
                value: reps,
                unit: "reps",
                goal: goal,
                goalUnit: "reps",
                progress: min(max(reps / goal, 0), 1)
            )
        }

        let minutes = totalMetricValue(named: "Duration", in: sessions)
        if minutes > 0 {
            let goal = 30.0
            return (
                value: minutes,
                unit: "min",
                goal: goal,
                goalUnit: "min",
                progress: min(max(minutes / goal, 0), 1)
            )
        }

        let sessionCount = Double(sessions.count)
        let goal = 7.0
        return (
            value: sessionCount,
            unit: "sessions",
            goal: goal,
            goalUnit: "sessions",
            progress: min(max(sessionCount / goal, 0), 1)
        )
    case .yoga:
        let minutes = totalMetricValue(named: "Duration", in: sessions)
        if minutes > 0 {
            let goal = 20.0
            return (
                value: minutes,
                unit: "min",
                goal: goal,
                goalUnit: "min",
                progress: min(max(minutes / goal, 0), 1)
            )
        }

        let sessionCount = Double(sessions.count)
        let goal = 2.0
        return (
            value: sessionCount,
            unit: "sessions",
            goal: goal,
            goalUnit: "sessions",
            progress: min(max(sessionCount / goal, 0), 1)
        )
    }
}

    private func gestationalWeek(for date: Date) -> Int? {
    progressStore.gestationalWeek(for: date)
}

    private func candidateActivityIds(for sessionId: String?, activityType activityTypeValue: String) -> Set<String> {
    var ids = Set<String>()
    if let sessionId, !sessionId.isEmpty {
        ids.insert(sessionId)
    }
    allActivities
        .filter { matchesActivityType($0.activityId, activityType: activityTypeValue) }
        .forEach { ids.insert($0.activityId) }
    return ids
}

    private func formatted(_ value: Double) -> String {
    if value == floor(value) {
        return "\(Int(value))"
    }
    return String(format: "%.1f", value)
}
    func loadInsightsFromJSON() -> [InsightResponse] {
    
    guard let url = Bundle.main.bloomaResourceURL(named: "insights", fileExtension: "json") else {
        print("json not found")
        return []
    }
    
    do {
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode([InsightResponse].self, from: data)
        print("Decoded weeks count:", decoded.count)
        return decoded
    } catch {
        print("Decoding error:", error)
        return []
    }
}



    func getCategoriesForCurrentWeek() -> [Category] {
    
    let allWeeks = loadInsightsFromJSON()
    let currentWeek = userProfile.gestationalWeek
    
    let matchingWeeks = allWeeks.filter { $0.week == currentWeek }
    
    let mergedCategories = matchingWeeks.flatMap { $0.categories }
    
    print("Categories for week \(currentWeek):", mergedCategories.count)
    
    return mergedCategories
}


    func getInsightCardsForCurrentWeek() -> [Insights] {
    
    let categories = getCategoriesForCurrentWeek()
    
    return categories.compactMap { category in
        
        guard let firstItem = category.items.first else { return nil }
        
        return Insights(
            image: UIImage(named: category.heroImage)
                ?? UIImage(systemName: "sparkles")!,
            title: category.title,
            description: firstItem.shortDescription,
            points: "+25 pts"
        )
    }
}


    func getCategoryById(_ id: String) -> Category? {
    return getCategoriesForCurrentWeek()
        .first(where: { $0.id == id })
}


    func getDetailForCategory(id: String) -> (title: String, body: String)? {
    
    guard let category = getCategoryById(id),
          let firstItem = category.items.first else {
        return nil
    }
    
    return (
        title: firstItem.title,
        body: firstItem.detailDescription
    )
}
    func loadInsightDetail(section: String, week: Int) -> InsightDetail? {

    // Try exact week first
    let exactFile = "\(section)_week_\(week)"
    if let url = Bundle.main.bloomaResourceURL(named: exactFile, fileExtension: "json"),
       let data = try? Data(contentsOf: url),
       let decoded = try? JSONDecoder().decode(InsightDetail.self, from: data) {
        return decoded
    }

    // Fallback to week 1 if current week doesn't exist yet
    let fallbackFile = "\(section)_week_1"
    guard let url = Bundle.main.bloomaResourceURL(named: fallbackFile, fileExtension: "json"),
          let data = try? Data(contentsOf: url),
          let decoded = try? JSONDecoder().decode(InsightDetail.self, from: data)
    else {
        print("❌ Could not load \(fallbackFile).json")
        return nil
    }

    print("⚠️ \(exactFile).json not found, using week 1 fallback")
    return decoded
}
}
