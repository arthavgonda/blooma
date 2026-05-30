//
//  FocusWorkoutSessionManager.swift
//  prenatalPregnancy
//
//  Created by Codex on 15/04/26.
//

import Foundation
import HealthKit
import CoreMotion

struct FocusWorkoutStats: Equatable {
    var isConnected = false
    var heartRate: Int?
    var peakHeartRate: Int?
    var spo2: Int?
    var peakSpo2: Int?
    var calories: Int?
    var steps: Int?
}

private struct FocusWorkoutMetricSample {
    let timestamp: Date
    let heartRate: Int?
    let calories: Int
    let steps: Int
}

final class FocusWorkoutHealthTracker {

    var onStatsChanged: ((FocusWorkoutStats) -> Void)?

    private let healthStore = HKHealthStore()
    private let pedometer = CMPedometer()
    private var pollingTimer: Timer?
    private var liveQueries: [HKQuery] = []
    private var startDate = Date()
    private var stats = FocusWorkoutStats()
    private var latestPhoneSteps: Int?
    private var maxCalories = 0
    private var maxSteps = 0
    private var heartRateValues: [Int] = []
    private var stepValues: [Int] = []
    private var calorieValues: [Int] = []
    private var metricSamples: [FocusWorkoutMetricSample] = []

    func start() {
        startDate = Date()
        latestPhoneSteps = nil
        maxCalories = 0
        maxSteps = 0
        heartRateValues.removeAll()
        stepValues.removeAll()
        calorieValues.removeAll()
        metricSamples.removeAll()
        startPhoneStepUpdates()
        
        guard HealthManager.shared.canUseHealthKitQueries else {
            print("Focus workout using free fallback; HealthKit entitlement unavailable")
            stats = FocusWorkoutStats(isConnected: false)
            onStatsChanged?(stats)
            pollFreeFallback()
            startPolling()
            return
        }

        requestAuthorization { [weak self] success in
            guard let self else { return }
            guard success else {
                self.stats = FocusWorkoutStats(isConnected: false)
                self.onStatsChanged?(self.stats)
                self.pollFreeFallback()
                self.startPolling()
                return
            }
            self.stats = FocusWorkoutStats(isConnected: true)
            self.onStatsChanged?(self.stats)
            self.startHealthKitLiveQueries()
            self.poll()
            self.startPolling()
        }
    }

