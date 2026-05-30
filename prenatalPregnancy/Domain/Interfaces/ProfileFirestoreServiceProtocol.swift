//
//  ProfileFirestoreServiceProtocol.swift
//  prenatalPregnancy
//

import Foundation

protocol ProfileFirestoreServiceProtocol: AnyObject {
    func saveProfileToFirestore(userId: String, profile: UserProfile)
    func createUserDocumentIfNeeded(userId: String, profile: UserProfile, completion: @escaping () -> Void)
    func onboardingCompleted(userId: String, completion: @escaping (Bool?) -> Void)
    func markOnboardingCompleted(userId: String)
    func loadProfileFromFirestore(
        userId: String,
        completion: @escaping (UserProfile?) -> Void
    )
    func loadAppContent(id: String) -> AppContent?
    func dateValue(from value: Any?) -> Date?
}
