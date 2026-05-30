//
//  HomeViewModel.swift
//  prenatalPregnancy
//

import Foundation
import UIKit

final class HomeViewModel {
    private unowned var dataSource: HomeDataSourceProtocol!
    private let dateService: DateServiceProtocol
    private let progressStore: ProgressStoreServiceProtocol
    private let insightsViewModel: InsightsViewModel
    private let routineViewModel: RoutineViewModel

    init(
        dateService: DateServiceProtocol,
        progressStore: ProgressStoreServiceProtocol,
        insightsViewModel: InsightsViewModel,
        routineViewModel: RoutineViewModel
    ) {
        self.dateService = dateService
        self.progressStore = progressStore
        self.insightsViewModel = insightsViewModel
        self.routineViewModel = routineViewModel
    }

    func attach(dataSource: HomeDataSourceProtocol) {
        self.dataSource = dataSource
    }

    private var userProfile: UserProfile { dataSource.userProfile }
    private var progressStoreMap: [String: ActivityExecutionRecord] { dataSource.progressStore }

    private func dayKey(_ date: Date) -> String {
        dateService.dayKey(date)
    }

    func getWatchVitals() -> [WatchVitalViewModel] {
        let vitals = dataSource.latestHealthVitals
        let heartRate = vitals?.avgHeartRate ?? 0
        let spo2 = Int(vitals?.avgSpO2?.rounded() ?? 0)
        let sleepHours = 7
        let sleepMinutes = 0
        let todaySteps = vitals?.steps ?? 0
        return [
            WatchVitalViewModel(
                icon: "heart.fill",
                title: "Heart Rate",
                value: heartRate > 0 ? "\(heartRate) bpm" : "-- bpm",
                tint: .systemRed
            ),
            WatchVitalViewModel(
                icon: "lungs.fill",
                title: "SpO₂",
                value: spo2 > 0 ? "\(spo2)%" : "--%",
                tint: .systemBlue
            ),
            WatchVitalViewModel(
                icon: "bed.double.fill",
                title: "Sleep",
                value: "\(sleepHours)h \(sleepMinutes)m",
                tint: .systemPurple
            ),
            WatchVitalViewModel(
                icon: "figure.walk",
                title: "Steps",
                value: todaySteps > 0 ? "\(todaySteps.formatted())" : "--",
                tint: .systemGreen
            )
        ]
    }