    func stop() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        pedometer.stopUpdates()
        liveQueries.forEach { healthStore.stop($0) }
        liveQueries.removeAll()
    }

    private func startPolling() {
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.pollPhoneSteps()

            if HealthManager.shared.canUseHealthKitQueries {
                self?.poll()
            } else {
                self?.pollFreeFallback()
            }

            self?.publishStatsFromArrays()
        }
        RunLoop.main.add(pollingTimer!, forMode: .common)
    }

    private func startPhoneStepUpdates() {
        guard CMPedometer.isStepCountingAvailable() else { return }

        pedometer.startUpdates(from: startDate) { [weak self] data, error in
            if let error {
                print("Focus pedometer live update error:", error.localizedDescription)
            }

            guard let steps = data?.numberOfSteps.intValue else { return }

            DispatchQueue.main.async {
                guard let self else { return }

                self.latestPhoneSteps = steps
                self.recordSteps(steps)
                self.recordEstimatedCaloriesIfNeeded()
            }
        }
    }

    private func pollPhoneSteps() {
        guard CMPedometer.isStepCountingAvailable() else { return }

        pedometer.queryPedometerData(from: startDate, to: Date()) { [weak self] data, error in
            if let error {
                print("Focus pedometer step query error:", error.localizedDescription)
            }

            guard let self, let steps = data?.numberOfSteps.intValue else { return }

            DispatchQueue.main.async {
                self.latestPhoneSteps = steps
                self.recordSteps(steps)
                self.recordEstimatedCaloriesIfNeeded()
            }
        }
    }

    private func startHealthKitLiveQueries() {
        liveQueries.forEach { healthStore.stop($0) }
        liveQueries.removeAll()

        startLiveQuantityQuery(.heartRate, unit: HKUnit(from: "count/min")) { [weak self] value in
            guard let self, let value, value > 0 else { return }
            self.recordHeartRate(Int(value.rounded()))
        }

        startLiveQuantityQuery(.activeEnergyBurned, unit: .kilocalorie(), aggregate: true) { [weak self] value in
            guard let self, let value else { return }
            self.recordCalories(Int(value.rounded()))
        }

        startLiveQuantityQuery(.stepCount, unit: .count(), aggregate: true) { [weak self] value in
            guard let self, let value else { return }
            self.recordSteps(Int(value.rounded()))
        }
    }

    private func startLiveQuantityQuery(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        aggregate: Bool = false,
        handler: @escaping (Double?) -> Void
    ) {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil)
        var anchor: HKQueryAnchor?
        var cumulativeValue = 0.0

        let query = HKAnchoredObjectQuery(
            type: type,
            predicate: predicate,
            anchor: anchor,
            limit: HKObjectQueryNoLimit
        ) { _, samples, _, newAnchor, _ in
            anchor = newAnchor
            self.handleQuantitySamples(samples, unit: unit, aggregate: aggregate, cumulativeValue: &cumulativeValue, handler: handler)
        }

        query.updateHandler = { _, samples, _, newAnchor, _ in
            anchor = newAnchor
            self.handleQuantitySamples(samples, unit: unit, aggregate: aggregate, cumulativeValue: &cumulativeValue, handler: handler)
        }

        liveQueries.append(query)
        healthStore.execute(query)
    }

    private func handleQuantitySamples(
        _ samples: [HKSample]?,
        unit: HKUnit,
        aggregate: Bool,
        cumulativeValue: inout Double,
        handler: @escaping (Double?) -> Void
    ) {
        let quantitySamples = samples as? [HKQuantitySample] ?? []
        let value: Double?

        if aggregate {
            cumulativeValue += quantitySamples.reduce(0) { $0 + $1.quantity.doubleValue(for: unit) }
            value = cumulativeValue
        } else {
            value = quantitySamples
                .sorted { $0.endDate > $1.endDate }
                .first?
                .quantity
                .doubleValue(for: unit)
        }

        DispatchQueue.main.async {
            handler(value)
        }
    }

    private func requestAuthorization(completion: @escaping (Bool) -> Void) {
        HealthManager.shared.requestHealthAccess { success in
            completion(success)
        }
    }
    
    private func pollFreeFallback() {
        guard CMPedometer.isStepCountingAvailable() else {
            recordCalories(estimatedCalories(steps: nil, durationSeconds: Int(Date().timeIntervalSince(startDate))))
            publishStatsFromArrays()
            return
        }
        
        pedometer.queryPedometerData(from: startDate, to: Date()) { [weak self] data, error in
            guard let self else { return }
            
            if let error {
                print("Focus free fallback pedometer error:", error.localizedDescription)
            }
            
            let steps = data?.numberOfSteps.intValue
            let elapsed = Int(Date().timeIntervalSince(self.startDate))
            DispatchQueue.main.async {
                self.recordSteps(steps)
                self.recordCalories(self.estimatedCalories(steps: steps, durationSeconds: elapsed))
            }
        }
    }
    
    private func estimatedCalories(steps: Int?, durationSeconds: Int) -> Int? {
        if let steps, steps > 0 {
            return Int((Double(steps) * 0.04).rounded())
        }
        
        guard durationSeconds > 0 else { return nil }
        
        let defaultWeightKg = 70.0
        let gentleWalkingMET = 3.5
        let calories = gentleWalkingMET * defaultWeightKg * (Double(durationSeconds) / 3600.0)
        return Int(calories.rounded())
    }

    private func poll() {
        let elapsed = Int(Date().timeIntervalSince(startDate))

        fetchLatest(.heartRate, unit: HKUnit(from: "count/min"), allowRecentFallback: true) { [weak self] value in
            guard let value, value > 0 else { return }
            self?.recordHeartRate(Int(value.rounded()))
        }

        fetchLatest(.oxygenSaturation, unit: .percent(), allowRecentFallback: true) { [weak self] value in
            guard let value, value > 0 else { return }
            let spo2 = Int((value * 100).rounded())
            self?.update {
                $0.spo2 = spo2
                $0.peakSpo2 = max($0.peakSpo2 ?? 0, spo2)
            }
        }

        fetchSum(.activeEnergyBurned, unit: .kilocalorie()) { [weak self] value in
            guard let self else { return }

            let healthCalories = Int(value.rounded())
            let fallbackCalories = self.estimatedCalories(
                steps: self.latestPhoneSteps ?? self.stats.steps,
                durationSeconds: elapsed
            )

            self.recordCalories(healthCalories > 0 ? healthCalories : fallbackCalories)
        }

        fetchSum(.stepCount, unit: .count()) { [weak self] value in
            guard let self else { return }

            let healthSteps = Int(value.rounded())
            let mergedSteps = max(healthSteps, self.latestPhoneSteps ?? 0)

            self.recordSteps(mergedSteps)
        }
    }

    private func recordHeartRate(_ heartRate: Int) {
        guard heartRate > 0 else { return }
        heartRateValues.append(heartRate)
        publishStatsFromArrays()
    }

    private func recordSteps(_ steps: Int?) {
        let steps = nextSteps(steps)
        stepValues.append(steps)
        publishStatsFromArrays()
    }

    private func recordCalories(_ calories: Int?) {
        let calories = nextCalories(calories)
        calorieValues.append(calories)
        publishStatsFromArrays()
    }

    private func recordEstimatedCaloriesIfNeeded() {
        guard maxCalories <= 0 else { return }
        let elapsed = Int(Date().timeIntervalSince(startDate))
        recordCalories(estimatedCalories(steps: latestPhoneSteps ?? stats.steps, durationSeconds: elapsed))
    }

    private func publishStatsFromArrays() {
        if let heartRate = heartRateValues.last {
            stats.heartRate = heartRate
            stats.peakHeartRate = max(stats.peakHeartRate ?? 0, heartRateValues.max() ?? heartRate)
        }

        if let steps = stepValues.last {
            stats.steps = steps
        }

        if let calories = calorieValues.last {
            stats.calories = calories
        }

        metricSamples.append(
            FocusWorkoutMetricSample(
                timestamp: Date(),
                heartRate: stats.heartRate,
                calories: stats.calories ?? 0,
                steps: stats.steps ?? 0
            )
        )

        DispatchQueue.main.async { [stats] in
            self.onStatsChanged?(stats)
        }
    }

    private func nextSteps(_ steps: Int?) -> Int {
        maxSteps = max(maxSteps, steps ?? 0)
        return maxSteps
    }

    private func nextCalories(_ calories: Int?) -> Int {
        maxCalories = max(maxCalories, calories ?? 0)
        return maxCalories
    }

    private func update(_ mutation: (inout FocusWorkoutStats) -> Void) {
        mutation(&stats)
        DispatchQueue.main.async { [stats] in
            self.onStatsChanged?(stats)
        }
    }

    private func fetchLatest(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        allowRecentFallback: Bool = false,
        completion: @escaping (Double?) -> Void
    ) {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion(nil)
            return
        }

        let now = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [sort]) { [weak self] _, samples, _ in
            let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
            if value == nil, allowRecentFallback {
                self?.fetchRecentLatest(type: type, unit: unit, end: now, completion: completion)
                return
            }
            DispatchQueue.main.async {
                completion(value)
            }
        }

        healthStore.execute(query)
    }

    private func fetchRecentLatest(
        type: HKQuantityType,
        unit: HKUnit,
        end: Date,
        completion: @escaping (Double?) -> Void
    ) {
        let recentStart = Calendar.current.date(byAdding: .minute, value: -30, to: end) ?? end.addingTimeInterval(-1800)
        let predicate = HKQuery.predicateForSamples(withStart: recentStart, end: end)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
            let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit)
            DispatchQueue.main.async {
                completion(value)
            }
        }

        healthStore.execute(query)
    }

    private func fetchSum(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        completion: @escaping (Double) -> Void
    ) {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion(0)
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date())
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
            DispatchQueue.main.async {
                completion(value)
            }
        }

        healthStore.execute(query)
    }
}
