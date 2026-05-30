//
//  ProfileViewModel.swift
//  prenatalPregnancy
//

import Foundation
import UIKit

final class ProfileViewModel {
    private let dateService: DateServiceProtocol
    private let progressStore: ProgressStoreServiceProtocol
    private weak var backing: DataControllerBacking?

    init(
        dateService: DateServiceProtocol,
        progressStore: ProgressStoreServiceProtocol,
        backing: DataControllerBacking?
    ) {
        self.dateService = dateService
        self.progressStore = progressStore
        self.backing = backing
    }

    func attach(backing: DataControllerBacking) {
        self.backing = backing
    }

    var onboardingGreetings: [String] {
        [
            "You’re in a safe space 🤍",
            "Let’s take this one step at a time",
            "Your body is doing something incredible",
            "We’re here to support you, always",
            "Gentle care for a beautiful journey",
            "Every pregnancy is unique — just like you",
            "Small steps, thoughtful care",
            "This journey deserves patience and love"
        ]
    }

    func onboardingGreeting(at index: Int) -> String {
        let messages = onboardingGreetings
        guard !messages.isEmpty else { return "" }
        return messages[index % messages.count]
    }

    func updateUserProfile(_ profile: UserProfile, replacing previous: UserProfile) {
        guard let backing else { return }
        backing.userProfile = profile
        backing.refreshProgressIndexesAfterProfileUpdate()
        if hasSignificantChange(old: previous, new: profile) {
            backing.invalidateTodayRoutine()
        }
    }

    func changePassword(old: String, new: String, confirm: String) -> (Bool, String) {
        guard let backing else { return (false, "Not available") }
        if old != backing.userProfile.password {
            return (false, "Old password is incorrect")
        }
        if new != confirm {
            return (false, "New passwords do not match")
        }
        if new.count < 6 {
            return (false, "Password must be at least 6 characters")
        }
        backing.userProfile.password = new
        backing.saveProfileToFirestore()
        return (true, "Password updated successfully")
    }

    func updateUserName(name: String) {
        guard let backing else { return }
        backing.userProfile.name = name
        guard backing.currentUserId != nil else { return }
        backing.saveProfileToFirestore()
    }

    func updateUserCredentials(username: String, password: String) {
        guard let backing else { return }
        backing.userProfile.userName = username
        backing.userProfile.password = password
        guard backing.currentUserId != nil else { return }
        backing.saveProfileToFirestore()
    }

    func updateUserAge(_ age: Int) {
        guard let backing else { return }
        backing.userProfile.age = age
        guard backing.currentUserId != nil else { return }
        backing.saveProfileToFirestore()
    }

    func updateGestationalWeek(_ week: Int, _ currentTrimester: Trimester) {
        guard let backing else { return }
        let lmpDate = PregnancyDateCalculation.estimatedLMP(
            fromWeek: week,
            day: 0,
            calendar: dateService.istCalendar
        )
        let calculation = PregnancyDateCalculation.fromLMP(lmpDate)
        backing.userProfile.lmpDate = calculation.lmpDate
        backing.userProfile.eddDate = calculation.eddDate
        backing.userProfile.gestationalWeek = week
        backing.userProfile.gestationalDay = 0
        backing.userProfile.trimester = currentTrimester
        progressStore.setInsightsStartWeek(week)
        progressStore.resetPregnancyProgressDayAnchor()
        guard backing.currentUserId != nil else { return }
        backing.saveProfileToFirestore()
    }

    func updatePregnancyDates(
        lmpDate: Date,
        eddDate: Date,
        gestationalWeek: Int,
        gestationalDay: Int,
        trimester: Trimester
    ) {
        guard let backing else { return }
        backing.userProfile.lmpDate = lmpDate
        backing.userProfile.eddDate = eddDate
        backing.userProfile.gestationalWeek = gestationalWeek
        backing.userProfile.gestationalDay = gestationalDay
        backing.userProfile.trimester = trimester
        progressStore.setInsightsStartWeek(gestationalWeek)
        progressStore.resetPregnancyProgressDayAnchor()
        guard backing.currentUserId != nil else { return }
        backing.saveProfileToFirestore()
    }

    func updateMedicalCondition(_ condition: [MedicalCondition]) {
        guard let backing else { return }
        backing.userProfile.medicalConditions = condition
        guard backing.currentUserId != nil else { return }
        backing.saveProfileToFirestore()
    }

    func updateActivityLevel(_ level: ActivityLevel) {
        guard let backing else { return }
        backing.userProfile.activityLevel = level
        guard backing.currentUserId != nil else { return }
        backing.saveProfileToFirestore()
    }

    func updateActivityLevelFromProgressIfNeeded(referenceDate: Date = Date()) {
        guard let backing else { return }
        let calendar = dateService.istCalendar
        let endDay = calendar.startOfDay(for: referenceDate)
        let startDay = calendar.date(byAdding: .day, value: -6, to: endDay) ?? endDay
        let recentRecords = progressStore.progressStore.values.filter { record in
            let day = calendar.startOfDay(for: record.date)
            return day >= startDay && day <= endDay
        }
        let completed = recentRecords.filter { $0.status == .completed }.count
        let skipped = recentRecords.filter { $0.status == .skipped }.count
        let activeDays = Set(
            recentRecords.filter { $0.status == .completed }.map { dateService.dayKey($0.date) }
        ).count
        let totalMinutes = recentRecords
            .filter { $0.status == .completed }
            .reduce(0) { $0 + (($1.durationSeconds ?? 0) / 60) }
        let nextLevel: ActivityLevel
        if completed >= 12 || activeDays >= 5 || totalMinutes >= 120 {
            nextLevel = .high
        } else if completed >= 5 || activeDays >= 3 || totalMinutes >= 45 {
            nextLevel = .moderate
        } else if skipped >= 3 && completed <= 2 {
            nextLevel = .low
        } else {
            nextLevel = backing.userProfile.activityLevel
        }
        guard nextLevel != backing.userProfile.activityLevel else { return }
        backing.userProfile.activityLevel = nextLevel
        backing.invalidateTodayRoutine()
        backing.saveProfileToFirestore()
    }

    func updateHasAppleWatch(_ watchStatus: Bool) {
        guard let backing else { return }
        backing.userProfile.hasAppleWatch = watchStatus
        guard backing.currentUserId != nil else { return }
        backing.saveProfileToFirestore()
    }

    func updateProfileImage(_ image: UIImage, userId: String) {
        guard let backing else { return }

        // Store locally immediately 
        backing.userProfile.profileImageData = image.jpegData(compressionQuality: 0.8)

        // Upload to Cloudinary
        CloudinaryService.shared.uploadProfileImage(image, userId: userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let url):
                    backing.userProfile.profileImageUrl = url   // store URL in profile
                    backing.saveProfileToFirestore()
                    print("Profile image uploaded:", url)
                case .failure(let error):
                    print("Profile image upload failed:", error.localizedDescription)
                    // Local data still saved — user sees image, re-upload on next launch
                }
            }
        }
    }

    private func hasSignificantChange(old: UserProfile, new: UserProfile) -> Bool {
        old.age != new.age
            || old.trimester != new.trimester
            || old.activityLevel != new.activityLevel
            || old.medicalConditions != new.medicalConditions
    }
}
