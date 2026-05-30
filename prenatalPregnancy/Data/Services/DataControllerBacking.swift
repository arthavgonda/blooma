//
//  DataControllerBacking.swift
//  prenatalPregnancy
//

import Foundation

protocol DataControllerBacking: AnyObject {
    var userProfile: UserProfile { get set }
    var currentUserId: String? { get set }

    /// True only after a successful loadProfileFromFirestore() call.
    /// Guards saveProfileToFirestore() so a blank placeholder profile
    /// can never overwrite real Firestore data (race-condition fix).
    var isProfileLoaded: Bool { get set }

    func notifyProgressChanged()

    /// Saves the full UserProfile to Firestore.
    /// No-op until isProfileLoaded is true.
    func saveProfileToFirestore()

    /// Saves ONLY the pregnancy-progress fields (week, gestationalDay,
    /// trimester) that the midnight refresh computed. This avoids the
    /// race where refreshPregnancyProgressIfNeeded fires before
    /// loadProfileFromFirestore completes and would wipe identity fields.
    func savePregnancyProgressFieldsToFirestore(week: Int, gestationalDay: Int, trimester: Trimester)

    func updateActivityLevelFromProgressIfNeeded(referenceDate: Date)
    func appendRotationHistory(activityId: String, date: Date)
    func loadProgressFromFirestore(completion: @escaping () -> Void)
    func refreshProgressIndexesAfterProfileUpdate()
    func invalidateTodayRoutine()
}
