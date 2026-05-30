//
//  ProgressStoreService.swift
//  prenatalPregnancy
//

import Foundation
import FirebaseFirestore

final class ProgressStoreService: ProgressStoreServiceProtocol {

    private let dateService: DateServiceProtocol
    private weak var backing: DataControllerBacking?
    weak var firestoreEncoder: ProgressRecordFirestoreEncoding?
    weak var progressFirestore: ProgressFirestoreServiceProtocol?

    var progressStore: [String: ActivityExecutionRecord] = [:]
    private var progressWeekIndex: [Int: [String: [String: ActivityExecutionRecord]]] = [:]
    var userFeedback: [UserFeedback] = []

    init(dateService: DateServiceProtocol, backing: DataControllerBacking?) {
        self.dateService = dateService
        self.backing = backing
    }

    func attach(backing: DataControllerBacking) {
        self.backing = backing
    }

    var currentUserId: String? {
        backing?.currentUserId
    }

    /// Canonical key for one activity record per calendar day (IST).
    /// Using the day key instead of a timestamp prevents duplicate records
    /// when saveProgress is called multiple times for the same activity on
    /// the same day (e.g., resume after pause). One key → one record per day.
    func progressKey(activityId: String, date: Date) -> String {
        "\(activityId)_\(dayKey(date))"
    }

    func progressEntry(activityId: String, on date: Date) -> (key: String, record: ActivityExecutionRecord)? {
        let exactKey = progressKey(activityId: activityId, date: date)
        if let exactRecord = progressStore[exactKey] {
            return (exactKey, exactRecord)
        }
        return progressStore
            .filter { _, record in
                record.activityId == activityId && dayKey(record.date) == dayKey(date)
            }
            .sorted { lhs, rhs in
                (lhs.value.endTime ?? lhs.value.date) > (rhs.value.endTime ?? rhs.value.date)
            }
            .first
            .map { (key: $0.key, record: $0.value) }
    }

    private func progressWeekDocumentId(for week: Int) -> String {
        "W\(max(1, min(week, PregnancyDateCalculation.maxGestationalWeek)))"
    }

