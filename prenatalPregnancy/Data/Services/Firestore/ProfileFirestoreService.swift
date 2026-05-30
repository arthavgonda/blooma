//
//  ProfileFirestoreService.swift
//  prenatalPregnancy
//

import Foundation
import FirebaseFirestore

final class ProfileFirestoreService: ProfileFirestoreServiceProtocol {
    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func saveProfileToFirestore(userId: String, profile: UserProfile) {
        var userDetails: [String: Any] = [
            "name": profile.name,
            "userName": profile.userName.lowercased(),
            "email": profile.email?.lowercased() ?? "",
            "password": profile.password,
            "age": profile.age,
            "profileImageUrl": profile.profileImageUrl ?? "",
            "week": profile.gestationalWeek,
            "gestationalDay": profile.gestationalDay,
            "trimester": profile.trimester.rawValue,
            "activityLevel": profile.activityLevel.rawValue,
            "hasAppleWatch": profile.hasAppleWatch,
            "watchConnected": profile.hasAppleWatch,
            "medicalConditions": profile.medicalConditions.map { $0.rawValue },
            "conditions": profile.medicalConditions.map { $0.rawValue }
        ]
        if let lmpDate = profile.lmpDate {
            userDetails["lmpDate"] = lmpDate
        }
        if let eddDate = profile.eddDate {
            userDetails["eddDate"] = eddDate
        }
        db.collection("users").document(userId).setData([
            "userDetails": userDetails,
            "schemaVersion": 2,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }

    func createUserDocumentIfNeeded(userId: String, profile: UserProfile, completion: @escaping () -> Void) {
        let ref = db.collection("users").document(userId)
        ref.getDocument { snapshot, _ in
            guard snapshot?.exists != true else {
                completion()
                return
            }

            let userDetails: [String: Any] = [
                "name": profile.name,
                "userName": profile.userName.lowercased(),
                "email": profile.email?.lowercased() ?? "",
                "password": profile.password,
                "age": profile.age,
                "week": profile.gestationalWeek,
                "gestationalDay": profile.gestationalDay,
                "trimester": profile.trimester.rawValue,
                "activityLevel": profile.activityLevel.rawValue,
                "hasAppleWatch": profile.hasAppleWatch,
                "watchConnected": profile.hasAppleWatch,
                "medicalConditions": profile.medicalConditions.map { $0.rawValue },
                "conditions": profile.medicalConditions.map { $0.rawValue }
            ]

            ref.setData([
                "email": profile.email?.lowercased() ?? "",
                "createdAt": FieldValue.serverTimestamp(),
                "onboardingCompleted": false,
                "userDetails": userDetails,
                "schemaVersion": 2,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true) { _ in
                completion()
            }
        }
    }

    func onboardingCompleted(userId: String, completion: @escaping (Bool?) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            guard error == nil, let snapshot, snapshot.exists else {
                completion(nil)
                return
            }
            completion(snapshot.data()?["onboardingCompleted"] as? Bool ?? false)
        }
    }

    func markOnboardingCompleted(userId: String) {
        db.collection("users").document(userId).setData([
            "onboardingCompleted": true,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }

    func loadProfileFromFirestore(
        userId: String,
        completion: @escaping (UserProfile?) -> Void
    ) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Firestore load error:", error)
                completion(nil)
                return
            }
            guard let rawData = snapshot?.data() else {
                completion(nil)
                return
            }
            let data = (rawData["userDetails"] as? [String: Any]) ?? rawData
            let trimester: Trimester
            if let intValue = data["trimester"] as? Int {
                trimester = Trimester(rawValue: intValue) ?? .first
            } else if let stringValue = data["trimester"] as? String {
                switch stringValue.lowercased() {
                case "first": trimester = .first
                case "second": trimester = .second
                case "third": trimester = .third
                default: trimester = .first
                }
            } else {
                trimester = .first
            }
            let medicalConditions: [MedicalCondition]
            if let rawArray = (data["conditions"] as? [String]) ?? (data["medicalConditions"] as? [String]) {
                medicalConditions = rawArray.compactMap { MedicalCondition(rawValue: $0) }
            } else {
                medicalConditions = []
            }
            
            let profileName = data["name"] as? String ?? ""
            let profileEmail = data["email"] as? String
            let profileUserName = data["userName"] as? String ?? ""
            let profilePassword = data["password"] as? String ?? ""
            let profileImageUrl = data["profileImageUrl"] as? String
            let profileAge = data["age"] as? Int ?? 0
            let profileWeek = data["week"] as? Int ?? 1
            let profileDay = data["gestationalDay"] as? Int ?? 0
            let profileActivity = ActivityLevel(rawValue: data["activityLevel"] as? String ?? "low") ?? .low
            let profileWatch = (data["watchConnected"] as? Bool) ?? (data["hasAppleWatch"] as? Bool) ?? false
            let profileLmp = self.dateValue(from: data["lmpDate"])
            let profileEdd = self.dateValue(from: data["eddDate"])

            let profile = UserProfile(
                userId: UUID(uuidString: userId) ?? UUID(),
                profileImageData: nil,
                profileImageUrl: profileImageUrl,
                name: profileName,
                email: profileEmail,
                userName: profileUserName,
                password: profilePassword,
                age: profileAge,
                lmpDate: profileLmp,
                eddDate: profileEdd,
                gestationalWeek: profileWeek,
                gestationalDay: profileDay,
                trimester: trimester,
                medicalConditions: medicalConditions,
                activityLevel: profileActivity,
                hasAppleWatch: profileWatch
            )
            completion(profile)
        }
    }

    func loadAppContent(id: String) -> AppContent? {
        let fileName: String
        let jsonKey: String
        switch id {
        case "about_blooma":
            fileName = "about_blooma"
            jsonKey = "about_blooma"
        case "data_sources":
            fileName = "data_sources"
            jsonKey = "data_sources"
        case "research_insights":
            fileName = "research_insights"
            jsonKey = "research_insights"
        case "legal_compliance":
            fileName = "legal_compliance"
            jsonKey = "privacy_policy"
        default:
            return nil
        }
        guard let url = Bundle.main.bloomaResourceURL(named: fileName, fileExtension: "json") else {
            print(" File not found:", fileName)
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let decodedDict = try JSONDecoder().decode([String: AppContent].self, from: data)
            guard let content = decodedDict[jsonKey] else {
                print(" Key not found in JSON:", jsonKey)
                return nil
            }
            print(" Loaded:", content.title)
            print(" Sections:", content.sections.count)
            return content
        } catch {
            print(" Decode error:", error)
            return nil
        }
    }

    func dateValue(from value: Any?) -> Date? {
        if let date = value as? Date {
            return date
        }
        if let timestamp = value as? Timestamp {
            return timestamp.dateValue()
        }
        if let interval = value as? TimeInterval {
            return Date(timeIntervalSince1970: interval)
        }
        if let string = value as? String {
            return ISO8601DateFormatter().date(from: string)
        }
        return nil
    }
}
