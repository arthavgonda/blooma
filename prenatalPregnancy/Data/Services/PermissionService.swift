//
//  Permission.swift
//  prenatalPregnancy
//
//  Created by GEU on 03/04/26.
//

import UIKit
import CoreMotion
import AVFoundation
import Photos
import UserNotifications
import HealthKit

extension Notification.Name {
    static let healthVitalsDidUpdate = Notification.Name("healthVitalsDidUpdate")
}

private var activeHealthObserverTypes = Set<HKQuantityTypeIdentifier>()

final class HealthManager {
    
    static let shared = HealthManager()
    
    let healthStore = HKHealthStore()
    
    private let authorizationRequestedKey = "HealthKitAuthorizationRequested"
    private(set) var isUsingFreeAccountFallback = false
    
    private init() {}
    
    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    var canUseHealthKitQueries: Bool {
        isHealthDataAvailable && !isUsingFreeAccountFallback
    }
    
    func requestHealthAccess(completion: @escaping (Bool) -> Void) {
        guard isHealthDataAvailable else {
            isUsingFreeAccountFallback = true
            print("HealthKit unavailable")
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }
        
        let readIdentifiers: [HKQuantityTypeIdentifier] = [
            .heartRate,
            .stepCount,
            .activeEnergyBurned,
            .oxygenSaturation
        ]
        
        let shareIdentifiers: [HKQuantityTypeIdentifier] = [
            .activeEnergyBurned
        ]
        
        let readTypes = Set(readIdentifiers.compactMap { HKObjectType.quantityType(forIdentifier: $0) })
        var shareTypes = Set<HKSampleType>(shareIdentifiers.compactMap { HKObjectType.quantityType(forIdentifier: $0) })
        shareTypes.insert(HKObjectType.workoutType())
        
        guard readTypes.count == readIdentifiers.count,
              shareTypes.count == shareIdentifiers.count + 1 else {
            print("HealthKit authorization failed: missing one or more quantity types")
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }
        
        if UserDefaults.standard.bool(forKey: authorizationRequestedKey) {
            print("Authorization already determined")
        }
        
        print("Requesting HealthKit authorization")
        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { success, error in
            UserDefaults.standard.set(true, forKey: self.authorizationRequestedKey)
            let didConnect = success
            
            if let error {
                print("HealthKit authorization failure:", error.localizedDescription)
                if error.localizedDescription.localizedCaseInsensitiveContains("entitlement") {
                    self.isUsingFreeAccountFallback = true
                }
            } else {
                print("HealthKit authorization request completed:", didConnect)
                self.isUsingFreeAccountFallback = false
            }
            
            DispatchQueue.main.async {
                completion(didConnect)
            }
        }
    }
}

extension DataController {
    
    func getPermissionStatus(for type: PermissionType) -> PermissionStatus {
        
        switch type {
            
        case .motion:
            let status = CMMotionActivityManager.authorizationStatus()
            if status == .notDetermined { return .notDetermined }
            return status == .authorized ? .authorized : .denied
            
        case .camera:
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            if status == .notDetermined { return .notDetermined }
            return status == .authorized ? .authorized : .denied
            
        case .photo:
            let status = PHPhotoLibrary.authorizationStatus()
            if status == .notDetermined { return .notDetermined }
            return (status == .authorized || status == .limited) ? .authorized : .denied
            
        case .notification:
            var result: PermissionStatus = .notDetermined
            let semaphore = DispatchSemaphore(value: 0)
            
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                switch settings.authorizationStatus {
                case .notDetermined: result = .notDetermined
                case .authorized: result = .authorized
                default: result = .denied
                }
                semaphore.signal()
            }
            
            semaphore.wait()
            return result
        }
    }
    
    func requestPermission(_ type: PermissionType, completion: @escaping () -> Void) {
        
        switch type {
            
        case .motion:
            let manager = CMMotionActivityManager()
            manager.startActivityUpdates(to: .main) { _ in }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                manager.stopActivityUpdates()
                DispatchQueue.main.async {
                    completion()
                }
            }
            
        case .camera:
            AVCaptureDevice.requestAccess(for: .video) { _ in
                DispatchQueue.main.async { completion() }
            }
            
        case .photo:
            PHPhotoLibrary.requestAuthorization { _ in
                DispatchQueue.main.async { completion() }
            }
            
        case .notification:
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
                DispatchQueue.main.async { completion() }
            }
        }
    }
}