    func getGreetingMessage() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let userName = userProfile.name
        if hour < 12 {
            return "Good Morning, \(userName)!"
        } else if hour < 17 {
            return "Good Afternoon, \(userName)!"
        } else {
            return "Good Evening, \(userName)!"
        }
    }

    func getVitalsSubtitle() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if userProfile.trimester == .first {
            return hour < 12 ? "Rest is important in early pregnancy." : "Your vitals look stable today."
        } else if userProfile.trimester == .second {
            return hour < 12 ? "Your energy levels are at their peak." : "Stay hydrated and keep moving."
        } else {
            return hour < 12 ? "Take it easy, you're doing great." : "Rest when you need to."
        }
    }

    func getDayItems() -> [DayItem] {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
        return dayLabels.enumerated().map { index, label in
            let adjustedIndex = (index + 1) % 7
            return DayItem(title: label, isSelected: adjustedIndex == weekday - 1)
        }
    }

    func homeWeeklyProgressSnapshot() -> HomeWeeklyProgressSnapshot {
        let displayWeek = insightsViewModel.preferredHomeProgressWeek()
        let dates = insightsViewModel.insightDates(for: displayWeek)
        let activityConfigs: [(routineType: RoutineType, activityType: ActivityType, category: String, imageName: String)] = [
            (.walking, .walking, "MOVEMENT", "walk"),
            (.exercise, .exercise, "STRENGTH", "excercise"),
            (.yoga, .yoga, "MINDFULNESS", "yoga")
        ]
        var chartValues: [RoutineType: [Double]] = [:]
        let activities = activityConfigs.map { config -> HomeWeeklyProgressActivity in
            let sessions = dates.flatMap {
                insightsViewModel.liveSessions(for: config.activityType, on: $0, preferredWeek: displayWeek)
            }
            let values = dates.map { date in
                insightsViewModel.graphMetricValue(
                    for: config.activityType,
                    sessions: insightsViewModel.liveSessions(for: config.activityType, on: date, preferredWeek: displayWeek)
                )
            }
            chartValues[config.routineType] = values
            let summary = insightsViewModel.homeWeeklyActivitySummary(for: config.activityType, sessions: sessions)
            return HomeWeeklyProgressActivity(
                routineType: config.routineType,
                category: config.category,
                name: config.activityType.title,
                value: summary.value,
                unit: summary.unit,
                goal: summary.goal,
                goalUnit: summary.goalUnit,
                progress: summary.progress,
                color: config.routineType.accentColor,
                imageName: config.imageName
            )
        }
        let totalProgress = activities.reduce(0.0) { $0 + $1.progress }
        let overallPercent = activities.isEmpty
            ? 0
            : Int(((totalProgress / Double(activities.count)) * 100).rounded())
        let hasAnySavedProgress = activities.contains { $0.value > 0 }
        let motivation = hasAnySavedProgress
            ? "Showing your saved progress from week \(displayWeek)."
            : getMotivationMessage()
        return HomeWeeklyProgressSnapshot(
            displayWeek: displayWeek,
            overallPercent: overallPercent,
            motivation: motivation,
            dayLabels: dates.map { DateService.graphDayLabelFormatter.string(from: $0) },
            chartValues: chartValues,
            activities: activities
        )
    }

    func progressBucket(completed: Int, total: Int) -> ProgressBucket {
        guard total > 0 else { return .notStarted }
        let p = Float(completed) / Float(total)
        switch p {
        case 0:
            return .notStarted
        case 0..<0.4:
            return .started
        case 0.4..<0.8:
            return .midway
        case 0.8..<1:
            return .almostDone
        default:
            return .completed
        }
    }

    func dynamicFootnote(routineType: RoutineType, completedItems: Int, totalItems: Int, rotationSeed: Int) -> [String] {
        routineType.footnotes(for: routineType, bucket: progressBucket(completed: completedItems, total: totalItems))
    }

    func getChartValues(for routineType: RoutineType) -> [Double] {
        return dataSource.currentUserId == nil
            ? getGuestChartData(for: routineType)
            : getRealChartData(for: routineType)
    }

    func getCurrentStreak() -> Int {
        let cal = dateService.istCalendarForProgress
        let today = cal.startOfDay(for: Date())
        var streak = 0
        var checkDate = today
        while true {
            let key = dayKey(checkDate)
            let dayRecords = progressStoreMap.values.filter { dayKey($0.date) == key }
            let hasActivity = dayRecords.contains { $0.status == .completed }
            if checkDate == today {
                if hasActivity { streak += 1 }
            } else {
                guard hasActivity else { break }
                streak += 1
            }
            guard let previous = cal.date(byAdding: .day, value: -1, to: checkDate) else { break }
            let reg = cal.startOfDay(for: getRegistrationDate())
            if previous < reg { break }
            checkDate = previous
        }
        UserDefaults.standard.set(streak, forKey: "currentStreak")
        return streak
    }

    func getLongestStreak() -> Int {
        let cal = dateService.istCalendarForProgress
        let reg = cal.startOfDay(for: getRegistrationDate())
        let today = cal.startOfDay(for: Date())
        guard let totalDays = cal.dateComponents([.day], from: reg, to: today).day else { return 0 }
        var longest = 0
        var current = 0
        for offset in 0...totalDays {
            guard let date = cal.date(byAdding: .day, value: offset, to: reg) else { continue }
            let key = dayKey(date)
            let hasActivity = progressStoreMap.values.contains {
                dayKey($0.date) == key && $0.status == .completed
            }
            if hasActivity {
                current += 1
                longest = max(longest, current)
            } else {
                current = 0
            }
        }
        return longest
    }

    func getOverallCompletionPercent(for date: Date) -> Int {
        let types = RoutineType.allCases
        var totalItems = 0
        var handled = 0
        for type in types {
            let items = routineViewModel.getRoutineItems(for: type, date: date)
            totalItems += items.count
            handled += items.filter {
                let p = progressStore.loadProgress(for: $0, date: date)
                return p.status == .completed || p.status == .skipped
            }.count
        }
        guard totalItems > 0 else { return 0 }
        return Int((Double(handled) / Double(totalItems)) * 100)
    }

    func getMotivationMessage() -> String {
        let isGuest = dataSource.currentUserId == nil
        if isGuest {
            return getGuestMotivation()
        } else {
            return getRealMotivation()
        }
    }

    func setupGuestRegistrationDate() {
        let cal = dateService.istCalendarForProgress
        let today = cal.startOfDay(for: Date())
        guard let sixDaysAgo = cal.date(byAdding: .day, value: -6, to: today) else { return }
        UserDefaults.standard.set(sixDaysAgo, forKey: "registrationDate")
    }

    func saveRegistrationDate() {
        dateService.saveRegistrationDate()
    }

    func getRegistrationDate() -> Date {
        dateService.getRegistrationDate()
    }

    func getWeekDayLabels() -> [String] {
        dateService.getWeekDayLabels()
    }

    func getWeekDayKeys() -> [String] {
        dateService.getWeekDayKeys()
    }

    private func getRealChartData(for routineType: RoutineType) -> [Double] {
        let keys = getWeekDayKeys()
        return keys.map { key -> Double in
            guard !key.isEmpty else { return -1 }
            let completed = progressStoreMap.values.filter {
                dayKey($0.date) == key && $0.status == .completed
            }
            guard !completed.isEmpty else { return 0 }
            switch routineType {
            case .walking:
                return Double(completed.count)
            case .exercise, .yoga:
                let durations = completed.compactMap { $0.durationSeconds }
                return durations.isEmpty ? 0 : Double(durations.reduce(0, +)) / 60.0
            }
        }
    }

    private func getGuestChartData(for routineType: RoutineType) -> [Double] {
        let cal = dateService.istCalendarForProgress
        let today = cal.startOfDay(for: Date())
        let reg = cal.startOfDay(for: getRegistrationDate())
        guard let daysSinceReg = cal.dateComponents([.day], from: reg, to: today).day else {
            return Array(repeating: -1, count: 7)
        }
        let seeds: [RoutineType: [Double]] = [
            .walking:  [3, 5, 2, 6, 4, 5, 3],
            .exercise: [18, 22, 15, 25, 20, 23, 19],
            .yoga:     [20, 25, 18, 28, 22, 26, 21]
        ]
        let base = seeds[routineType] ?? Array(repeating: 0, count: 7)
        var result: [Double] = []
        for slot in 0..<7 {
            if slot < 6 {
                if slot > daysSinceReg {
                    result.append(-1)
                } else if slot == daysSinceReg {
                    result.append(base[6])
                } else {
                    result.append(base[slot])
                }
            } else {
                result.append(daysSinceReg >= 6 ? base[6] : -1)
            }
        }
        return result
    }

    private func getGuestMotivation() -> String {
        guard let url = Bundle.main.bloomaResourceURL(named: "footerInsights", fileExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(InsightsResponse.self, from: data) else {
            return "A calm evening routine helps you and baby sleep better."
        }
        let week = userProfile.gestationalWeek
        let weekStr = "week_\(week)"
        let all = decoded.insights.flatMap { insight in
            insight.weeks.filter { $0.week == weekStr }.flatMap { weekData in
                weekData.days.flatMap { $0.sessions.map { $0.sessionTitle } }
            }
        }
        return all.randomElement() ?? "A calm evening routine helps you and baby sleep better."
    }

    private func getRealMotivation() -> String {
        let trimester = userProfile.trimester
        let hour = Calendar.current.component(.hour, from: Date())
        let messages: [Trimester: [String]] = [
            .first: [
                "Small steps today build strength for tomorrow.",
                "Rest when you need to, move when you can.",
                "Your body is doing incredible work right now.",
                "Gentle movement supports you and baby both.",
                "Every little effort counts — you're doing great."
            ],
            .second: [
                "Your energy is building — keep the momentum.",
                "Stay hydrated and keep moving, mama.",
                "You're halfway there — celebrate every session.",
                "Consistency now makes the third trimester easier.",
                "Baby feels your movement — keep it up!"
            ],
            .third: [
                "Take it one breath, one step at a time.",
                "Rest is just as important as movement now.",
                "You're in the home stretch — be proud.",
                "Listen to your body, it knows what it needs.",
                "Almost there — every session is a gift to baby."
            ]
        ]
        let pool = messages[trimester] ?? messages[.first]!
        if hour < 12 {
            return pool.first ?? "You're doing amazing."
        } else if hour < 17 {
            return pool[safe: 1] ?? pool.randomElement() ?? "Keep going!"
        } else {
            return pool.last ?? "Rest well tonight."
        }
    }
}