    private func firestoreRecordMapKey(for key: String) -> String {
        key
            .replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "/", with: "_")
    }

    func replaceProgressState(
        restored: [String: ActivityExecutionRecord],
        feedbackLookup: [UUID: UserFeedback]
    ) {
        progressStore = restored
        rebuildProgressWeekIndex()
        userFeedback = feedbackLookup.values.sorted { $0.createdAt > $1.createdAt }
        backing?.notifyProgressChanged()
    }

    func clearProgressState() {
        progressStore.removeAll()
        progressWeekIndex.removeAll()
        userFeedback.removeAll()
        backing?.notifyProgressChanged()
    }

    private func rebuildProgressWeekIndex() {
        progressWeekIndex.removeAll()

        for (key, record) in progressStore {
            // NEW: Prefer the explicit Firestore week for Insights indexing.
            // This keeps graph data aligned with progress_weeks/Wxx even when
            // the local profile timeline has shifted after the record was saved.
            guard let week = record.firestoreWeek ?? gestationalWeek(for: record.date) else { continue }
            let keyForDay = dayKey(record.date)
            progressWeekIndex[week, default: [:]][keyForDay, default: [:]][key] = record
        }
    }

    func weekRecords(for gestationalWeek: Int) -> [String: [String: ActivityExecutionRecord]] {
        progressWeekIndex[gestationalWeek] ?? [:]
    }

    var progressIndexedWeeks: [Int] {
        Array(progressWeekIndex.keys)
    }

    func reindexProgressRecord(key: String, record: ActivityExecutionRecord) {
        progressStore[key] = record
        if let week = record.firestoreWeek ?? gestationalWeek(for: record.date) {
            progressWeekIndex[week, default: [:]][dayKey(record.date), default: [:]][key] = record
        }
    }

    private func removeProgressIndexEntry(for key: String) {
        for week in Array(progressWeekIndex.keys) {
            let dayKeys = progressWeekIndex[week].map { Array($0.keys) } ?? []

            for day in dayKeys {
                progressWeekIndex[week]?[day]?[key] = nil

                if progressWeekIndex[week]?[day]?.isEmpty == true {
                    progressWeekIndex[week]?[day] = nil
                }
            }

            if progressWeekIndex[week]?.isEmpty == true {
                progressWeekIndex[week] = nil
            }
        }
    }

    private func progressWeek(for date: Date) -> Int? {
        if dayKey(date) == dayKey(Date()) {
            guard let profile = backing?.userProfile else { return nil }
            return max(1, min(profile.gestationalWeek, PregnancyDateCalculation.maxGestationalWeek))
        }
        return gestationalWeek(for: date)
    }

    private func pregnancyProgressDefaultsKey(_ suffix: String) -> String {
        dateService.pregnancyProgressDefaultsKey(suffix, userId: backing?.currentUserId)
    }

    func setInsightsStartWeek(_ week: Int) {
        let safeWeek = max(1, min(week, PregnancyDateCalculation.maxGestationalWeek))
        UserDefaults.standard.set(safeWeek, forKey: pregnancyProgressDefaultsKey("insightsStartWeek"))
    }

    func insightsStartWeek() -> Int {
        guard let profile = backing?.userProfile else { return 1 }
        let currentWeek = max(1, min(profile.gestationalWeek, PregnancyDateCalculation.maxGestationalWeek))
        let defaults = UserDefaults.standard
        let key = pregnancyProgressDefaultsKey("insightsStartWeek")

        if defaults.object(forKey: key) != nil {
            return max(1, min(defaults.integer(forKey: key), currentWeek))
        }

        let earliestWeekWithProgress = progressWeekIndex.keys
            .filter { $0 >= 1 && $0 <= currentWeek }
            .min()

        return earliestWeekWithProgress ?? currentWeek
    }

    func availableInsightWeeks() -> [Int] {
        guard let profile = backing?.userProfile else { return [1] }
        let currentWeek = max(1, min(profile.gestationalWeek, PregnancyDateCalculation.maxGestationalWeek))
        return Array(1...currentWeek)
    }

    func resetPregnancyProgressDayAnchor() {
        UserDefaults.standard.set(dayKey(Date()), forKey: pregnancyProgressDefaultsKey("lastDayKey"))
    }

    func refreshPregnancyProgressIfNeeded(referenceDate: Date = Date()) {
        guard var profile = backing?.userProfile else { return }
        let todayKey = dayKey(referenceDate)
        let defaultsKey = pregnancyProgressDefaultsKey("lastDayKey")
        let defaults = UserDefaults.standard

        guard let lastKey = defaults.string(forKey: defaultsKey), !lastKey.isEmpty else {
            defaults.set(todayKey, forKey: defaultsKey)
            return
        }

        guard lastKey != todayKey,
              let lastDate = dateService.date(fromDayKey: lastKey),
              let today = dateService.date(fromDayKey: todayKey) else {
            return
        }

        let elapsedDays = dateService.istCalendar.dateComponents([.day], from: lastDate, to: today).day ?? 0
        guard elapsedDays > 0 else { return }

        let totalDays = max(0, profile.gestationalDay + elapsedDays)
        profile.gestationalWeek = min(PregnancyDateCalculation.maxGestationalWeek, max(1, profile.gestationalWeek + (totalDays / 7)))
        profile.gestationalDay = totalDays % 7
        profile.trimester = PregnancyDateCalculation.trimester(for: profile.gestationalWeek)
        backing?.userProfile = profile

        defaults.set(todayKey, forKey: defaultsKey)
        refreshProgressIndexesAfterProfileUpdate()

        // BUG-016 FIX: Use savePregnancyProgressFieldsToFirestore instead of
        // saveProfileToFirestore. The midnight refresh fires during every cold
        // launch (sceneWillEnterForeground races bootstrapLoggedInUser), so at
        // that moment userProfile may still be the blank placeholder created in
        // SceneDelegate. Writing the full profile would wipe name/userName/
        // password/profileImageUrl. updateData() only touches these three fields
        // and is safe to call even before the full profile has been fetched.
        backing?.savePregnancyProgressFieldsToFirestore(
            week: profile.gestationalWeek,
            gestationalDay: profile.gestationalDay,
            trimester: profile.trimester
        )
    }

    // NEW: Rebuild the Insights week/day cache after the actual pregnancy
    // profile loads. The Firestore listener can start while the app still has
    // the placeholder profile, which can index valid records into the wrong
    // gestational week and leave the Insights cards at zero.
    func refreshProgressIndexesAfterProfileUpdate() {
        rebuildProgressWeekIndex()
        backing?.notifyProgressChanged()
    }

    func progressWeekWritePayload(
        record: ActivityExecutionRecord,
        item: RoutineItem? = nil,
        feedback: UserFeedback? = nil,
        documentKey: String
    ) -> (documentId: String, data: [String: Any])? {
        refreshPregnancyProgressIfNeeded()

        guard let week = progressWeek(for: record.date) else { return nil }
        guard let firestoreEncoder else { return nil }

        let safeDayKey = dayKey(record.date)
        let recordFieldKey = firestoreRecordMapKey(for: documentKey)
        let startOfDay = dateService.startOfDayInIST(for: record.date)
        var recordPayload = firestoreEncoder.firestoreData(for: record, item: item, feedback: feedback)
        recordPayload["documentKey"] = documentKey
        recordPayload["week"] = week
        recordPayload["dayKey"] = safeDayKey

        let dayPrefix = "days.\(safeDayKey)"
        let recordPrefix = "\(dayPrefix).records.\(recordFieldKey)"

        return (
            documentId: progressWeekDocumentId(for: week),
            data: [
                "week": week,
                "updatedAt": FieldValue.serverTimestamp(),
                "\(dayPrefix).dayKey": safeDayKey,
                "\(dayPrefix).date": Timestamp(date: startOfDay),
                "\(dayPrefix).updatedAt": FieldValue.serverTimestamp(),
                recordPrefix: recordPayload
            ]
        )
    }

    func loadProgress(for item: RoutineItem, date: Date) -> RoutineItemProgress {
        let record = progressEntry(activityId: item.activityId, on: date)?.record

        return RoutineItemProgress(
            activityId: item.activityId,
            date: date,
            elapsedSeconds: record?.durationSeconds ?? 0,
            heartRateAverage: record?.avgHeartRate,
            caloriesBurned: record?.activeEnergyKcal,
            distanceCovered: record?.distanceMeters,
            repetitionsCompleted: item.routineType == .walking ? record?.steps : record?.reps,
            status: record?.status ?? .pending
        )
    }

    func saveProgress(
        for item: RoutineItem,
        elapsedSeconds: Int?,
        status: RoutineItemStatus,
        date: Date
    ) {
        let existingEntry = progressEntry(activityId: item.activityId, on: date)
        let key = existingEntry?.key ?? progressKey(activityId: item.activityId, date: date)

        var record = existingEntry?.record ?? ActivityExecutionRecord(
            activityId: item.activityId,
            date: date,
            firestoreWeek: nil,
            startTime: Date(),
            endTime: nil,
            status: .pending,
            durationSeconds: nil,
            distanceMeters: nil,
            activeEnergyKcal: nil,
            avgHeartRate: nil,
            peakHeartRate: nil,
            avgSpO2: nil,
            peakSpO2: nil,
            steps: nil,
            reps: item.reps,
            sets: item.sets,
            feedback: nil
        )

        // Time tracking
        if record.startTime == nil {
            record.startTime = Date()
        }

        if status == .completed || status == .skipped {
            record.endTime = Date()
        }

        // Duration (from old system)
        if let elapsed = elapsedSeconds {
            record.durationSeconds = elapsed
        }

        // Distance
        if status != .skipped, let distance = item.distanceMeters {
            record.distanceMeters = Double(distance)
        }

        if status != .skipped {
            record.reps = item.reps
            record.sets = item.sets
        }

        // Status update
        record.status = status

        // Save
        if let week = progressWeek(for: record.date) {
            record.firestoreWeek = week
        }

        // Save
        progressStore[key] = record
        removeProgressIndexEntry(for: key)
        if let week = record.firestoreWeek ?? progressWeek(for: record.date) {
            progressWeekIndex[week, default: [:]][dayKey(record.date), default: [:]][key] = record
        }
        backing?.notifyProgressChanged()

        progressFirestore?.saveProgressToFirestore(record: record, item: item, feedback: nil, documentKey: key)

        // Rotation update (only when completed)
        if status == .completed {
            backing?.appendRotationHistory(activityId: item.activityId, date: date)
            backing?.updateActivityLevelFromProgressIfNeeded(referenceDate: date)
        }
    }

    func markItemCompleted(_ item: inout RoutineItem, date: Date) {
        item.status = .completed
        saveProgress(for: item, elapsedSeconds: item.durationSeconds, status: .completed, date: date)
    }

    func markItemSkipped(_ item: inout RoutineItem, date: Date) {
        item.status = .skipped
        saveProgress(for: item, elapsedSeconds: nil, status: .skipped, date: date)
    }

    func updateProgressVitals(
        for item: RoutineItem,
        date: Date,
        heartRate: Int?,
        peakHeartRate: Int?,
        spo2: Int?,
        peakSpo2: Int?,
        calories: Int?,
        steps: Int?,
        elapsedSeconds: Int?,
        status: RoutineItemStatus
    ) {
        let existingEntry = progressEntry(activityId: item.activityId, on: date)
        let key = existingEntry?.key ?? progressKey(activityId: item.activityId, date: date)

        var record = existingEntry?.record ?? ActivityExecutionRecord(
            activityId: item.activityId,
            date: date,
            firestoreWeek: nil,
            startTime: Date(),
            endTime: nil,
            status: status,
            durationSeconds: nil,
            distanceMeters: nil,
            activeEnergyKcal: nil,
            avgHeartRate: nil,
            peakHeartRate: nil,
            avgSpO2: nil,
            peakSpO2: nil,
            steps: nil,
            reps: item.reps,
            sets: item.sets,
            feedback: nil
        )

        if record.startTime == nil {
            record.startTime = Date()
        }

        if status == .completed {
            record.endTime = Date()
        }

        record.status = status
        record.durationSeconds = elapsedSeconds ?? record.durationSeconds
        record.distanceMeters = record.distanceMeters ?? Double(item.distanceMeters ?? 0)
        record.reps = item.routineType == .walking ? item.reps : steps
        record.sets = item.sets

        if let heartRate, heartRate > 0 {
            record.avgHeartRate = heartRate
        }

        if let peakHeartRate, peakHeartRate > 0 {
            record.peakHeartRate = max(record.peakHeartRate ?? 0, peakHeartRate)
        }

        if let spo2, spo2 > 0 {
            record.avgSpO2 = Double(spo2)
        }

        if let peakSpo2, peakSpo2 > 0 {
            record.peakSpO2 = max(record.peakSpO2 ?? 0, Double(peakSpo2))
        }

        if let calories {
            record.activeEnergyKcal = Double(max(0, calories))
        }

        if let steps, item.routineType == .walking {
            record.steps = max(0, steps)
        }

        if let week = progressWeek(for: record.date) {
            record.firestoreWeek = week
        }

        progressStore[key] = record
        removeProgressIndexEntry(for: key)
        if let week = record.firestoreWeek ?? progressWeek(for: record.date) {
            progressWeekIndex[week, default: [:]][dayKey(record.date), default: [:]][key] = record
        }
        backing?.notifyProgressChanged()

        progressFirestore?.saveProgressToFirestore(record: record, item: item, feedback: nil, documentKey: key)

        if status == .completed {
            backing?.updateActivityLevelFromProgressIfNeeded(referenceDate: date)
        }
    }

    func latestProgressKey(activityId: String, date: Date) -> String? {
        progressStore
            .filter { _, record in
                record.activityId == activityId && dayKey(record.date) == dayKey(date)
            }
            .sorted { lhs, rhs in lhs.value.date > rhs.value.date }
            .first?
            .key
    }

    func getAllProgress() -> [ActivityExecutionRecord] {
        return Array(progressStore.values)
    }

    func getProgress(for activityId: String) -> [ActivityExecutionRecord] {
        return progressStore.values.filter { $0.activityId == activityId }
    }

    func gestationalWeek(for date: Date) -> Int? {
        let startDate = dateService.istCalendar.startOfDay(for: pregnancyReferenceLMP())
        let normalizedDate = dateService.istCalendar.startOfDay(for: date)
        let dayOffset = dateService.istCalendar.dateComponents([.day], from: startDate, to: normalizedDate).day ?? 0
        guard dayOffset >= 0 else { return nil }
        return min(max((dayOffset / 7) + 1, 1), PregnancyDateCalculation.maxGestationalWeek)
    }

    private func pregnancyReferenceLMP() -> Date {
        guard let profile = backing?.userProfile else {
            return dateService.istCalendar.startOfDay(for: Date())
        }
        if let lmp = profile.lmpDate {
            return dateService.istCalendar.startOfDay(for: lmp)
        }

        let estimated = PregnancyDateCalculation.estimatedLMP(
            fromWeek: profile.gestationalWeek,
            day: profile.gestationalDay,
            calendar: dateService.istCalendar,
            today: Date()
        )
        return dateService.istCalendar.startOfDay(for: estimated)
    }

    private func dayKey(_ date: Date) -> String {
        dateService.dayKey(date)
    }
}