extension DataController {
    
    private var healthStore: HKHealthStore { HealthManager.shared.healthStore }
    
    func isHealthAvailable() -> Bool {
        return HealthManager.shared.canUseHealthKitQueries
    }
    
    func connectAppleWatch(completion: @escaping (Bool) -> Void) {
        
        if userProfile.hasAppleWatch {
            print("HealthKit profile flag already enabled; re-validating authorization")
        }
        
        HealthManager.shared.requestHealthAccess { [weak self] success in
            if success {
                self?.updateHasAppleWatch(true)
                self?.startHealthKitObservers()
                self?.refreshAndPublishTodayVitals()
                print("HealthKit connected")
            } else if HealthManager.shared.isUsingFreeAccountFallback {
                self?.updateHasAppleWatch(false)
                self?.refreshAndPublishTodayVitals()
                print("HealthKit unavailable for this signing account; continuing with free fallback")
                completion(true)
                return
            } else {
                print("HealthKit authorization did not complete")
            }
            
            completion(success)
        }
    }

    func requestStartupTrackingPermissions() {
        if userProfile.hasAppleWatch {
            startHealthKitObservers()
            refreshAndPublishTodayVitals()
        }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
            if let error {
                print("Notification permission error:", error)
            }
        }
    }

    func startHealthKitObservers() {
        guard isHealthAvailable() else { return }

        observeHealthQuantity(.heartRate)
        observeHealthQuantity(.oxygenSaturation)
        observeHealthQuantity(.stepCount)
        observeHealthQuantity(.activeEnergyBurned)
    }

    func refreshAndPublishTodayVitals() {
        fetchTodayVitals { record in
            self.latestHealthVitals = record
            NotificationCenter.default.post(name: .healthVitalsDidUpdate, object: self, userInfo: ["record": record])
        }
    }

    private func observeHealthQuantity(_ identifier: HKQuantityTypeIdentifier) {
        guard !activeHealthObserverTypes.contains(identifier),
              let type = HKObjectType.quantityType(forIdentifier: identifier) else { return }

        activeHealthObserverTypes.insert(identifier)

        let query = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, completionHandler, error in
            if let error {
                print("Health observer error:", error)
                completionHandler()
                return
            }

            self?.refreshAndPublishTodayVitals()
            completionHandler()
        }

        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: type, frequency: .immediate) { success, error in
            if let error {
                print("Health background delivery error:", error)
            } else if !success {
                print("Health background delivery was not enabled for \(identifier.rawValue)")
            }
        }
    }
}

extension DataController {
    
    func fetchTodayVitals(completion: @escaping (ActivityExecutionRecord) -> Void) {
        guard HealthManager.shared.canUseHealthKitQueries else {
            fetchFallbackTodayVitals(completion: completion)
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        
        var record = ActivityExecutionRecord(
            activityId: "watch_daily",
            date: now,
            firestoreWeek: nil,
            startTime: nil,
            endTime: nil,
            status: .completed,
            durationSeconds: nil,
            distanceMeters: nil,
            activeEnergyKcal: nil,
            avgHeartRate: nil,
            peakHeartRate: nil,
            avgSpO2: nil,
            peakSpO2: nil,
            steps: nil,
            reps: nil,
            sets: nil,
            feedback: nil
        )
        
        let group = DispatchGroup()
        
        // Steps
        group.enter()
        fetchQuantity(.stepCount, unit: HKUnit.count(), start: startOfDay, end: now) { value in
            record.steps = Int(value)
            group.leave()
        }
        
        // Distance
        group.enter()
        fetchQuantity(.distanceWalkingRunning, unit: HKUnit.meter(), start: startOfDay, end: now) { value in
            record.distanceMeters = value
            group.leave()
        }
        
        group.enter()
        fetchQuantity(.activeEnergyBurned, unit: HKUnit.kilocalorie(), start: startOfDay, end: now) { value in
            record.activeEnergyKcal = value
            group.leave()
        }
        
        // Heart Rate (avg)
        group.enter()
        fetchAverageHeartRate(start: startOfDay, end: now) { value in
            record.avgHeartRate = Int(value)
            group.leave()
        }

        group.enter()
        fetchAverageSpO2(start: startOfDay, end: now) { value in
            record.avgSpO2 = value
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(record)
        }
    }
    
    private func fetchFallbackTodayVitals(completion: @escaping (ActivityExecutionRecord) -> Void) {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        
        var record = ActivityExecutionRecord(
            activityId: "free_fallback_daily",
            date: now,
            firestoreWeek: nil,
            startTime: nil,
            endTime: nil,
            status: .completed,
            durationSeconds: nil,
            distanceMeters: nil,
            activeEnergyKcal: nil,
            avgHeartRate: nil,
            peakHeartRate: nil,
            avgSpO2: nil,
            peakSpO2: nil,
            steps: nil,
            reps: nil,
            sets: nil,
            feedback: nil
        )
        
        guard CMPedometer.isStepCountingAvailable() else {
            print("Free fallback: pedometer step counting unavailable")
            DispatchQueue.main.async {
                completion(record)
            }
            return
        }
        
        let pedometer = CMPedometer()
        pedometer.queryPedometerData(from: startOfDay, to: now) { data, error in
            if let error {
                print("Free fallback pedometer error:", error.localizedDescription)
            }
            
            let steps = data?.numberOfSteps.intValue
            let distance = data?.distance?.doubleValue
            record.steps = steps
            record.distanceMeters = distance
            record.activeEnergyKcal = self.estimatedCalories(steps: steps, durationSeconds: nil)
            
            DispatchQueue.main.async {
                completion(record)
            }
        }
    }
    
    private func estimatedCalories(steps: Int?, durationSeconds: Int?) -> Double? {
        if let steps, steps > 0 {
            return Double(steps) * 0.04
        }
        
        guard let durationSeconds, durationSeconds > 0 else {
            return nil
        }
        
        let defaultWeightKg = 70.0
        let gentleWalkingMET = 3.5
        return gentleWalkingMET * defaultWeightKg * (Double(durationSeconds) / 3600.0)
    }
}


extension DataController {
    
    private func fetchQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date, completion: @escaping (Double) -> Void) {
        
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion(0)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            
            let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
            
            DispatchQueue.main.async {
                completion(value)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchAverageHeartRate(start: Date, end: Date, completion: @escaping (Double) -> Void) {
        
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            completion(0)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
            
            let value = result?.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min")) ?? 0
            
            DispatchQueue.main.async {
                completion(value)
            }
        }
        
        healthStore.execute(query)
    }

    private func fetchAverageSpO2(start: Date, end: Date, completion: @escaping (Double) -> Void) {
        
        guard let type = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else {
            completion(0)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, _ in
            
            let value = (result?.averageQuantity()?.doubleValue(for: .percent()) ?? 0) * 100
            
            DispatchQueue.main.async {
                completion(value)
            }
        }
        
        healthStore.execute(query)
    }
}

extension DataController {
    
    private struct WorkoutSession {
        var startTime: Date
        var activityId: String
    }
    
    private static var currentSession: WorkoutSession?
    
    func startWorkout(activityId: String) {
        DataController.currentSession = WorkoutSession(
            startTime: Date(),
            activityId: activityId
        )
        
        print("Workout Started")
    }
    
    func stopWorkout(completion: @escaping (ActivityExecutionRecord?) -> Void) {
        
        guard let session = DataController.currentSession else {
            completion(nil)
            return
        }
        
        let endTime = Date()
        let durationSeconds = Int(endTime.timeIntervalSince(session.startTime))
        
        fetchTodayVitals { [weak self] vitals in
            let fallbackCalories = self?.estimatedCalories(steps: vitals.steps, durationSeconds: durationSeconds)
            
            let record = ActivityExecutionRecord(
                activityId: session.activityId,
                date: vitals.date,
                firestoreWeek: nil,
                startTime: session.startTime,
                endTime: endTime,
                status: .completed,
                durationSeconds: durationSeconds,
                distanceMeters: vitals.distanceMeters,
                activeEnergyKcal: vitals.activeEnergyKcal ?? fallbackCalories,
                avgHeartRate: vitals.avgHeartRate,
                peakHeartRate: vitals.peakHeartRate ?? vitals.avgHeartRate,
                avgSpO2: vitals.avgSpO2,
                peakSpO2: vitals.peakSpO2 ?? vitals.avgSpO2,
                steps: vitals.steps,
                reps: nil,
                sets: nil,
                feedback: nil
            )
            
            print("Workout Completed:", record)
            
            self?.saveWorkoutRecord(record)
            
            DataController.currentSession = nil
            
            completion(record)
        }
    }
    
    private func saveWorkoutRecord(_ record: ActivityExecutionRecord) {
        print("Saved:", record)
    }
}
